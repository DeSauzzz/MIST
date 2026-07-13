module mist_gpr(
  input  logic        clk_i,

  input  logic        wr_en1_i,
  input  logic        wr_en2_i,

  input  logic [4:0]  wr_addr1_i,
  input  logic [4:0]  wr_addr2_i,

  input  logic [4:0]  rd_addr1_i,
  input  logic [4:0]  rd_addr2_i,

  input  logic [31:0] wr_data1_i,
  input  logic [31:0] wr_data2_i,

  output logic [31:0] rd_data1_o,
  output logic [31:0] rd_data2_o
);

  logic [31:0] rf_mem [32];
  initial      rf_mem [0] = 32'd0;

  always_ff @( posedge clk_i ) begin
    if( ( wr_en1_i ) && ( wr_addr1_i != 5'd0 ) )
      rf_mem[wr_addr1_i] <= wr_data1_i;
    if( ( wr_en2_i ) && ( wr_addr2_i != 5'd0 ) )
      rf_mem[wr_addr2_i] <= wr_data2_i;
  end

  assign rd_data1_o = rf_mem[rd_addr1_i];
  assign rd_data2_o = rf_mem[rd_addr2_i];

endmodule
