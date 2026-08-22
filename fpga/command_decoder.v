// Command Decoder
// Decodes bytestream from CPU into commands and (triangle) data.

// TODO:
// - Adapt command input interface for FIFO
// - Support back-pressure from Vertex FIFO
// - Texture upload
// - Output control
// - Reset

module command_decoder (
  input clk,
  input rst,
  // Command input
  input [15:0] command_rddata,
  output reg command_pull,
  input command_empty,
  
  // Triangle output
  input triangle_full,
  output [479:0] cmd_triangle_wrdata,
  output reg triangle_push,
  input draw_next,
  
  output reg [13:0] texture_wraddr,
  output reg [15:0] texture_wrdata,
  output reg texture_write
);

// Pull logic
//assign command_pull = !command_empty & !triangle_full;
  
// Triangle data storage
reg [479:0] triangle_data;
reg [15:0] triangle_data_last_word;
reg [4:0] triangle_data_count;
reg last_word_select;
wire triangle_ready = (triangle_data_count == 30);

//assign triangle_push = triangle_ready;
assign cmd_triangle_wrdata = {(last_word_select ? triangle_data_last_word : triangle_data[479:464]), triangle_data[463:0]};

always@(posedge clk)
begin
  if(command_pull)
  begin
    triangle_data <= { triangle_data[463:0], command_rddata};
    triangle_data_last_word <= command_rddata;
  end
end

// Texture data
reg [13:0] texture_wraddr_r;

always@(posedge clk)
begin
  if(command_pull)
  begin
    texture_wraddr_r <= command_rddata[13:0];
    texture_wraddr <= texture_wraddr_r;
    texture_wrdata <= command_rddata;
  end
end

localparam COMMAND_PULL=3'd0,
           COMMAND_PARSE=3'd1,
           TRIANGLE_PULL=3'd2,
           TRIANGLE_PARSE=3'd3,
           EFB_SEND=3'd4,
           EFB_WAIT=3'd5,
           TEXTURE_PULL=3'd6,
           TEXTURE_PARSE=3'd7;
           //WAIT=3'd5;

reg [2:0] state;

always@(posedge clk)
begin
  if(rst | state == COMMAND_PULL)
    triangle_data_count <= 5'h00;
  else if(command_pull)
    triangle_data_count <= triangle_data_count + 1;
end


always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    state <= 0;
    triangle_push = 0;
    last_word_select = 0;
    command_pull = 0;
    texture_write = 0;
  end
  else
  begin
    triangle_push = 0;
    last_word_select = 0;
    command_pull = 0;
    texture_write = 0;
    case(state)
      COMMAND_PULL: begin
        command_pull = !command_empty & !triangle_full;
        if(command_pull)
        begin
          state <= COMMAND_PARSE;
        end
        else
        begin
          state <= COMMAND_PULL;
        end
      end
      COMMAND_PARSE: begin
        if(command_rddata[15:14] == 2'h0)
        begin
          state <= TRIANGLE_PULL;
        end
        else if(command_rddata[15:14] == 2'h3)
        begin
          state <= TEXTURE_PULL;
        end
        else // Either EFB or EF, both are handled the same here
        begin
          state <= EFB_SEND;
        end
      end
      TRIANGLE_PULL: begin
        command_pull = !command_empty & !triangle_full;
        if(command_pull)
        begin
          state <= TRIANGLE_PARSE;
        end
        else
        begin
          state <= TRIANGLE_PULL;
        end
      end
      TRIANGLE_PARSE: begin
        if(triangle_data_count == 29)
        begin
          state <= COMMAND_PULL;
          triangle_push = 1;
        end
        else
        begin
          state <= TRIANGLE_PULL;
        end
      end
      EFB_SEND: begin
        state <= EFB_WAIT;
        last_word_select = 1;
        triangle_push = 1;
      end
      EFB_WAIT: begin
        if(draw_next)
        begin
          state <= COMMAND_PULL;
        end
        else
        begin
          state <= EFB_WAIT;
        end
      end
      TEXTURE_PULL: begin // Texture data
        command_pull = !command_empty;
        if(command_pull)
        begin
          state <= TEXTURE_PARSE;
        end
        else
        begin
          state <= TEXTURE_PULL;
        end
      end
      TEXTURE_PARSE: begin // Texture data
        state <= COMMAND_PULL;
        texture_write = 1;
      end
    endcase
  end
end

endmodule

