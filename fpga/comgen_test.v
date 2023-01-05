module comgen_test(
  input clk,
  input rst,
  output reg [7:0] command_wrdata,
  output command_push,
  input command_full
);

// Command Generator
reg [5:0] comgen_state;
reg [3:0] id_x;
reg [2:0] id_y;
wire next_tile = (comgen_state == 6'h2E) & !command_full;

assign command_push = !command_full;

wire [15:0] tile_command = {2'h1, 7'h00, id_y, id_x};
//wire [15:0] vertex_command = {tile_command, tex_command, 7'h00, id_y, id_x};
wire [47:0] vertex_a = {2'h3, 2'h0, 6'h00, 6'h14, 6'h05, 10'h00F, 5'h1F, 6'h00, 5'h00};
wire [47:0] vertex_b = {2'h3, 2'h1, 6'h00, 6'h03, 6'h14, 10'h0F0, 5'h00, 6'h3F, 5'h00};
wire [47:0] vertex_c = {2'h3, 2'h2, 6'h00, 6'h1A, 6'h1A, 10'h100, 5'h00, 6'h00, 5'h1F};
wire [47:0] vertex_d = {2'h3, 2'h0, 6'h00, 6'h00, 6'h00, 10'h200, id_x[2:0],id_x[2:1], 6'h3F, id_y[2:0],id_y[2:1]};
wire [47:0] vertex_e = {2'h3, 2'h1, 6'h00, 6'h20, 6'h00, 10'h200, id_x[2:0],id_x[2:1], 6'h00, id_y[2:0],id_y[2:1]};
wire [47:0] vertex_f = {2'h3, 2'h2, 6'h00, 6'h00, 6'h20, 10'h200, id_x[2:0],id_x[2:1], 6'h3F, id_y[2:0],id_y[2:1]};
wire [47:0] vertex_g = {2'h3, 2'h3, 6'h00, 6'h20, 6'h20, 10'h200, id_x[2:0],id_x[2:1], 6'h00, id_y[2:0],id_y[2:1]};
wire [7:0] triangle1_command = {2'h2, 2'h0, 2'h1, 2'h2};
wire [7:0] triangle2_command = {2'h2, 2'h0, 2'h1, 2'h2};
wire [7:0] triangle3_command = {2'h2, 2'h1, 2'h2, 2'h3};

always@*
begin
  case(comgen_state)
    'h00:
    begin
      command_wrdata <= tile_command[15:8];
    end
    'h01:
    begin
      command_wrdata <= tile_command[7:0];
    end

    'h02:
    begin
      command_wrdata <= vertex_a[47:40];
    end
    'h03:
    begin
      command_wrdata <= vertex_a[39:32];
    end
    'h04:
    begin
      command_wrdata <= vertex_a[31:24];
    end
    'h05:
    begin
      command_wrdata <= vertex_a[23:16];
    end
    'h06:
    begin
      command_wrdata <= vertex_a[15:8];
    end
    'h07:
    begin
      command_wrdata <= vertex_a[7:0];
    end

    'h08:
    begin
      command_wrdata <= vertex_b[47:40];
    end
    'h09:
    begin
      command_wrdata <= vertex_b[39:32];
    end
    'h0A:
    begin
      command_wrdata <= vertex_b[31:24];
    end
    'h0B:
    begin
      command_wrdata <= vertex_b[23:16];
    end
    'h0C:
    begin
      command_wrdata <= vertex_b[15:8];
    end
    'h0D:
    begin
      command_wrdata <= vertex_b[7:0];
    end

    'h0E:
    begin
      command_wrdata <= vertex_c[47:40];
    end
    'h0F:
    begin
      command_wrdata <= vertex_c[39:32];
    end
    'h10:
    begin
      command_wrdata <= vertex_c[31:24];
    end
    'h11:
    begin
      command_wrdata <= vertex_c[23:16];
    end
    'h12:
    begin
      command_wrdata <= vertex_c[15:8];
    end
    'h13:
    begin
      command_wrdata <= vertex_c[7:0];
    end
    'h14:
    begin
      command_wrdata <= triangle1_command;
    end

    'h15:
    begin
      command_wrdata <= vertex_d[47:40];
    end
    'h16:
    begin
      command_wrdata <= vertex_d[39:32];
    end
    'h17:
    begin
      command_wrdata <= vertex_d[31:24];
    end
    'h18:
    begin
      command_wrdata <= vertex_d[23:16];
    end
    'h19:
    begin
      command_wrdata <= vertex_d[15:8];
    end
    'h1A:
    begin
      command_wrdata <= vertex_d[7:0];
    end

    'h1B:
    begin
      command_wrdata <= vertex_e[47:40];
    end
    'h1C:
    begin
      command_wrdata <= vertex_e[39:32];
    end
    'h1D:
    begin
      command_wrdata <= vertex_e[31:24];
    end
    'h1E:
    begin
      command_wrdata <= vertex_e[23:16];
    end
    'h1F:
    begin
      command_wrdata <= vertex_e[15:8];
    end
    'h20:
    begin
      command_wrdata <= vertex_e[7:0];
    end

    'h21:
    begin
      command_wrdata <= vertex_f[47:40];
    end
    'h22:
    begin
      command_wrdata <= vertex_f[39:32];
    end
    'h23:
    begin
      command_wrdata <= vertex_f[31:24];
    end
    'h24:
    begin
      command_wrdata <= vertex_f[23:16];
    end
    'h25:
    begin
      command_wrdata <= vertex_f[15:8];
    end
    'h26:
    begin
      command_wrdata <= vertex_f[7:0];
    end

    'h27:
    begin
      command_wrdata <= vertex_g[47:40];
    end
    'h28:
    begin
      command_wrdata <= vertex_g[39:32];
    end
    'h29:
    begin
      command_wrdata <= vertex_g[31:24];
    end
    'h2A:
    begin
      command_wrdata <= vertex_g[23:16];
    end
    'h2B:
    begin
      command_wrdata <= vertex_g[15:8];
    end
    'h2C:
    begin
      command_wrdata <= vertex_g[7:0];
    end
    'h2D:
    begin
      command_wrdata <= triangle2_command;
    end
    'h2E:
    begin
      command_wrdata <= triangle3_command;
    end
    default:
    begin
      command_wrdata <= 8'h00;
    end
  endcase
end

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    comgen_state <= 6'h00;
  end
  else if(!command_full)
  begin
    if(comgen_state >= 6'h2E)
      comgen_state <= 6'h00;
    else
      comgen_state <= comgen_state + 1;
  end
end

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    id_x <= 4'h0;
    id_y <= 3'h0;
  end
  else
  begin
    if(next_tile)
    begin
      if(id_x >= 4'h9)
      begin
        id_x <= 4'h0;
        id_y <= id_y + 3'h1;
      end
      else
        id_x <= id_x + 4'h1;
    end
  end
end

endmodule