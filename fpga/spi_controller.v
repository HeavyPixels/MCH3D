module spi_controller(
  input spi_clk,
  input spi_cs,
  input spi_data,
  input clk,
  input rst,
  output [7:0] command_wrdata,
  output reg command_push
);

reg [7:0] spi_buffer;
reg [2:0] spi_count = 0;

reg data_wrstate[0:3];
reg [7:0] data[0:3];

always@(posedge spi_clk)
begin
  if(spi_cs)
  begin
    spi_buffer = {spi_buffer[6:0], spi_data};
    spi_count <= spi_count + 3'h1;
    if(spi_count == 3'h7)
    begin
      data_wrstate[0] <= ~data_wrstate[0];
      data[0] <= spi_buffer;
    end
  end
end

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    data_wrstate[1] <= 0; data_wrstate[2] <= 0; data_wrstate[3] <= 0;
    data[1] <= 8'h00; data[2] <= 8'h00; data[3] <= 8'h00;
  end
  else
  begin
    data_wrstate[1] <= data_wrstate[0]; data_wrstate[2] <= data_wrstate[1]; data_wrstate[3] <= data_wrstate[2];
    data[1] <= data[0]; data[2] <= data[1]; data[3] <= data[2];
  end
end

reg data_rdstate;

assign command_wrdata = data[3];

always@(posedge clk)
begin
  command_push = 0;
  if((data_wrstate[3] == data_wrstate[2]) && (data_wrstate[2] != data_rdstate))
  begin
    data_rdstate <= ~data_rdstate;
    command_push = 1;
  end
end

endmodule