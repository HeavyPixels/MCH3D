`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_command_decoder;

/*
reg end_frameblock;    //   1
reg end_frame;         //   1
reg  [5:0] reserved1;  //   6
reg  [8:0] x_curr;     //   9.0
reg  [8:0] x2;         //   9.0
reg  [8:0] x3;         //   9.0
reg [16:0] y_start;    //   8.9
reg [16:0] y_end;      //   8.9
reg  [7:0] y2;         //   8.0
reg [17:0] m1, m2, m3; //s. 8.9
reg [23:0] z_curr;     //  15.9
reg [24:0] mz, nz;     //s.15.9
reg [13:0] r_curr;     //   5.9
reg [14:0] mr, nr;     //s. 5.9
reg [14:0] g_curr;     //   6.9
reg [15:0] mg, ng;     //s. 6.9
reg [13:0] b_curr;     //   5.9
reg [14:0] mb, nb;     //s. 5.9
reg [20:0] u_curr;     //  12.9
reg [21:0] mu, nu;     //s.12.9
reg [20:0] v_curr;     //  12.9
reg [21:0] mv, nv;     //s.12.9
reg  [9:0] reserved2;  //  10

wire triangle_data = {
  end_frameblock,
  end_frame,
  reserved1,
  x_curr, x2, x3,
  y_start, y_end, y2,
  m1, m2, m3,
  z_curr,
  r_curr,
  g_curr,
  b_curr,
  u_curr,
  v_curr,
  mz, nz,
  mr, nr,
  mg, ng,
  mb, nb,
  mu, nu,
  mv, nv,
  reserved2
};*/


reg spi_clk;
reg spi_cs;
reg spi_mosi;

reg clk;
reg rst;
wire [15:0] command_wrdata;
wire command_push;
wire command_full;
wire [15:0] command_rddata;
wire command_pull;
wire command_empty;
reg triangle_full;
wire [479:0] triangle_wrdata;
wire triangle_push;
reg draw_next;


spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(spi_cs),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
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
  .triangle_wrdata(triangle_wrdata),
  .triangle_push(triangle_push),
  .draw_next(draw_next)
);

always 
begin
  clk = 1'b1;
  #15;
  clk = 1'b0;
  #15;
end

/*task set_triangle(
  input [8:0] x1,
  input [8:0] x2,
  input [8:0] x3,
  input [7:0] y1,
  input [7:0] y2,
  input [7:0] y3,
  input [14:0] z1,
  input [14:0] z2,
  input [14:0] z3,
  input [4:0] r1,
  input [4:0] r2,
  input [4:0] r3,
  input [5:0] g1,
  input [5:0] g2,
  input [5:0] g3,
  input [4:0] b1,
  input [4:0] b2,
  input [4:0] b3,
  input [11:0] u1,
  input [11:0] u2,
  input [11:0] u3,
  input [11:0] v1,
  input [11:0] v2,
  input [11:0] v3
);*/

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
  rst = 0;
  triangle_full = 0;
  draw_next = 0;
  spi_clk = 0;
  spi_cs = 0;
  spi_mosi = 0;
  //command_push = 0;
  #30;
  rst = 1;
  #30;
  rst = 0;
  @(posedge clk);
  send_spi_triangle(480'h0F23456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234567);
  send_spi_triangle(480'h0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff0000111122223333444455556666777788889999aaaabbbbccccdddd);
  send_spi_command(16'h7666);
  send_spi_triangle(480'h0F23456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef01234567);
  
  #2000
  @(posedge clk);
  draw_next = 1;
  @(posedge clk);
  draw_next = 0;
  @(posedge clk);
  
end

endmodule