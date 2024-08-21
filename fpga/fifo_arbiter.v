module fifo_arbiter(
  input clk,
  input rst,
  input [479:0] wrdata_a,
  input push_a,
  input [479:0] wrdata_b,
  input push_b,
  output reg [239:0] wrdata_out,
  output reg push_out
);

reg [479:0] buffer_a;
reg [1:0] buffer_a_count;
reg buffer_a_read;

reg [479:0] buffer_b;
reg [1:0] buffer_b_count;
reg buffer_b_read;

always@(posedge clk)
begin
  if(push_a) buffer_a <= wrdata_a;
  if(push_b) buffer_b <= wrdata_b;
end
  
always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    buffer_a_count <= 0;
    buffer_b_count <= 0;
  end
  else
  begin
    if(push_a)
      buffer_a_count <= 2'h2;
    else if (buffer_a_read)
      buffer_a_count <= buffer_a_count - 1;
      
    if(push_b)
      buffer_b_count <= 2'h2;
    else if (buffer_b_read)
      buffer_b_count <= buffer_b_count - 1;
  end
end

always@*
begin
  buffer_a_read = 0;
  buffer_b_read = 0;
  push_out = 0;
  if(buffer_a_count == 2'h1)
  begin
    wrdata_out = buffer_a[239:0];
    buffer_a_read = 1;
    push_out = 1;
  end
  else if(buffer_b_count == 2'h1)
  begin
    wrdata_out = buffer_b[239:0];
    buffer_b_read = 1;
    push_out = 1;
  end
  else if(buffer_a_count == 2'h2)
  begin
    wrdata_out = buffer_a[479:240];
    buffer_a_read = 1;
    push_out = 1;
  end
  else if(buffer_b_count == 2'h2)
  begin
    wrdata_out = buffer_b[479:240];
    buffer_b_read = 1;
    push_out = 1;
  end
end

endmodule