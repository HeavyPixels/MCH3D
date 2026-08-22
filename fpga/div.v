module abs #(
  parameter WIDTH=8
  ) (
  input clk,
  input [WIDTH-1:0] i,
  output reg [WIDTH-1:0] o,
  output reg s
);
always@(posedge clk)
begin
  s = i[WIDTH-1];
  o = s ? -i : i;
end

endmodule


module sign #(
  parameter WIDTH=8
  ) (
  input clk,
  input [WIDTH-1:0] i,
  input s,
  output reg [WIDTH-1:0] o
);
always@(posedge clk)
begin
  o = s ? -i : i;
end

endmodule

module div_multistep #(
  parameter DIVISOR_WIDTH=8,
  parameter OUTPUT_WIDTH=8,
  parameter LOGSTEPS=2
  ) (
  input clk,
  input [LOGSTEPS-1:0] state,
  input [DIVISOR_WIDTH-1:0] divisor_in,
  input [DIVISOR_WIDTH:0] acc_in,
  input [OUTPUT_WIDTH-1:0] quot_in,
  input sign_in,
  output reg [DIVISOR_WIDTH-1:0] divisor_out,
  output [DIVISOR_WIDTH:0] acc_out,
  output [OUTPUT_WIDTH-1:0] quot_out,
  output reg sign_out
);
localparam STEPS = 1<<(LOGSTEPS);

reg [DIVISOR_WIDTH:0] acc_buf;
reg [OUTPUT_WIDTH-1:0] quot_buf;

wire [DIVISOR_WIDTH:0] acc = (state==0) ? acc_in : acc_buf;
/*// double-cycle
reg [DIVISOR_WIDTH:0] acc_prev;
reg [DIVISOR_WIDTH+1:0] acc_sub;
/**/
// mono-cycle
wire [DIVISOR_WIDTH+1:0] acc_sub = acc - divisor_out;
/**/
wire acc_bigger = ~acc_sub[DIVISOR_WIDTH+1];
/*// double-cycle
wire [DIVISOR_WIDTH:0] acc_temp = acc_bigger ? acc_sub : acc_prev;
/**/
// mono-cycle
wire [DIVISOR_WIDTH:0] acc_temp = acc_bigger ? acc_sub : acc;
/**/

wire [OUTPUT_WIDTH-1:0] quot = (state==0) ? quot_in : quot_buf;

assign acc_out = acc_buf;
assign quot_out = quot_buf;

always@(posedge clk)
begin
  /*// double-cycle
  acc_prev <= acc;
  acc_sub <= acc - divisor_out;
  /**/
  {acc_buf, quot_buf} <= {acc_temp, quot, acc_bigger};
end

always@(posedge clk)
begin
  if(state==STEPS-1)
  begin
    divisor_out <= divisor_in;
    sign_out <= sign_in;
  end
end
endmodule


module div_multi #(
  parameter DIVIDEND_WIDTH=21,
  parameter DIVISOR_WIDTH=12,
  parameter OUTPUT_WIDTH=22,
  parameter OUTPUT_FRAC=6,
  parameter LOGSTEPS=2
  ) (
  input clk,
  input rst,
  input [DIVIDEND_WIDTH-1:0] dividend, // Must remain constant from next to next
  input [DIVISOR_WIDTH-1:0] divisor, // Must remain constant from next to next
  output [OUTPUT_WIDTH-1:0] quotient,
  output pull,
  output push
);

// NOTE: OUTPUT_WIDTH+OUTPUT_FRAC must be a multiple of the stepsize 1<<LOGSTEPS)
localparam ITERATIONS = (OUTPUT_WIDTH+OUTPUT_FRAC)>>LOGSTEPS;
localparam INIT_PADDING = DIVISOR_WIDTH + OUTPUT_WIDTH - DIVIDEND_WIDTH;
localparam STEPS = 1<<(LOGSTEPS);

wire [DIVISOR_WIDTH-1:0] divisor_i [0:ITERATIONS];
wire [DIVISOR_WIDTH:0] accumulator [0:ITERATIONS];
wire [OUTPUT_WIDTH-1:0] quotient_i [0:ITERATIONS];
wire sign_i [0:ITERATIONS];

reg [LOGSTEPS-1:0] state;
always@(posedge clk or posedge rst)
begin
  if(rst)
    state <= 0;
  else
    state <= state + 1;
end
assign pull = state == STEPS - 3;
assign push = state == 1;

wire dividend_sign;
wire divisor_sign;

wire [DIVIDEND_WIDTH-1:0] dividend_abs;

abs #(.WIDTH(DIVIDEND_WIDTH)) abs_dividend (
  .clk(clk),
  .i(dividend),
  .o(dividend_abs),
  .s(dividend_sign)
);

abs #(.WIDTH(DIVISOR_WIDTH)) abs_divisor (
  .clk(clk),
  .i(divisor),
  .o(divisor_i[0]),
  .s(divisor_sign)
);

assign sign_i[0] = dividend_sign ^ divisor_sign;

assign {accumulator[0], quotient_i[0]} = { {INIT_PADDING{1'b0}}, dividend_abs, 1'b0};

genvar i;
generate
  for (i=0; i<ITERATIONS; i=i+1) begin
    div_multistep #(.DIVISOR_WIDTH(DIVISOR_WIDTH), .OUTPUT_WIDTH(OUTPUT_WIDTH), .LOGSTEPS(LOGSTEPS))
    step (
      .clk(clk),
      .state(state),
      .divisor_in(divisor_i[i]),
      .acc_in(accumulator[i]),
      .quot_in(quotient_i[i]),
      .sign_in(sign_i[i]),
      .divisor_out(divisor_i[i+1]),
      .acc_out(accumulator[i+1]),
      .quot_out(quotient_i[i+1]),
      .sign_out(sign_i[i+1])
    );
  end
endgenerate

reg quotient_sign;
always@(posedge clk) quotient_sign <= sign_i[ITERATIONS];

sign #(.WIDTH(OUTPUT_WIDTH)) sign_quotient (
  .clk(clk),
  .i(quotient_i[ITERATIONS]),
  .s(quotient_sign),
  .o(quotient)
);

endmodule