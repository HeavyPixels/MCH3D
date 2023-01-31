module char_display (
  input clk,
  input rst,
  
  input [7:0] char_wrdata,
  input [9:0] char_wraddr,
  input char_we,
  
  output reg [15:0] draw_wrdata,
  output reg [9:0] draw_wraddr,
  output reg draw_we,
  //output [15:0] draw_rddata,
  //input [9:0] draw_rdaddr,
  output reg [6:0] draw_id,
  output draw_next,
  input draw_ready
);

wire [7:0] char_rddata;
wire [9:0] char_rdaddr;

char_ram _char_ram (
  .wr_clk_i(clk), 
  .rd_clk_i(clk), 
  .rst_i(rst), 
  .wr_clk_en_i(1'h1), 
  .rd_en_i(1'h1), 
  .rd_clk_en_i(1'h1), 
  .wr_en_i(char_we), 
  .wr_data_i(char_wrdata), 
  .wr_addr_i(char_wraddr), 
  .rd_addr_i(char_rdaddr), 
  .rd_data_o(char_rddata)
);

wire [7:0] font_rddata;
wire [9:0] font_rdaddr;

font_rom _font_rom (
  .rd_clk_i (clk), 
  .rst_i (rst), 
  .rd_en_i (1'h1), 
  .rd_clk_en_i (1'h1), 
  .rd_addr_i(font_rdaddr), 
  .rd_data_o(font_rddata)
);

reg [2:0] render_x;
reg [1:0] render_x1;
reg [1:0] render_x2;
reg [7:0] render_y;
reg [7:0] render_y1;
reg [7:0] render_y2;
reg draw_we2;
reg draw_we1;

reg wait_state;

assign draw_next = render_x[2];

always@(posedge clk)
begin
  if(rst)
  begin
    wait_state <= 0;
    draw_id <= 7'h00;
    render_x <= 3'h0;
    render_y <= 8'h00;
  end
  else
  begin
    if(wait_state)
    begin
      if(draw_ready) wait_state <= 0;
    end
    else if(render_x[2])
    begin
      render_x <= 3'h0;
      wait_state <= 1;
      if(draw_id < 'h4F)
        draw_id <= draw_id + 1;
      else
        draw_id <= 0;
    end
    else
    begin
      {render_x, render_y} <= {render_x, render_y} + 1;
    end
  end
  render_x1 <= render_x[1:0];
  render_y1 <= render_y;
  
  render_x2 <= render_x1;
  render_y2 <= render_y1;
end

assign char_rdaddr = {render_y[7:3], draw_id[5:1]};
assign font_rdaddr = {char_rddata[6:0], render_y1[2:0]};
reg pixel_color;

always@(posedge clk) pixel_color <= char_rddata[7];

// Note: This addressing mirrors the bits from the usual writing order (MSb left) for display (MSb right)
// So a font row 'b00110101 will be rendered as #.#.##..
// By a "happy accident", this is also how the font is specified.
wire pixel = font_rddata[{draw_id[0], render_x2[1:0]}];

always@(posedge clk)
begin
  if(pixel)
  begin
    if(pixel_color)
      draw_wrdata <= 16'hFFFF;
    else
      draw_wrdata <= 16'hE5A3;
  end
  else
  begin
    draw_wrdata <= 16'h0000;
  end
  draw_wraddr <= {render_x2[1:0], render_y2};
  draw_we2 <= !wait_state & !render_x[2];
  draw_we1 <= draw_we2;
  draw_we <= draw_we1;
end

endmodule