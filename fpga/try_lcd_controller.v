module try_lcd_controller (
  input  clk_in,
  
  // CPU Communication. Will be restored later
  //input spi_clk,
  //input spi_cs_n,
  //input spi_mosi,

  output [7:0] lcd_d,
  output lcd_rst_n,// NOTE: Assumed to be active LOW
  output lcd_cs_n, // NOTE: Assumed to be active LOW
  output lcd_rs, // NOTE: Assumed to be LOW for command, HIGH for data
  output lcd_wr_n, // NOTE: Assumed to be triggered on RISING EDGE
  
  output ram_clk,
  output ram_cs_n,
  inout [3:0] ram_io,
  
  input lcd_mode
);

reg clk = 0;
wire clk2;
wire outcore_o;
wire lock_o;

// Memory Controller
wire [19:0] mem_addr;
reg mem_read;
reg mem_write;
wire mem_ready;
wire [31:0] mem_rddata;
wire [63:0] mem_wrdata;
// Scanline
wire [15:0] draw_wrdata;
wire [9:0] draw_wraddr;
wire draw_we;
wire [15:0] draw_rddata;
wire [ 9:0] draw_rdaddr;
wire [ 6:0] draw_id;
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
//    pll_rst <= pll_rst + 1;
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

// Memory test:
// Every second:
// Write random values
// - 32 x 16 symbols, 32 x 8 bytes, 32 blocks
// - Also write to upper half of screen
// Read values
// - Also write to lower half of screen
reg [27:0] second_counter;
reg second_edge;
always@(posedge clk)
begin
  if(rst) second_counter <= 28'h0000000;
  else second_counter <= second_counter + 28'h0000001;
  //second_edge <= second_counter[15]; // Sim
  second_edge <= second_counter[27]; // Synth
end

reg value_count;
reg [4:0] value_counter;
always@(posedge clk)
begin
  if(rst)
    value_counter <= 5'h00;
  else if(value_count)
    value_counter <= value_counter + 5'h01;
end

reg [3:0] write_value [0:15];
reg write_trigger;

reg [2:0] memtest_state;

always@(posedge clk)
begin
  if(rst)
  begin
    memtest_state <= 0;
    write_trigger <= 0;
  end
  else
  begin
    case(memtest_state)
      'h0: // Wait for second trigger
      begin
        //if(second_counter[15] != second_edge) // Sim
        if(second_counter[27] != second_edge) // Synth
          memtest_state <= 'h1;
        else
          memtest_state <= 'h0;
        write_trigger <= 0;
      end
      'h1: // Write value to memory
      begin
        memtest_state <= 'h2;
        {write_value[0], write_value[1], write_value[2], write_value[3],
         write_value[4], write_value[5], write_value[6], write_value[7],
         write_value[8], write_value[9], write_value[10], write_value[11],
         write_value[12], write_value[13], write_value[14], write_value[15]} <= 64'h00070A57EDC0FFEE ^ {13{value_counter}};
        write_trigger <= 1;
      end
      'h2: // Write value to screen
      begin
        memtest_state <= 'h3;
        write_trigger <= 0;
      end
      'h3: // Wait for mem_ready 1
      begin
        if(mem_ready)
          memtest_state <= 'h4;
        else
          memtest_state <= 'h3;
        write_trigger <= 0;
      end
      'h4: // Wait for mem_ready 2
      begin
        if(mem_ready)
        begin
          if(value_counter == 'h00)
            memtest_state <= 'h5;
          else
            memtest_state <= 'h1;
        end
        else
          memtest_state <= 'h4;
        write_trigger <= 0;
      end
      'h5: // Read value from memory
      begin
        memtest_state <= 'h6;
        write_trigger <= 0;
      end
      'h6: // Wait for mem_ready 1
      begin
        if(mem_ready)
        begin
          {write_value[0], write_value[1], write_value[2], write_value[3],
           write_value[4], write_value[5], write_value[6], write_value[7]} <= mem_rddata;
          memtest_state <= 'h7;
        end
        else
          memtest_state <= 'h6;
        write_trigger <= 0;
      end
      'h7: // Wait for mem_ready 2
      begin
        if(mem_ready)
        begin
          {write_value[8], write_value[9], write_value[10], write_value[11],
           write_value[12], write_value[13], write_value[14], write_value[15]} <= mem_rddata;
          write_trigger <= 1;
          if(value_counter == 'h00)
            memtest_state <= 'h0;
          else
            memtest_state <= 'h5;
        end
        else
        begin
          memtest_state <= 'h7;
          write_trigger <= 0;
        end
      end
    endcase
  end
end

assign mem_wrdata = 64'h00070A57EDC0FFEE ^ {13{value_counter}};
assign mem_addr = {15'h0000, value_counter};

always@*
begin
  mem_write = 0;
  mem_read = 0;
  value_count = 0;
  case(memtest_state)
    'h1: // Write value to memory
    begin
      mem_write = 1;
      value_count = 1;
    end
    'h5: // Read value from memory
    begin
      mem_read = 1;
      value_count = 1;
    end
  endcase
end

mem_controller _mem_controller (
  .clk(clk),
  .clk2(clk2),
  .rst(rst),
  
  .mem_addr(mem_addr),
  .mem_read(mem_read),
  .mem_write(mem_write),
  .mem_ready(mem_ready),
  .mem_rddata(mem_rddata),
  .mem_wrdata(mem_wrdata),
  
  .ram_clk(ram_clk),
  .ram_cs_n(ram_cs_n),
  .ram_io(ram_io)
);

// Value writer
reg [3:0] write_counter;
reg [5:0] write_position;
always@(posedge clk)
begin
  if(rst)
  begin
    {write_position, write_counter} <= 9'h000;
  end
  else
  begin
    if(write_counter != 4'h0 | write_trigger)
    begin
      {write_position, write_counter} <= {write_position, write_counter} + 9'h001;
    end
  end
end

wire char_we = (write_counter != 4'h0 | write_trigger);
wire [9:0] char_wraddr = {write_position, write_counter};
wire [7:0] char_wrdata = {write_position[5], 3'h0, write_value[write_counter]};

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