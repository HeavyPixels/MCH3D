module trigen_test(
  input clk,
  input rst,
  output [121:0] vertices_wrdata,
  output reg vertices_push,
  input vertices_full
);
  

// Vertex Generator
reg [2:0] vertgen_state;
reg [3:0] id_x;
reg [2:0] id_y;
reg next_tile;

reg [5:0] xa, xb, xc;
reg [5:0] ya, yb, yc;
reg       za, zb, zc;
reg [4:0] ra, rb, rc;
reg [5:0] ga, gb, gc;
reg [4:0] ba, bb, bc;

reg tile_command;
wire [7:0] vertex_command = {tile_command, id_y, id_x};
wire [37:0] vertex_a = {xa, ya, za, 9'h000, ra, ga, ba}; //x[6],y[6],z[10],r[5],g[6],b[5]
wire [37:0] vertex_b = {xb, yb, zb, 9'h000, rb, gb, bb}; //x[6],y[6],z[10],r[5],g[6],b[5]
wire [37:0] vertex_c = {xc, yc, zc, 9'h000, rc, gc, bc}; //x[6],y[6],z[10],r[5],g[6],b[5]

assign vertices_wrdata = {vertex_command, vertex_a, vertex_b, vertex_c};

reg [1:0] tri_sel;

always@*
begin
  case(tri_sel)
    'h0:
    begin
      xa <= 6'h0; ya <= 6'h0; za <= 1'h0; ra <= 5'h0; ga <= 6'h0; ba <= 5'h0;
      xb <= 6'h0; yb <= 6'h0; zb <= 1'h0; rb <= 5'h0; gb <= 6'h0; bb <= 5'h0;
      xc <= 6'h0; yc <= 6'h0; zc <= 1'h0; rc <= 5'h0; gc <= 6'h0; bc <= 5'h0;
    end
    'h1:
    begin
      xa <= 6'h14; ya <= 6'h05; za <= 1'h0; ra <= 5'h1F; ga <= 6'h0; ba <= 5'h0;
      xb <= 6'h03; yb <= 6'h14; zb <= 1'h0; rb <= 5'h0; gb <= 6'h3F; bb <= 5'h0;
      xc <= 6'h1A; yc <= 6'h1A; zc <= 1'h0; rc <= 5'h0; gc <= 6'h0; bc <= 5'h1F;
    end
    'h2:
    begin
      xa <= 6'h00; ya <= 6'h00; za <= 1'h1; ra <= {id_x[2:0],id_x[2:1]}; ga <= 6'h3F; ba <= {id_y[2:0],id_y[2:1]};
      xb <= 6'h20; yb <= 6'h00; zb <= 1'h1; rb <= {id_x[2:0],id_x[2:1]}; gb <= 6'h3F; bb <= {id_y[2:0],id_y[2:1]};
      xc <= 6'h00; yc <= 6'h20; zc <= 1'h1; rc <= {id_x[2:0],id_x[2:1]}; gc <= 6'h3F; bc <= {id_y[2:0],id_y[2:1]};
    end
    'h3:
    begin
      xa <= 6'h20; ya <= 6'h00; za <= 1'h1; ra <= {id_x[2:0],id_x[2:1]}; ga <= 6'h00; ba <= {id_y[2:0],id_y[2:1]};
      xb <= 6'h00; yb <= 6'h20; zb <= 1'h1; rb <= {id_x[2:0],id_x[2:1]}; gb <= 6'h00; bb <= {id_y[2:0],id_y[2:1]};
      xc <= 6'h20; yc <= 6'h20; zc <= 1'h1; rc <= {id_x[2:0],id_x[2:1]}; gc <= 6'h00; bc <= {id_y[2:0],id_y[2:1]};
    end
  endcase
end

always@*
begin
  tile_command = 0;
  next_tile = 0;
  vertices_push = 0;
  case(vertgen_state)
    'h0: // Set Tile ID
    begin
      tri_sel = 0;
      tile_command = 1;
      vertices_push = 1;
    end
    'h1: // Wait 1
    begin
      tri_sel = 0;
    end
    'h2: // Triangle 1
    begin
      tri_sel = 1;
      vertices_push = 1;
    end
    'h3: // Wait 2
    begin
      tri_sel = 1;
    end
    'h4: // Triangle 2
    begin
      tri_sel = 2;
      vertices_push = 1;
    end
    'h5: // Wait 3
    begin
      tri_sel = 2;
    end
    'h6: // Triangle 3
    begin
      tri_sel = 3;
      vertices_push = 1;
      next_tile = 1;
    end
    'h7: // Wait 4
    begin
      tri_sel = 3;
    end
  endcase
end

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    vertgen_state <= 4'h0;
  end
  else
  begin
    case(vertgen_state)
      'h0: // Set Tile ID
      begin
        vertgen_state <= 'h1;
      end
      'h1: // Wait 1
      begin
        if(vertices_full)
          vertgen_state <= 'h1;
        else
          vertgen_state <= 'h2;
      end
      'h2: // Triangle 1
      begin
        vertgen_state <= 'h3;
      end
      'h3: // Wait 2
      begin
        if(vertices_full)
          vertgen_state <= 'h3;
        else
          vertgen_state <= 'h4;
      end
      'h4: // Triangle 2
      begin
        vertgen_state <= 'h5;
      end
      'h5: // Wait 3
      begin
        if(vertices_full)
          vertgen_state <= 'h5;
        else
          vertgen_state <= 'h6;
      end
      'h6: // Triangle 3
      begin
        vertgen_state <= 'h7;
      end
      'h7: // Wait 4
      begin
        if(vertices_full)
          vertgen_state <= 'h7;
        else
          vertgen_state <= 'h0;
      end
    endcase
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