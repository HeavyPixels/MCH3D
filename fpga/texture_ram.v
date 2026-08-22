module texture_ram (
  input clk,
  input rst,
  input [11:0] u,
  input [11:0] v,
  output [15:0] pixel_out,
  input [13:0] write_addr,
  input [15:0] write_data,
  input write
);

wire [13:0] read_addr = {v[6:0], u[6:0]};
wire [13:0] mem_addr = write ? write_addr : read_addr;

SP256K texture_mem (
  .AD       (mem_addr),  // I
  .DI       (write_data),  // I
  .MASKWE   (4'b1111),  // I
  .WE       (write),  // I
  .CS       (1'b1),  // I
  .CK       (clk),  // I
  .STDBY    (1'b0),  // I
  .SLEEP    (1'b0),  // I
  .PWROFF_N (1'b1),  // I
  .DO       (pixel_out[15:0])   // O
);

endmodule
