module try_spi_communication (
  input  clk_in,
  
  // CPU Communication. Will be restored later
  input spi_clk,
  input spi_cs_n,
  input spi_mosi,

  output [7:0] lcd_d,
  output lcd_rst_n,// NOTE: Assumed to be active LOW
  output lcd_cs_n, // NOTE: Assumed to be active LOW
  output lcd_rs, // NOTE: Assumed to be LOW for command, HIGH for data
  output lcd_wr_n, // NOTE: Assumed to be triggered on RISING EDGE
  
  //output ram_clk,
  //output ram_cs_n,
  //inout [3:0] ram_io,
  
  input lcd_mode
);

reg clk = 0;
wire clk2;
wire outcore_o;
wire lock_o;

// Command data
wire [7:0] command_wrdata;
wire command_push;
// Scanline
wire [15:0] draw_wrdata;
wire [9:0] draw_wraddr;
wire draw_we;
wire [15:0] draw_rddata;
wire [ 9:0] draw_rdaddr;
wire [ 6:0] draw_id;
wire        draw_next;
wire        draw_ready;
// LCD Driver
wire [15:0] display_rddata;
wire [ 9:0] display_rdaddr; // The address within the frameblock
wire [ 6:0] display_id; // With the vertical stripes this is essentially frame_x[8:2]
wire        display_next;
wire        display_ready;

// Sim only! Set .rst_n_i to 1'h1 for synthesis!
//reg [2:0] pll_rst = 0;
//always@(posedge clk_in)
//begin
//  if(!pll_rst[2])
    //pll_rst <= pll_rst + 1;
//end


pll36 _pll (
  .ref_clk_i(clk_in), 
  //.rst_n_i(pll_rst[2]), // Sim
  .rst_n_i(1'h1), // Synth
  .lock_o(lock_o), 
  .outcore_o(outcore_o), 
  .outglobal_o(clk2)
);

always@(posedge clk2)
begin
  clk = ~clk;
end

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

spi_controller #(.LOGWORD(3)) _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(~spi_cs_n),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

// Value writer
reg [9:0] write_position;
wire write_trigger = command_push;
always@(posedge clk)
begin
  if(rst)
  begin
    write_position <= 0;
  end
  else
  begin
    if(write_trigger)
    begin
      write_position <= write_position + 1;
    end
  end
end

wire char_we = write_trigger;
wire [9:0] char_wraddr = write_position;
wire [7:0] char_wrdata = command_wrdata;

char_display _char_display (
  .clk(clk),
  .rst(rst),
  .char_wrdata(char_wrdata),
  .char_wraddr(char_wraddr),
  .char_we(char_we),
  
  .draw_wrdata(draw_wrdata),
  .draw_wraddr(draw_wraddr),
  .draw_we(draw_we),
  .draw_id(draw_id),
  .draw_next(draw_next),
  .draw_ready(draw_ready)
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

// LCD ready stabilization
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