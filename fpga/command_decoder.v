// TODO:
// - Adapt command input interface for FIFO
// - Support back-pressure from Vertex FIFO
// - Texture upload
// - Output control
// - Reset

module command_decoder (
  input clk,
  input rst,
  input [7:0] command_rddata,
  output command_pull,
  input command_empty,
  //Write interface
  output reg [1:0] v_sel,
  output [7:0] v_data,
  output reg [2:0] v_addr,
  output reg v_we,
  //Command interface
  output reg [7:0] command,
  output [1:0] va_sel,
  output [1:0] vb_sel,
  output [1:0] vc_sel,
  output reg write,
  input vertices_almost_full
);

reg [7:0] decode_state;
assign command_pull = !command_empty & !vertices_almost_full;
reg did_pull;

always@(posedge clk) did_pull <= command_pull;

always@(posedge clk or posedge rst)
begin
  if(rst)
    decode_state <= 0;
  else
  begin
    if(did_pull)
    begin
      case(decode_state)
        4'h0: begin // Reset
          casez(command_rddata[7:6])
            2'b11: // Vertex 1 | 11VV----
              decode_state <= 4'h1;
            2'b01: // New Block 1 | 01------
              decode_state <= 4'hB;
          endcase
        end
        4'h1: begin // Vertex 2 | --XXXXXX
          decode_state <= 4'h2;
        end
        4'h2: begin // Vertex 3 | YYYYYYZZ
          decode_state <= 4'h3;
        end
        4'h3: begin // Vertex 4 | ZZZZZZZZ
          decode_state <= 4'h4;
        end
        4'h4: begin // Vertex 5 | RRRRRGGG
          decode_state <= 4'h5;
        end
        4'h5: begin // Vertex 6 | GGGBBBBB
          decode_state <= 4'h0;
        end
        4'hB: begin // New Block 2 | -YYYXXXX
          decode_state <= 4'h0;
        end
        default: begin
          decode_state <= 4'h0;
        end
      endcase
    end
  end
end

reg v_sel_write;
always@(posedge clk)
begin
  if(v_sel_write) v_sel <= command_rddata[5:4];
end

assign v_data = command_rddata;

assign va_sel = command_rddata[5:4];
assign vb_sel = command_rddata[3:2];
assign vc_sel = command_rddata[1:0];


always@*
begin
  write = 0;
  v_sel_write = 0;
  v_addr = 3'hx;
  v_we = 0;
  command = 8'h00;
  if(did_pull)
  begin
    case(decode_state)
      4'h0: begin // Reset
        casez(command_rddata[7:6])
          2'b11: begin // Vertex 1 | 11VV....
            v_sel_write = 1;
          end
          2'b10: begin // Triangle | 10AABBCC
            write = 1;
          end
//          2'b01: begin // New Block 1 | 01------
//            ;
//          end
//          2'b00: begin // Output control | 00-----E
//            ;
//          end
        endcase
      end
      4'h1: begin // Vertex 2 | --XXXXXX
        v_addr = 3'h4;
        v_we = 1;
      end
      4'h2: begin // Vertex 3 | YYYYYYZZ
        v_addr = 3'h3;
        v_we = 1;
      end
      4'h3: begin // Vertex 4 | ZZZZZZZZ
        v_addr = 3'h2;
        v_we = 1;
      end
      4'h4: begin // Vertex 5 | RRRRRGGG
        v_addr = 3'h1;
        v_we = 1;
      end
      4'h5: begin // Vertex 6 | GGGBBBBB
        v_addr = 3'h0;
        v_we = 1;
      end
      4'hB: begin // New Block 2 | -YYYXXXX
        command = {1'h1, command_rddata[6:0]};
        write = 1;
      end
    endcase
  end
end

endmodule