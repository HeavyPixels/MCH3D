`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_cache_controller;
  
reg clk; // input
reg rst; // input
reg [11:0] u; // input
reg [11:0] v; // input
reg read; // input
reg [63:0] data_in; // input
reg write; // input
wire accept; // output
wire [15:0] pixel_out; //output
wire pixel_ready; // output
wire [19:0] mem_addr; //output
wire mem_read; // output
wire mem_write; // output
reg mem_ready; // input
reg [31:0] mem_rddata; // input
wire [63:0] mem_wrdata; // output
  
cache_controller _cache_controller(
  .clk(clk),
  .rst(rst),
  .u(u),
  .v(v),
  .read(read),
  .data_in(data_in),
  .write(write),
  .accept(accept),
  .pixel_out(pixel_out),
  .pixel_ready(pixel_ready),
  .mem_addr(mem_addr),
  .mem_read(mem_read),
  .mem_write(mem_write),
  .mem_ready(mem_ready),
  .mem_rddata(mem_rddata),
  .mem_wrdata(mem_wrdata)
);

reg [31:0] mem_addr_buf;
reg [31:0] mem_read_buf;
reg [31:0] mem_write_buf;
always@(posedge clk)
begin
  if(rst)
  begin
    mem_read_buf = 0;
    mem_write_buf = 0;
    mem_addr_buf = 0;
  end
  else
  begin
    mem_read_buf = {mem_read_buf[30:0], mem_read};
    mem_write_buf = {mem_write_buf[30:0], mem_write};
    if(mem_read | mem_write)
    begin
      mem_addr_buf <= mem_addr;
    end
  end
end

reg [31:0] ram[0:31];
always@(posedge clk)
begin
  if (mem_read_buf[27])
  begin
    mem_rddata <= ram[{mem_addr_buf[4:1],1'h0}];
  end
  else if (mem_read_buf[31])
  begin
    mem_rddata <= ram[{mem_addr_buf[4:1],1'h1}];
  end
  else if (mem_write_buf[27])
  begin
    mem_rddata <= mem_wrdata[63:32];
    ram[{mem_addr_buf[4:1],1'h0}] <= mem_wrdata[63:32];
  end
  else if (mem_write_buf[31])
  begin
    mem_rddata <= mem_wrdata[31:0];
    ram[{mem_addr_buf[4:1],1'h1}] <= mem_wrdata[31:0];
  end
  mem_ready <= (mem_read_buf[27] | mem_read_buf[31] | mem_write_buf[27] | mem_write_buf[31]);
end

always 
begin
    clk = 1'b1;
    #10;
    clk = 1'b0;
    #10;
end

integer i,j;

initial
begin
  u = 0;
  v = 0;
  rst = 1;
  read = 0;
  write = 0;
  mem_ready = 0;
  for(j=0; j<32; j=j+1) begin
    ram[j] = 32'h00000000;
  end
  
  @(posedge clk);
  rst = 0;
  
  @(posedge clk); // Write miss
  u = 12'h123;
  v = 12'h456;
  data_in = 64'h0123456789ABCDEF;
  write = 1;
  
  @(posedge accept); // Write miss, same set
  @(posedge clk);
  write = 1;
  u = 12'h127;
  v = 12'h45A;
  data_in = 64'h57A1E70A57EDBEEF;
  
  @(posedge accept); // Write hit
  @(posedge clk);
  u = 12'h127;
  v = 12'h45A;
  data_in = 64'hDECADE501DC0FFEE;
  write = 1;
  
  @(posedge accept); // Write miss, same set
  @(posedge clk);
  u = 12'h12B;
  v = 12'h45E;
  data_in = 64'hFEDCBA9876543210;
  write = 1;
  
  @(posedge accept); // Hit
  @(posedge clk);
  write = 0;
  read = 1;
  u = 12'h12B;
  v = 12'h45E;
  data_in = 64'h0;
  
  @(posedge accept); // Hit
  @(posedge clk);
  write = 0;
  read = 1;
  u = 12'h127;
  v = 12'h45A;
  data_in = 64'h0;
  
  @(posedge accept); // Miss
  @(posedge clk);
  write = 0;
  read = 1;
  u = 12'h123;
  v = 12'h456;
  data_in = 64'h0;
  
  @(posedge accept);
  @(posedge clk);
  write = 0;
  read = 0;
  u = 12'h0;
  v = 12'h0;
  data_in = 64'h0;
  
end

endmodule