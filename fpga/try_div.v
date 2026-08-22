module try_div (
  input  clk_in,
  
  // CPU Communication
  input spi_clk,
  input spi_cs_n,
  input spi_mosi,
  output irq_n,

  output reg [7:0] lcd_d,
  output lcd_rst_n,// NOTE: Assumed to be active LOW
  output lcd_cs_n, // NOTE: Assumed to be active LOW
  output lcd_rs, // NOTE: Assumed to be LOW for command, HIGH for data
  output lcd_wr_n, // NOTE: Assumed to be triggered on RISING EDGE
  
  input lcd_mode
);

wire clk;
wire outcore_o;
wire lock_o;

pll36 _pll (
  .ref_clk_i(clk_in), 
  //.rst_n_i(pll_rst[2]), // Sim
  .rst_n_i(1'h1), // Synth
  .lock_o(lock_o), 
  .outcore_o(outcore_o), 
  .outglobal_o(clk)
);

// Reset generator
reg pll_lock;
reg rst = 0;
reg reset_done = 0;

always@(posedge clk)
begin
  pll_lock <= lock_o;
  reset_done <= pll_lock;
  rst <= pll_lock & !reset_done; // Reset on rising edge of pll_lock
end


wire [15:0] command_wrdata;
wire command_push;

spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(~spi_cs),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

reg [15:0] dividend;
reg [15:0] divisor;

reg cnt;
always@(posedge clk)
begin
  if(rst)
  begin
    cnt <= 0;
    dividend <= 0;
    divisor <= 0;
  end
  else
  begin
    if(command_push)
    begin
      if(cnt) divisor <= command_wrdata;
      else dividend <= command_wrdata;
      cnt <= ~cnt;
    end
  end
end

wire [31:0] quotient;
wire pull;
wire push;

div_multi #(
  .DIVIDEND_WIDTH(16),
  .DIVISOR_WIDTH(16),
  .OUTPUT_WIDTH(32),
  .OUTPUT_FRAC(16),
  .LOGSTEPS(1)
  ) _div_multi (
  .clk(clk),
  .rst(rst),
  .dividend(dividend), // Must remain constant from next to next
  .divisor(divisor), // Must remain constant from next to next
  .quotient(quotient),
  .pull(pull),
  .push(push)
);

reg [31:0] q;
reg [1:0] cnt2;
always@(posedge clk)
begin
  if(rst)
  begin
    cnt2 <= 0;
    q <= 0;
  end
  else
  begin
    if(push)
    begin
      q <= quotient;
    end
    else
    begin
      lcd_d <= q[31:24];
      q <= {q[23:0], 8'h00};
    end
  end
end


endmodule