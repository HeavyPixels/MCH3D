module triangle_fifo(
  input clk,
  input rst,
  input [119:0] data_in,
  input push,
  output full,
  output almost_full,
  output [119:0] data_out,
  input pull,
  output empty,
  output almost_empty
);

//reg [239:0] buffer [0:255];
reg [9:0] wr_ptr;
reg [9:0] rd_ptr;

//assign data_out = buffer[rd_ptr[7:0]];
wire [9:0] count = wr_ptr - rd_ptr;

assign empty = count == 0;
assign almost_empty = count <= 1;
assign almost_full = count >= 504;
assign full = count[9];

pmi_ram_dp
#(
  .pmi_wr_addr_depth    (512), // integer
  .pmi_wr_addr_width    (9), // integer
  .pmi_wr_data_width    (120), // integer
  .pmi_rd_addr_depth    (512), // integer
  .pmi_rd_addr_width    (9), // integer
  .pmi_rd_data_width    (120), // integer
  .pmi_regmode          ("noreg"), // "reg"|"noreg"
  .pmi_resetmode        ("sync"), // "async"|"sync"
  //.pmi_init_file        ( ), // string
  //.pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("iCE40UP")  // "iCE40UP"|"common"
) triangle_fifo_ram (
  .Data      (data_in),  // I:
  .WrAddress (wr_ptr[8:0]),  // I:
  .RdAddress (rd_ptr[8:0]),  // I:
  .WrClock   (clk),  // I:
  .RdClock   (clk),  // I:
  .WrClockEn (1'h1),  // I:
  .RdClockEn (1'h1),  // I:
  .WE        (push && !full),  // I:
  .Reset     (rst),  // I:
  .Q         (data_out)   // O:
);
/*triangle_fifo_ram _triangle_fifo_ram(
  .wr_clk_i(clk),
  .rd_clk_i(clk),
  .rst_i(rst),
  .wr_clk_en_i(1'h1),
  .rd_en_i(1'h1),
  .rd_clk_en_i(1'h1),
  .wr_en_i(push && !full),
  .wr_data_i(data_in),
  .wr_addr_i(wr_ptr[7:0]),
  .rd_addr_i(rd_ptr[7:0]),
  .rd_data_o(data_out)
);*/

always@(posedge clk)
begin
  if(rst)
  begin
    wr_ptr <= 0;
    rd_ptr <= 0;
  end
  else
  begin
    if(push && !full)
    begin
      //buffer[wr_ptr[7:0]] <= data_in;
      wr_ptr <= wr_ptr + 1;
    end
    if(pull && !empty)
    begin
      rd_ptr <= rd_ptr + 1;
    end
  end
end

endmodule