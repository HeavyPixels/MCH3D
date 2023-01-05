module lcd_controller (
  input clk,
  input rst,
  input [15:0] frameblock_data,
  output [9:0] frameblock_addr,
  input [6:0] frameblock_id,
  output reg frameblock_next,
  input frameblock_ready,
  output reg [8:0] lcd_command_data,
  input lcd_command_pull,
  output reg lcd_rst,
  input lcd_ready
);

reg [8:0] tile_command_data;

reg [7:0] rom_addr;
wire [8:0] rom_data;

init_rom _init_rom(
  .rd_clk_i(clk),
  .rst_i(rst),
  .rd_en_i(1'h1),
  .rd_clk_en_i(1'h1),
  .rd_addr_i(rom_addr[6:0]),
  .rd_data_o(rom_data)
);

wire delay_zero;
assign init_done = rom_addr[7];

wire do_count = lcd_command_pull & delay_zero & ~init_done & lcd_ready;

always@(posedge clk or posedge rst)
begin
  if(rst)
    rom_addr = 7'h00;
  else
    rom_addr = rom_addr + do_count;
end

// The delay counter is 24 bits, which gives us a range of just under 350ms at 48MHz.
// 24'h010000 is 1.365 ms, which is close enough to basically treat the upper byte as a slow millisecond counter.
reg [24:0] delay_counter;
assign delay_zero = delay_counter[24];
reg [7:0] delay_data;
reg delay_write;

always@(posedge clk or posedge rst)
begin
  if(rst)
    delay_counter <= 25'h0000000;
  else if(delay_write)
    delay_counter <= {1'h0, delay_data, 16'h0000};
  else
    delay_counter <= delay_counter - {24'h000000, ~delay_zero};
end

reg expect_delay;

// Command processing
// Most commands will be passed straight to the output.
// Special commands:
// 9'h100: NOP
//         No operation. Used as a default output to hide special commands.
// 9'h1FD: Set Reset
//         Sets the reset pin
// 9'h1FE: Clear Reset
//         Clears the reset pin
// 9'h1FF: Delay
//         The next byte indicates the upper byte of the delay counter.
always@(posedge clk)
begin
  delay_write = 0;
  if(lcd_command_pull)
  begin
    if(init_done)
    begin
      lcd_command_data <= tile_command_data;
    end
    else if(delay_zero)
    begin
      if(expect_delay)
      begin
        delay_data <= rom_data[7:0];
        delay_write = 1;
        expect_delay = 0;
      end
      else case(rom_data)
        9'h1FD: begin // Set Reset
          lcd_rst <= 1;
          lcd_command_data <= 9'h100;
        end
        9'h1FE: begin // Clear Reset
          lcd_rst <= 0;
          lcd_command_data <= 9'h100;
        end
        9'h1FF: begin // Delay
          expect_delay = 1;
          lcd_command_data <= 9'h100;
        end
        default: begin
          lcd_command_data <= rom_data;
        end
      endcase
    end
  end
end


reg [3:0] tile_state;

reg [10:0] tile_counter;
assign frameblock_addr = tile_counter[9:0];

wire count_done = ((frameblock_id[6:4] == 3'h7) && tile_counter == 11'h1FF) || (tile_counter == 11'h3FF);

wire frameblock_pull = (tile_state == 4'hE) && lcd_command_pull;

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    tile_counter <= 11'h400;
    frameblock_next <= 0;
  end
  else
  begin
    if(((frameblock_id[6:4] == 3'h7) && tile_counter[9]) || tile_counter[10])
    begin
      frameblock_next <= 1;
      tile_counter <= 11'h0;
    end
    else
    begin 
      frameblock_next <= 0;
      if(frameblock_pull)
      begin
        tile_counter <= tile_counter + 11'h1;
      end
    end
  end
end



always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    tile_state <= 4'h0;
  end
  else
  begin
    if(lcd_command_pull)
    begin
      case(tile_state)
        4'h0: begin // reset
          if(init_done)
            tile_state <= 4'h1;
        end
        4'h1: begin // wait for ready
          if(frameblock_ready)
            tile_state <= 4'h2;
        end
        4'h2: begin // CAS_command
          tile_state <= 4'h3;
        end
        4'h3: begin // CAS_SC_high
          tile_state <= 4'h4;
        end
        4'h4: begin // CAS_SC_low
          tile_state <= 4'h5;
        end
        4'h5: begin // CAS_EC_high
          tile_state <= 4'h6;
        end
        4'h6: begin // CAS_EC_low
          tile_state <= 4'h7;
        end
        4'h7: begin // PAS_command
          tile_state <= 4'h8;
        end
        4'h8: begin // PAS_SP_high
          tile_state <= 4'h9;
        end
        4'h9: begin // PAS_SP_low
          tile_state <= 4'hA;
        end
        4'hA: begin // PAS_EP_high
          tile_state <= 4'hB;
        end
        4'hB: begin // PAS_EP_low
          tile_state <= 4'hC;
        end
        4'hC: begin // MW_command
          tile_state <= 4'hD;
        end
        4'hD: begin // MW_write_high
          tile_state <= 4'hE;
        end
        4'hE: begin // MW_write_low
          if(count_done)
            tile_state <= 4'h1;
          else
            tile_state <= 4'hD;
        end
        default:
          tile_state <= 4'h0;
      endcase
    end
  end
end
        
always@*
begin
  case(tile_state)
    4'h0: begin // reset
      tile_command_data <= 9'h100;
    end
    4'h1: begin // wait for ready
      tile_command_data <= 9'h100;
    end
    4'h2: begin // CAS_command
      tile_command_data <= 9'h12A;
    end
    4'h3: begin // CAS_SC_high
      tile_command_data <= {8'h00, frameblock_id[3]};
    end
    4'h4: begin // CAS_SC_low
      tile_command_data <= {frameblock_id[2:0], 5'h00};
    end
    4'h5: begin // CAS_EC_high
      tile_command_data <= {8'h00, frameblock_id[3]};
    end
    4'h6: begin // CAS_EC_low
      tile_command_data <= {frameblock_id[2:0], 5'h1F};
    end
    4'h7: begin // PAS_command
      tile_command_data <= 9'h12B;
    end
    4'h8: begin // PAS_SP_high
      tile_command_data <= 9'h000;
    end
    4'h9: begin // PAS_SP_low
      tile_command_data <= {frameblock_id[6:4], 5'h00};
    end
    4'hA: begin // PAS_EP_high
      tile_command_data <= 9'h000;
    end
    4'hB: begin // PAS_EP_low
      if(frameblock_id[6:4] == 3'h7) // last row
        tile_command_data <= {frameblock_id[6:4], 5'h0F};
      else
        tile_command_data <= {frameblock_id[6:4], 5'h1F};
    end
    4'hC: begin // MW_command
      tile_command_data <= 9'h12C;
    end
    4'hD: begin // MW_write_high
      tile_command_data <= {1'h0, frameblock_data[15:8]};
    end
    4'hE: begin // MW_write_low
      tile_command_data <= {1'h0, frameblock_data[7:0]};
    end
    default:
      tile_command_data <= 9'h100;
  endcase
end


endmodule