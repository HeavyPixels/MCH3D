module shader (
  input clk,
  input rst,
  input [8:0] r,
  input [9:0] g,
  input [8:0] b,
  input tex_en,
  input [11:0] u,
  input [11:0] v,
  input [1:0] x,
  input [7:0] y,
  input we,
  // Texture
  output [11:0] texture_u,
  output [11:0] texture_v,
  input [15:0] texture_data,
  // Frameblock
  output [15:0] draw_wrdata,
  output reg [9:0] draw_wraddr,
  output reg draw_we  
);
reg tex_en_r;
reg we_r;
reg [1:0] x_r;
reg [7:0] y_r;

wire [3:0] bayer = {x[0] ^ y[0], y[0], y[1] ^ x[1], y[1]};
reg [9:0] rbay;
reg [10:0] gbay;
reg [9:0] bbay;

reg [4:0] pixel_r;
reg [5:0] pixel_g;
reg [4:0] pixel_b;

assign draw_wrdata = {pixel_r, pixel_g, pixel_b};

assign texture_u = u;
assign texture_v = v;
/*reg [15:0] texture_data;

always@(posedge clk)
begin
  texture_data <= {u[4:0] ^ v[4:0], u[9:4] ^ v[9:4], u[11:7] ^ v[11:7]};
end*/

always@(posedge clk)
begin
  tex_en_r <= tex_en;
  we_r <= we;
  x_r <= x;
  y_r <= y;
  
  rbay <= r + bayer;
  gbay <= g + bayer;
  bbay <= b + bayer;
  if(tex_en_r)
  begin
    pixel_r <= texture_data[15:11];
    pixel_g <= texture_data[10:5];
    pixel_b <= texture_data[4:0];
  end
  else
  begin 
    pixel_r <= rbay[9] ? 5'h1F : rbay[8:4];
    pixel_g <= gbay[10] ? 6'h3F : gbay[9:4];
    pixel_b <= bbay[9] ? 5'h1F : bbay[8:4];
  end
  draw_wraddr <= {x_r, y_r};
  draw_we <= we_r;
end

endmodule