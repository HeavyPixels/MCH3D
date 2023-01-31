module lcd_driver (
	input  clk,
  input  rst,
  input [15:0] frameblock_data,
  output [9:0] frameblock_addr,
  input [6:0] frameblock_id,
  output frameblock_next,
  input frameblock_ready,
	output [7:0] lcd_d,
	output lcd_rst,
	output lcd_cs,
	output lcd_rs,
	output lcd_wr,
  input lcd_ready
);

wire [8:0] lcd_command_data;
wire lcd_command_pull;

//reg [6:0] frameblock_internal;
//always@(posedge clk)
//begin
//  if(frameblock_next) frameblock_internal <= frameblock_id;
//end

lcd_controller _lcd_controller (
  .clk( clk ),
  .rst( rst ),
  .frameblock_data( frameblock_data ),
  .frameblock_addr( frameblock_addr ),
  .frameblock_id( frameblock_id ), //frameblock_internal
  .frameblock_next ( frameblock_next ),
  .frameblock_ready( frameblock_ready ),
  .lcd_command_data( lcd_command_data ),
  .lcd_command_pull( lcd_command_pull ),
  .lcd_rst(lcd_rst),
  .lcd_ready(lcd_ready)
);

lcd_interface _lcd_interface (
  .clk( clk ),
  .rst( rst ),
  .lcd_command_data( lcd_command_data ),
  .lcd_command_pull( lcd_command_pull ),
  .lcd_rs(lcd_rs),
  .lcd_cs(lcd_cs),
  .lcd_wr(lcd_wr),
  .lcd_d(lcd_d)
);

endmodule