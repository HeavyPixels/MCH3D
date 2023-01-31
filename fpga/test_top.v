`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_top;
  
reg clk_in;
wire [7:0] lcd_d;
wire lcd_rst_n;
wire lcd_cs_n;
wire lcd_rs;
wire lcd_wr_n;
wire ram_clk;
wire ram_cs_n;
wire [3:0] ram_io;
wire lcd_mode = 1;

try_lcd_controller _try_lcd_controller(
  .clk_in(clk_in),
  .lcd_d(lcd_d),
  .lcd_rst_n(lcd_rst_n),// NOTE: Assumed to be active LOW
  .lcd_cs_n(lcd_cs_n), // NOTE: Assumed to be active LOW
  .lcd_rs(lcd_rs), // NOTE: Assumed to be LOW for command, HIGH for data
  .lcd_wr_n(lcd_wr_n), // NOTE: Assumed to be triggered on RISING EDGE
  .ram_clk(ram_clk),
  .ram_cs_n(ram_cs_n),
  .ram_io(ram_io),
  .lcd_mode(lcd_mode)
);

always 
begin
  clk_in = 1'b1;
  #42;
  clk_in = 1'b0;
  #42;
end

// Memory Stub
reg [7:0] cmd;
reg cmd_count = 0;
reg ready_for_cmd = 1;
always@(posedge ram_clk)
begin
  if(ready_for_cmd)
  begin
    cmd <= {cmd[3:0], ram_io};
    cmd_count <= ~cmd_count;
    if(cmd_count)
      ready_for_cmd <= 0;
  end
end

always@*
begin
  if(ram_cs_n) ready_for_cmd <= 1;
end

reg read_mode = 0;
reg wait_mode = 0;
reg [3:0] wait_count = 0;
reg [3:0] ram_o;
assign ram_io = (read_mode & !ram_cs_n) ? ram_o : 4'hz;

always@*
begin
  if(ram_cs_n)
  begin
    read_mode <= 0;
    wait_mode <= 0;
  end
end

always@(negedge ram_clk)
begin
  if(!ram_cs_n)
  begin
    if(read_mode)
    begin
      ram_o <= ram_o + 4'h1;
    end
    else if(wait_mode)
    begin
      wait_count <= wait_count + 1;
      if(wait_count == 4'hA)
      begin
        read_mode <= 1;
        wait_mode <= 0;
      end
    end
    else
    begin
      if(cmd == 8'h0b)
      begin
        wait_mode <= 1;
        wait_count <= 0;
        ram_o <= 0;
      end
    end
  end
end

endmodule