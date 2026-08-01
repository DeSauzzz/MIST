import mist_decoder_pkg::EXEC_WB_RESULT;
import mist_decoder_pkg::LSU_WB_DATA;
import mist_decoder_pkg::CSR_WB_DATA;

module mist_core(
  input logic clk_i,
  input logic rstn_i
);

  localparam f = 3'd0; // fetch
  localparam d = 3'd1; // decode
  localparam e = 3'd2; // execute
  localparam m = 3'd3; // memory
  localparam w = 3'd4; // writeback

  logic        hu_stall_req      [f:m];
  logic        hu_flush_req      [f:m];

  logic        hu_stall          [f:m];
  logic        hu_flush          [f:m];

  logic [31:0] hu_frw_result     [e:m];
  logic [31:0] hu_op_a           [e:e];
  logic [31:0] hu_op_b           [e:e];

  logic [4:0]  hu_rs1_addr       [f:e];
  logic [4:0]  hu_rs2_addr       [f:e];
  logic [4:0]  hu_rd_addr        [e:m];

  logic        hu_raw_solve      [d:d];
  logic        hu_raw_solve_op_a [e:e];
  logic        hu_raw_solve_op_b [e:e];

  logic [31:0] hu_gpr_wd         [d:d];
  logic [4:0]  hu_gpr_wa         [d:d];
  logic        hu_gpr_we         [d:d];

  logic        mret              [d:e];

  logic        ill_instr         [d:e];
  logic [6:0]  pd_opcode          [f:m];
  logic [31:0] instr             [f:f];
  logic [31:0] pc_cur            [f:d];

  logic        branch            [d:e];
  logic        jalr              [d:e];
  logic        jal               [d:e];

  logic [31:0] offset_bj_pc      [e:e];
  logic [31:0] offset_jr_pc      [e:e];

  logic [31:0] imm_b             [d:d];
  logic [31:0] imm_j             [d:d];

  logic [31:0] alu_result        [e:w];
  logic [3:0]  alu_op            [d:d];
  logic        alu_flag          [e:e];

  logic [31:0] op_a              [d:d];
  logic [31:0] op_b              [d:d];

  logic [2:0]  csr_op            [d:e];
  logic        csr_we            [d:e];

  logic [31:0] gpr_wd            [w:w];
  logic [4:0]  gpr_wa            [d:w];
  logic        gpr_we            [d:w];
  logic [4:0]  gpr_rs1_addr      [d:d];
  logic [4:0]  gpr_rs2_addr      [d:d];

  logic [31:0] lsu_rd            [m:w];
  logic [31:0] lsu_wd            [d:e];
  logic [2:0]  lsu_size          [d:e];
  logic        lsu_req           [d:e];
  logic        lsu_we            [d:e];

  logic [3:0]  mem_be            [m:m];
  logic        mem_req           [m:m];
  logic        mem_we            [m:m];
  logic [31:0] mem_addr          [m:m];
  logic [31:0] mem_wd            [m:m];
  logic [31:0] mem_rd            [m:m];
  logic        mem_ack           [m:m];

  logic [1:0]  wb_sel            [d:w];

  /////////////////////
  // Writeback stage //
  /////////////////////

  assign alu_result[w]  = alu_result[m];

  assign gpr_wa    [w]  = gpr_wa    [m];
  assign gpr_we    [w]  = gpr_we    [m];

  assign lsu_rd    [w]  = lsu_rd    [m];

  assign wb_sel    [w]  = wb_sel    [m];

  always_comb begin
    case( wb_sel[w] )
      EXEC_WB_RESULT: gpr_wd[w] = alu_result[w];
      LSU_WB_DATA:    gpr_wd[w] = lsu_rd    [w];
      CSR_WB_DATA:    gpr_wd[w] = 32'd0;         // TODO: Fix when CSR appears
      default:        gpr_wd[w] = 32'd0;
    endcase
  end

  //////////////////////
  // Module instances //
  //////////////////////

  mist_fetch_stage #(
    .INIT_IMEM("program.mem")
  ) fetch_stage (
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From execute stage
    .alu_flag_e_i          ( alu_flag         [e] ),
    .branch_e_i            ( branch           [e] ),
    .jalr_e_i              ( jalr             [e] ),
    .jal_e_i               ( jal              [e] ),
    .offset_bj_pc_e_i      ( offset_bj_pc     [e] ),
    .offset_jr_pc_e_i      ( offset_jr_pc     [e] ),

    // From Hazard Unit
    .hu_stall_f_i          ( hu_stall         [f] ),
    .hu_flush_f_i          ( hu_flush         [f] ),

    // To Hazard Unit
    .hu_rs1_addr_f_o       ( hu_rs1_addr      [f] ),
    .hu_rs2_addr_f_o       ( hu_rs2_addr      [f] ),

    // To Decode Stage
    .instr_f_o             ( instr            [f] ),
    .pd_opcode_f_o         ( pd_opcode        [f] ),
    .pc_cur_f_o            ( pc_cur           [f] )
  );

  mist_decode_stage decode_stage(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From fetch stage
    .instr_f_i             ( instr            [f] ),
    .pd_opcode_f_i         ( pd_opcode        [f] ),
    .pc_cur_f_i            ( pc_cur           [f] ),

    // From wb stage
    .gpr_wa_wb_i           ( gpr_wa           [w] ),
    .gpr_wd_wb_i           ( gpr_wd           [w] ),
    .gpr_we_wb_i           ( gpr_we           [w] ),

    // From Hazard Unit
    .hu_gpr_wd_d_i         ( hu_gpr_wd        [d] ),
    .hu_gpr_wa_d_i         ( hu_gpr_wa        [d] ),
    .hu_gpr_we_d_i         ( hu_gpr_we        [d] ),
    .hu_raw_solve_d_i      ( hu_raw_solve     [d] ),

    .hu_stall_d_i          ( hu_stall         [d] ),
    .hu_flush_d_i          ( hu_flush         [d] ),

    // To Hazard Unit
    .hu_rs1_addr_d_o       ( hu_rs1_addr      [d] ),
    .hu_rs2_addr_d_o       ( hu_rs2_addr      [d] ),

    // To execute stage
    .imm_b_d_o             ( imm_b            [d] ),
    .imm_j_d_o             ( imm_j            [d] ),

    .op_a_d_o              ( op_a             [d] ),
    .op_b_d_o              ( op_b             [d] ),

    .gpr_rs1_addr_d_o      ( gpr_rs1_addr     [d] ),
    .gpr_rs2_addr_d_o      ( gpr_rs2_addr     [d] ),
    .gpr_wa_d_o            ( gpr_wa           [d] ),
    .gpr_we_d_o            ( gpr_we           [d] ),

    .ill_instr_d_o         ( ill_instr        [d] ),
    .pd_opcode_d_o         ( pd_opcode        [d] ),

    .csr_op_d_o            ( csr_op           [d] ),
    .csr_we_d_o            ( csr_we           [d] ),

    .branch_d_o            ( branch           [d] ),
    .jalr_d_o              ( jalr             [d] ),
    .jal_d_o               ( jal              [d] ),

    .lsu_req_d_o           ( lsu_req          [d] ),
    .lsu_we_d_o            ( lsu_we           [d] ),
    .lsu_size_d_o          ( lsu_size         [d] ),
    .lsu_wd_d_o            ( lsu_wd           [d] ),

    .alu_op_d_o            ( alu_op           [d] ),

    .mret_d_o              ( mret             [d] ),
    .wb_sel_d_o            ( wb_sel           [d] ),

    .pc_cur_d_o            ( pc_cur           [d] )
  );

  mist_execute_stage execute_stage(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From decode stage
    .imm_b_d_i             ( imm_b            [d] ),
    .imm_j_d_i             ( imm_j            [d] ),

    .op_a_d_i              ( op_a             [d] ),
    .op_b_d_i              ( op_b             [d] ),

    .gpr_rs1_addr_d_i      ( gpr_rs1_addr     [d] ),
    .gpr_rs2_addr_d_i      ( gpr_rs2_addr     [d] ),
    .gpr_wa_d_i            ( gpr_wa           [d] ),
    .gpr_we_d_i            ( gpr_we           [d] ),

    .ill_instr_d_i         ( ill_instr        [d] ),
    .pd_opcode_d_i         ( pd_opcode        [d] ),

    .csr_op_d_i            ( csr_op           [d] ),
    .csr_we_d_i            ( csr_we           [d] ),

    .branch_d_i            ( branch           [d] ),
    .jalr_d_i              ( jalr             [d] ),
    .jal_d_i               ( jal              [d] ),

    .lsu_req_d_i           ( lsu_req          [d] ),
    .lsu_we_d_i            ( lsu_we           [d] ),
    .lsu_size_d_i          ( lsu_size         [d] ),
    .lsu_wd_d_i            ( lsu_wd           [d] ),

    .alu_op_d_i            ( alu_op           [d] ),

    .mret_d_i              ( mret             [d] ),
    .wb_sel_d_i            ( wb_sel           [d] ),

    .pc_cur_d_i            ( pc_cur           [d] ),

    // From Hazard unit
    .hu_stall_e_i          ( hu_stall         [e] ),
    .hu_flush_e_i          ( hu_flush         [e] ),

    .hu_raw_solve_op_a_e_i ( hu_raw_solve_op_a[e] ),
    .hu_raw_solve_op_b_e_i ( hu_raw_solve_op_b[e] ),

    .hu_frw_op_a_i         ( hu_op_a          [e] ),
    .hu_frw_op_b_i         ( hu_op_b          [e] ),

    // To Hazard Unit
    .hu_rs1_addr_e_o       ( hu_rs1_addr      [e] ),
    .hu_rs2_addr_e_o       ( hu_rs2_addr      [e] ),
    .hu_flush_req_e_o      ( hu_flush_req     [e] ),
    .hu_rd_addr_e_o        ( hu_rd_addr       [e] ),
    .hu_frw_result_e_o     ( hu_frw_result    [e] ),

    // To fetch stage
    .alu_flag_e_o          ( alu_flag         [e] ),
    .branch_e_o            ( branch           [e] ),
    .jalr_e_o              ( jalr             [e] ),
    .jal_e_o               ( jal              [e] ),
    .offset_bj_pc_e_o      ( offset_bj_pc     [e] ),
    .offset_jr_pc_e_o      ( offset_jr_pc     [e] ),

    // To memory stage
    .alu_result_e_o        ( alu_result       [e] ),

    .gpr_wa_e_o            ( gpr_wa           [e] ),
    .gpr_we_e_o            ( gpr_we           [e] ),

    .ill_instr_e_o         ( ill_instr        [e] ),
    .pd_opcode_e_o         ( pd_opcode        [e] ),

    .csr_op_e_o            ( csr_op           [e] ),
    .csr_we_e_o            ( csr_we           [e] ),

    .lsu_req_e_o           ( lsu_req          [e] ),
    .lsu_we_e_o            ( lsu_we           [e] ),
    .lsu_size_e_o          ( lsu_size         [e] ),
    .lsu_wd_e_o            ( lsu_wd           [e] ),

    .mret_e_o              ( mret             [e] ),
    .wb_sel_e_o            ( wb_sel           [e] )
  );

  mist_memory_stage memory_stage(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From execute stage
    .alu_result_e_i        ( alu_result       [e] ),

    .gpr_wa_e_i            ( gpr_wa           [e] ),
    .gpr_we_e_i            ( gpr_we           [e] ),

    .ill_instr_e_i         ( ill_instr        [e] ),
    .pd_opcode_e_i         ( pd_opcode        [e] ),

    .csr_op_e_i            ( csr_op           [e] ),
    .csr_we_e_i            ( csr_we           [e] ),

    .lsu_req_e_i           ( lsu_req          [e] ),
    .lsu_we_e_i            ( lsu_we           [e] ),
    .lsu_size_e_i          ( lsu_size         [e] ),
    .lsu_wd_e_i            ( lsu_wd           [e] ),

    .mret_e_i              ( mret             [e] ),
    .wb_sel_e_i            ( wb_sel           [e] ),

    // From Hazard unit
    .hu_stall_m_i          ( hu_stall         [m] ),
    .hu_flush_m_i          ( hu_flush         [m] ),

    // From data memory
    .mem_rd_m_i            ( mem_rd           [m] ),
    .mem_ack_m_i           ( mem_ack          [m] ),

    // To Hazard unit
    .hu_rd_addr_m_o        ( hu_rd_addr       [m] ),
    .hu_frw_res_m_o        ( hu_frw_result    [m] ),
    .hu_stall_req_m_o      ( hu_stall_req     [m] ),

    .pd_opcode_m_o         ( pd_opcode        [m] ),

    // To data memory
    .mem_be_m_o            ( mem_be           [m] ),
    .mem_addr_m_o          ( mem_addr         [m] ),
    .mem_req_m_o           ( mem_req          [m] ),
    .mem_we_m_o            ( mem_we           [m] ),
    .mem_wd_m_o            ( mem_wd           [m] ),

    // To writeback stage
    .lsu_rd_m_o            ( lsu_rd           [m] ),

    .alu_result_m_o        ( alu_result       [m] ),

    .gpr_wa_m_o            ( gpr_wa           [m] ),
    .gpr_we_m_o            ( gpr_we           [m] ),

    .wb_sel_m_o            ( wb_sel           [m] )
  );

  mist_hu hazard_unit(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From fetch stage
    .hu_rs1_addr_f_i       ( hu_rs1_addr      [f] ),
    .hu_rs2_addr_f_i       ( hu_rs2_addr      [f] ),
    .hu_opcode_f_i         ( pd_opcode        [f] ),

    // From decode stage
    .hu_rs1_addr_d_i       ( hu_rs1_addr      [d] ),
    .hu_rs2_addr_d_i       ( hu_rs2_addr      [d] ),
    .hu_opcode_d_i         ( pd_opcode        [d] ),

    // From execute stage
    .hu_rs1_addr_e_i       ( hu_rs1_addr      [e] ),
    .hu_rs2_addr_e_i       ( hu_rs2_addr      [e] ),
    .hu_rd_addr_e_i        ( hu_rd_addr       [e] ),
    .hu_frw_result_e_i     ( hu_frw_result    [e] ),
    .hu_opcode_e_i         ( pd_opcode        [e] ),

    // From memory stage
    .hu_rd_addr_m_i        ( hu_rd_addr       [m] ),
    .hu_frw_result_m_i     ( hu_frw_result    [m] ),
    .hu_opcode_m_i         ( pd_opcode        [m] ),

    // To decode stage
    .hu_raw_solve_d_o      ( hu_raw_solve     [d] ),
    .hu_gpr_we_d_o         ( hu_gpr_we        [d] ),
    .hu_gpr_wa_d_o         ( hu_gpr_wa        [d] ),
    .hu_gpr_wd_d_o         ( hu_gpr_wd        [d] ),

    // To execute stage
    .hu_raw_rs1_solve_e_o  ( hu_raw_solve_op_a[e] ),
    .hu_raw_rs2_solve_e_o  ( hu_raw_solve_op_b[e] ),
    .hu_op_a_e_o           ( hu_op_a          [e] ),
    .hu_op_b_e_o           ( hu_op_b          [e] ),

    // Control signals
    .hu_stall_req_f_i      ( 1'd0                 ), // TODO: These stages can't send stall request yet
    .hu_stall_req_d_i      ( 1'd0                 ), // TODO: These stages can't send stall request yet
    .hu_stall_req_e_i      ( 1'd0                 ), // TODO: These stages can't send stall request yet
    .hu_stall_req_m_i      ( hu_stall_req     [m] ),

    .hu_flush_req_f_i      ( 1'd0                 ), // TODO: These stages can't send flush request yet
    .hu_flush_req_d_i      ( 1'd0                 ), // TODO: These stages can't send flush request yet
    .hu_flush_req_e_i      ( hu_flush_req     [e] ),
    .hu_flush_req_m_i      ( 1'd0                 ), // TODO: These stages can't send flush request yet

    .hu_stall_f_o          ( hu_stall         [f] ),
    .hu_stall_d_o          ( hu_stall         [d] ),
    .hu_stall_e_o          ( hu_stall         [e] ),
    .hu_stall_m_o          ( hu_stall         [m] ),

    .hu_flush_f_o          ( hu_flush         [f] ),
    .hu_flush_d_o          ( hu_flush         [d] ),
    .hu_flush_e_o          ( hu_flush         [e] ),
    .hu_flush_m_o          ( hu_flush         [m] )
  );

  mist_data_mem data_mem(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    .mem_be_i              ( mem_be           [m] ),
    .mem_addr_i            ( mem_addr         [m] ),
    .mem_req_i             ( mem_req          [m] ),
    .mem_we_i              ( mem_we           [m] ),
    .mem_wd_i              ( mem_wd           [m] ),

    .mem_rd_o              ( mem_rd           [m] ),
    .mem_ack_o             ( mem_ack          [m] )
  );

endmodule
