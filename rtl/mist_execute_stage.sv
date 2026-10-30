module mist_execute_stage(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From decode stage
  input  logic [31:0] imm_b_d_i,
  input  logic [31:0] imm_j_d_i,

  input  logic [31:0] op_a_d_i,
  input  logic [31:0] op_b_d_i,

  input  logic [4:0]  gpr_rs1_addr_d_i,
  input  logic [4:0]  gpr_rs2_addr_d_i,
  input  logic [4:0]  gpr_wa_d_i,
  input  logic        gpr_we_d_i,

  input  logic        ill_instr_d_i,
  input  logic        use_rs1_d_i,
  input  logic        use_rs2_d_i,

  input  logic [2:0]  csr_op_d_i,
  input  logic        csr_we_d_i,

  input  logic        branch_d_i,
  input  logic        jalr_d_i,
  input  logic        jal_d_i,

  input  logic        lsu_req_d_i,
  input  logic        lsu_we_d_i,
  input  logic [2:0]  lsu_size_d_i,
  input  logic [31:0] lsu_wd_d_i,

  input  logic [3:0]  alu_op_d_i,

  input  logic        mret_d_i,
  input  logic [1:0]  wb_sel_d_i,

  input  logic [31:0] pc_cur_d_i,

  // From Hazard unit
  input  logic        hu_stall_e_i,
  input  logic        hu_flush_e_i,

  input  logic        hu_solver_m_e_i,
  input  logic [1:0]  hu_solver_lsu_e_i,
  input  logic        hu_op_byp_m_e_i,
  input  logic [31:0] hu_data_byp_m_e_i,

  input  logic        hu_solver_wb_e_i,
  input  logic        hu_op_byp_wb_e_i,
  input  logic [31:0] hu_data_byp_wb_e_i,

  // To Hazard Unit
  output logic [4:0]  hu_rs1_e_o,
  output logic [4:0]  hu_rs2_e_o,

  output logic        hu_flush_req_e_o,

  output logic        hu_mem_req_e_o,
  output logic        hu_mem_we_e_o,

  output logic        hu_use_rs1_e_o,
  output logic        hu_use_rs2_e_o,

  // To fetch stage
  output logic        alu_flag_e_o,
  output logic        branch_e_o,
  output logic        jalr_e_o,
  output logic        jal_e_o,
  output logic [31:0] offset_pc_e_o,

  // To memory stage
  output logic [31:0] alu_result_e_o,

  output logic [4:0]  gpr_wa_e_o,
  output logic        gpr_we_e_o,

  output logic        ill_instr_e_o,

  output logic [2:0]  csr_op_e_o,
  output logic        csr_we_e_o,

  output logic        lsu_req_e_o,
  output logic        lsu_we_e_o,
  output logic [2:0]  lsu_size_e_o,
  output logic [31:0] lsu_wd_e_o,

  output logic        mret_e_o,
  output logic [1:0]  wb_sel_e_o
);

  // Choosing lsu_wd logic
  logic [31:0] lsu_wd;

  assign lsu_wd = ( hu_solver_lsu_e_i[0] ) ? ( hu_data_byp_m_e_i  ):
                  ( hu_solver_lsu_e_i[1] ) ? ( hu_data_byp_wb_e_i ):
                                             ( lsu_wd_d_i         );

  // ALU logic
  logic [31:0] op_a;
  logic [31:0] op_b;

  logic [31:0] alu_result;
  logic        alu_flag;

  assign op_a = ( ( hu_solver_m_e_i  ) && !( hu_op_byp_m_e_i  ) ) ? ( hu_data_byp_m_e_i  ):
                ( ( hu_solver_wb_e_i ) && !( hu_op_byp_wb_e_i ) ) ? ( hu_data_byp_wb_e_i ):
                                                                    ( op_a_d_i           );
  assign op_b = ( ( hu_solver_m_e_i  ) &&  ( hu_op_byp_m_e_i  ) ) ? ( hu_data_byp_m_e_i  ):
                ( ( hu_solver_wb_e_i ) &&  ( hu_op_byp_wb_e_i ) ) ? ( hu_data_byp_wb_e_i ):
                                                                    ( op_b_d_i           );

  mist_alu e_alu(
    .op_a_i   ( op_a       ),
    .op_b_i   ( op_b       ),
    .alu_op_i ( alu_op_d_i ),

    .flag_o   ( alu_flag   ),
    .result_o ( alu_result )
  );

  // Offset generator
  logic [31:0] offset_pc;

  assign offset_pc = ( branch_d_i ) ? ( pc_cur_d_i + imm_b_d_i     ):
                     ( jal_d_i    ) ? ( pc_cur_d_i + imm_j_d_i     ):
                     ( jalr_d_i   ) ? ( { alu_result[31:1], 1'd0 } ):
                                      ( 32'd0                      );

  assign offset_pc_e_o = offset_pc;
  assign branch_e_o    = branch_d_i;
  assign jalr_e_o      = jalr_d_i;
  assign jal_e_o       = jal_d_i;
  assign alu_flag_e_o  = alu_flag;

  // To Hazard Unit
  logic hu_flush_req;

  always_comb begin
    hu_flush_req = 1'd0;
    if( ( jalr_d_i ) || ( jal_d_i ) )
      hu_flush_req = 1'd1;
    else if( ( branch_d_i ) && ( alu_flag ) )
      hu_flush_req = 1'd1;
  end

  assign hu_rs1_e_o       = gpr_rs1_addr_d_i;
  assign hu_rs2_e_o       = gpr_rs2_addr_d_i;

  assign hu_flush_req_e_o = hu_flush_req;

  assign hu_mem_req_e_o   = lsu_req_d_i;
  assign hu_mem_we_e_o    = lsu_we_d_i;

  assign hu_use_rs1_e_o   = use_rs1_d_i;
  assign hu_use_rs2_e_o   = use_rs2_d_i;

  // To memory stage
  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      alu_result_e_o    <= 32'd0;
      gpr_wa_e_o        <= 5'd0;
      ill_instr_e_o     <= 1'd0;
      csr_op_e_o        <= 3'd0;
      csr_we_e_o        <= 1'd0;
      lsu_req_e_o       <= 1'd0;
      lsu_we_e_o        <= 1'd0;
      lsu_size_e_o      <= 3'd0;
      lsu_wd_e_o        <= 32'd0;
      gpr_we_e_o        <= 1'd0;
      mret_e_o          <= 1'd0;
      wb_sel_e_o        <= 2'd0;
    end
    else if( ( hu_flush_e_i ) && !( hu_stall_e_i ) ) begin
      alu_result_e_o    <= 32'd0;
      gpr_wa_e_o        <= 5'd0;
      ill_instr_e_o     <= 1'd0;
      csr_op_e_o        <= 3'd0;
      csr_we_e_o        <= 1'd0;
      lsu_req_e_o       <= 1'd0;
      lsu_we_e_o        <= 1'd0;
      lsu_size_e_o      <= 3'd0;
      lsu_wd_e_o        <= 32'd0;
      gpr_we_e_o        <= 1'd0;
      mret_e_o          <= 1'd0;
      wb_sel_e_o        <= 2'd0;
    end
    else if( !hu_stall_e_i ) begin
      alu_result_e_o    <= alu_result;
      gpr_wa_e_o        <= gpr_wa_d_i;
      ill_instr_e_o     <= ill_instr_d_i;
      csr_op_e_o        <= csr_op_d_i;
      csr_we_e_o        <= csr_we_d_i;
      lsu_req_e_o       <= lsu_req_d_i;
      lsu_we_e_o        <= lsu_we_d_i;
      lsu_size_e_o      <= lsu_size_d_i;
      lsu_wd_e_o        <= lsu_wd;
      gpr_we_e_o        <= gpr_we_d_i;
      mret_e_o          <= mret_d_i;
      wb_sel_e_o        <= wb_sel_d_i;
    end
  end

endmodule
