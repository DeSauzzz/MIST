module mist_gpr(
  input  logic        clk_i,

  input  logic        hu_solver_i,
  input  logic        hu_op1_byp_i,
  input  logic        hu_op2_byp_i,

  input  logic        wr_en_i,

  input  logic [4:0]  wr_addr_i,

  input  logic [4:0]  rd_addr1_i,
  input  logic [4:0]  rd_addr2_i,

  input  logic [31:0] wr_data_i,

  output logic [31:0] rd_data1_o,
  output logic [31:0] rd_data2_o
);

  logic [31:0] rf_mem [32];
  initial      rf_mem [0] = 32'd0;

  always_ff @( posedge clk_i ) begin
    if( ( wr_en_i ) && ( wr_addr_i != 5'd0 ) )
      rf_mem[wr_addr_i] <= wr_data_i;
  end

  assign rd_data1_o = ( ( hu_solver_i ) && ( hu_op1_byp_i ) ) ? ( wr_data_i ) : ( rf_mem[rd_addr1_i] );
  assign rd_data2_o = ( ( hu_solver_i ) && ( hu_op2_byp_i ) ) ? ( wr_data_i ) : ( rf_mem[rd_addr2_i] );

endmodule
