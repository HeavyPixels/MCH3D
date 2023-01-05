`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module test_spi;

reg spi_clk;
reg spi_cs;
reg spi_data;

reg clk;
reg rst;
wire [7:0] command_wrdata;
wire command_push;


spi_controller _spi_controller (
  .spi_clk(spi_clk),
  .spi_cs(spi_cs),
  .spi_data(spi_data),
  .clk(clk),
  .rst(rst),
  .command_wrdata(command_wrdata),
  .command_push(command_push)
);

reg [7:0] data_buffer [0:31];
reg [4:0] data_pointer;

integer i;

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    for(i=0; i<32; i=i+1) begin
      data_buffer[i] = 8'h00;
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
  input [7:0] data_send//,
  //output spi_clk,
  //output spi_data
);
  integer j;
  for(j=7; j>=0; j=j-1) begin
    spi_clk = 1'b0;
    spi_data = data_send[j];
    #24;
    spi_clk = 1'b1;
    #24; 
  end
endtask

initial
begin
  spi_clk = 1'b0;
  spi_cs = 1'b0;
  spi_data = 1'b0;
  rst = 1'b0;
  #28;
  rst = 1'b1;
  #28;
  rst = 1'b0;
  spi_cs = 1'b1;
  send(8'h01);//, spi_clk, spi_data);
  spi_cs = 1'b0;
  #48;
  spi_cs = 1'b1;
  send(8'h23);//, spi_clk, spi_data);
  send(8'h45);//, spi_clk, spi_data);
  spi_cs = 1'b0;
  #48;
  spi_cs = 1'b1;
  send(8'h67);//, spi_clk, spi_data);
  send(8'h89);//, spi_clk, spi_data);
  send(8'hAB);//, spi_clk, spi_data);
  send(8'hCD);//, spi_clk, spi_data);
  send(8'hEF);//, spi_clk, spi_data);
  spi_cs = 1'b0;
end

endmodule