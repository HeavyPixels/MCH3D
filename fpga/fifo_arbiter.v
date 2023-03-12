module fifo_arbiter #(
  parameter WIDTH=8
) (
  input clk,
  input rst,
  input [WIDTH-1:0] wrdata_a,
  input push_a,
  input [WIDTH-1:0] wrdata_b,
  input push_b,
  output [WIDTH-1:0] wrdata_out,
  output push_out
);

reg [WIDTH-1:0] buffer;
reg buffer_full;

always@(posedge clk)
begin
  if(rst | (!push_a & !push_b))
  begin
    buffer_full <= 0;
  end
  else if(push_a & push_b)
  begin
    buffer <= wrdata_b;
    buffer_full <= 1;
  end
end

assign wrdata_out = push_a ? wrdata_a
                  : push_b ? wrdata_b
                  : buffer;
assign push_out = push_a | push_b | buffer_full;

endmodule