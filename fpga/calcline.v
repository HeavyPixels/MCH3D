module calcline(
  input clk,
  input rst,
  // PreCalc
  input [216:0] triangle_data,
  input triangle_empty,
  output reg triangle_pull,
  // DrawLine
  output reg [125:0] span_data,
  output reg span_start,
  input span_done,
  // Frameblock
  output reg [6:0] draw_id,
  output reg draw_next,
  input draw_ready
);

localparam IDLE=3'd0, POP=3'd1, STEP=3'd2, WAIT1=3'd3, WAIT2=3'd4, NWAIT=3'd5, NEXT=3'd6;

reg        block_command;
reg  [6:0] command_data;
reg  [5:0] x1, x2, x3;
reg  [5:0] y1, y2, y3;
reg [12:0] m1, m2, m3;
reg  [9:0] z1;
reg [16:0] mz, nz;
reg  [4:0] r1;
reg [11:0] mr, nr;
reg  [5:0] g1;
reg [12:0] mg, ng;
reg  [4:0] b1;
reg [11:0] mb, nb;

reg [12:0] x_start, x_end;
reg  [5:0] y_curr;
reg [16:0] z_curr;
reg [11:0] r_curr;
reg [12:0] g_curr;
reg [11:0] b_curr;

reg [12:0] x_start_add, x_end_add;
reg [ 5:0] y_add;
reg [16:0] z_add;
reg [11:0] r_add;
reg [12:0] g_add;
reg [11:0] b_add;

always@(posedge clk)
begin
  x_start_add <= x_start + m1;
  if(y_curr+1 < y2)
    x_end_add = x_end + m2;
  if(y_curr+1 == y2)
    x_end_add = {x2, 6'h00};
  if(y_curr+1 > y2)
    x_end_add = x_end + m3;
  y_add <= y_curr + 1;
  z_add <= z_curr + mz;
  r_add <= r_curr + mr;
  g_add <= g_curr + mg;
  b_add <= b_curr + mb;
end


reg [2:0] state;

always@(posedge clk)
begin
  span_start = 0;
  draw_next = 0;
  triangle_pull = 0;
  if(rst)
  begin
    state <= IDLE;
  end
  else
  begin
    case(state)
      IDLE: begin
        state <= POP;
      end
      POP: begin
        if(!triangle_empty)
        begin
          {
            block_command,
            command_data,
            x1,x2,x3,
            y1,y2,y3,
            m1,m2,m3,
            z1,mz,nz,
            r1,mr,nr,
            g1,mg,ng,
            b1,mb,nb
          } = triangle_data;
          x_start = {x1, 6'h00};
          if(y1 == y2)
            x_end = {x2, 6'h00};
          else
            x_end = {x1, 6'h00};
          y_curr = y1;
          z_curr = {z1, 6'h00};
          r_curr = {r1, 6'h00};
          g_curr = {g1, 6'h00};
          b_curr = {b1, 6'h00};
          triangle_pull = 1;
          if(block_command)
          begin
            draw_id <= command_data[6:0];
            draw_next = 1;
            state <= NWAIT;
          end
          else
            state <= STEP;
        end
        else
          state <= POP;
      end
      STEP: begin
        span_data <= {
          x_start[11:6], x_end[11:6],
          y_curr,
          z_curr, nz,
          r_curr, nr,
          g_curr, ng,
          b_curr, nb};
        span_start = 1;
          
        
        state <= WAIT1;
      end
      WAIT1: begin
        x_start = x_start_add[12] ? 13'h0000 : x_start_add[11] ? 13'h0800 : x_start_add;
        x_end = x_end_add[12] ? 13'h0000 : x_end_add[11] ? 13'h0800 : x_end_add;
        y_curr <= y_add;
        z_curr = z_add[16] ? (mz[16] ? 17'h00000 : 17'h1FFFF) : z_add;
        r_curr = r_add[11] ? (mr[11] ? 12'h000 : 12'h7FF) : r_add;
        g_curr = g_add[12] ? (mg[12] ? 13'h0000 : 13'h0FFF) : g_add;
        b_curr = b_add[11] ? (mb[11] ? 12'h000 : 12'h7FF) : b_add;
        state <= WAIT2;
      end
      WAIT2: begin
        if(!span_done)
          state <= WAIT2;
        else if (y_curr > y3 || y_curr > 31)
          state <= IDLE;
        else
          state <= STEP;
      end
      NWAIT: begin
        state <= NEXT;
      end
      NEXT: begin
        if(draw_ready)
          state <= IDLE;
        else
          state <= NEXT;
      end
    endcase
  end
end

endmodule