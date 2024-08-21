module calcline(
  input clk,
  input rst,
  // PreCalc
  input [239:0] triangle_rddata,
  input triangle_empty,
  output triangle_pull,
  output reg [479:0] triangle_wrdata,
  output reg triangle_push,
  // DrawLine
  output [248:0] span_data,
  output reg span_start,
  input span_done,
  // Frameblock
  output reg [6:0] draw_id,
  output reg draw_next,
  input draw_ready
);

localparam IDLE=4'd0, PULL1=4'd1, PULL2=4'd2, PULL3=4'd3, PUSH1=4'd4, PUSH2=4'd5, WAIT=4'd6, NEXT1=4'd7, NEXT2=4'd8;

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
reg end_frameblock;    //   1
reg end_frame;         //   1
reg  [5:0] reserved1;  //   6
reg [14:0] g_curr;     //   6.9
reg [15:0] mg, ng;     //s. 6.9
reg [13:0] b_curr;     //   5.9
reg [14:0] mb, nb;     //s. 5.9
reg [20:0] u_curr;     //  12.9
reg [21:0] mu, nu;     //s.12.9
reg [20:0] v_curr;     //  12.9
reg [21:0] mv, nv;     //s.12.9
reg  [9:0] reserved2;  //  10

assign span_data = {
  y_start[16:9], y_end[16:9],
  x_curr[2:0],
  1'b0, z_curr, nz,
  1'b0, r_curr, nr,
  1'b0, g_curr, ng,
  1'b0, b_curr, nb,
  1'b0, u_curr, nu,
  1'b0, v_curr, nv
};

reg [17:0] y_start_add, y_end_add;  //s. 8.9
reg  [8:0] x_add;                   //   9.0
reg [24:0] z_add;                   //s.15.9
reg [14:0] r_add;                   //s. 5.9
reg [15:0] g_add;                   //s. 6.9
reg [14:0] b_add;                   //s. 5.9
reg [21:0] u_add;                   //s.12.9
reg [21:0] v_add;                   //s.12.9

reg pop1, pop2, pop3;
assign triangle_pull = pop1 | pop2;
reg next_add;
reg push;

always@(posedge clk)
begin
  if(pop2)
  begin
    {
      x_curr, x2, x3,
      y_start, y_end, y2,
      m1, m2, m3,
      z_curr,
      r_curr,
      g_curr,
      b_curr,
      u_curr,
      v_curr,
      end_frameblock,
      end_frame,
      reserved1
    } <= triangle_rddata;
  end
  else if(pop3)
  begin
    {
      mz, nz,
      mr, nr,
      mg, ng,
      mb, nb,
      mu, nu,
      mv, nv,
      reserved2
    } <= triangle_rddata;
  end
  else if(next_add)
  begin
    y_start <= y_start_add;
    y_end <= y_end_add;
    x_curr <= x_add;
    z_curr <= z_add;
    r_curr <= r_add;
    g_curr <= g_add;
    b_curr <= b_add;
    u_curr <= u_add;
    v_curr <= v_add;
  end
  else if(push)
  begin
    triangle_wrdata <= {
      x_curr, x2, x3,
      y_start, y_end, y2,
      m1, m2, m3,
      z_curr,
      r_curr,
      g_curr,
      b_curr,
      u_curr,
      v_curr,
      end_frameblock,
      end_frame,
      reserved1,
      mz, nz,
      mr, nr,
      mg, ng,
      mb, nb,
      mu, nu,
      mv, nv,
      reserved2
    };
  end
  triangle_push <= push & !rst;
end

reg [17:0] m_end_current;

always@(posedge clk)
begin
  y_start_add <= y_start + m1;
  if(x_curr+1 < x2)
    m_end_current <= m2;
  else
    m_end_current <= m3;
  if(x_curr+1 == x2)
    y_end_add = {y2, 9'h000};
  else 
    y_end_add = y_end + m_end_current;
  x_add <= x_curr + 1;
  z_add <= z_curr + mz;
  r_add <= r_curr + mr;
  g_add <= g_curr + mg;
  b_add <= b_curr + mb;
  u_add <= u_curr + mu;
  v_add <= v_curr + mv;
end

always@(posedge clk)
begin
  if(rst)
  begin
    draw_id <= 7'h00;
    draw_next <= 0;
  end
  else if(end_frameblock & pop3)
  begin
    draw_id <= draw_id + 7'h01;
    draw_next <= 1;
  end
  else if(end_frame & pop3)
  begin
    draw_id <= 7'h00;
    draw_next <= 1;
  end
  else
  begin
    draw_next <= 0;
  end
end

reg [3:0] state;

wire active = (x_curr[8:2] == draw_id) && !(end_frameblock | end_frame);
wire current = x3 > {draw_id, 2'h3};

always@(posedge clk)
begin
  if(rst)
    state <= IDLE;
  else
  begin
    case(state)
      IDLE: begin
        if(!triangle_empty & draw_ready)
          state <= PULL1;
        else
          state <= IDLE;
      end
      PULL1: begin
        state <= PULL2;
      end
      PULL2: begin
        state <= PULL3;
      end
      PULL3: begin
        //if(end_frameblock | end_frame)
        //  state <= IDLE;
        //else
          state <= WAIT;
      end
      WAIT: begin
        if(span_done)
        begin
          if(active)
            state <= NEXT1;
          else if(current)
            state <= PUSH1;
          else
            state <= IDLE;
        end
      end
      NEXT1: begin
        state <= NEXT2;
      end
      NEXT2: begin
        state <= WAIT;
      end
      PUSH1: begin
        state <= PUSH2;
      end
      PUSH2: begin
        state <= IDLE;
      end
    endcase
  end
end

always@*
begin
  pop1 = 0;
  pop2 = 0;
  pop3 = 0;
  push = 0;
  span_start = 0;
  next_add = 0;
  case(state)
    //IDLE: begin
    //  ;
    //end
    PULL1: begin
      pop1 = 1;
    end
    PULL2: begin
      pop2 = 1;
    end
    PULL3: begin
      pop3 = 1;
    end
    //WAIT: begin
    //  ;
    //end
    NEXT1: begin
      span_start = 1;
    end
    NEXT2: begin
      next_add = 1;
    end
    PUSH1: begin
      push = 1;
    end
    //PUSH2: begin
    //  ;
    //end
  endcase
end

/*
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
            x1,x2,x3,
            y1,y2,y3,
            m1,m2,m3,
            z1,mz,nz,
            r1,mr,nr,
            g1,mg,ng,
            b1,mb,nb
          } = triangle_data;
          y_start = {y1, 9'h000};
          if(x1 == x2)
            y_end = {y2, 9'h000};
          else
            y_end = {y1, 9'h000};
          x_curr = x1;
          z_curr = {z1, 9'h000};
          r_curr = {r1, 9'h000};
          g_curr = {g1, 9'h000};
          b_curr = {b1, 9'h000};
          triangle_pull = 1;
          state <= STEP;
        end
        else
          state <= POP;
      end
      STEP: begin
        span_data <= {
          y_start[16:9], y_end[16:9],
          x_curr,
          z_curr, nz,
          r_curr, nr,
          g_curr, ng,
          b_curr, nb};
        span_start = 1;
          
        
        state <= WAIT1;
      end
      WAIT1: begin
        y_start = y_start_add[17] ? 18'h00000 : y_start_add[16] ? 18'h10000 : y_start_add;
        y_end = y_end_add[17] ? 18'h00000 : y_end_add[16] ? 18'h10000 : y_end_add;
        x_curr <= x_add;
        z_curr = z_add[24] ? (mz[24] ? 25'h00000 : 25'h0FFFFF) : z_add;
        r_curr = r_add[14] ? (mr[14] ? 15'h0000 : 15'h3FFF) : r_add;
        g_curr = g_add[15] ? (mg[15] ? 16'h0000 : 16'h7FFF) : g_add;
        b_curr = b_add[14] ? (mb[14] ? 15'h0000 : 15'h3FFF) : b_add;
        state <= WAIT2;
      end
      WAIT2: begin
        if(!span_done) // Continue waiting
          state <= WAIT2;
        else if (x_curr > x3) // Triangle done
          state <= IDLE;
        else if (x_curr > 31) // Push back triangle
          state <= ???
        else
          state <= STEP; // Draw next line
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
*/

endmodule