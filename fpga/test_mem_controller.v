`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_mem_controller;

reg clk = 0;
reg clk2;
reg rst;

reg [19:0] mem_addr;
reg mem_read;
reg mem_write;
wire mem_ready;
wire [31:0] mem_rddata;
reg [63:0] mem_wrdata;

wire ram_clk;
wire ram_cs_n;
wire [3:0] ram_io;

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

// Memory Stub
reg [7:0] cmd;
reg [1:0] cmd_count;
reg ready_for_cmd = 1;
always@(posedge ram_clk)
begin
  if(ready_for_cmd)
  begin
    cmd <= {cmd[3:0], ram_io};
    cmd_count <= cmd_count + 1;
    if(cmd_count[1])
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
// End Memory Stub

always 
begin
  clk2 = 1'b1;
  #5;
  clk2 = 1'b0;
  #5;
end

always@(posedge clk2)
begin
  clk <= ~clk;
end

initial
begin
  rst = 1;
  mem_addr = 20'h00000;
  mem_read = 0;
  mem_write = 0;
  
  #20;
  rst = 0;
  
  mem_addr = 20'h12345;
  mem_read = 1;
  
  #1000;
  
  @(negedge mem_ready);
  mem_read = 0;
  
  mem_addr = 20'h6789A;
  mem_wrdata = 64'hADD70A57EDC0FFEE;
  mem_write = 1;
  
end

endmodule