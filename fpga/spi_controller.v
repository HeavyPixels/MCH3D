// SPI Controller
// Mono-directional data controller for communication with the CPU.

// Note: The SPI Controller operates on two clocks:
// - clk:     Internal FPGA clock (36MHz)
// - spi_clk: External SPI clock  (up to 80MHz)
// This means that the SPI Controller acts as a clock domain transition.
// For data throughput, the FPGA side should always have the advantage thanks
// to the wide interface vs the serial SPI. To stabilize data over the
// clock domain crossing it is buffered via a small FIFO.

// TODO:
// - Bi-directional communication

module spi_controller #(parameter LOGWORD = 4, WORD = 1 << LOGWORD) (
  // SPI interface
  input spi_clk,
  input spi_cs,
  input spi_mosi,
  // FPGA clock
  input clk,
  input rst,
  // FPGA interface: Actively pushes to FIFO
  output [WORD-1:0] command_wrdata,
  output reg command_push
  //input [WORD-1:0] return_wrdata,
  //input return_push
);

reg [WORD-2:0] spi_buffer;
reg [WORD-1:0] spi_data_cache;
reg [LOGWORD-1:0] spi_count = 0;

reg spi_cache_full;
reg spi_cmd_reset;


reg [WORD-1:0] user_data;
reg user_mode;

reg [1:0] cache_full;
reg [1:0] cache_reset;

reg ack_spi_word;
reg ack_user_reset;

assign command_wrdata = user_data;

always@(posedge spi_clk or posedge ack_user_reset)
begin
  if (ack_user_reset)
  begin
    spi_cmd_reset <= 0;
  end
  else
  begin
    spi_cmd_reset <= 1;
  end
end

always@(posedge spi_clk or posedge ack_spi_word)
begin
  if (ack_spi_word)
  begin
    spi_cache_full <= 0;
  end
  else
  begin
    if (spi_cs && spi_count == WORD-1)
    begin
      spi_cache_full <= 1;
    end
  end
end
  
always@(posedge spi_clk or negedge spi_cs)
begin
  if (!spi_cs)
  begin
    spi_count <= 0;
  end
  else
  begin
    spi_count <= spi_count + 1;
  end
end
  
always@(posedge spi_clk or negedge spi_cs)
begin
  if (!spi_cs)
  begin
    spi_buffer <= 0;
  end
  else
  begin
    if(ack_spi_word)
    begin
      spi_buffer <= {spi_buffer[WORD-3:0], spi_mosi};
    end
    else
    begin
      if (spi_count == WORD-1) // NOTE: Is the !ack_spi_word condition wanted here?
      begin
        spi_buffer <= 0;
        spi_data_cache <= {spi_buffer, spi_mosi};
      end
      else
      begin
        spi_buffer <= {spi_buffer[WORD-3:0], spi_mosi};
      end
    end
  end
end

always@(posedge clk)
begin
  if (cache_full[1])
  begin
    cache_full <= 0;
    user_data <= spi_data_cache;
    command_push <= 1;
    ack_spi_word <= 1;
  end
  else
  begin
    cache_full <= {cache_full[0], spi_cache_full};
    user_data <= user_data;
    command_push <= 0;
    ack_spi_word <= 0;
  end
end

always@(posedge clk)
begin
  if (cache_reset[1])
  begin
    cache_reset <= 0;
    user_mode <= 0;
    ack_user_reset <= 1;
  end
  else
  begin
    cache_reset <= {cache_reset[0], spi_cmd_reset};
    user_mode <= 1;
    ack_user_reset <= 0;
  end
end

endmodule