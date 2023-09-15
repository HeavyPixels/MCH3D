module triangle_fifo(
  input clk,
  input rst,
  input [239:0] data_in,
  input push,
  output full,
  output almost_full,
  output [239:0] data_out,
  input pull,
  output empty,
  output almost_empty
);

//reg [239:0] buffer [0:255];
reg [8:0] wr_ptr;
reg [8:0] rd_ptr;

//assign data_out = buffer[rd_ptr[7:0]];
wire [8:0] count = wr_ptr - rd_ptr;

assign empty = count == 0;
assign almost_empty = count <= 1;
assign almost_full = count >= 252;
assign full = count[8];

pmi_ram_dp
#(
  .pmi_wr_addr_depth    (256), // integer
  .pmi_wr_addr_width    (8), // integer
  .pmi_wr_data_width    (240), // integer
  .pmi_rd_addr_depth    (256), // integer
  .pmi_rd_addr_width    (8), // integer
  .pmi_rd_data_width    (240), // integer
  .pmi_regmode          ("noreg"), // "reg"|"noreg"
  .pmi_resetmode        ("sync"), // "async"|"sync"
  //.pmi_init_file        ( ), // string
  //.pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("iCE40UP")  // "iCE40UP"|"common"
) triangle_fifo_ram (
  .Data      (data_in),  // I:
  .WrAddress (wr_ptr[7:0]),  // I:
  .RdAddress (rd_ptr[7:0]),  // I:
  .WrClock   (clk),  // I:
  .RdClock   (clk),  // I:
  .WrClockEn (1'h1),  // I:
  .RdClockEn (1'h1),  // I:
  .WE        (push && !full),  // I:
  .Reset     (rst),  // I:
  .Q         (data_out)   // O:
);

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