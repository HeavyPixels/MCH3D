module fifo_arbiter(
  input clk,
  input rst,
  input [479:0] wrdata_a,
  input push_a,
  input [479:0] wrdata_b,
  input push_b,
  output reg [119:0] wrdata_out,
  output reg push_out
);

reg [479:0] buffer_a;
reg [3:0] buffer_a_count;
reg buffer_a_read;

reg [479:0] buffer_b;
reg [3:0] buffer_b_count;
reg buffer_b_read;

  
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
    begin
      buffer_a_count <= 8; // = 4 words
      buffer_a <= wrdata_a;
    end
    else if (buffer_a_read)
    begin
      buffer_a_count <= {1'b0, buffer_a_count[3:1]}; // -=1
      buffer_a <= {buffer_a[359:0], 120'h0};
    end
      
    if(push_b)
    begin
      buffer_b_count <= 8; // = 4 words
      buffer_b <= wrdata_b;
    end
    else if (buffer_b_read)
    begin
      buffer_b_count <= {1'b0, buffer_b_count[3:1]}; // -=1
      buffer_b <= {buffer_b[359:0], 120'h0};
    end
  end
end

always@*
begin
  buffer_a_read = 0;
  buffer_b_read = 0;
  push_out = 0;
  wrdata_out = 'hx;
  // Buffer A in progress
  if(buffer_a_count[2:0])
  begin
    wrdata_out = buffer_a[479:360];
    buffer_a_read = 1;
    push_out = 1;
  end
  // Buffer B in progress
  else if(buffer_b_count[2:0])
  begin
    wrdata_out = buffer_b[479:360];
    buffer_b_read = 1;
    push_out = 1;
  end
  // Buffer A start
  else if(buffer_a_count[3])
  begin
    wrdata_out = buffer_a[479:360];
    buffer_a_read = 1;
    push_out = 1;
  end
  // Buffer B start
  else if(buffer_b_count[3])
  begin
    wrdata_out = buffer_b[479:360];
    buffer_b_read = 1;
    push_out = 1;
  end
end

endmodule
