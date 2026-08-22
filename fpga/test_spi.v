`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_spi;

reg spi_clk;
reg spi_cs;
reg spi_mosi;

reg clk;
reg rst;
wire [15:0] command_wrdata;
wire command_push;


spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(spi_cs),
  .spi_mosi(spi_mosi),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

reg [15:0] data_buffer [0:31];
reg [4:0] data_pointer;

integer i;

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    data_pointer <= 0;
    for(i=0; i<32; i=i+1) begin
      data_buffer[i] = 16'h00;
    end
  end
  else if(command_push)
  begin
    data_buffer[data_pointer] <= command_wrdata;
    data_pointer <= data_pointer + 5'h01;
  end
end

always
begin
  clk = 1'b0;
  #14;
  clk = 1'b1;
  #14;
end


task send(
  input [15:0] data_send//,
  //output spi_clk,
  //output spi_data
);
  integer j;
  for(j=15; j>=0; j=j-1) begin
    spi_mosi = data_send[j];
    #6;
    spi_clk = 1'b1;
    #6; 
    spi_clk = 1'b0;
  end
endtask

initial
begin
  spi_clk = 1'b0;
  spi_cs = 1'b0;
  spi_mosi = 1'b0;
  rst = 1'b0;
  #28;
  rst = 1'b1;
  #28;
  rst = 1'b0;
  spi_cs = 1'b1;
  send(16'h0123);//, spi_clk, spi_data);
  spi_cs = 1'b0;
  #48;
  spi_cs = 1'b1;
  send(16'h4567);//, spi_clk, spi_data);
  send(16'h89ab);//, spi_clk, spi_data);
  spi_cs = 1'b0;
  #48;
  spi_cs = 1'b1;
  send(16'h1111);//, spi_clk, spi_data);
  send(16'h2222);//, spi_clk, spi_data);
  send(16'h3333);//, spi_clk, spi_data);
  send(16'h4444);//, spi_clk, spi_data);
  send(16'h5555);//, spi_clk, spi_data);
  send(16'h6666);//, spi_clk, spi_data);
  send(16'h7777);//, spi_clk, spi_data);
  send(16'h8888);//, spi_clk, spi_data);
  send(16'h9999);//, spi_clk, spi_data);
  send(16'hAAAA);//, spi_clk, spi_data);
  send(16'hBBBB);//, spi_clk, spi_data);
  send(16'hCCCC);//, spi_clk, spi_data);
  send(16'hDDDD);//, spi_clk, spi_data);
  send(16'hEEEE);//, spi_clk, spi_data);
  send(16'hFFFF);//, spi_clk, spi_data);
  send(16'h0000);//, spi_clk, spi_data);
  spi_cs = 1'b0;
end

endmodule