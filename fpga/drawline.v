module drawline(
  input clk,
  input rst,
  // CalcLine
  input [125:0] span_data,
  input span_start,
  output reg span_done,
  input [6:0] tile_id,
  // ZBuffer
  output reg [15:0] zbuf_wrdata,
  output reg [9:0] zbuf_wraddr,
  output reg zbuf_we,
  input [15:0] zbuf_rddata,
  output [9:0] zbuf_rdaddr,
  // Frameblock
  output reg [15:0] draw_wrdata,
  output reg [9:0] draw_wraddr,
  output reg draw_we
  //input [15:0] draw_rddata,
  //output reg [9:0] draw_rdaddr
);

localparam IDLE=3'd0, POP=3'd1, DRAW_FWD=3'd2, DRAW_BWD=3'd3;

reg [5:0] x_end;
reg [5:0] x_curr[0:2];
reg [5:0] y_curr[0:2];
reg [17:0] z_curr[0:2], nz;
reg [12:0] r_curr[0:2], nr;
reg [13:0] g_curr[0:2], ng;
reg [12:0] b_curr[0:2], nb;

wire [17:0] z_add = z_curr[0] + nz;
wire [12:0] r_add = r_curr[0] + nr;
wire [13:0] g_add = g_curr[0] + ng;
wire [12:0] b_add = b_curr[0] + nb;
wire [21:0] z_sub = z_curr[0] - nz;
wire [12:0] r_sub = r_curr[0] - nr;
wire [13:0] g_sub = g_curr[0] - ng;
wire [12:0] b_sub = b_curr[0] - nb;

always@(posedge clk)
begin
  x_curr[1] <= x_curr[0];
  y_curr[1] <= y_curr[0];
  z_curr[1] <= z_curr[0][17] ? 18'h00000 : z_curr[0][16] ?  18'h0FFFF : z_curr[0];
  r_curr[1] <= r_curr[0][12] ? 13'h000 : r_curr[0][11] ?  13'h7FF : r_curr[0];
  g_curr[1] <= g_curr[0][13] ? 14'h0000 : g_curr[0][12] ? 14'h0FFF : g_curr[0];
  b_curr[1] <= b_curr[0][12] ? 13'h000 :  b_curr[0][11] ? 13'h7FF : b_curr[0];
  x_curr[2] <= x_curr[1];
  y_curr[2] <= y_curr[1];
  z_curr[2] <= z_curr[1];
  r_curr[2] <= r_curr[1];
  g_curr[2] <= g_curr[1];
  b_curr[2] <= b_curr[1];
end

// NOTE: Drawing in reverse
// The starting color values are defined along the long edge, at x_begin.
// The n-values are defined as (c_b-c_a)/(x_b-x_a), so in delta_c/delta_x.
// When drawing from left to right (x_begin<x_end) this is fine:
// x_curr <= x_curr + 1;  c_curr = c_curr + nc; [repeat while x_curr < x_end]
// In this case, the values at x_begin are drawn, and are set to c1.
// Values at x_end are not drawn.
// When x_begin > x_end, we could still draw from left to right, but this
// requires knowing the c-values on the other edge, either via c1+(x_end-x_begin)*nc,
// which requires a mult and is expensive, or by calculating the c values// along the edges, which requires 2 additional m-values per ccomponent.
// Alternatively, we can draw from right to left. In that case, c1 is still
// the initial value, but the formula now subtracts instead of adds:
// x_curr <= x_curr - 1;  c_curr = c_curr - nc; [repeat while x_curr >= x_end]
// In this case, x_begin is NOT drawn and x_end IS drawn.

reg [1:0] state;
reg [4:0] draw;


// Z-buffer check
assign zbuf_rdaddr = {y_curr[0][4:0], x_curr[0][4:0]};

always@(posedge clk)
begin
  span_done = 0;
  if(rst)
  begin
    state <= IDLE;
    draw[0] <= 0;
    x_curr[0] = 'hx;
    z_curr[0] = 'hx;
    r_curr[0] = 'hx;
    g_curr[0] = 'hx;
    b_curr[0] = 'hx;   
  end
  else
  begin
    case(state)
      IDLE: begin
        draw[0] <= 0;
        x_curr[0] = 'hx;
        z_curr[0] = 'hx;
        r_curr[0] = 'hx;
        g_curr[0] = 'hx;
        b_curr[0] = 'hx;       
        if(span_start)
        begin
          state <= POP;
          span_done = 0;
        end
        else
        begin
          state <= IDLE;
          span_done = 1;
        end
      end
      POP: begin
        x_curr[0] = span_data[125:120]; x_end = span_data[119:114]; //[5:0]
        y_curr[0] = span_data[113:108];                      // [5:0]
        z_curr[0] = {span_data[107], span_data[107:91]}; nz = {span_data[90], span_data[90:74]};    //[16:0]
        r_curr[0] = {span_data[73], span_data[73:62]}; nr = {span_data[61], span_data[61:50]};    //[11:0]
        g_curr[0] = {span_data[49], span_data[49:37]}; ng = {span_data[36], span_data[36:24]};    //[12:0]
        b_curr[0] = {span_data[23], span_data[23:12]};   nb = {span_data[11], span_data[11:0]};    //[11:0]
        if(x_curr[0] < x_end)
        begin
          draw[0] <= 1; // Draw inclusive of x_begin
          state <= DRAW_FWD;
        end
        else if(x_curr[0] == x_end)
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        else //if(x_curr[0] > x_end)
        begin
          draw[0] <= 0; // Draw exclusive of x_begin
          state <= DRAW_BWD;
        end
      end
      DRAW_FWD: begin
        if(x_curr[0] < x_end - 1) // Draw exclusive of x_end
        begin
          draw[0] <= 1;
          state <= DRAW_FWD;
        end
        else
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        x_curr[0] = x_curr[0] + 1;
        z_curr[0] = z_add;
        r_curr[0] = r_add;
        g_curr[0] = g_add;
        b_curr[0] = b_add;
      end
      DRAW_BWD: begin
        if(x_curr[0] > x_end) // Draw inclusive of x_end
        begin
          draw[0] <= 1;
          state <= DRAW_BWD;
        end
        else
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        x_curr[0] = x_curr[0] - 1;
        z_curr[0] = z_sub;
        r_curr[0] = r_sub;
        g_curr[0] = g_sub;
        b_curr[0] = b_sub;
      end
    endcase
  end
end

always@(posedge clk)
begin
  draw[1] <= draw[0];
  draw[2] <= draw[1] && ((zbuf_rddata[15:10] != tile_id[5:0]) || (zbuf_rddata[9:0] >= z_curr[0][15:6]));
end

// Shading
wire [4:0] pixel_r = r_curr[2][11:6];
wire [5:0] pixel_g = g_curr[2][12:6];
wire [4:0] pixel_b = b_curr[2][11:6];

// Output
always@(posedge clk)
begin
  draw_wrdata <= {pixel_r, pixel_g, pixel_b};
  draw_wraddr <= {y_curr[2][4:0], x_curr[2][4:0]};
  zbuf_wrdata <= {tile_id[5:0], z_curr[2][15:6]};
  zbuf_wraddr <= {y_curr[2][4:0], x_curr[2][4:0]};
  if(draw[2])
  begin
    draw_we <= 1;
    zbuf_we <= 1;
  end
  else
  begin
    draw_we <= 0;
    zbuf_we <= 0;
  end
end

endmodule