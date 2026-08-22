`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_drawline;

reg clk; //in
reg rst; //in
reg lcd_mode; //in

always 
begin
    clk = 1'b1;
    #10;
    clk = 1'b0;
    #10;
end

// Command FIFO
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
wire [239:0] triangle_wrdata;
wire triangle_push;
wire triangle_full;
wire [239:0] triangle_rddata;
wire triangle_empty;
wire triangle_pull;
// CalcLine
wire [248:0] span_data;
wire span_start;
wire span_done;
// ZBuffer
wire [15:0] zbuf_wrdata;
wire [9:0] zbuf_wraddr;
wire zbuf_we;
reg [15:0] zbuf_rddata;
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
// LCD Driver
wire [15:0] display_rddata;
wire [ 9:0] display_rdaddr;
wire [ 6:0] display_id;
wire        display_next;
wire        display_ready;
// Display
wire [7:0] lcd_d;
wire lcd_rst;
wire lcd_cs;
wire lcd_rs;
wire lcd_wr;
wire lcd_rd;

/*// Z-Buffer
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
);*/

/*spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(~spi_cs_n),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);*/

triangle_tester _triangle_tester (
  .clk(clk),
  .rst(rst),
  .triangle_full(command_full),
  .triangle_wrdata(command_wrdata),
  .triangle_push(command_push),
  .draw_next(draw_next)
);

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
  .draw_next(draw_next)
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


// Z-Buffer
reg [15:0] z_buffer[0:1023];

integer i,j;

initial
begin
  for(i=0; i<1024; i=i+1) begin
    z_buffer[i] = 16'hFFFF;
  end
end

always@(posedge clk)
begin
  if(zbuf_we)
  begin
    z_buffer[zbuf_wraddr] <= zbuf_wrdata;
  end
  zbuf_rddata <=  z_buffer[zbuf_rdaddr];
end

lcd_emu _lcd_emu (
  .rst(rst),  
  .lcd_d(lcd_d),
  .lcd_rst_n(lcd_rst_n),
  .lcd_cs_n(lcd_cs_n),
  .lcd_rs(lcd_rs),
  .lcd_wr_n(lcd_wr_n)
);


initial
begin  
  rst = 1;
  lcd_mode = 0;
  
  #20;
  rst = 0;
  lcd_mode = 1;
end

endmodule