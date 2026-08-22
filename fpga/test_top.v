`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_top;
  
reg clk_in;
reg spi_clk;
reg spi_cs;
reg spi_mosi;
wire [7:0] lcd_d;
wire lcd_rst_n;
wire lcd_cs_n;
wire lcd_rs;
wire lcd_wr_n;
//wire ram_clk;
//wire ram_cs_n;
//wire [3:0] ram_io;
wire lcd_mode = 1;

//try_triangle_render try_triangle_render(
top _top (
//try_spi_communication _try_spi_communication (
  .clk_in(clk_in),
  
  // CPU Communication
  .spi_clk(spi_clk),
  .spi_cs_n(~spi_cs),
  .spi_mosi(spi_mosi),
  //.irq_n(irq_n),

  .lcd_d(lcd_d),
  .lcd_rst_n(lcd_rst_n),// NOTE: Assumed to be active LOW
  .lcd_cs_n(lcd_cs_n), // NOTE: Assumed to be active LOW
  .lcd_rs(lcd_rs), // NOTE: Assumed to be LOW for command, HIGH for data
  .lcd_wr_n(lcd_wr_n), // NOTE: Assumed to be triggered on RISING EDGE
  
  .lcd_mode(lcd_mode)
);

lcd_emu _lcd_emu (
  .rst(~lcd_rst_n),  
  .lcd_d(lcd_d),
  .lcd_rst_n(lcd_rst_n),
  .lcd_cs_n(lcd_cs_n),
  .lcd_rs(lcd_rs),
  .lcd_wr_n(lcd_wr_n)
);

always 
begin
  clk_in = 1'b1;
  #42;
  clk_in = 1'b0;
  #42;
end


task send_spi_command(
  input [15:0] data
);
  integer j;
begin
  spi_cs = 1'b1;
  for(j=15; j>=0; j=j-1) begin
    spi_clk = 1'b0;
    spi_mosi = data[j];
    #7;
    spi_clk = 1'b1;
    #7; 
  end
  spi_cs = 1'b0;
end
endtask

task send_spi_triangle(
  input [479:0] data
);
  integer j;
begin
  spi_cs = 1'b1;
  for(j=479; j>=0; j=j-1) begin
    spi_clk = 1'b0;
    spi_mosi = data[j];
    #7;
    spi_clk = 1'b1;
    #7; 
  end
  spi_cs = 1'b0;
end
endtask

// Note: Vertices must be ordered by ascending x
function [479:0] precalc (
  input [8:0] x1, x2, x3,
  input [7:0] y1, y2, y3,
  input [15:0] z1, z2, z3,
  input [4:0] r1, r2, r3,
  input [5:0] g1, g2, g3,
  input [4:0] b1, b2, b3,
  input [11:0] u1, u2, u3,
  input [11:0] v1, v2, v3
);
  real fQ;
  real fm1, fm2, fm3;
  real fmz;
  real fmr, fmg, fmb;
  real fmu, fmv;
  real fnz;
  real fnr, fng, fnb;
  real fnu, fnv;
  reg [17:0] m1, m2, m3;
  reg [24:0] mz, nz;
  reg [14:0] mr, nr;
  reg [15:0] mg, ng;
  reg [14:0] mb, nb;
  reg [21:0] mu, nu;
  reg [21:0] mv, nv;
begin
  fQ = $itor(x2-x1)/$itor(x3-x1);
  fmz = $itor(z3-z1)/$itor(x3-x1);
  fmr = $itor(r3-r1)/$itor(x3-x1);
  fmg = $itor(g3-g1)/$itor(x3-x1);
  fmb = $itor(b3-b1)/$itor(x3-x1);
  fmu = $itor(u3-u1)/$itor(x3-x1);
  fmv = $itor(v3-v1)/$itor(x3-x1);
  fm1 = $itor(y3-y1)/$itor(x3-x1);
  if (x2 == x1)
      fm2 = 0.0;
  else
      fm2 = $itor(y2-y1)/$itor(x2-x1);
  if (x3 == x2)
      fm3 = 0.0;
  else
      fm3 = $itor(y3-y2)/$itor(x3-x2);
  fnz = ($itor(z2-z1)-fQ*$itor(z3-z1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  fnr = ($itor(r2-r1)-fQ*$itor(r3-r1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  fng = ($itor(g2-g1)-fQ*$itor(g3-g1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  fnb = ($itor(b2-b1)-fQ*$itor(b3-b1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  fnu = ($itor(u2-u1)-fQ*$itor(u3-u1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  fnv = ($itor(v2-v1)-fQ*$itor(v3-v1)) / ($itor(y2-y1)-fQ*$itor(y3-y1));
  
  m1 = $rtoi(fm1 * 512.0);
  m2 = $rtoi(fm2 * 512.0);
  m3 = $rtoi(fm3 * 512.0);
  mz = $rtoi(fmz * 512.0);
  mr = $rtoi(fmr * 512.0);
  mg = $rtoi(fmg * 512.0);
  mb = $rtoi(fmb * 512.0);
  mu = $rtoi(fmu * 512.0);
  mv = $rtoi(fmv * 512.0);
  nz = $rtoi(fnz * 512.0);
  nr = $rtoi(fnr * 512.0);
  ng = $rtoi(fng * 512.0);
  nb = $rtoi(fnb * 512.0);
  nu = $rtoi(fnu * 512.0);
  nv = $rtoi(fnv * 512.0);
  
  precalc = {
    1'h0, 1'h0, 6'h0,
    x1, x2, x2,
    y1, 9'h0, y1, 9'h0, y2,
    m1, m2, m3,
    z1, r1, g1, b1, u1, v1,
    mz, nz, mr, nr, mg, ng,
    mb, nb, mu, nu, mv, nv,
    10'h0
  };
end
endfunction

/*task send_triangle(
  input [479:0] data
);
  integer j;
begin
  for(j=29; j>=0; j=j-1) begin
    command_wrdata = data[j*16 +: 16]; //triangle_data
    command_push = 1;
    @(posedge clk);
    command_push = 0;
    @(posedge clk);
  end
  command_push = 0;
end
endtask*/

initial
begin
  spi_clk = 0;
  spi_cs = 0;
  spi_mosi = 0;
  #10000;
  @(posedge clk_in);
  send_spi_triangle(480'h00002827fde00ef00007fe85fe82003040000000000000f8000000000000_0001917ffde940007fa80065005aff9e00b0000000000000000000000000);
  send_spi_triangle(480'h00000027fde000000007fd020000000004e2000f003e0078000000000000_000000000000000000000000000000000000000000000000000000000000);
  send_spi_triangle(480'h00004fe7fde00ef0077ffd020000000004e2000f003e0078000000000000_000000000000000000000000000000000000000000000000000000000000);
  //EFB x79
  send_spi_triangle(480'h80000123456789abcdef0123456789abcdef0123456789abcdef01234567_0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab);
  send_spi_triangle(480'h80000123456789abcdef0123456789abcdef0123456789abcdef01234567_0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab);
  send_spi_triangle(480'h80000123456789abcdef0123456789abcdef0123456789abcdef01234567_0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); // EFB (x80)
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000); send_spi_command(16'h8000);
  //send_spi_command(16'h4000); // EF  
end

/*integer f; //file pointer

initial
begin
  //tile_id = 0;
  //vertices_empty = 1;
  
  rst = 1;
  
  #20;
  rst = 0;

  #19000000;
  
  f = $fopen("C:/Users/third/source/output.ppm", "w");
  $fwrite(f, "P3\n320 240\n255");
  for(j=0; j<240; j=j+1) begin
    $fwrite(f, "\n");
    for(i=0; i<320; i=i+1) begin
      $fwrite(f,"%d %d %d  ",
        {draw_buffer[i+320*j][15:11],draw_buffer[i+320*j][15:13]},
        {draw_buffer[i+320*j][10:5],draw_buffer[i+320*j][10:9]},
        {draw_buffer[i+320*j][4:0],draw_buffer[i+320*j][4:2]}
      );
    end
  end
  $fclose(f);
  $display("Done!");
end
*/

/*
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
*/
endmodule