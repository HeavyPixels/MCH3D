module top (
  input  clk_in,
  
  // CPU Communication
  input spi_clk,
  input spi_cs_n,
  input spi_mosi,
  output irq_n,

  output [7:0] lcd_d,
  output lcd_rst_n,// NOTE: Assumed to be active LOW
  output lcd_cs_n, // NOTE: Assumed to be active LOW
  output lcd_rs, // NOTE: Assumed to be LOW for command, HIGH for data
  output lcd_wr_n, // NOTE: Assumed to be triggered on RISING EDGE
  
  input lcd_mode
);

// Internal Oscillator
//wire clk;
/*HSOSC
#(
  .CLKHF_DIV (2'b00)
) _hsosc (
  .CLKHFPU (1),  // I
  .CLKHFEN (1),  // I
  .CLKHF   (clk)   // O
);*/

//reg clk = 0;
wire clk;
wire outcore_o;
wire lock_o;

// Sim only! Set .rst_n_i to 1'h1 for synthesis!
//reg [2:0] pll_rst = 0;
//always@(posedge clk_in)
//begin
//  if(!pll_rst[2])
//    pll_rst <= pll_rst + 1;
//end

pll36 _pll (
  .ref_clk_i(clk_in), 
  //.rst_n_i(pll_rst[2]), // Sim
  .rst_n_i(1'h1), // Synth
  .lock_o(lock_o), 
  .outcore_o(outcore_o), 
  .outglobal_o(clk)
);

//always@(posedge clk2)
//begin
//  clk = ~clk;
//end

// Reset generator
reg pll_lock;
reg rst = 0;
reg reset_done = 0;

always@(posedge clk)
begin
  pll_lock <= lock_o;
  reset_done <= pll_lock;
  rst <= pll_lock & !reset_done; // Reset on rising edge of pll_lock
end

wire [15:0] command_wrdata;
wire command_push;
wire command_full;
wire [15:0] command_rddata;
wire command_pull;
wire command_empty;
wire [479:0] spi_triangle_wrdata;
wire spi_triangle_push;
wire [479:0] calcline_triangle_wrdata;
wire calcline_triangle_push;
wire [119:0] triangle_wrdata;
wire triangle_push;
wire triangle_full;
wire [119:0] triangle_rddata;
wire triangle_empty;
wire triangle_pull;
// CalcLine
wire [249:0] span_data;
wire span_start;
wire span_done;
// ZBuffer
wire [15:0] zbuf_wrdata;
wire [9:0] zbuf_wraddr;
wire zbuf_we;
wire [15:0] zbuf_rddata;
wire [9:0] zbuf_rdaddr;
// Scanline
wire [15:0] draw_wrdata;
wire [9:0] draw_wraddr;
wire draw_we;
//wire [15:0] draw_rddata;
//wire [ 9:0] draw_rdaddr;
wire [ 6:0] draw_id;
wire        draw_next;
wire        draw_ready;
// Texture RAM
wire [11:0] texture_u;
wire [11:0] texture_v;
wire [15:0] texture_pixel_out;
wire [13:0] texture_write_addr;
wire [15:0] texture_write_data;
wire texture_write;
// LCD Driver
wire [15:0] display_rddata;
wire [ 9:0] display_rdaddr;
wire [ 6:0] display_id;
wire        display_next;
wire        display_ready;

// Z-Buffer
frameblock_ram zbuf (
  .wr_clk_i( clk ),
  .rd_clk_i( clk ),
  .rst_i( rst ),
  .wr_clk_en_i( 1'h1 ),
  .rd_en_i( 1'h1 ),
  .rd_clk_en_i( 1'h1 ),
  .wr_en_i( zbuf_we ),
  .wr_data_i( zbuf_wrdata ),
  .wr_addr_i( zbuf_wraddr ),
  .rd_addr_i( zbuf_rdaddr ),
  .rd_data_o( zbuf_rddata )
);

spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(~spi_cs_n),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

/*triangle_tester _triangle_tester (
  .clk(clk),
  .rst(rst),
  .triangle_full(command_full),
  .triangle_wrdata(command_wrdata),
  .triangle_push(command_push),
  .draw_next(draw_next)
);*/

command_fifo _command_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(command_wrdata),
  .push(command_push),
  .full(command_full),
  .data_out(command_rddata),
  .pull(command_pull),
  .empty(command_empty)
);

command_decoder _command_decoder (
  .clk(clk),
  .rst(rst),
  // Command input
  .command_rddata(command_rddata),
  .command_pull(command_pull),
  .command_empty(command_empty),
  
  // Triangle output
  .triangle_full(triangle_full),
  .cmd_triangle_wrdata(spi_triangle_wrdata),
  .triangle_push(spi_triangle_push),
  .draw_next(draw_next),
  
  // Texture output
  .texture_wraddr(texture_write_addr),
  .texture_wrdata(texture_write_data),
  .texture_write(texture_write)
);

fifo_arbiter triangle_fifo_arbiter (
  .clk(clk),
  .rst(rst),
  .wrdata_a(calcline_triangle_wrdata),
  .push_a(calcline_triangle_push),
  .wrdata_b(spi_triangle_wrdata),
  .push_b(spi_triangle_push),
  .wrdata_out(triangle_wrdata),
  .push_out(triangle_push)
);

//assign triangle_full = !triangle_empty;
/*basicfifo #(
  .WIDTH(240),
  .LOG_DEPTH(8),
  .ALMOST_FULL(240)
) triangle_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(triangle_wrdata),
  .push(triangle_push),
  .almost_full(triangle_full),
  .data_out(triangle_rddata),
  .pull(triangle_pull),
  .empty(triangle_empty)
);*/
triangle_fifo _triangle_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(triangle_wrdata),
  .push(triangle_push),
  .almost_full(triangle_full),
  .data_out(triangle_rddata),
  .pull(triangle_pull),
  .almost_empty(triangle_empty)
);

calcline _calcline(
  .clk(clk),
  .rst(rst),
  // PreCalc
  .triangle_rddata(triangle_rddata),
  .triangle_empty(triangle_empty),
  .triangle_pull(triangle_pull),
  .calc_triangle_wrdata(calcline_triangle_wrdata),
  .triangle_push(calcline_triangle_push),
  // DrawLine
  .span_data(span_data),
  .span_start(span_start),
  .span_done(span_done),
  // Frameblock
  .draw_id(draw_id),
  .draw_next(draw_next),
  .draw_ready(draw_ready)
);


wire [8:0] shader_r;
wire [9:0] shader_g;
wire [8:0] shader_b;
wire shader_tex_en;
wire [11:0] shader_u;
wire [11:0] shader_v;
wire [1:0] shader_x;
wire [7:0] shader_y;
wire shader_we;

drawline _drawline(
  .clk(clk),
  .rst(rst),
  // CalcLine
  .span_data(span_data),
  .span_start(span_start),
  .span_done(span_done),
  // ZBuffer
  .zbuf_wrdata(zbuf_wrdata),
  .zbuf_wraddr(zbuf_wraddr),
  .zbuf_we(zbuf_we),
  .zbuf_rddata(zbuf_rddata),
  .zbuf_rdaddr(zbuf_rdaddr),
  // Frameblock
  //.draw_wrdata(draw_wrdata),
  //.draw_wraddr(draw_wraddr),
  //.draw_we(draw_we)
  // Shader
  .shader_r(shader_r),
  .shader_g(shader_g),
  .shader_b(shader_b),
  .shader_tex_en(shader_tex_en),
  .shader_u(shader_u),
  .shader_v(shader_v),
  .shader_x(shader_x),
  .shader_y(shader_y),
  .shader_we(shader_we)
);

texture_ram _texture_ram (
   .clk(clk),
   .rst(rst),
   .u(texture_u),
   .v(texture_v),
   .pixel_out(texture_pixel_out),
   .write_addr(texture_write_addr),
   .write_data(texture_write_data),
   .write(texture_write)
);

shader _shader (
  .clk(clk),
  .rst(rst),
  .r(shader_r),
  .g(shader_g),
  .b(shader_b),
  .tex_en(shader_tex_en),
  .u(shader_u),
  .v(shader_v),
  .x(shader_x),
  .y(shader_y),
  .we(shader_we),
  // Texture
  .texture_u(texture_u),
  .texture_v(texture_v),
  .texture_data(texture_pixel_out),
  // Frameblock
  .draw_wrdata(draw_wrdata),
  .draw_wraddr(draw_wraddr),
  .draw_we(draw_we) 
);

frameblock_controller _frameblock_controller (
  .clk(clk),
  .rst(rst),
  .draw_wrdata(draw_wrdata),
  .draw_wraddr(draw_wraddr),
  .draw_we(draw_we),
  //.draw_rddata(draw_rddata),
  .draw_rdaddr(0), //unconnected
  .draw_id(draw_id),
  .draw_next(draw_next),
  .draw_ready(draw_ready),
  
  .display_rddata(display_rddata),
  .display_rdaddr(display_rdaddr),
  .display_id(display_id),
  .display_next(display_next),
  .display_ready(display_ready)
);

reg [7:0] lcd_ready_buf;
wire lcd_ready = (lcd_ready_buf == 8'hFF);
always@(posedge clk or posedge rst)
begin
  if(rst) lcd_ready_buf <= 8'h00;
  else lcd_ready_buf <= {lcd_ready_buf[6:0], lcd_mode};
end

wire [7:0] i_lcd_d;
wire i_lcd_rst;
wire i_lcd_cs;
wire i_lcd_rs;
wire i_lcd_wr;

lcd_driver _lcd_driver (
	.clk(clk),
  .rst(rst),
  .frameblock_data(display_rddata),
  .frameblock_addr(display_rdaddr),
  .frameblock_id(display_id),
  .frameblock_next(display_next),
  .frameblock_ready(display_ready),
	.lcd_d(i_lcd_d),
	.lcd_rst(i_lcd_rst),
	.lcd_cs(i_lcd_cs),
	.lcd_rs(i_lcd_rs),
	.lcd_wr(i_lcd_wr),
	.lcd_ready(lcd_ready)
);


assign lcd_rst_n = lcd_ready ? i_lcd_rst : 1'bz;
assign lcd_cs_n = lcd_ready ? i_lcd_cs : 1'bz;
assign lcd_wr_n = lcd_ready ? i_lcd_wr : 1'bz;
assign lcd_rs = lcd_ready ? i_lcd_rs : 1'bz;
assign lcd_d = lcd_ready ? i_lcd_d : 8'bzzzzzzzz;
	
endmodule