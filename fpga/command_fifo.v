module command_fifo (
  input clk,
  input rst,
  input [7:0] data_in,
  input push,
  output full,
  //output almost_full,
  output [7:0] data_out,
  input pull,
  output empty//,
  //output almost_empty
);

//localparam ALMOST_EMPTY = 1;
//localparam ALMOST_FULL = 2046;

reg [9:0] wr_ptr;
reg [9:0] rd_ptr;
wire we = push && !full;

commandfifo_ram _commandfifo_ram(
  .wr_clk_i(clk),
  .rd_clk_i(clk),
  .rst_i(rst),
  .wr_clk_en_i(1'h1),
  .rd_en_i(1'h1),
  .rd_clk_en_i(1'h1),
  .wr_en_i(we),
  .wr_data_i(data_in),
  .wr_addr_i(wr_ptr[8:0]),
  .rd_addr_i(rd_ptr[8:0]),
  .rd_data_o(data_out)
);

wire [9:0] count = wr_ptr - rd_ptr;

//assign almost_empty = count <= ALMOST_EMPTY;
//assign almost_full = count >= ALMOST_FULL;
assign empty = count == 0;
assign full = count[9];

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
      wr_ptr <= wr_ptr + 1;
    end
    if(pull && !empty)
    begin
      rd_ptr <= rd_ptr + 1;
    end
  end
end

endmodule