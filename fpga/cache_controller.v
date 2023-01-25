module cache_controller (
  input clk,
  input rst,
  input [11:0] u, // Currently using the same interface for both read and write, but may make separate write address.
  input [11:0] v,
  input read,
  input [63:0] data_in,
  input write,
  output accept,
  output [15:0] pixel_out,
  output pixel_ready,
  output [19:0] mem_addr,
  output mem_read,
  output mem_write,
  input mem_ready,
  input [31:0] mem_rddata,
  output [63:0] mem_wrdata
);

wire [23:0] addr = {
  v[11], u[11], v[10], u[10], v[9], u[9], v[8], u[8],
  v[7], u[7], v[6], u[6], v[5], u[5], v[4], u[4],
  v[3], u[3], v[2], u[2], v[1], v[0], u[1], u[0]
};
reg [7:0] tag;
reg [11:0] index;
reg [3:0] offset;

reg [63:0] data_in_buf;
assign mem_wrdata = data_in_buf;

wire [13:0] cache_addr;
wire [31:0] cache_wrdata;
wire [31:0] cache_rddata;
wire cache_we;

SP256K cache_ram_a (
  .AD       (cache_addr),  // I
  .DI       (cache_wrdata[15:0]),  // I
  .MASKWE   (4'b1111),  // I
  .WE       (cache_we),  // I
  .CS       (1'b1),  // I
  .CK       (clk),  // I
  .STDBY    (1'b0),  // I
  .SLEEP    (1'b0),  // I
  .PWROFF_N (1'b1),  // I
  .DO       (cache_rddata[15:0])   // O
);

SP256K cache_ram_b (
  .AD       (cache_addr),  // I
  .DI       (cache_wrdata[31:16]),  // I
  .MASKWE   (4'b1111),  // I
  .WE       (cache_we),  // I
  .CS       (1'b1),  // I
  .CK       (clk),  // I
  .STDBY    (1'b0),  // I
  .SLEEP    (1'b0),  // I
  .PWROFF_N (1'b1),  // I
  .DO       (cache_rddata[31:16])   // O
);

wire [13:0] tag_addr;
wire [15:0] tag_wrdata;
wire [15:0] tag_rddata;
wire [3:0] tag_maskwe;
wire tag_we;

SP256K tag_ram (
  .AD       (tag_addr),  // I
  .DI       (tag_wrdata),  // I
  .MASKWE   (tag_maskwe),  // I
  .WE       (tag_we),  // I
  .CS       (1'b1),  // I
  .CK       (clk ),  // I
  .STDBY    (1'b0),  // I
  .SLEEP    (1'b0),  // I
  .PWROFF_N (1'b1),  // I
  .DO       (tag_rddata)   // O
);

wire [11:0] lru_addr;
wire lru_wrdata;
wire lru_rddata_;
wire lru_rddata = (lru_rddata_ === 1); //Sanitization step for sim only. Use output directly for synthesis
wire lru_we;

lru_ram _lru_ram (
  .wr_clk_i(clk),
  .rd_clk_i(clk),
  .rst_i(rst),
  .wr_clk_en_i(1'b1),
  .rd_en_i(1'b1),
  .rd_clk_en_i(1'b1),
  .wr_en_i(lru_we),
  .wr_data_i(lru_wrdata),
  .wr_addr_i(lru_addr),
  .rd_addr_i(lru_addr),
  .rd_data_o(lru_rddata_)
);

reg pulse = 0;

always@(posedge clk)
begin
  pulse = ~pulse;
end

reg miss_state;
reg read_state;
reg write_state;
reg mem_count;

assign tag_addr = {2'h0, index};
wire [7:0] tag_a = tag_rddata[7:0];
wire [7:0] tag_b = tag_rddata[15:8];
wire match_a = (tag_a === tag); //Sim: ===, Synth: ==
wire match_b = (tag_b === tag); //Sim: ===, Synth: ==
wire tag_match = match_a | match_b | rst;
assign accept = (read | write) & pulse & !miss_state & !write_state & (!read_state | tag_match);
assign tag_wrdata = {tag, tag};
assign tag_we = (miss_state | write_state) & !tag_match & pulse;
assign tag_maskwe = {lru_rddata, lru_rddata, !lru_rddata, !lru_rddata};
reg [1:0] write_buf;
assign lru_addr = index;
assign lru_wrdata = !match_b;
assign lru_we = accept; // TODO: Investigate if this works well with a) reset, b) waits between requests.
assign mem_addr = {index, tag};
assign mem_read = !tag_match & miss_state & pulse;
assign mem_write = write_buf[1];
assign cache_addr = {match_b, index, mem_count};
assign cache_wrdata = mem_rddata;
assign cache_we = mem_ready;

always@(posedge clk)
begin
  if(rst)
  begin
    tag <= 8'h00;
    index <= 12'h000;
    offset <= 4'h0;
  end    
  else if(accept)
  begin
    tag <= addr[23:16];
    index <= addr[16:4];
    offset <= addr[3:0];
  end
end

always@(posedge clk)
begin
  if(accept)
  begin
    data_in_buf <= data_in;
  end
end

always@(posedge clk)
begin
  if(rst)
    write_buf <= 0;
  else
    write_buf <= {write_buf[0], write & accept};
end

always@(posedge clk)
begin
  if(rst)
  begin
    write_state <= 0;
  end
  else if(accept)
  begin
    write_state <= write;
  end
  else if(mem_count & mem_ready)
  begin
    write_state <= 0;
  end
end

always@(posedge clk)
begin
  if(rst)
  begin
    miss_state <= 0;
  end
  else if(pulse & read_state & !tag_match)
  begin
    miss_state <= 1;
  end
  else if(mem_count & mem_ready)
  begin
    miss_state <= 0;
  end
end

always@(posedge clk)
begin
  if(rst)
  begin
    read_state <= 0;
  end
  else if(accept)
  begin
    read_state <= read;
  end
  else if(tag_match & pulse)
  begin
    read_state <= 0;
  end
end

always@(posedge clk)
begin
  if(rst)
    mem_count <= 0;
  else
    mem_count <= mem_count ^ mem_ready;
end

endmodule