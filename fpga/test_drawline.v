`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_drawline;

reg clk; //in
reg rst; //in

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
reg [15:0] zbuf_rddata;
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

/*
trigen_test _trigen(
  .clk(clk),
  .rst(rst),
  .vertices_wrdata(vertices_wrdata),
  .vertices_push(vertices_push),
  .vertices_full(vertices_full)
);*/

comgen_test _comgen(
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push),
  .command_full(command_full)
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
  //.ALMOST_FULL(1)
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

lcd_driver _lcd_driver (
	.clk(clk),
  .rst(rst),
  .frameblock_data(display_rddata),
  .frameblock_addr(display_rdaddr),
  .frameblock_id(display_id),
  .frameblock_next(display_next),
  .frameblock_ready(display_ready),
	.lcd_d(lcd_d),
	.lcd_rst(lcd_rst),
	.lcd_cs(lcd_cs),
	.lcd_rs(lcd_rs),
	.lcd_wr(lcd_wr),
	.lcd_rd(lcd_rd)
);


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

// Draw-Buffer
reg [15:0] draw_buffer[0:81919];

initial
begin
  for(j=0; j<76800; j=j+1) begin
    draw_buffer[j] = 16'h0000;
  end
end

wire [16:0] draw_buffer_wraddr = {draw_id[6:4], draw_wraddr[9:5]}*320 + {draw_id[3:0], draw_wraddr[4:0]};

always@(posedge clk)
begin
  if(draw_we)
  begin
    draw_buffer[draw_buffer_wraddr] <= draw_wrdata;
  end
  //draw_rddata <=  draw_buffer[draw_rdaddr];
end

/*always@(posedge clk)
begin
  if(draw_next)
  begin
    tile_id <= draw_id;
  end
end*/


/* Registers for drawline test

reg [5:0] x_start, x_end;
reg [5:0] y;
reg [20:0] z, nz;
reg [11:0] r, nr;
reg [12:0] g, ng;
reg [11:0] b, nb;
reg [15:0] u, nu;
reg [15:0] v, nv;

assign span_data = {
  x_start, x_end,
  y,
  z, nz,
  r, nr,
  g, ng,
  b, nb,
  u, nu,
  v, nv
};
*/

/*// Registers for calcline test
reg [15:0] command;
reg  [5:0] x1, x2, x3;
reg  [5:0] y1, y2, y3;
reg [12:0] m1, m2, m3;
reg [13:0] z1;
reg [20:0] mz, nz;
reg  [4:0] r1;
reg [11:0] mr, nr;
reg  [5:0] g1;
reg [12:0] mg, ng;
reg  [4:0] b1;
reg [11:0] mb, nb;
reg  [8:0] u1;
reg [15:0] mu, nu;
reg  [8:0] v1;
reg [15:0] mv, nv;

assign triangle_rddata = {
  command,
  x1, x2, x3,
  y1, y2, y3,
  m1, m2, m3,
  z1, mz, nz,
  r1, mr, nr,
  g1, mg, ng,
  b1, mb, nb,
  u1, mu, nu,
  v1, mv, nv
};*/

/*// Registers for PreCalc test
reg [15:0] vertex_command;
reg [59:0] vertex_a; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
reg [59:0] vertex_b; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
reg [59:0] vertex_c; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]

assign vertices_data = {vertex_command, vertex_a, vertex_b, vertex_c};*/

integer f; //file pointer

initial
begin
  //tile_id = 0;
  //vertices_empty = 1;
  
  rst = 1;
  
  #20;
  rst = 0;
  
  /* Drawline test:
  for(j=0; j<32; j=j+1) begin
    span_start = 1;
    x_start = 0;
    x_end = 32;
    y = j;
    z = {15'h0000, 6'h00}; nz = {15'h0000, 6'h00};
    r = {   6'h1F, 6'h00}; nr = {   6'h00, 6'h00};
    g = {   7'h3F, 6'h00}; ng = {   7'h00, 6'h00};
    b = {   6'h1F, 6'h00}; nb = {   6'h00, 6'h00};
    u = { 10'h000, 6'h00}; nu = { 10'h001, 6'h00};
    v = {       j, 6'h00}; nv = { 10'h000, 6'h00};
    #20;
    span_start = 0;
    #1000;
  end*/
  
  /*// Calcline test:
  triangle_empty = 0;
  command = 16'h4000;  
  @(posedge triangle_pull);
  @(posedge clk);
  for(j=0; j<7; j=j+1) begin
    for(i=0; i<10; i=i+1) begin
      command = 16'h8000 + i + (j<<4);
      
      @(posedge triangle_pull);
      @(posedge clk);
      
      command = 16'h0000;
      x1 = 6'h00; x2 = 6'h20; x3 = 6'h00;
      y1 = 6'h00; y2 = 6'h00; y3 = 6'h20;
      m1 = {7'h00, 6'h00}; m2 = {7'h3F, 6'h3F}; m3 = {7'h7F, 6'h00};
      
      z1 = 14'h0000; mz = {15'h0000, 6'h00}; nz = {15'h0000, 6'h00};
      r1 = {i[2:0],i[2:1]}; mr = {   6'h00, 6'h00}; nr = {   6'h00, 6'h00};
      g1 =    6'h3F; mg = {   7'h00, 6'h00}; ng = {   7'h00, 6'h00};
      b1 = {j[2:0],j[2:1]}; mb = {   6'h00, 6'h00}; nb = {   6'h00, 6'h00};
      u1 =   9'h000; mu = { 10'h000, 6'h00}; nu = { 10'h000, 6'h00};
      v1 =   9'h000; mv = { 10'h000, 6'h00}; nv = { 10'h000, 6'h00};
      
      @(posedge triangle_pull);
      @(posedge clk);
      
      command = 16'h0000;
      x1 = 6'h20; x2 = 6'h00; x3 = 6'h20;
      y1 = 6'h00; y2 = 6'h20; y3 = 6'h20;
      m1 = {7'h00, 6'h00}; m2 = {7'h7F, 6'h00}; m3 = {7'h3F, 6'h3F};
      
      z1 = 14'h0000; mz = {15'h0000, 6'h00}; nz = {15'h0000, 6'h00};
      r1 = {i[2:0],i[2:1]}; mr = {   6'h00, 6'h00}; nr = {   6'h00, 6'h00};
      g1 =    6'h00; mg = {   7'h00, 6'h00}; ng = {   7'h00, 6'h00};
      b1 = {j[2:0],j[2:1]}; mb = {   6'h00, 6'h00}; nb = {   6'h00, 6'h00};
      u1 =   9'h000; mu = { 10'h000, 6'h00}; nu = { 10'h000, 6'h00};
      v1 =   9'h000; mv = { 10'h000, 6'h00}; nv = { 10'h000, 6'h00};
      
      @(posedge triangle_pull);
      @(posedge clk);
    end
  end
  triangle_empty = 1;*/
  
  /*// PreCalc test:
  vertices_empty = 0;
  vertex_command = 16'h4000;
      
  @(posedge clk);
  while(!vertices_pull)
    @(posedge clk);
  
  for(j=0; j<8; j=j+1) begin
    for(i=0; i<10; i=i+1) begin
      vertex_command = 16'h8000 + i + (j<<4);
      
      @(posedge clk);
      while(!vertices_pull)
        @(posedge clk);
      
      vertex_command = 16'h0000;
      vertex_a = {6'h14, 6'h05, 14'h0000, 5'h1F, 6'h00, 5'h00, 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_b = {6'h03, 6'h14, 14'h0000, 5'h00, 6'h3F, 5'h00, 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_c = {6'h1A, 6'h1A, 14'h0000, 5'h00, 6'h00, 5'h1F, 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      
      @(posedge clk);
      while(!vertices_pull)
        @(posedge clk);
      
      vertex_command = 16'h0000;
      vertex_a = {6'h00, 6'h00, 14'h2000, i[2:0],i[2:1], 6'h3F, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_b = {6'h20, 6'h00, 14'h2000, i[2:0],i[2:1], 6'h3F, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_c = {6'h00, 6'h20, 14'h2000, i[2:0],i[2:1], 6'h3F, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      
      @(posedge clk);
      while(!vertices_pull)
        @(posedge clk);
      
      vertex_command = 16'h0000;
      vertex_a = {6'h20, 6'h00, 14'h2000, i[2:0],i[2:1], 6'h00, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_b = {6'h00, 6'h20, 14'h2000, i[2:0],i[2:1], 6'h00, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      vertex_c = {6'h20, 6'h20, 14'h2000, i[2:0],i[2:1], 6'h00, j[2:0],j[2:1], 9'h000, 9'h000}; //x[6],y[6],z[14],r[5],g[6],b[5],u[9],v[9]
      
      @(posedge clk);
      while(!vertices_pull)
        @(posedge clk);
    end
  end
  vertices_empty = 1;
  
  @(posedge triangle_empty);*/
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

always 
begin
    clk = 1'b1;
    #10;
    clk = 1'b0;
    #10;
end

endmodule