module mist_fetch_stage #(
  parameter INIT_IMEM = ""
)(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From Write-back stage
  input  logic        jalr_wb_i,
  input  logic        branch_jal_wb_i,
  input  logic [31:0] offset_pc_wb_i,
  input  logic [31:0] offset_alu_wb_i,

  // From Hazard Unit
  input  logic        hu_stall_f_i,
  input  logic        hu_flush_f_i,

  // To Hazard Unit
  output logic [4:0]  pd_rs1_addr_f_o,
  output logic [4:0]  pd_rs2_addr_f_o,

  // To Decode Stage
  output logic [31:0] instr_f_o,
  output logic [6:0]  pd_opcode_f_o,   // Also going to hazard unit
  output logic [31:0] pc_cur_f_o
);

  logic [31:0] instr_cur;

  logic [31:0] pc_cur;
  logic [31:0] pc_nxt;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      pc_cur <= 32'd0;
    else if( !hu_stall_f_i )
      pc_cur <= pc_nxt;
  end

  assign pc_nxt = ( jalr_wb_i       ) ? ( pc_cur + offset_alu_wb_i ):
                  ( branch_jal_wb_i ) ? ( pc_cur + offset_pc_wb_i  ):
                                        ( pc_cur + 32'd4           );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      instr_f_o  <= 32'd0;
      pc_cur_f_o <= 32'd0;
    end
    else if( hu_flush_f_i ) begin
      instr_f_o  <= 32'd0;
      pc_cur_f_o <= 32'd0;
    end
    else if( !hu_stall_f_i ) begin
      instr_f_o  <= instr_cur;
      pc_cur_f_o <= pc_cur;
    end
  end

  mist_instr_mem #(
    .INIT_IMEM(INIT_IMEM)
  ) f_imem (
    .read_addr_i ( pc_cur          ),
    .read_data_o ( instr_cur       )
  );

  mist_predecode f_predecode (
    .pd_instr_i  ( { instr_cur[6:0], instr_cur[24:15] } ),
    .rs1_addr_o  ( pd_rs1_addr_f_o ),
    .rs2_addr_o  ( pd_rs2_addr_f_o ),
    .opcode_o    ( pd_opcode_f_o   )
  );

endmodule
