import mist_decoder_pkg::*;

module mist_hu(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From fetch stage
  input  logic [4:0]  hu_rs1_addr_f_i,
  input  logic [4:0]  hu_rs2_addr_f_i,
  input  logic [6:0]  hu_opcode_f_i,

  // From decode stage
  input  logic [4:0]  hu_rs1_addr_d_i,
  input  logic [4:0]  hu_rs2_addr_d_i,
  input  logic [4:0]  hu_rd_addr_d_i,
  input  logic [6:0]  hu_opcode_d_i,

  // From execute stage
  input  logic [4:0]  hu_rd_addr_e_i,
  input  logic [31:0] hu_frw_result_e_i,
  input  logic [6:0]  hu_opcode_e_i,

  // From memory stage
  input  logic [4:0]  hu_rd_addr_m_i,
  input  logic [31:0] hu_frw_result_m_i,

  // To decode stage
  output logic        hu_raw_solve_d_o,
  output logic        hu_gpr_we_d_o,
  output logic [4:0]  hu_gpr_wa_d_o,
  output logic [31:0] hu_gpr_wd_d_o,

  // To execute stage
  output logic        hu_raw_rs1_solve_e_o,
  output logic        hu_raw_rs2_solve_e_o,
  output logic [31:0] hu_op_a_e_o,
  output logic [31:0] hu_op_b_e_o,

  // Control signals
  input  logic        hu_stall_req_f_i,
  input  logic        hu_stall_req_d_i,
  input  logic        hu_stall_req_e_i,
  input  logic        hu_stall_req_m_i,

  input  logic        hu_flush_req_f_i,
  input  logic        hu_flush_req_d_i,
  input  logic        hu_flush_req_e_i,
  input  logic        hu_flush_req_m_i,

  output logic        hu_stall_f_o,
  output logic        hu_stall_d_o,
  output logic        hu_stall_e_o,
  output logic        hu_stall_m_o,

  output logic        hu_flush_f_o,
  output logic        hu_flush_d_o,
  output logic        hu_flush_e_o,
  output logic        hu_flush_m_o
);

  logic  stall_req;
  assign stall_req    = ( hu_stall_req_f_i ) || ( hu_stall_req_d_i ) || ( hu_stall_req_e_i ) || ( hu_stall_req_m_i );

  assign hu_stall_f_o = stall_req;
  assign hu_stall_d_o = stall_req;
  assign hu_stall_e_o = stall_req;
  assign hu_stall_m_o = stall_req;

  assign hu_flush_f_o = ( hu_flush_req_e_i );
  assign hu_flush_d_o = ( hu_flush_req_e_i );
  assign hu_flush_e_o = ( hu_flush_req_e_i );
  assign hu_flush_m_o = 1'd0;

  // Function for resolving conflicts detected at the decode stage
  function automatic logic d_hazard_detector(
    input logic [4:0] rd_addr,
    input logic [4:0] rs1_addr,
    input logic [4:0] rs2_addr,
    input logic [6:0] opcode
  );
    case( opcode )
      OP_OPCODE,
      STORE_OPCODE,
      BRANCH_OPCODE: d_hazard_detector = ( ( rd_addr == rs1_addr ) || ( rd_addr == rs2_addr ) ) && ( rd_addr != 5'd0 );
      IMM_OPCODE,
      JAL_OPCODE,
      LOAD_OPCODE:   d_hazard_detector = ( rd_addr == rs1_addr ) && ( rd_addr != 5'd0 );
      default:       d_hazard_detector = 1'd0;
    endcase
  endfunction

  // D -> E Conflict detection
  logic  detect_de_hazard;
  assign detect_de_hazard = d_hazard_detector( hu_rd_addr_d_i, hu_rs1_addr_f_i, hu_rs2_addr_f_i, hu_opcode_f_i );

  // D -> M Conflict detection
  logic  detect_dm_hazard;
  assign detect_dm_hazard = d_hazard_detector( hu_rd_addr_e_i, hu_rs1_addr_f_i, hu_rs2_addr_f_i, hu_opcode_f_i );

  // D -> W Conflict detection
  logic  detect_dw_hazard;
  assign detect_dw_hazard = d_hazard_detector( hu_rd_addr_m_i, hu_rs1_addr_f_i, hu_rs2_addr_f_i, hu_opcode_f_i );

  // Informing the decode stage about the conflict resolution
  assign hu_raw_solve_d_o = ( detect_dm_hazard ) || ( detect_dw_hazard );
  assign hu_gpr_we_d_o    = ( detect_dm_hazard ) || ( detect_dw_hazard );
  assign hu_gpr_wa_d_o    = ( detect_dm_hazard ) ?  ( hu_rd_addr_e_i      ) :
                            ( detect_dw_hazard ) ?  ( hu_rd_addr_m_i      ) : ( 5'd0  );
  assign hu_gpr_wd_d_o    = ( detect_dm_hazard ) ?  ( hu_frw_result_e_i   ) :
                            ( detect_dw_hazard ) ?  ( hu_frw_result_m_i   ) : ( 32'd0 );

  // E -> M Conflict detection
  // logic detect_em_hazard_rs1_ff;
  // logic detect_em_hazard_rs2_ff;

  // always_ff @( posedge clk_i ) begin
  //   if( !rstn_i )
  //     detect_em_hazard_rs1_ff <= 1'd0;
  //   else if( ( detect_em_hazard_rs1_ff ) && !( stall_req ) )
  //     detect_em_hazard_rs1_ff <= 1'd0;
  //   else if( ( hu_rd_addr_m_i == hu_rs1_addr_d_i ) && ( hu_rd_addr_m_i != 5'd0 ) )
  //     detect_em_hazard_rs1_ff <= 1'd1;
  // end

  // always_ff @( posedge clk_i ) begin
  //   if( !rstn_i )
  //     detect_em_hazard_rs2_ff <= 1'd0;
  //   else if( ( detect_em_hazard_rs2_ff ) && !( stall_req ) )
  //     detect_em_hazard_rs2_ff <= 1'd0;
  //   else if( ( hu_rd_addr_m_i == hu_rs2_addr_d_i ) && ( hu_rd_addr_m_i != 5'd0 ) )
  //     detect_em_hazard_rs2_ff <= 1'd1;
  // end

  assign hu_raw_rs1_solve_e_o = 1'd0;
  assign hu_raw_rs2_solve_e_o = 1'd0;

  assign hu_op_a_e_o          = hu_frw_result_m_i;
  assign hu_op_b_e_o          = hu_frw_result_m_i;

endmodule
