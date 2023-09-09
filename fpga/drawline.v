module drawline(
  input clk,
  input rst,
  // CalcLine
  input [160:0] span_data,
  input span_start,
  output reg span_done,
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
);

localparam IDLE=3'd0, POP=3'd1, DRAW_FWD=3'd2, DRAW_BWD=3'd3;

reg [7:0] y_end; // Note: original design had 1 additional bit to support a 0.0 - 1.0 range (0-32). For the 0-240 range this is not needed.
reg [7:0] y_curr[0:2]; //
reg [2:0] x_curr[0:2]; // +1bit for z-buffer polarity
reg [25:0] z_curr[0:2], nz; // 1bit overflow + s.15.9
reg [15:0] r_curr[0:2], nr; // 1bit overflow + s. 5.9
reg [16:0] g_curr[0:2], ng; // 1bit overflow + s. 6.9
reg [15:0] b_curr[0:2], nb; // 1bit overflow + s. 5.9
reg [22:0] u_curr[0:2], nu; // 1bit overflow + s.12.9
reg [22:0] v_curr[0:2], nv; // 1bit overflow + s.12.9

wire [25:0] z_add = z_curr[0] + nz; // o.s.15.9
wire [15:0] r_add = r_curr[0] + nr; // o.s. 5.9
wire [16:0] g_add = g_curr[0] + ng; // o.s. 6.9
wire [15:0] b_add = b_curr[0] + nb; // o.s. 5.9
wire [22:0] u_add = u_curr[0] + nu; // o.s.12.9
wire [22:0] v_add = v_curr[0] + nv; // o.s.12.9
wire [25:0] z_sub = z_curr[0] - nz; // o.s.15.9
wire [15:0] r_sub = r_curr[0] - nr; // o.s. 5.9
wire [16:0] g_sub = g_curr[0] - ng; // o.s. 6.9
wire [15:0] b_sub = b_curr[0] - nb; // o.s. 5.9
wire [22:0] u_sub = u_curr[0] - nu; // o.s.12.9
wire [22:0] v_sub = v_curr[0] - nv; // o.s.12.9

always@(posedge clk)
begin
  y_curr[1] <= y_curr[0];
  x_curr[1] <= x_curr[0];
  z_curr[1] <= z_curr[0][25] ? 26'h00000 : z_curr[0][24] ? 26'h7FFFF : z_curr[0];
  r_curr[1] <= r_curr[0][15] ? 16'h0000 : r_curr[0][14] ? 16'h3FFF : r_curr[0];
  g_curr[1] <= g_curr[0][16] ? 17'h00000 : g_curr[0][15] ? 17'h07FFF : g_curr[0];
  b_curr[1] <= b_curr[0][15] ? 16'h0000 : b_curr[0][14] ? 16'h3FFF : b_curr[0];
  u_curr[1] <= u_curr[0][22] ? 23'h00000 : u_curr[0][21] ? 23'h1FFFFF : u_curr[0];
  v_curr[1] <= v_curr[0][22] ? 23'h00000 : v_curr[0][21] ? 23'h1FFFFF : v_curr[0];
  y_curr[2] <= y_curr[1];
  x_curr[2] <= x_curr[1];
  z_curr[2] <= z_curr[1];
  r_curr[2] <= r_curr[1];
  g_curr[2] <= g_curr[1];
  b_curr[2] <= b_curr[1];
  u_curr[2] <= u_curr[1];
  v_curr[2] <= v_curr[1];
end

// NOTE: Drawing in reverse
// The starting color values are defined along the long edge, at y_begin.
// The n-values are defined as (c_b-c_a)/(y_b-y_a), so in delta_c/delta_y.
// When drawing from top to bottom (y_begin<y_end) this is fine:
// y_curr <= y_curr + 1;  c_curr = c_curr + nc; [repeat while y_curr < y_end]
// In this case, the values at y_begin are drawn, and are set to c1.
// Values at y_end are not drawn.
// When y_begin > y_end, we could still draw from top to bottom, but this
// requires knowing the c-values on the other edge, either via c1+(y_end-y_begin)*nc,
// which requires a mult and is expensive, or by calculating the c values// along the edges, which requires 2 additional m-values per ccomponent.
// Alternatively, we can draw from bottom to top. In that case, c1 is still
// the initial value, but the formula now subtracts instead of adds:
// y_curr <= y_curr - 1;  c_curr = c_curr - nc; [repeat while y_curr >= y_end]
// In this case, y_begin is NOT drawn and y_end IS drawn.

reg [1:0] state;
reg [4:0] draw;


// Z-buffer check
assign zbuf_rdaddr = {x_curr[0][1:0], y_curr[0][7:0]};

always@(posedge clk)
begin
  span_done = 0;
  if(rst)
  begin
    state <= IDLE;
    draw[0] <= 0;
    y_curr[0] = 'hx;
    z_curr[0] = 'hx;
    r_curr[0] = 'hx;
    g_curr[0] = 'hx;
    b_curr[0] = 'hx;
    u_curr[0] = 'hx;
    v_curr[0] = 'hx;
  end
  else
  begin
    case(state)
      IDLE: begin
        draw[0] <= 0;
        y_curr[0] = 'hx;
        z_curr[0] = 'hx;
        r_curr[0] = 'hx;
        g_curr[0] = 'hx;
        b_curr[0] = 'hx;
        u_curr[0] = 'hx;
        v_curr[0] = 'hx;
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
        y_curr[0] = span_data[248:241]; y_end = span_data[240:233]; //[7:0]
        x_curr[0] = span_data[232:230];                      // [2:0]
        z_curr[0] = {span_data[229], span_data[229:205]}; nz = {span_data[204], span_data[204:180]};    //[24:0] s.15.9
        r_curr[0] = {span_data[179], span_data[179:165]}; nr = {span_data[164], span_data[164:150]};    //[14:0] s.5.9
        g_curr[0] = {span_data[149], span_data[149:134]}; ng = {span_data[133], span_data[133:118]};    //[15:0] s.6.9
        b_curr[0] = {span_data[117], span_data[117:103]};   nb = {span_data[102], span_data[102:88]};    //[14:0] s.5.9
        u_curr[0] = {span_data[87], span_data[87:66]};   nu = {span_data[65], span_data[65:44]};    //[21:0] s.12.9
        v_curr[0] = {span_data[43], span_data[43:22]};   nv = {span_data[21], span_data[21:0]};    //[21:0] s.12.9
        if(y_curr[0] < y_end)
        begin
          draw[0] <= 1; // Draw inclusive of y_begin
          state <= DRAW_FWD;
        end
        else if(y_curr[0] == y_end)
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        else //if(y_curr[0] > y_end)
        begin
          draw[0] <= 0; // Draw exclusive of y_begin
          state <= DRAW_BWD;
        end
      end
      DRAW_FWD: begin
        if(y_curr[0] < y_end - 1) // Draw exclusive of y_end
        begin
          draw[0] <= 1;
          state <= DRAW_FWD;
        end
        else
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        y_curr[0] = y_curr[0] + 1;
        z_curr[0] = z_add;
        r_curr[0] = r_add;
        g_curr[0] = g_add;
        b_curr[0] = b_add;
        u_curr[0] = u_add;
        v_curr[0] = v_add;
      end
      DRAW_BWD: begin
        if(y_curr[0] > y_end) // Draw inclusive of y_end
        begin
          draw[0] <= 1;
          state <= DRAW_BWD;
        end
        else
        begin
          draw[0] <= 0;
          state <= IDLE;
        end
        y_curr[0] = y_curr[0] - 1;
        z_curr[0] = z_sub;
        r_curr[0] = r_sub;
        g_curr[0] = g_sub;
        b_curr[0] = b_sub;
        u_curr[0] = u_sub;
        v_curr[0] = v_sub;
      end
    endcase
  end
end

always@(posedge clk)
begin
  draw[1] <= draw[0];
  draw[2] <= draw[1] && ((zbuf_rddata[15] != x_curr[0][2]) || (zbuf_rddata[14:0] >= z_curr[0][23:9]));
end

// Shading
wire [4:0] pixel_r = r_curr[2][13:9];
wire [5:0] pixel_g = g_curr[2][14:9];
wire [4:0] pixel_b = b_curr[2][13:9];

// Output
always@(posedge clk)
begin
  draw_wrdata <= {pixel_r, pixel_g, pixel_b};
  draw_wraddr <= {x_curr[2][1:0], y_curr[2][7:0]};
  zbuf_wrdata <= {x_curr[2][2], z_curr[2][23:9]};
  zbuf_wraddr <= {x_curr[2][1:0], y_curr[2][7:0]};
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