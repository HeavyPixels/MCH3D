module basicfifo #(
  parameter WIDTH=8,
  parameter LOG_DEPTH=4,
  parameter ALMOST_FULL=9,
  parameter ALMOST_EMPTY=1
) (
  input clk,
  input rst,
  input [WIDTH-1:0] data_in,
  input push,
  output full,
  output almost_full,
  output [WIDTH-1:0] data_out,
  input pull,
  output empty,
  output almost_empty
);

reg [WIDTH-1:0] buffer [0:(1<<LOG_DEPTH)-1];
reg [LOG_DEPTH:0] wr_ptr;
reg [LOG_DEPTH:0] rd_ptr;

assign data_out = buffer[rd_ptr[LOG_DEPTH-1:0]];
wire [LOG_DEPTH:0] count = wr_ptr - rd_ptr;

assign empty = count == 0;
assign almost_empty = count <= ALMOST_EMPTY;
assign almost_full = count >= ALMOST_FULL;
assign full = count[LOG_DEPTH];

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
      buffer[wr_ptr[LOG_DEPTH-1:0]] <= data_in;
      wr_ptr <= wr_ptr + 1;
    end
    if(pull && !empty)
    begin
      rd_ptr <= rd_ptr + 1;
    end
  end
end

endmodule