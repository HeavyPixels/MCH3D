// SPI Controller
// Mono-directional data controller for communication with the CPU.

// Note: The SPI Controller operates on two clocks:
// - clk:     Internal FPGA clock (32MHz)
// - spi_clk: External SPI clock  (up to 80MHz)
// This means that the SPI Controller acts as a clock domain transition.
// For data throughput, the FPGA side should always have the advantage thanks
// to the byte-wide interface vs the serial SPI. To stabilize data over the
// clock domain crossing it is buffered via a small FIFO.

// TODO:
// - Bi-directional communication

module spi_controller(
  // SPI interface
  input spi_clk,
  input spi_cs,
  input spi_mosi,
  // FPGA clock
  input clk,
  input rst,
  // FPGA interface: Actively pushes to FIFO
  output [7:0] command_wrdata,
  output reg command_push
  //input [7:0] return_wrdata,
  //input return_push
);
/*
reg return_status;
reg [7:0] return_data;

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    return_status <= 0;
  end
  else if(return_push)
  begin
    return_data <= return_wrdata;
    return_status <= 1;
  end
end
*/
reg [7:0] spi_buffer;
reg [2:0] spi_count = 0;

reg data_wrstate[0:3];
reg [7:0] data[0:3];

// SPI deserializer
// data_wrstate flips polarity for each processed byte.
always@(posedge spi_clk)
begin
  if(spi_cs)
  begin
    spi_buffer = {spi_buffer[6:0], spi_mosi};
    spi_count <= spi_count + 3'h1;
    if(spi_count == 3'h7)
    begin
      data_wrstate[0] <= ~data_wrstate[0];
      data[0] <= spi_buffer;
    end
  end
end

// Clock transition buffer
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

// Data output
// When data_wrstate is stable, and different from data_rdstate, push the
// latest byte to the command output.
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