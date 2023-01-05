module triangle_assembly(
  input clk,
  //Write interface
  input [1:0] v_sel,
  input [7:0] v_data,
  input [2:0] v_addr,
  input v_we,
  //Command interface
  input [7:0] command,
  input [1:0] va_sel,
  input [1:0] vb_sel,
  input [1:0] vc_sel,
  input write,
  output [121:0] vertices_wrdata,
  output reg vertices_push,
  input vertices_full
);

// Some extra padding makes the write operation easier
reg [39:0] v0;
reg [39:0] v1;
reg [39:0] v2;
reg [39:0] v3;

always@(posedge clk)
begin
  if(v_we)
  begin
    case(v_sel)
      'h0: v0[v_addr*8 +: 8] <= v_data;
      'h1: v1[v_addr*8 +: 8] <= v_data;
      'h2: v2[v_addr*8 +: 8] <= v_data;
      'h3: v3[v_addr*8 +: 8] <= v_data;
    endcase
  end
end

reg [7:0] vcom;
reg [37:0] va;
reg [37:0] vb;
reg [37:0] vc;

assign vertices_wrdata = {vcom, va, vb, vc};

always@(posedge clk)
begin
  vcom <= command;
  case(va_sel)
    'h0: va <= v0[37:0];
    'h1: va <= v1[37:0];
    'h2: va <= v2[37:0];
    'h3: va <= v3[37:0];
  endcase
  case(vb_sel)
    'h0: vb <= v0[37:0];
    'h1: vb <= v1[37:0];
    'h2: vb <= v2[37:0];
    'h3: vb <= v3[37:0];
  endcase
  case(vc_sel)
    'h0: vc <= v0[37:0];
    'h1: vc <= v1[37:0];
    'h2: vc <= v2[37:0];
    'h3: vc <= v3[37:0];
  endcase
  
  vertices_push <= write & !vertices_full;
end

endmodule