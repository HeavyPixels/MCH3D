module lcd_emu (
  input rst,
  
  input [7:0] lcd_d,
  input lcd_rst_n,// NOTE: Assumed to be active LOW
  input lcd_cs_n, // NOTE: Assumed to be active LOW
  input lcd_rs, // NOTE: Assumed to be LOW for command, HIGH for data
  input lcd_wr_n // NOTE: Assumed to be triggered on RISING EDGE
);


integer f; //file pointer
integer i,j;

// Draw-Buffer
reg [15:0] draw_buffer[0:76799];

initial
begin
  for(j=0; j<76800; j=j+1) begin
    draw_buffer[j] = 16'h0000;
  end
end

// LCD emulator
localparam IDLE=4'h0,
           PAS_SC_high=4'h1,
           PAS_SC_low=4'h2,
           PAS_EC_high=4'h3,
           PAS_EC_low=4'h4,
           CAS_SP_high=4'h5,
           CAS_SP_low=4'h6,
           CAS_EP_high=4'h7,
           CAS_EP_low=4'h8,
           MW_write_high=4'h9,
           MW_write_low=4'hA;

reg [3:0] lcd_emu_state;
reg [15:0] lcd_emu_colstart;
reg [15:0] lcd_emu_colend;
reg [15:0] lcd_emu_rowstart;
reg [15:0] lcd_emu_rowend;
reg [9:0] draw_counter;

always@(rst or posedge lcd_wr_n)
begin
  if(rst)
    lcd_emu_state <= IDLE;
  else if(!lcd_cs_n)
  begin
    if(!lcd_rs)
    begin
      case(lcd_d)
        8'h2B: lcd_emu_state <= PAS_SC_high;
        8'h2A: lcd_emu_state <= CAS_SP_high;
        8'h2C: lcd_emu_state <= MW_write_high;
        default: lcd_emu_state <= IDLE;
      endcase
    end
    else
    begin
      case(lcd_emu_state)
        PAS_SC_high: begin
          draw_counter <= 0;
          lcd_emu_colstart[15:8] <= lcd_d; //{7'h00, frameblock_id[6]};
          lcd_emu_state <= PAS_SC_low;
        end
        PAS_SC_low: begin
          draw_counter <= 0;
          lcd_emu_colstart[7:0] <= lcd_d; //{frameblock_id[5:0], 2'h0};
          lcd_emu_state <= PAS_EC_high;
        end
        PAS_EC_high: begin
          draw_counter <= 0;
          lcd_emu_colend[15:8] <= lcd_d; //{8'h00, frameblock_id[6]};
          lcd_emu_state <= PAS_EC_low;
        end
        PAS_EC_low: begin
          draw_counter <= 0;
          lcd_emu_colend[7:0] <= lcd_d; //{frameblock_id[5:0], 2'h3};
          lcd_emu_state <= IDLE;
        end
        CAS_SP_high: begin
          draw_counter <= 0;
          lcd_emu_rowstart[15:8] <= lcd_d;
          lcd_emu_state <= CAS_SP_low;
        end
        CAS_SP_low: begin
          draw_counter <= 0;
          lcd_emu_rowstart[7:0] <= lcd_d;
          lcd_emu_state <= CAS_EP_high;
        end
        CAS_EP_high: begin
          draw_counter <= 0;
          lcd_emu_rowend[15:8] <= lcd_d;
          lcd_emu_state <= CAS_EP_low;
        end
        CAS_EP_low: begin
          draw_counter <= 0;
          lcd_emu_rowend[7:0] <= lcd_d;
          lcd_emu_state <= IDLE;
        end
        MW_write_high: begin
          draw_buffer[draw_counter + lcd_emu_colstart*240][15:8] <= lcd_d;
          lcd_emu_state <= MW_write_low;
        end
        MW_write_low: begin
          draw_buffer[draw_counter + lcd_emu_colstart*240][7:0] <= lcd_d;
          draw_counter <= draw_counter + 1;
          lcd_emu_state <= MW_write_high;
        end
        default: begin
          lcd_emu_state <= IDLE;
        end
      endcase
    end
  end
end

task write_lcd (input[33*8:0] fname);
  begin
    $display("Writing to %s", fname);
    f = $fopen(fname, "w");
    $fwrite(f, "P3\n320 240\n255");
    for(j=0; j<240; j=j+1) begin
      $fwrite(f, "\n");
      for(i=0; i<320; i=i+1) begin
        $fwrite(f,"%d %d %d  ",
          {draw_buffer[240*i+j][15:11],draw_buffer[240*i+j][15:13]},
          {draw_buffer[240*i+j][10:5],draw_buffer[240*i+j][10:9]},
          {draw_buffer[240*i+j][4:0],draw_buffer[240*i+j][4:2]}
        );
      end
    end
    $fclose(f);
  end
endtask

reg [5:0] image_counter = 6'h00;
wire [28*8-1:0] filename = {"C:/Users/rfmsc/source/", (8'h30+image_counter[5:3]), (8'h30+image_counter[2:0]), ".ppm"};

always@(posedge lcd_wr_n)
begin
  if(!lcd_cs_n && lcd_rs && (lcd_emu_state==PAS_SC_high) && (lcd_emu_colstart==16'h013C))
  begin
    write_lcd(filename);
    image_counter <= image_counter + 1;
  end
end

endmodule