// Frameblock controller
// The frameblock is a double-buffered (triple-buffered?) block of 32x32 pixels acting as a partial framebuffer. While triangles are drawn to one buffer, the other buffer is written to the screen.
// On the drawing side, the dual-port ram block is exposed directly to allow for random pixel writes and read-modify-write operations. When the a block has finished drawing, the drawing controller sets the next block id and pulses the next signal. The drawing controller should wait until the ready signal is raised before accessing the new block.
// On the display side, a 
module frameblock_controller (
  input clk,
  input rst,
  input [15:0] draw_wrdata,
  input [9:0] draw_wraddr,
  input draw_we,
  output [15:0] draw_rddata,
  input [9:0] draw_rdaddr,
  input [6:0] draw_id,
  input draw_next,
  output draw_ready,
  
  output [15:0] display_rddata,
  input [9:0] display_rdaddr,
  output [6:0] display_id,
  input display_next,
  output display_ready
);

wire [15:0] rama_wrdata;
wire [ 9:0] rama_wraddr;
wire        rama_we;
wire [15:0] rama_rddata;
wire [ 9:0] rama_rdaddr;

wire [15:0] ramb_wrdata;
wire [ 9:0] ramb_wraddr;
wire        ramb_we;
wire [15:0] ramb_rddata;
wire [ 9:0] ramb_rdaddr;


frameblock_ram rama (
  .wr_clk_i( clk ),
  .rd_clk_i( clk ),
  .rst_i( rst ),
  .wr_clk_en_i( 1'h1 ),
  .rd_en_i( 1'h1 ),
  .rd_clk_en_i( 1'h1 ),
  .wr_en_i( rama_we ),
  .wr_data_i( rama_wrdata ),
  .wr_addr_i( rama_wraddr ),
  .rd_addr_i( rama_rdaddr ),
  .rd_data_o( rama_rddata )
);
reg [6:0] rama_id;

frameblock_ram ramb (
  .wr_clk_i( clk ),
  .rd_clk_i( clk ),
  .rst_i( rst ),
  .wr_clk_en_i( 1'h1 ),
  .rd_en_i( 1'h1 ),
  .rd_clk_en_i( 1'h1 ),
  .wr_en_i( ramb_we ),
  .wr_data_i( ramb_wrdata ),
  .wr_addr_i( ramb_wraddr ),
  .rd_addr_i( ramb_rdaddr ),
  .rd_data_o( ramb_rddata )
);
reg [6:0] ramb_id;

reg ram_sel;

assign rama_wraddr = draw_wraddr;
assign ramb_wraddr = draw_wraddr;

assign rama_wrdata = draw_wrdata;
assign ramb_wrdata = draw_wrdata;

assign rama_we = !ram_sel && draw_we && draw_ready;
assign ramb_we = ram_sel && draw_we && draw_ready;

assign rama_rdaddr = !ram_sel ? draw_rdaddr : display_rdaddr;
assign ramb_rdaddr = ram_sel ? draw_rdaddr : display_rdaddr;

assign draw_rddata = !ram_sel ? rama_rddata : ramb_rddata;
assign display_rddata = ram_sel ? rama_rddata : ramb_rddata;

assign display_id = ram_sel ? rama_id : ramb_id;

// RAM selector logic
reg [1:0] sel_state;

always@(posedge clk)
begin
  if(draw_next)
  begin
    if(ram_sel)
      ramb_id <= draw_id;
    else
      rama_id <= draw_id;
  end
end

reg frameblock_id[6:0];

always@(posedge clk or posedge rst)
begin
  if(rst)
  begin
    sel_state <= 2'h2;
    ram_sel <= 1'h0;
  end
  else
  begin
    case(sel_state)
      2'h0: begin // ram_sel stable
        sel_state <= {display_next, draw_next};
      end
      2'h1: begin // wait for display
        sel_state <= {display_next, 1'h1};
      end
      2'h2: begin // wait for draw
        sel_state <= {1'h1, draw_next};
      end
      default: begin // switch
        sel_state <= 2'h0;
        ram_sel <= ~ram_sel;
      end
    endcase
  end
end

assign {display_ready, draw_ready} = ~sel_state;
        

endmodule