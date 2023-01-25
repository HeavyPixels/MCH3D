module mem_controller (
  input clk,
  input clk2,
  input rst,
  
  input [19:0] mem_addr,
  input mem_read,
  input mem_write,
  output mem_ready,
  output [31:0] mem_rddata,
  input [63:0] mem_wrdata,
  
  output ram_clk,
  output ram_cs_n,
  inout [3:0] ram_io
);

// Phy

assign ram_clk = !ram_cs_n ? ~clk2 : 1'h0;
wire ram_we;
reg [3:0] ram_o;
assign ram_io = ram_we ? ram_o : 4'hz;

// Control to Phy
reg [7:0] more_ctrl;
reg cs_ctrl;
reg rd_ctrl;
reg wr_ctrl;
reg more_phy;
reg more_flip = 0;
reg more_edge;
reg more_ret;
reg cs_phy;
reg rd_phy;
reg rd_phy_buf;
reg rd_flip = 0;
reg rd_edge;
reg rd_ret;
reg rd_out;
reg wr_phy;

//reg idle;
//reg idle_detect;
//reg idle_ret;

reg start;
reg [31:0] wrbuf_ctrl;
reg [7:0] wrbuf_phy [0:6];
reg [3:0] rdbuf_phy [0:7];
reg [31:0] rdbuf_buf;
reg [31:0] rdbuf_ctrl;

assign ram_cs_n = !cs_phy;
assign ram_we = wr_phy;

assign mem_ready = rd_out;
assign mem_rddata = rdbuf_ctrl;

always@(posedge clk2)
begin
  rdbuf_phy[7] <= rdbuf_phy[6];
  rdbuf_phy[6] <= rdbuf_phy[5];
  rdbuf_phy[5] <= rdbuf_phy[4];
  rdbuf_phy[4] <= rdbuf_phy[3];
  rdbuf_phy[3] <= rdbuf_phy[2];
  rdbuf_phy[2] <= rdbuf_phy[1];
  rdbuf_phy[1] <= rdbuf_phy[0];
  rdbuf_phy[0] <= ram_io;
end

always@(posedge clk2)
begin
  if(rst)
  begin
    {more_phy, cs_phy, rd_phy, wr_phy, ram_o} <= 8'h00;
    wrbuf_phy[6] <= 8'h00;
    wrbuf_phy[5] <= 8'h00;
    wrbuf_phy[4] <= 8'h00;
    wrbuf_phy[3] <= 8'h00;
    wrbuf_phy[2] <= 8'h00;
    wrbuf_phy[1] <= 8'h00;
    wrbuf_phy[0] <= 8'h00;
  end
  else if((start & !cs_phy) | more_phy)
  begin    
    {more_phy, cs_phy, rd_phy, wr_phy, ram_o}
                  <= {more_ctrl[7], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[31:28]};
    wrbuf_phy[6]  <= {more_ctrl[6], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[27:24]};
    wrbuf_phy[5]  <= {more_ctrl[5], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[23:20]};
    wrbuf_phy[4]  <= {more_ctrl[4], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[19:16]};
    wrbuf_phy[3]  <= {more_ctrl[3], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[15:12]};
    wrbuf_phy[2]  <= {more_ctrl[2], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[11:8]};
    wrbuf_phy[1]  <= {more_ctrl[1], cs_ctrl,    1'h0, wr_ctrl, wrbuf_ctrl[7:4]};
    wrbuf_phy[0]  <= {more_ctrl[0], cs_ctrl, rd_ctrl, wr_ctrl, wrbuf_ctrl[3:0]};
  end
  else
  begin
    {more_phy, cs_phy, rd_phy, wr_phy, ram_o} <= wrbuf_phy[6];
    wrbuf_phy[6] <= wrbuf_phy[5];
    wrbuf_phy[5] <= wrbuf_phy[4];
    wrbuf_phy[4] <= wrbuf_phy[3];
    wrbuf_phy[3] <= wrbuf_phy[2];
    wrbuf_phy[2] <= wrbuf_phy[1];
    wrbuf_phy[1] <= wrbuf_phy[0];
    wrbuf_phy[0] <= 8'h0;
  end
end

// Additional logic for Phy -> Ctrl clock domain crossing
always@(posedge clk2)
begin
  rd_phy_buf <= rd_phy;
  if(more_phy) more_flip <= ~more_flip;
  if(rd_phy) rd_flip <= ~rd_flip;
end

always@(posedge clk)
begin
  more_edge <= more_flip;
  more_ret <= more_edge != more_flip;
  
  rd_edge <= rd_flip;
  rd_ret <= rd_edge != rd_flip;
end

always@(posedge clk2)
begin
  if(rd_phy_buf)
  begin
    rdbuf_buf <= {rdbuf_phy[7], rdbuf_phy[6], rdbuf_phy[5], rdbuf_phy[4], rdbuf_phy[3], rdbuf_phy[2], rdbuf_phy[1], rdbuf_phy[0]};
  end
end

always@(posedge clk)
begin
  rd_out <= rd_ret;
  if(rd_ret)
  begin
    rdbuf_ctrl <= rdbuf_buf;
  end
end

// Control

// Init routine:
// - Wait, with CLK low, /CS high, IO low, for 150us.
// - Reset Enable, /CS low, command 'h66 in SPI mode.
// - CLK low, /CS high for at least one cycle
// - Reset command, /CS low, command 'h99 in SPI mode.
// - CLK low, /CS high for at least one cycle
// - Quad Mode Enable, /CS low, command 'h35 in SPI mode.
// Read routine:
// - Read command 'h0B
// - Read address, 3 bytes, 6 nibbles.
// - Read wait, 5 clk2 cycles. NOTE: this offsets read by 1/2 clk cycle!
// - Read data, 8 bytes, 16 nibbles.
// Write routine:
// - Write command 'h38
// - Write address, 3 bytes, 6 nibbles.
// - Write data, 8 bytes, 16 nibbles.

reg [3:0] state;

reg [19:0] addr_buf;
reg [63:0] wrdata_buf;

reg [13:0] init_counter;
wire init_ready = init_counter[13];
always@(posedge clk)
begin
  if(rst)
  begin
    init_counter = 0;
  end
  else if(!init_ready)
  begin
    init_counter <= init_counter + 14'h0001;
  end
end

always@(posedge clk)
begin
  if(rst)
  begin
    state <= 0;
  end
  else
  begin
    case(state)
      'h0: // Init wait
      begin
        if(init_ready) state <= 'h1;
      end
      'h1: // Reset Enable command
      begin
        state <= 'h2;
      end
      'h2: // CS high
      begin
        if(more_ret) state <= 'h3;
        else         state <= 'h2;
      end
      'h3: // Reset command
      begin
        if(more_ret) state <= 'h4;
        else         state <= 'h3;
      end
      'h4: // CS high
      begin
        if(more_ret) state <= 'h5;
        else         state <= 'h4;
      end
      'h5: // Quad Mode Enable command
      begin
        if(more_ret) state <= 'hF;
        else         state <= 'h5;
      end
      'hF: // CS high
      begin
        if(more_ret) state <= 'h6;
        else         state <= 'hF;
      end
      'h6: // Idle
      begin
        if(mem_read) state <= 'h7;
        else if(mem_write) state <= 'hB;
        else state <= 'h6;
        addr_buf <= mem_addr;
        wrdata_buf <= mem_wrdata;
      end
      'h7: // Read command
      begin
        state <= 'h8;
      end
      'h8: // Read wait
      begin
        if(more_ret) state <= 'h9;
        else         state <= 'h8;
      end
      'h9: // Read data 1
      begin
        if(more_ret) state <= 'hA;
        else         state <= 'h9;
      end
      'hA: // Read data 2
      begin
        if(more_ret) state <= 'hF;
        else         state <= 'hA;
      end
      'hB: // Write command
      begin
        state <= 'hC;
      end
      'hC: // Write data 1
      begin
        if(more_ret) state <= 'hD;
        else         state <= 'hC;
      end
      'hD: // Write data 2
      begin
        if(more_ret) state <= 'hF;
        else         state <= 'hD;
      end
      default: // Idle
      begin
        state <= 'h04;
      end    
    endcase
  end
end

always@*
begin
  case(state)
    'h0: // Init wait
    begin
      more_ctrl = 8'h00;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h1: // Reset Enable command
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = 32'h01100110;
      start = 1;
    end
    'h2: // CS high
    begin
      more_ctrl = 8'h10;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h3: // Reset command
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = 32'h10011001;
      start = 0;
    end
    'h4: // CS high
    begin
      more_ctrl = 8'h10;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h5: // Quad Mode Enable command
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = 32'h00110101;
      start = 0;
    end
    'hF: // CS high
    begin
      more_ctrl = 8'h00;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h6: // Idle
    begin
      more_ctrl = 8'h00;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h7: // Read command
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = {8'h0B, addr_buf, 4'h0};
      start = 1;
    end
    'h8: // Read wait
    begin
      more_ctrl = 8'h08;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'h9: // Read data 1
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h01;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'hA: // Read data 2
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h01;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end
    'hB: // Write command
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = {8'h38, addr_buf, 4'h0};
      start = 1;
    end
    'hC: // Write data 1
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h01;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = wrdata_buf[63:32];
      start = 0;
    end
    'hD: // Write data 2
    begin
      more_ctrl = 8'h01;
      cs_ctrl = 8'hFF;
      rd_ctrl = 8'h01;
      wr_ctrl = 8'hFF;
      wrbuf_ctrl = wrdata_buf[31:0];
      start = 0;
    end
    default: // Idle
    begin
      more_ctrl = 8'h00;
      cs_ctrl = 8'h00;
      rd_ctrl = 8'h00;
      wr_ctrl = 8'h00;
      wrbuf_ctrl = 32'h00000000;
      start = 0;
    end    
  endcase
end

endmodule