// LCD Interface
// This module connects directly to the LCD device, transferring individual command and data bytes using the correct RS and WR signals.
// No reads are supported, so RD is fixed to high. The device is always active, so CS is fixed to low. Which should probably be fine...
// Write speed is 1/4 of the input clock
module lcd_interface(
  input clk,
  input rst,
  input [8:0] lcd_command_data,
  output reg lcd_command_pull,
  output reg lcd_rs,
  output     lcd_cs,
  output reg lcd_wr,
  output reg [7:0] lcd_d
);

parameter s0 = 0,
          s1 = 1,
          s2 = 2,
          s3 = 3;

assign lcd_cs = 0; // Always enable chip

reg cmd;
reg [7:0] data;

reg [1:0] state;

always @ (posedge clk/* or posedge rst*/)
begin
  if (rst) state <= s0;
  else     state <= state + 2'h1;
end

always @ (posedge clk)
begin
  if(lcd_command_pull)
  begin
    cmd <= lcd_command_data[8];
    data <= lcd_command_data[7:0]; 
  end
end

// Output decoder
always @*
begin
  case (state)
    s0: begin // Reset, set data
      lcd_rs <= ~cmd;
      lcd_wr <= 0;
      lcd_d <= data;
      lcd_command_pull <= 0;
    end
    s1: begin // Wait state
      lcd_rs <= ~cmd;
      lcd_wr <= 0;
      lcd_d <= data;
      lcd_command_pull <= 0;
    end
    s2: begin // Trigger WR
      lcd_rs <= ~cmd;
      lcd_wr <= ({cmd,data} != 9'h100); // Active high, disabled for NOP
      lcd_d <= data;    
      lcd_command_pull <= 0;   
    end
    s3: begin  // Trigger WR, next command
      lcd_rs <= ~cmd;
      lcd_wr <= ({cmd,data} != 9'h100); // Active high, disabled for NOP
      lcd_d <= data;    
      lcd_command_pull <= 1;  
    end
  endcase
end

endmodule