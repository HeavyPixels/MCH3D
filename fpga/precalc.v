module precalc(
  input clk,
  input rst,
  input [121:0] vertices_data,
  input vertices_empty,
  output vertices_pull,
  output reg [216:0] triangle_data,
  input triangle_full,
  output reg triangle_push
);

localparam DSEL_Q =4'h0,
           DSEL_MZ=4'h1,
           DSEL_MR=4'h2,
           DSEL_MG=4'h3,
           DSEL_MB=4'h4,
           DSEL_M1=4'h5,
           DSEL_M2=4'h6,
           DSEL_M3=4'h7,
           DSEL_NZ=4'h8,
           DSEL_NR=4'h9,
           DSEL_NG=4'hA,
           DSEL_NB=4'hB;
localparam MSEL_QX=3'h0,
           MSEL_QZ=3'h1,
           MSEL_QR=3'h2,
           MSEL_QG=3'h3,
           MSEL_QB=3'h4;

wire [7:0] vertex_command = vertices_data[121:114];
wire [37:0] vertex_a = vertices_data[113:76]; //x[6],y[6],z[10],r[5],g[6],b[5]
wire [37:0] vertex_b = vertices_data[75:38]; //x[6],y[6],z[10],r[5],g[6],b[5]
wire [37:0] vertex_c = vertices_data[37:0]; //x[6],y[6],z[10],r[5],g[6],b[5]

reg [7:0] command [0:1];

reg signed [16:0] dividend; //s.10.6
reg signed [12:0] divisor;  //s. 6.6
wire signed [17:0] quotient;//s.10.6 //+1 extra

reg signed [10:0] mult; //s.10.0
wire signed [18:0] product;     //s.12.6

reg  [5:0] x1[0:1], x2[0:1], x3[0:1]; //u. 6.0
reg  [5:0] y1[0:1], y2[0:1], y3[0:1]; //u. 6.0
reg  [9:0] z1[0:1], z2[0:1], z3[0:1]; //u.10.0
reg  [4:0] r1[0:1], r2[0:1], r3[0:1]; //u. 5.0
reg  [5:0] g1[0:1], g2[0:1], g3[0:1]; //u. 6.0
reg  [4:0] b1[0:1], b2[0:1], b3[0:1]; //u. 5.0

reg signed  [6:0] Q;      reg load_Q;      //u. 1.6
reg signed [16:0] mz;     reg load_mz;     //s.10.6
reg signed [11:0] mr;     reg load_mr;     //s. 5.6
reg signed [12:0] mg;     reg load_mg;     //s. 6.6
reg signed [11:0] mb;     reg load_mb;     //s. 5.6
reg signed [12:0] m1;     reg load_m1;     //s. 6.6
reg signed [12:0] m2;     reg load_m2;     //s. 6.6
reg signed [12:0] m3;     reg load_m3;     //s. 6.6
reg signed [16:0] nz;     reg load_nz;     //s.10.6
reg signed [11:0] nr;     reg load_nr;     //s. 5.6
reg signed [12:0] ng;     reg load_ng;     //s. 6.6
reg signed [11:0] nb;     reg load_nb;     //s. 5.6
reg signed [12:0] QMultX; reg load_QMultX; //s. 6.6
reg signed [16:0] QMultZ; reg load_QMultZ; //s.10.6
reg signed [11:0] QMultR; reg load_QMultR; //s. 5.6
reg signed [12:0] QMultG; reg load_QMultG; //s. 6.6
reg signed [11:0] QMultB; reg load_QMultB; //s. 5.6

reg [3:0] div_sel;
reg [2:0] mult_sel;

wire div_next;

reg [5:0] state;

reg pop;
reg push;

reg empty[0:1];

//wires for sorting
wire [5:0] ya = vertex_a[31:26];
wire [5:0] yb = vertex_b[31:26];
wire [5:0] yc = vertex_c[31:26];

wire [2:0] sort_sel = {ya<=yb,ya<=yc,yb<=yc};

assign vertices_pull = pop & ~triangle_full;

//input fifo
always@(posedge clk)
begin
  if(rst)
  begin
    empty[0]<=1; empty[1]<=1;
  end
  else if(pop)
  begin
    empty[0]<=vertices_empty | triangle_full;
    empty[1]<=empty[0];
    case(sort_sel)
      'b111: begin //abc
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_a;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_b;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_c;
      end
      'b110: begin //acb
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_a;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_c;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_b;
      end
      'b011: begin //bac
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_b;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_a;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_c;
      end
      'b100: begin //bca
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_c;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_a;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_b;
      end
      'b001: begin //cab
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_b;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_c;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_a;
      end
      'b000: begin //cba
        {x1[0],y1[0],z1[0],r1[0],g1[0],b1[0]} <= vertex_c;
        {x2[0],y2[0],z2[0],r2[0],g2[0],b2[0]} <= vertex_b;
        {x3[0],y3[0],z3[0],r3[0],g3[0],b3[0]} <= vertex_a;
      end
    endcase
    
    x1[1]<=x1[0];
    x2[1]<=x2[0];
    x3[1]<=x3[0];
    y1[1]<=y1[0];
    y2[1]<=y2[0];
    y3[1]<=y3[0];
    z1[1]<=z1[0];
    z2[1]<=z2[0];
    z3[1]<=z3[0];
    r1[1]<=r1[0];
    r2[1]<=r2[0];
    r3[1]<=r3[0];
    g1[1]<=g1[0];
    g2[1]<=g2[0];
    g3[1]<=g3[0];
    b1[1]<=b1[0];
    b2[1]<=b2[0];
    b3[1]<=b3[0];
    
    command[0]<=vertex_command;
    command[1]<=command[0];
  end
end

//output buffer
always@(posedge clk)
begin
  triangle_data <= { 
    command[1],
    x1[1],x2[1],x3[1], //u. 6.0, u. 6.0, u. 6.0
    y1[1],y2[1],y3[1], //u. 6.0, u. 6.0, u. 6.0
    m1,m2,m3, //s. 6.6, s. 6.6, s. 6.6
    z1[1],mz,nz, //u.10.0, s.10.6, s.10.6
    r1[1],mr,nr, //u. 5.0, s. 5.6, s. 5.6
    g1[1],mg,ng, //u. 6.0, s. 6.6, s. 6.6
    b1[1],mb,nb  //u. 5.0, s. 5.6, s. 5.6
  };
  triangle_push <= push & !empty[1];
end

//controller
always@*
begin
  pop = 0;
  div_sel = 0;
  load_Q = 0;
  load_mz = 0;
  load_mr = 0;
  load_mg = 0;
  load_mb = 0;
  load_m1 = 0;
  load_m2 = 0;
  load_m3 = 0;
  load_nz = 0;
  load_nr = 0;
  load_ng = 0;
  load_nb = 0;
  mult_sel = 0;
  load_QMultX = 0;
  load_QMultZ = 0;
  load_QMultR = 0;
  load_QMultG = 0;
  load_QMultB = 0;
  push = 0;
  case(state)
    'h00:
    begin
      div_sel = DSEL_Q;
    end
    'h01:
    begin
      div_sel = DSEL_Q;
      load_nz = 1;
    end
    'h02:
    begin
      div_sel = DSEL_Q;
    end
    'h03:
    begin
      div_sel = DSEL_Q;
    end
    'h04:
    begin
      div_sel = DSEL_MZ;
    end
    'h05:
    begin
      div_sel = DSEL_MZ;
      load_nr = 1;
    end
    'h06:
    begin
      div_sel = DSEL_MZ;
    end
    'h07:
    begin
      div_sel = DSEL_MZ;
    end
    'h08:
    begin
      div_sel = DSEL_MR;
    end
    'h09:
    begin
      div_sel = DSEL_MR;
      load_ng = 1;
    end
    'h0A:
    begin
      div_sel = DSEL_MR;
    end
    'h0B:
    begin
      div_sel = DSEL_MR;
    end
    'h0C:
    begin
      div_sel = DSEL_MG;
    end
    'h0D:
    begin
      div_sel = DSEL_MG;
      load_nb = 1;
    end
    'h0E:
    begin
      div_sel = DSEL_MG;
    end
    'h0F:
    begin
      div_sel = DSEL_MG;
    end
    'h10:
    begin
      div_sel = DSEL_MB;
    end
    'h11:
    begin
      div_sel = DSEL_MB;
    end
    'h12:
    begin
      div_sel = DSEL_MB;
    end
    'h13:
    begin
      div_sel = DSEL_MB;
    end
    'h14:
    begin
      div_sel = DSEL_M1;
    end
    'h15:
    begin
      div_sel = DSEL_M1;
    end
    'h16:
    begin
      div_sel = DSEL_M1;
    end
    'h17:
    begin
      div_sel = DSEL_M1;
    end
    'h18:
    begin
      div_sel = DSEL_M2;
    end
    'h19:
    begin
      div_sel = DSEL_M2;
    end
    'h1A:
    begin
      div_sel = DSEL_M2;
    end
    'h1B:
    begin
      div_sel = DSEL_M2;
    end
    'h1C:
    begin
      div_sel = DSEL_M3;
    end
    'h1D:
    begin
      div_sel = DSEL_M3;
      load_Q = 1;
    end
    'h1E:
    begin
      div_sel = DSEL_M3;
      push = 1;
    end
    'h1F:
    begin
      mult_sel = MSEL_QX;
      div_sel = DSEL_M3;
    end
    'h20:
    begin
      mult_sel = MSEL_QZ;
    end
    'h21:
    begin
      load_mz = 1;
      mult_sel = MSEL_QR;
      load_QMultX = 1;
    end
    'h22:
    begin
      mult_sel = MSEL_QG;
      load_QMultZ = 1;
    end
    'h23:
    begin
      mult_sel = MSEL_QB;
      load_QMultR = 1;
    end
    'h24:
    begin
      div_sel = DSEL_NZ;
      load_QMultG = 1;
    end
    'h25:
    begin
      div_sel = DSEL_NZ;
      load_mr = 1;
      load_QMultB = 1;
    end
    'h26:
    begin
      div_sel = DSEL_NZ;
    end
    'h27:
    begin
      div_sel = DSEL_NZ;
    end
    'h28:
    begin
      div_sel = DSEL_NR;
    end
    'h29:
    begin
      div_sel = DSEL_NR;
      load_mg = 1;
    end
    'h2A:
    begin
      div_sel = DSEL_NR;
    end
    'h2B:
    begin
      div_sel = DSEL_NR;
    end
    'h2C:
    begin
      div_sel = DSEL_NG;
    end
    'h2D:
    begin
      div_sel = DSEL_NG;
      load_mb = 1;
    end
    'h2E:
    begin
      div_sel = DSEL_NG;
    end
    'h2F:
    begin
      div_sel = DSEL_NG;
    end
    'h30:
    begin
      div_sel = DSEL_NB;
    end
    'h31:
    begin
      div_sel = DSEL_NB;
      load_m1 = 1;
    end
    'h32:
    begin
      div_sel = DSEL_NB;
    end
    'h33:
    begin
      div_sel = DSEL_NB;
    end
    'h34:
    begin
      mult_sel = MSEL_QX;
    end
    'h35:
    begin
      load_m2 = 1;
    end
    //'h36:
    //begin
    //  ;
    //end
    //'h37:
    //begin
    //  ;
    //end
    //'h38:
    //begin
    //  ;
    //end
    'h39:
    begin
      load_m3 = 1;
    end
    //'h3A:
    //begin
    //  ;
    //end
    //'h3B:
    //begin
    //  ;
    //end
    //'h3C:
    //begin
    //  ;
    //end
    //'h3D:
    //begin
    //  ;
    //end
    //'h3E:
    //begin
    //  ;
    //end
    'h3F:
    begin
      pop = 1;
    end
  endcase
end

//state counter
always@(posedge clk)
begin
  if(rst)
    state <= 0;
  else
    state <= state + 1;
end

//subtractions
reg signed [6:0] y3y1;
reg signed [6:0] y2y1;
reg signed [6:0] y3y2;
reg signed [6:0] x3x1;
reg signed [6:0] x2x1;
reg signed [6:0] x3x2;
reg signed [10:0] z3z1;
reg signed [5:0] r3r1;
reg signed [6:0] g3g1;
reg signed [5:0] b3b1;
reg signed [12:0] x2Qxx1;
reg signed [16:0] z2Qzz1;
reg signed [11:0] r2Qrr1;
reg signed [12:0] g2Qgg1;
reg signed [11:0] b2Qbb1;


always@*//
begin
  y3y1   = (y3[0]-y1[0]);
  y2y1   = (y2[0]-y1[0]);
  y3y2   = (y3[0]-y2[0]);
  x3x1   = (x3[0]-x1[0]);
  x2x1   = (x2[0]-x1[0]);
  x3x2   = (x3[0]-x2[0]);
  z3z1   = (z3[0]-z1[0]);
  r3r1   = (r3[0]-r1[0]);
  g3g1   = (g3[0]-g1[0]);
  b3b1   = (b3[0]-b1[0]);
  x2Qxx1 = (-QMultX-{x1[0],6'h00})+{x2[0],6'h00};
  z2Qzz1 = (-QMultZ-{z1[0],6'h00})+{z2[0],6'h00};
  r2Qrr1 = (-QMultR-{r1[0],6'h00})+{r2[0],6'h00};
  g2Qgg1 = (-QMultG-{g1[0],6'h00})+{g2[0],6'h00};
  b2Qbb1 = (-QMultB-{b1[0],6'h00})+{b2[0],6'h00};
end

//dividend mux
always@(posedge clk)//
begin
  case(div_sel)
    DSEL_Q : dividend = y2y1;
    DSEL_MZ: dividend = z3z1;
    DSEL_MR: dividend = r3r1;
    DSEL_MG: dividend = g3g1;
    DSEL_MB: dividend = b3b1;
    DSEL_M1: dividend = x3x1;
    DSEL_M2: dividend = x2x1;
    DSEL_M3: dividend = x3x2;
    DSEL_NZ: dividend = z2Qzz1;
    DSEL_NR: dividend = r2Qrr1;
    DSEL_NG: dividend = g2Qgg1;
    DSEL_NB: dividend = b2Qbb1;
    default: dividend = 0;
  endcase
end
//divisor mux
always@(posedge clk)//
begin
  case(div_sel)
    DSEL_Q : divisor = y3y1;
    DSEL_MZ: divisor = y3y1;
    DSEL_MR: divisor = y3y1;
    DSEL_MG: divisor = y3y1;
    DSEL_MB: divisor = y3y1;
    DSEL_M1: divisor = y3y1;
    DSEL_M2: divisor = y2y1;
    DSEL_M3: divisor = y3y2;
    DSEL_NZ: divisor = x2Qxx1;
    DSEL_NR: divisor = x2Qxx1;
    DSEL_NG: divisor = x2Qxx1;
    DSEL_NB: divisor = x2Qxx1;
    default: divisor = 0;
  endcase
end
//quotient demux
always@(posedge clk)
begin
  if(load_Q)
  begin
    Q<=quotient[6:0];
  end
  if(load_mz)
  begin
    mz<=quotient[16:0];
  end
  if(load_mr)
  begin
    mr<=quotient[11:0];
  end
  if(load_mg)
  begin
    mg<=quotient[12:0];
  end
  if(load_mb)
  begin
    mb<=quotient[11:0];
  end
  if(load_m1)
  begin
    m1<=quotient[12:0];
  end
  if(load_m2)
  begin
    m2<=quotient[12:0];
  end
  if(load_m3)
  begin
    m3<=quotient[12:0];
  end
  if(load_nz)
  begin
    nz<=quotient[16:0];
  end
  if(load_nr)
  begin
    nr<=quotient[11:0];
  end
  if(load_ng)
  begin
    ng<=quotient[12:0];
  end
  if(load_nb)
  begin
    nb<=quotient[11:0];
  end
end



//multiplier mux
always@(posedge clk) //
begin
  case(mult_sel)
    MSEL_QX: mult = x3x1;
    MSEL_QZ: mult = z3z1;
    MSEL_QR: mult = r3r1;
    MSEL_QG: mult = g3g1;
    MSEL_QB: mult = b3b1;
    default: mult = 0;
  endcase
end
//product demux
always@(posedge clk)
begin
  if(load_QMultX)
  begin
    QMultX<=product[12:0];
  end
  if(load_QMultZ)
  begin
    QMultZ<=product[16:0];
  end
  if(load_QMultR)
  begin
    QMultR<=product[11:0];
  end
  if(load_QMultG)
  begin
    QMultG<=product[12:0];
  end
  if(load_QMultB)
  begin
    QMultB<=product[11:0];
  end
end
   
div_multi #(
  .DIVIDEND_WIDTH(17),
  .DIVISOR_WIDTH(13),
  .OUTPUT_WIDTH(18),
  .OUTPUT_FRAC(6),
  .LOGSTEPS(2)
) precalcdiv (
  .clk(clk),
  .rst(rst),
  .dividend(dividend),
  .divisor(divisor),
  .quotient(quotient),
  .pull(div_next)
);


pmi_mult #(
  .pmi_dataa_width         (8), // integer
  .pmi_datab_width         (11), // integer
  .pmi_sign                ("on"), // "on"|"off"
  .pmi_additional_pipeline (0), // integer
  .pmi_input_reg           ("off"), // "on"|"off"
  .pmi_output_reg          ("on"), // "on"|"off"
  .pmi_family              ("iCE40UP"), // "iCE40UP" | "common"
  .pmi_implementation      ("DSP")  // "DSP"|"LUT"
) precalcmult (
  .DataA  ({1'h0,Q}), // "signed" Q, s.1.6
  .DataB  (mult), // up to s.10.0
  .Clock  (clk),
  .ClkEn  ('h1),
  .Aclr   ('h0), // I think it acts as a reset
  .Result (product)   // O: s.16.6 (s.15.7 for Q*x)
);

endmodule
