// Command Decoder
// Decodes bytestream from CPU into commands and (triangle) data.

// TODO:
// - Adapt command input interface for FIFO
// - Support back-pressure from Vertex FIFO
// - Texture upload
// - Output control
// - Reset

module command_decoder (
  input clk,
  input rst,
  // Command input
  input [7:0] command_rddata,
  output command_pull,
  input command_empty,
  
  // Triangle output
  input triangle_full,
  output reg [479:0] triangle_wrdata,
  output triangle_push,
  input draw_next
);

// Pull logic
assign command_pull = !command_empty & !triangle_full;
reg did_pull;

always@(posedge clk) did_pull <= command_pull;

reg [5:0] byte_count;
assign triangle_push = (byte_count == 60);


always@(posedge clk or posedge rst)
begin
  if(rst)
    byte_count <= 0;
  else
  begin
    if(did_pull)
    begin
      triangle_wrdata <= { triangle_wrdata[471:0], command_rddata};
      byte_count <= byte_count + 1;
    end
    if(byte_count == 60)
    begin
      byte_count <= 0;
    end
  end
end

endmodule