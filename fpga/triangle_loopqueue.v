module triangle_loopqueue(
  input clk,
  input rst,
  input [15:0] data_add,
  input add,
  input [239:0] data_write,
  input write,
  output full,
  output almost_full,
  output [239:0] data_read,
  input read,
  output empty,
  output almost_empty
);

reg [15:0] data_add_buf;
reg add_ready;

reg [8:0] start_ptr;
reg [7:0] read_ptr;
reg [7:0] write_ptr;
reg [8:0] end_ptr;

reg pending_rollover;

//assign data_out = buffer[rd_ptr[7:0]];
wire [8:0] count = end_ptr - start_ptr;

assign empty = count == 0;
assign almost_empty = count <= 4;
assign almost_full = count >= 252;
assign full = count[8];

reg [29:0] add_byte_en;

wire [29:0] byte_en = write ? 30'h3FFFFFFF : add_byte_en;

wire [239:0] data_add_wide = {15{data_add_buf}};

wire [239:0] data_mux = write ? data_write : data_add_wide;

wire [7:0] write_addr = write ? write_ptr : (start_ptr - 1);

pmi_ram_dp_be
#(
  .pmi_wr_addr_depth    (256), // integer
  .pmi_wr_addr_width    (8), // integer
  .pmi_wr_data_width    (240), // integer
  .pmi_rd_addr_depth    (256), // integer
  .pmi_rd_addr_width    (8), // integer
  .pmi_rd_data_width    (240), // integer
  .pmi_regmode          ("noreg"), // "reg"|"noreg"
  .pmi_resetmode        ("sync"), // "async"|"sync"
  .pmi_family           ("iCE40UP"),  // "iCE40UP"|"common"
  .pmi_byte_size        (8)  // integer   
) triangle_fifo_ram (
  .Data      (data_mux),  // I:
  .WrAddress (write_addr),  // I:
  .RdAddress (read_ptr),  // I:
  .WrClock   (clk),  // I:
  .RdClock   (clk),  // I:
  .WrClockEn (1'h1),  // I:
  .RdClockEn (1'h1),  // I:
  .WE        ((write || add_ready) && !full),  // I:
  .Reset     (rst),  // I:
  .ByteEn    (byte_en[29:0]),  // I:
  .Q         (data_read)   // O:
);

always@(posedge clk)
begin
  if(rst)
  begin
    add_ready <= 0;
    data_add_buf <= 0;
  end
  else
  begin
    if(add)
    begin
      add_ready <= 1;
      data_add_buf <= data_add;
    end
    else if(!write && !full)
    begin
      add_ready <= 0;
    end
  end
end

always@(posedge clk)
begin
  if(rst)
  begin
    start_ptr <= 0;
    write_ptr <= 0;
    read_ptr <= 0;
    end_ptr <= 0;
    add_byte_en <= {2'h3, 28'h00000000};
    pending_rollover = 0;
  end
  else
  begin
    if(add && !full)
    begin
      add_byte_en <= {add_byte_en[1:0], add_byte_en[29:2]};
      if(add_byte_en[0]) start_ptr <= start_ptr - 1;
    end
    if(pending_rollover && (write || read))
    begin
      pending_rollover = 0;
      write_ptr <= start_ptr;
    end
    else if(write)
    begin
      write_ptr <= write_ptr + 1;
    end
    if(read && !empty)
    begin
      if(read_ptr == end_ptr)
      begin
          read_ptr <= start_ptr;
          pending_rollover = 1;
      end
      else
      begin
        read_ptr <= read_ptr + 1;
      end
    end
  end
end

endmodule