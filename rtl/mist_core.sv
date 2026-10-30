import mist_decoder_pkg::EXEC_WB_RESULT;
import mist_decoder_pkg::LSU_WB_DATA;
import mist_decoder_pkg::CSR_WB_DATA;

module mist_core(
  input logic clk_i,
  input logic rstn_i,

  // Interrupt Controller Interface
  // TODO

  // Instruction Memory Interface
  input  logic [31:0] instr_i,
  output logic [31:0] instr_addr_o,

  // Data Memory Interface
  input  logic        mem_ack_i,
  input  logic [31:0] mem_rd_i,

  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  output logic [3:0]  mem_be_o,
  output logic        mem_req_o,
  output logic        mem_we_o
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

  logic [4:0]  hu_rs1            [d:e];
  logic [4:0]  hu_rs2            [d:e];
  logic [4:0]  hu_wa             [m:m];
  logic        hu_gpr_we         [m:w];

  logic [1:0]  hu_op_a_sel       [d:d];
  logic [2:0]  hu_op_b_sel       [d:d];

  logic [31:0] hu_comp_res       [m:m];
  logic [31:0] hu_mem_data       [m:m];

  logic        hu_use_rs1        [d:e];
  logic        hu_use_rs2        [d:e];

  logic        hu_mem_req        [e:m];
  logic        hu_mem_we         [e:m];

  logic [1:0]  hu_solver_lsu     [e:e];

  logic        hu_solver_m       [e:e];
  logic        hu_op_byp_m       [e:e];
  logic [31:0] hu_data_byp_m     [e:e];

  logic        hu_solver_wb      [d:e];
  logic        hu_op_byp_wb      [d:e];
  logic [31:0] hu_data_byp_wb    [d:e];

  logic        mret              [d:e];

  logic        ill_instr         [d:e];
  logic        use_rs1           [d:d];
  logic        use_rs2           [d:d];
  logic [31:0] instr             [f:f];
  logic [31:0] pc_cur            [f:d];

  logic        branch            [d:e];
  logic        jalr              [d:e];
  logic        jal               [d:e];

  logic [31:0] offset_pc         [e:e];

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

  ////////////////////////////////////
  // Communication with mist system //
  ////////////////////////////////////

  // Data Memory Interface
  assign mem_ack [m] = mem_ack_i;
  assign mem_rd  [m] = mem_rd_i;

  assign mem_be_o    = mem_be   [m];
  assign mem_req_o   = mem_req  [m];
  assign mem_we_o    = mem_we   [m];
  assign mem_addr_o  = mem_addr [m];
  assign mem_wd_o    = mem_wd   [m];

  /////////////////////
  // Writeback stage //
  /////////////////////

  assign alu_result[w]  = alu_result[m];

  assign gpr_wa    [w]  = gpr_wa    [m];
  assign gpr_we    [w]  = gpr_we    [m];

  assign lsu_rd    [w]  = lsu_rd    [m];

  assign wb_sel    [w]  = wb_sel    [m];

  assign hu_gpr_we [w]  = gpr_we    [w];

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

  mist_fetch_stage fetch_stage (
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From execute stage
    .alu_flag_e_i          ( alu_flag         [e] ),
    .branch_e_i            ( branch           [e] ),
    .jalr_e_i              ( jalr             [e] ),
    .jal_e_i               ( jal              [e] ),
    .offset_pc_e_i         ( offset_pc        [e] ),

    // From Hazard Unit
    .hu_stall_f_i          ( hu_stall         [f] ),
    .hu_flush_f_i          ( hu_flush         [f] ),

    // From Instruction Memory
    .sys_instr_i           ( instr_i              ),

    // To Instruction Memory
    .sys_addr_o            ( instr_addr_o         ),

    // To Decode Stage
    .instr_f_o             ( instr            [f] ),
    .pc_cur_f_o            ( pc_cur           [f] )
  );

  mist_decode_stage decode_stage(
    .clk_i                 ( clk_i                ),
    .rstn_i                ( rstn_i               ),

    // From fetch stage
    .instr_f_i             ( instr            [f] ),
    .pc_cur_f_i            ( pc_cur           [f] ),

    // From wb stage
    .gpr_wa_wb_i           ( gpr_wa           [w] ),
    .gpr_wd_wb_i           ( gpr_wd           [w] ),
    .gpr_we_wb_i           ( gpr_we           [w] ),

    // From Hazard Unit
    .hu_stall_d_i          ( hu_stall         [d] ),
    .hu_flush_d_i          ( hu_flush         [d] ),

    .hu_solver_wb_d_i      ( hu_solver_wb     [d] ),
    .hu_op_byp_wb_d_i      ( hu_op_byp_wb     [d] ),
    .hu_data_byp_wb_d_i    ( hu_data_byp_wb   [d] ),

    // To Hazard Unit
    .hu_rs1_d_o            ( hu_rs1           [d] ),
    .hu_rs2_d_o            ( hu_rs2           [d] ),

    .hu_op_a_sel_d_o       ( hu_op_a_sel      [d] ),
    .hu_op_b_sel_d_o       ( hu_op_b_sel      [d] ),

    .hu_use_rs1_d_o        ( hu_use_rs1       [d] ),
    .hu_use_rs2_d_o        ( hu_use_rs2       [d] ),

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
    .use_rs1_d_o           ( use_rs1          [d] ),
    .use_rs2_d_o           ( use_rs2          [d] ),

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
    .use_rs1_d_i           ( use_rs1          [d] ),
    .use_rs2_d_i           ( use_rs2          [d] ),

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

    .hu_solver_m_e_i       ( hu_solver_m      [e] ),
    .hu_solver_lsu_e_i     ( hu_solver_lsu    [e] ),
    .hu_op_byp_m_e_i       ( hu_op_byp_m      [e] ),
    .hu_data_byp_m_e_i     ( hu_data_byp_m    [e] ),

    .hu_solver_wb_e_i      ( hu_solver_wb     [e] ),
    .hu_op_byp_wb_e_i      ( hu_op_byp_wb     [e] ),
    .hu_data_byp_wb_e_i    ( hu_data_byp_wb   [e] ),

    // To Hazard Unit
    .hu_rs1_e_o            ( hu_rs1           [e] ),
    .hu_rs2_e_o            ( hu_rs2           [e] ),

    .hu_flush_req_e_o      ( hu_flush_req     [e] ),

    .hu_mem_req_e_o        ( hu_mem_req       [e] ),
    .hu_mem_we_e_o         ( hu_mem_we        [e] ),

    .hu_use_rs1_e_o        ( hu_use_rs1       [e] ),
    .hu_use_rs2_e_o        ( hu_use_rs2       [e] ),

    // To fetch stage
    .alu_flag_e_o          ( alu_flag         [e] ),
    .branch_e_o            ( branch           [e] ),
    .jalr_e_o              ( jalr             [e] ),
    .jal_e_o               ( jal              [e] ),
    .offset_pc_e_o         ( offset_pc        [e] ),

    // To memory stage
    .alu_result_e_o        ( alu_result       [e] ),

    .gpr_wa_e_o            ( gpr_wa           [e] ),
    .gpr_we_e_o            ( gpr_we           [e] ),

    .ill_instr_e_o         ( ill_instr        [e] ),

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

    .trap_m_i              ( 1'd0                 ), // TODO: Because interrupts not supported

    // From execute stage
    .alu_result_e_i        ( alu_result       [e] ),

    .gpr_wa_e_i            ( gpr_wa           [e] ),
    .gpr_we_e_i            ( gpr_we           [e] ),

    .ill_instr_e_i         ( ill_instr        [e] ),

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

    // To Hazard unit
    .hu_comp_res_m_o       ( hu_comp_res      [m] ),
    .hu_mem_data_m_o       ( hu_mem_data      [m] ),
    .hu_wa_m_o             ( hu_wa            [m] ),
    .hu_mem_req_m_o        ( hu_mem_req       [m] ),
    .hu_mem_we_m_o         ( hu_mem_we        [m] ),
    .hu_stall_req_m_o      ( hu_stall_req     [m] ),
    .hu_gpr_we_m_o         ( hu_gpr_we        [m] ),

    // From data memory
    .mem_rd_m_i            ( mem_rd           [m] ),
    .mem_ack_m_i           ( mem_ack          [m] ),

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

    // From Decode stage
    .hu_rs1_d_i            ( hu_rs1           [d] ),
    .hu_rs2_d_i            ( hu_rs2           [d] ),

    .hu_op_a_sel_d_i       ( hu_op_a_sel      [d] ),
    .hu_op_b_sel_d_i       ( hu_op_b_sel      [d] ),

    .hu_use_rs1_d_i        ( hu_use_rs1       [d] ),
    .hu_use_rs2_d_i        ( hu_use_rs2       [d] ),

    // From Execute stage
    .hu_rs1_e_i            ( hu_rs1           [e] ),
    .hu_rs2_e_i            ( hu_rs2           [e] ),

    .hu_mem_req_e_i        ( hu_mem_req       [e] ),
    .hu_mem_we_e_i         ( hu_mem_we        [e] ),

    .hu_use_rs1_e_i        ( hu_use_rs1       [e] ),
    .hu_use_rs2_e_i        ( hu_use_rs2       [e] ),

    // From Memory stage
    .hu_comp_res_m_i       ( hu_comp_res      [m] ),
    .hu_mem_data_m_i       ( hu_mem_data      [m] ),
    .hu_wa_m_i             ( hu_wa            [m] ),
    .hu_mem_req_m_i        ( hu_mem_req       [m] ),
    .hu_mem_we_m_i         ( hu_mem_we        [m] ),
    .hu_gpr_we_m_i         ( hu_gpr_we        [m] ),

    // From Writeback stage
    .hu_wb_data_wb_i       ( gpr_wd           [w] ),
    .hu_wa_wb_i            ( gpr_wa           [w] ),
    .hu_gpr_we_wb_i        ( hu_gpr_we        [w] ),

    // To decode stage
    .hu_solver_wb_d_o      ( hu_solver_wb     [d] ),
    .hu_op_byp_wb_d_o      ( hu_op_byp_wb     [d] ),
    .hu_data_byp_wb_d_o    ( hu_data_byp_wb   [d] ),

    // To execute stage
    .hu_solver_m_e_o       ( hu_solver_m      [e] ),
    .hu_solver_lsu_e_o     ( hu_solver_lsu    [e] ),
    .hu_op_byp_m_e_o       ( hu_op_byp_m      [e] ),
    .hu_data_byp_m_e_o     ( hu_data_byp_m    [e] ),

    .hu_solver_wb_e_o      ( hu_solver_wb     [e] ),
    .hu_op_byp_wb_e_o      ( hu_op_byp_wb     [e] ),
    .hu_data_byp_wb_e_o    ( hu_data_byp_wb   [e] ),

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

endmodule
