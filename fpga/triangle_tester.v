// SERIAL VERSION
module triangle_tester(
  input clk,
  input rst,
  input triangle_full,
  output reg [7:0] triangle_wrdata,
  output reg triangle_push,
  input draw_next
);

// "Command Controller"

reg [479:0] triangle_data[0:4];
initial begin
  triangle_data[0] = 480'h002827fde00ef00007fe85fe82003040000000000000f800000000000000_0001917ffde940007fa80065005aff9e00b0000000000000000000000000;
  triangle_data[1] = 480'h000027fde000000007fd020000000004e2000f003e007800000000000000_000000000000000000000000000000000000000000000000000000000000;
  triangle_data[2] = 480'h004fe7fde00ef0077ffd020000000004e2000f003e007800000000000000_000000000000000000000000000000000000000000000000000000000000;
  triangle_data[3] = 480'h000000000000000000000000000000000000000000000000000000000080_000000000000000000000000000000000000000000000000000000000000;
  triangle_data[4] = 480'h000000000000000000000000000000000000000000000000000000000040_000000000000000000000000000000000000000000000000000000000000;
end

reg [0:1] triangle_ready;
reg triangle_ready_set, triangle_ready_clear;
always@(posedge clk)
begin
  if(rst)
    triangle_ready <= 2'h3; // Testing
  else if(triangle_ready_set)
    triangle_ready <= 2'h3;
  else if(triangle_ready_clear)
    triangle_ready <= triangle_ready - 2'h1;
end

reg efb_ready;
wire efb_ready_set = draw_next;
reg efb_ready_clear;
always@(posedge clk)
begin
  if(rst)
    efb_ready <= 1;
  else if(efb_ready_set)
    efb_ready <= 1;
  else if(efb_ready_clear)
    efb_ready <= 0;
end


reg [6:0] efb_counter;
reg efb_add=0, efb_sub;
reg efb_rst; // Testing
always@(posedge clk)
begin
  if(rst || efb_rst)
    efb_counter <= 7'h4F; // Testing
  else if(efb_add && !efb_sub)
    efb_counter <= efb_counter + 7'h01;
  else if(!efb_add && efb_sub)
    efb_counter <= efb_counter - 7'h01;
end


reg ef_state;
reg ef_set, ef_clear;
always@(posedge clk)
begin
  if(rst)
    ef_state <= 1; // Testing
  else if(ef_set)
    ef_state <= 1;
  else if(ef_clear)
    ef_state <= 0;
end

reg [6:0] output_counter;
reg [2:0] state;

localparam IDLE=3'd0, TRI1=3'd1, TRI2=3'd2, EFB1=3'd3, EFB2=3'd4, EF1=3'd5, EF2=3'd6;

always@(posedge clk)
begin
  if(rst)
  begin
    state <= IDLE;
  end
  else
  begin
    case(state)
      IDLE: begin
        if(triangle_full)
          state <= IDLE;
        else if(triangle_ready > 0)
        begin
          state <= TRI1;
          output_counter <= 59;
        end
        else if(efb_counter > 0 && efb_ready)
        begin
          state <= EFB1;
          output_counter <= 59;
        end
        else if(ef_state && efb_ready)
        begin
          state <= EF1;
          output_counter <= 59;
        end
      end
      TRI1: begin
        if(output_counter == 0)
          state <= TRI2;
        else
          state <= TRI1;
        output_counter <= output_counter - 1;
      end
      TRI2: begin
        state <= IDLE;
      end
      EFB1: begin
        if(output_counter == 0)
          state <= EFB2;
        else
          state <= EFB1;
        output_counter <= output_counter - 1;
      end
      EFB2: begin
        state <= IDLE;
      end
      EF1: begin
        if(output_counter == 0)
          state <= EF2;
        else
          state <= EF1;
        output_counter <= output_counter - 1;
      end
      EF2: begin
        state <= IDLE;
      end
    endcase
  end
end

always@*
begin
  triangle_ready_set = 0;
  triangle_ready_clear = 0;
  efb_ready_clear = 0;
  efb_sub = 0;
  ef_set = 0;
  ef_clear = 0;
  triangle_push = 0;
  efb_rst = 0; // Testing
  case(state)
    TRI1: begin
      triangle_wrdata = triangle_data[2'h3 - triangle_ready][8*output_counter+:8];
      triangle_push = 1;
    end
    TRI2: begin
      triangle_ready_clear = 1;
    end
    EFB1: begin
      triangle_wrdata = triangle_data[3][8*output_counter+:8];
      triangle_push = 1;
      efb_ready_clear = 1;
      efb_sub = 1;
    end
    //EFB2: begin
    //  ;
    //end
    EF1: begin
      triangle_wrdata = triangle_data[4][8*output_counter+:8];
      triangle_push = 1;
      triangle_ready_set = 1; // Testing
      efb_ready_clear = 1;
      ef_clear = 1;
      efb_rst = 1; // Testing
    end
    EF2: begin
      ef_set = 1; // Testing
    end
  endcase
end
endmodule

/* PARALLEL VERSION
module triangle_tester(
  input clk,
  input rst,
  input triangle_full,
  output reg [479:0] triangle_wrdata,
  output reg triangle_push,
  input draw_next
);

// "Command Controller"

reg [479:0] triangle_data[0:2];
initial begin
  triangle_data[0] = 480'h002827fde00ef00007fe85fe82003040000000000000f800000000000000_0001917ffde940007fa80065005aff9e00b0000000000000000000000000;
  triangle_data[1] = 480'h000027fde000000007fd020000000004e2000f003e007800000000000000_000000000000000000000000000000000000000000000000000000000000;
  triangle_data[2] = 480'h004fe7fde00ef0077ffd020000000004e2000f003e007800000000000000_000000000000000000000000000000000000000000000000000000000000;
end

reg [0:1] triangle_ready;
reg triangle_ready_set, triangle_ready_clear;
always@(posedge clk)
begin
  if(rst)
    triangle_ready <= 2'h3; // Testing
  else if(triangle_ready_set)
    triangle_ready <= 2'h3;
  else if(triangle_ready_clear)
    triangle_ready <= triangle_ready - 2'h1;
end

reg efb_ready;
wire efb_ready_set = draw_next;
reg efb_ready_clear;
always@(posedge clk)
begin
  if(rst)
    efb_ready <= 1;
  else if(efb_ready_set)
    efb_ready <= 1;
  else if(efb_ready_clear)
    efb_ready <= 0;
end


reg [6:0] efb_counter;
reg efb_add=0, efb_sub;
reg efb_rst; // Testing
always@(posedge clk)
begin
  if(rst || efb_rst)
    efb_counter <= 7'h4F; // Testing
  else if(efb_add && !efb_sub)
    efb_counter <= efb_counter + 7'h01;
  else if(!efb_add && efb_sub)
    efb_counter <= efb_counter - 7'h01;
end


reg ef_state;
reg ef_set, ef_clear;
always@(posedge clk)
begin
  if(rst)
    ef_state <= 1; // Testing
  else if(ef_set)
    ef_state <= 1;
  else if(ef_clear)
    ef_state <= 0;
end

reg [2:0] state;

localparam IDLE=3'd0, TRI1=3'd1, TRI2=3'd2, EFB1=3'd3, EFB2=3'd4, EF1=3'd5, EF2=3'd6;

always@(posedge clk)
begin
  if(rst)
  begin
    state <= IDLE;
  end
  else
  begin
    case(state)
      IDLE: begin
        if(triangle_full)
          state <= IDLE;
        else if(triangle_ready > 0)
          state <= TRI1;
        else if(efb_counter > 0 && efb_ready)
          state <= EFB1;
        else if(ef_state && efb_ready)
          state <= EF1;
      end
      TRI1: begin
        state <= TRI2;
      end
      TRI2: begin
        state <= IDLE;
      end
      EFB1: begin
        state <= EFB2;
      end
      EFB2: begin
        state <= IDLE;
      end
      EF1: begin
        state <= EF2;
      end
      EF2: begin
        state <= IDLE;
      end
    endcase
  end
end

always@*
begin
  triangle_ready_set = 0;
  triangle_ready_clear = 0;
  efb_ready_clear = 0;
  efb_sub = 0;
  ef_set = 0;
  ef_clear = 0;
  triangle_push = 0;
  efb_rst = 0; // Testing
  case(state)
    TRI1: begin
      triangle_wrdata = triangle_data[2'h3 - triangle_ready][479:0];
      triangle_push = 1;
    end
    TRI2: begin
      triangle_ready_clear = 1;
    end
    EFB1: begin
      triangle_wrdata = 480'h000000000000000000000000000000000000000000000000000000000080_000000000000000000000000000000000000000000000000000000000000;
      triangle_push = 1;
      efb_ready_clear = 1;
      efb_sub = 1;
    end
    //EFB2: begin
    //  ;
    //end
    EF1: begin
      triangle_wrdata = 240'h000000000000000000000000000000000000000000000000000000000040_000000000000000000000000000000000000000000000000000000000000;
      triangle_push = 1;
      triangle_ready_set = 1; // Testing
      efb_ready_clear = 1;
      ef_clear = 1;
      efb_rst = 1; // Testing
    end
    EF2: begin
      ef_set = 1; // Testing
    end
  endcase
end
endmodule*/