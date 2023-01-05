module top (
	input  clk_in,
  
  input spi_clk,
  input spi_cs_n,
  input spi_mosi,

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

wire clk;
wire outcore_o;
wire lock_o;

pll36 _pll (
  .ref_clk_i(clk_in), 
  .rst_n_i(1'h1), 
  .lock_o(lock_o), 
  .outcore_o(outcore_o), 
  .outglobal_o(clk)
);

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

// Command FIFO
wire [7:0] command_wrdata;
wire command_push;
wire command_full;
wire [7:0] command_rddata;
wire command_pull;
wire command_empty;
// Triangle Assembly
wire [1:0] triass_v_sel;
wire [7:0] triass_v_data;
wire [2:0] triass_v_addr;
wire triass_v_we;
wire [7:0] triass_command;
wire [1:0] triass_va_sel;
wire [1:0] triass_vb_sel;
wire [1:0] triass_vc_sel;
wire triass_write;
// Vertices FIFO
wire [121:0] vertices_wrdata;
wire vertices_full;
wire vertices_almost_full;
wire vertices_push;
wire [121:0] vertices_rddata;
wire vertices_empty;
wire vertices_pull;
// PreCalc
wire [216:0] triangle_wrdata;
wire triangle_push;
wire triangle_full;
wire [216:0] triangle_rddata;
wire triangle_empty;
wire triangle_pull;
// CalcLine
wire [125:0] span_data;
wire span_start;
wire span_done;
wire [6:0] draw_id;
wire draw_next;
// ZBuffer
wire [15:0] zbuf_wrdata;
wire [9:0] zbuf_wraddr;
wire zbuf_we;
wire [15:0] zbuf_rddata;
wire [9:0] zbuf_rdaddr;
// Frameblock
wire [15:0] draw_wrdata;
wire [9:0] draw_wraddr;
wire draw_we;
wire [15:0] draw_rddata;
wire [ 9:0] draw_rdaddr;
wire        draw_ready;
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
  .spi_data(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

/*
trigen_test _trigen(
  .clk(clk),
  .rst(rst),
  .vertices_wrdata(vertices_wrdata),
  .vertices_push(vertices_push),
  .vertices_full(vertices_full)
);*/
/*
comgen_test _comgen(
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push),
  .command_full(command_full)
);*/

/*basicfifo #(
  .WIDTH(8),
  .LOG_DEPTH(3),
  .ALMOST_FULL(2)
) command_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(command_wrdata),
  .push(command_push),
  .full(command_full),
  .data_out(command_rddata),
  .pull(command_pull),
  .empty(command_empty)
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

command_decoder _command_decoder(
  .clk(clk),
  .rst(rst),
  .command_rddata(command_rddata),
  .command_pull(command_pull),
  .command_empty(command_empty),
  .v_sel(triass_v_sel),
  .v_data(triass_v_data),
  .v_addr(triass_v_addr),
  .v_we(triass_v_we),
  .command(triass_command),
  .va_sel(triass_va_sel),
  .vb_sel(triass_vb_sel),
  .vc_sel(triass_vc_sel),
  .write(triass_write),
  .vertices_almost_full(vertices_almost_full)
);

triangle_assembly _triangle_assembly(
  .clk(clk),
  .v_sel(triass_v_sel),
  .v_data(triass_v_data),
  .v_addr(triass_v_addr),
  .v_we(triass_v_we),
  .command(triass_command),
  .va_sel(triass_va_sel),
  .vb_sel(triass_vb_sel),
  .vc_sel(triass_vc_sel),
  .write(triass_write),
  .vertices_wrdata(vertices_wrdata),
  .vertices_push(vertices_push),
  .vertices_full(vertices_full)
);

assign vertices_almost_full = !vertices_empty;

basicfifo #(
  .WIDTH(122),
  .LOG_DEPTH(1),
  .ALMOST_FULL(1)
) vertices_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(vertices_wrdata),
  .push(vertices_push),
  .full(vertices_full),
  //.almost_full(vertices_almost_full),
  .data_out(vertices_rddata),
  .pull(vertices_pull),
  .empty(vertices_empty)
);
/*
always@(posedge clk)
begin
  if(vertices_test_clk)
    vertices_rddata <= {vertices_rddata, vertices_test_data};
end*/

precalc _precalc(
  .clk(clk),
  .rst(rst),
  .vertices_data(vertices_rddata),
  .vertices_empty(vertices_empty),
  .vertices_pull(vertices_pull),
  .triangle_data(triangle_wrdata),
  .triangle_full(triangle_full),
  .triangle_push(triangle_push)
);

assign triangle_full = !triangle_empty;
basicfifo #(
  .WIDTH(217),
  .LOG_DEPTH(1)//,
//  .ALMOST_FULL(1)
) triangle_fifo(
  .clk(clk),
  .rst(rst),
  .data_in(triangle_wrdata),
  .push(triangle_push),
  //.almost_full(triangle_full),
  .data_out(triangle_rddata),
  .pull(triangle_pull),
  .empty(triangle_empty)
);

/*
reg [216:0] triangle_buf;
assign triangle_rddata = triangle_buf;
reg triangle_state;
assign triangle_full = triangle_state;
assign triangle_empty = !triangle_state;
always@(posedge clk)
begin
  if(triangle_push)
    triangle_buf <= triangle_wrdata;
  if(triangle_push & !triangle_pull)
    triangle_state <= 1;
  if(!triangle_push & triangle_pull)
    triangle_state <= 0;
end
*/

calcline _calcline(
  .clk(clk),
  .rst(rst),
  // PreCalc
  .triangle_data(triangle_rddata),
  .triangle_empty(triangle_empty),
  .triangle_pull(triangle_pull),
  // DrawLine
  .span_data(span_data),
  .span_start(span_start),
  .span_done(span_done),
  // Frameblock
  .draw_id(draw_id),
  .draw_next(draw_next),
  .draw_ready(draw_ready)
);

drawline _drawline(
  .clk(clk),
  .rst(rst),
  // CalcLine
  .span_data(span_data),
  .span_start(span_start),
  .span_done(span_done),
  .tile_id(draw_id),
  // ZBuffer
  .zbuf_wrdata(zbuf_wrdata),
  .zbuf_wraddr(zbuf_wraddr),
  .zbuf_we(zbuf_we),
  .zbuf_rddata(zbuf_rddata),
  .zbuf_rdaddr(zbuf_rdaddr),
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
  .draw_rddata(draw_rddata),
  .draw_rdaddr(draw_rdaddr),
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