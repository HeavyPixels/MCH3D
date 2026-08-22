module command_fifo (
  input clk,
  input rst,
  input [15:0] data_in,
  input push,
  output full,
  //output almost_full,
  output [15:0] data_out,
  input pull,
  output empty//,
  //output almost_empty
);

//localparam ALMOST_EMPTY = 1;
//localparam ALMOST_FULL = 2046;

reg [15:0] write_buffer;
reg write_buffer_state;
reg write_buffer_clear;

reg did_pull;

always@(posedge clk)
begin
  if(push) write_buffer <= data_in;
  did_pull <= pull;
end
  
always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    write_buffer_state <= 0;
  end
  else
  begin
    if(push)
      write_buffer_state <= 1;
    else if (write_buffer_clear)
      write_buffer_state <= 0;
  end
end

reg [14:0] wr_ptr;
reg [14:0] rd_ptr;
reg fifo_we;

reg [13:0] fifo_addr;

always@*
begin
  write_buffer_clear = 0;
  // Read by default
  fifo_we = 0;
  fifo_addr = rd_ptr[13:0];
  if(!did_pull && write_buffer_state && !full)
  begin
    // do write
    fifo_addr = wr_ptr[13:0];
    fifo_we = 1;
    write_buffer_clear = 1;
  end
end

SP256K commandfifo_ram (
  .AD       (fifo_addr),
  .DI       (write_buffer),
  .MASKWE   (4'b1111),
  .WE       (fifo_we),
  .CS       (1'b1),
  .CK       (clk),
  .STDBY    (1'b0),
  .SLEEP    (1'b0),
  .PWROFF_N (1'b1),
  .DO       (data_out)
);

wire [14:0] count = wr_ptr - rd_ptr;

//assign almost_empty = count <= ALMOST_EMPTY;
//assign almost_full = count >= ALMOST_FULL;

// Only reset empty once a read has been done.
wire empty_count = (count == 0);
reg empty_reg;
always@(posedge clk)
begin
  empty_reg <= empty_count || (empty_reg && fifo_we);
end
assign empty = empty_count || empty_reg;
assign full = count[14];

always@(posedge clk)
begin
  if(rst)
  begin
    wr_ptr <= 0;
    rd_ptr <= 0;
  end
  else
  begin
    if(fifo_we)
    begin
      wr_ptr <= wr_ptr + 1;
    end
    if(pull && !empty)
    begin
      rd_ptr <= rd_ptr + 1;
    end
  end
end

endmodule