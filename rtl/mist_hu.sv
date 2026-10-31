// Operand A selector
import mist_alu_pkg::OP_A_RS1;
import mist_alu_pkg::OP_A_CURR_PC;
import mist_alu_pkg::OP_A_ZERO;

// Operand B selector
import mist_alu_pkg::OP_B_RS2;
import mist_alu_pkg::OP_B_INCR;
import mist_alu_pkg::OP_B_IMM_I;
import mist_alu_pkg::OP_B_IMM_U;
import mist_alu_pkg::OP_B_IMM_S;

// Opcode check
import mist_decoder_pkg::*;

module mist_hu(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From Decode stage
  input  logic [4:0]  hu_rs1_d_i,
  input  logic [4:0]  hu_rs2_d_i,

  input  logic        hu_use_rs1_d_i,
  input  logic        hu_use_rs2_d_i,

  // From Execute stage
  input  logic [4:0]  hu_rs1_e_i,
  input  logic [4:0]  hu_rs2_e_i,

  input  logic        hu_mem_req_e_i,
  input  logic        hu_mem_we_e_i,

  input  logic        hu_use_rs1_e_i,
  input  logic        hu_use_rs2_e_i,

  // From Memory stage
  input  logic [31:0] hu_comp_res_m_i,
  input  logic [31:0] hu_mem_data_m_i,
  input  logic [4:0]  hu_wa_m_i,
  input  logic        hu_mem_req_m_i,
  input  logic        hu_mem_we_m_i,
  input  logic        hu_gpr_we_m_i,

  // From Writeback stage
  input  logic [31:0] hu_wb_data_wb_i,
  input  logic [4:0]  hu_wa_wb_i,
  input  logic        hu_gpr_we_wb_i,

  // To decode stage
  output logic        hu_solver_wb_d_o,
  output logic        hu_op1_byp_wb_d_o,
  output logic        hu_op2_byp_wb_d_o,
  output logic [31:0] hu_data_byp_wb_d_o,

  // To execute stage
  output logic        hu_solver_m_e_o,
  output logic [1:0]  hu_solver_lsu_e_o,
  output logic        hu_op1_byp_m_e_o,
  output logic        hu_op2_byp_m_e_o,
  output logic [31:0] hu_data_byp_m_e_o,

  output logic        hu_solver_wb_e_o,
  output logic        hu_op1_byp_wb_e_o,
  output logic        hu_op2_byp_wb_e_o,
  output logic [31:0] hu_data_byp_wb_e_o,

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

  // Stall and Flush logic
  logic  stall_req;
  assign stall_req = ( hu_stall_req_f_i ) || ( hu_stall_req_d_i ) || ( hu_stall_req_e_i ) || ( hu_stall_req_m_i );

  assign hu_stall_f_o = stall_req;
  assign hu_stall_d_o = stall_req;
  assign hu_stall_e_o = stall_req;
  assign hu_stall_m_o = stall_req;

  assign hu_flush_f_o = hu_flush_req_e_i;
  assign hu_flush_d_o = hu_flush_req_e_i;
  assign hu_flush_e_o = 1'd0;
  assign hu_flush_m_o = 1'd0;

  // Hazard identification
  logic [1:0] hu_em_mem_raw;  // Potential memory operation RAW hazard between execute and memory stages
  logic [1:0] hu_em_comp_raw; // Potential computing operation RAW hazard between execute and memory stages
  logic [1:0] hu_ewb_raw;     // Potential RAW hazard between execute and writeback stages
  logic       hu_dwb_raw;     // Potential RAW hazard between decode and writeback stages

  assign hu_em_mem_raw [0] = ( ( ( hu_wa_m_i == hu_rs1_e_i )  &&  ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs1_e_i ) )   ||
                               ( ( hu_wa_m_i == hu_rs2_e_i )  &&  ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs2_e_i ) ) ) &&
                               ( hu_mem_req_m_i            )  && !( hu_mem_we_m_i );

  assign hu_em_comp_raw[0] = ( ( ( hu_wa_m_i == hu_rs1_e_i )  &&  ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs1_e_i ) )   ||
                               ( ( hu_wa_m_i == hu_rs2_e_i )  &&  ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs2_e_i ) ) ) &&
                              !( hu_mem_req_m_i            )  && !( hu_mem_we_m_i );

  assign hu_em_mem_raw [1] = ( ( hu_wa_m_i == hu_rs2_e_i ) && ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs2_e_i ) ) &&  ( hu_mem_req_e_i ) &&  ( hu_mem_we_e_i )
                                                                                                            &&  ( hu_mem_req_m_i ) && !( hu_mem_we_m_i );
  assign hu_em_comp_raw[1] = ( ( hu_wa_m_i == hu_rs2_e_i ) && ( hu_wa_m_i != 5'd0 ) && ( hu_use_rs2_e_i ) ) &&  ( hu_mem_req_e_i ) &&  ( hu_mem_we_e_i )
                                                                                                            && !( hu_mem_req_m_i ) && !( hu_mem_we_m_i );

  assign hu_ewb_raw    [0] = ( ( hu_wa_wb_i == hu_rs1_e_i ) && ( hu_wa_wb_i != 5'd0 ) && ( hu_use_rs1_e_i ) ) ||
                             ( ( hu_wa_wb_i == hu_rs2_e_i ) && ( hu_wa_wb_i != 5'd0 ) && ( hu_use_rs2_e_i ) );
  assign hu_ewb_raw    [1] = ( ( hu_wa_wb_i == hu_rs2_e_i ) && ( hu_wa_wb_i != 5'd0 ) && ( hu_use_rs2_e_i ) ) && ( hu_mem_req_e_i ) && ( hu_mem_we_e_i );

  assign hu_dwb_raw        = ( ( hu_wa_wb_i == hu_rs1_d_i ) && ( hu_wa_wb_i != 5'd0 ) && ( hu_use_rs1_d_i ) ) ||
                             ( ( hu_wa_wb_i == hu_rs2_d_i ) && ( hu_wa_wb_i != 5'd0 ) && ( hu_use_rs2_d_i ) );

  // Hazard acknowledgment
  logic [1:0] hu_em_mem_raw_ack;  // Acknowledgment memory operation RAW hazard between execute and memory stages
  logic [1:0] hu_em_comp_raw_ack; // Acknowledgment computing operation RAW hazard between execute and memory stages
  logic [1:0] hu_ewb_raw_ack;     // Acknowledgment RAW hazard between execute and writeback stages
  logic       hu_dwb_raw_ack;     // Acknowledgment RAW hazard between decode and writeback stages

  assign hu_em_mem_raw_ack [0] = ( hu_em_mem_raw [0] ) && ( hu_gpr_we_m_i  );
  assign hu_em_comp_raw_ack[0] = ( hu_em_comp_raw[0] ) && ( hu_gpr_we_m_i  );
  assign hu_em_mem_raw_ack [1] = ( hu_em_mem_raw [1] ) && ( hu_gpr_we_m_i  );
  assign hu_em_comp_raw_ack[1] = ( hu_em_comp_raw[1] ) && ( hu_gpr_we_m_i  );
  assign hu_ewb_raw_ack    [0] = ( hu_ewb_raw    [0] ) && ( hu_gpr_we_wb_i );
  assign hu_ewb_raw_ack    [1] = ( hu_ewb_raw    [1] ) && ( hu_gpr_we_wb_i );
  assign hu_dwb_raw_ack        = ( hu_dwb_raw        ) && ( hu_gpr_we_wb_i );

  // Hazard resolution for decode stage
  assign hu_solver_wb_d_o      = ( hu_dwb_raw_ack );
  assign hu_data_byp_wb_d_o    = ( hu_wb_data_wb_i );
  assign hu_op1_byp_wb_d_o     = ( ( hu_wa_wb_i == hu_rs1_d_i ) ) && ( hu_use_rs1_d_i );
  assign hu_op2_byp_wb_d_o     = ( ( hu_wa_wb_i == hu_rs2_d_i ) ) && ( hu_use_rs2_d_i );

  // Hazard resolution for execute stage
  assign hu_solver_m_e_o       = ( hu_em_mem_raw_ack[0] ) || ( hu_em_comp_raw_ack[0] );
  assign hu_solver_lsu_e_o[0]  = ( hu_em_mem_raw_ack[1] ) || ( hu_em_comp_raw_ack[1] );

  assign hu_data_byp_m_e_o     = ( |hu_em_mem_raw  ) ? ( hu_mem_data_m_i ):
                                 ( |hu_em_comp_raw ) ? ( hu_comp_res_m_i ):
                                                       ( 32'd0           );

  assign hu_solver_wb_e_o      = ( hu_ewb_raw_ack[0] );
  assign hu_solver_lsu_e_o[1]  = ( hu_ewb_raw_ack[1] );
  assign hu_data_byp_wb_e_o    = ( hu_wb_data_wb_i   );

  assign hu_op1_byp_m_e_o      = ( ( hu_wa_m_i  == hu_rs1_e_i ) ) && ( hu_use_rs1_e_i );
  assign hu_op2_byp_m_e_o      = ( ( hu_wa_m_i  == hu_rs2_e_i ) ) && ( hu_use_rs2_e_i );

  assign hu_op1_byp_wb_e_o     = ( ( hu_wa_wb_i == hu_rs1_e_i ) ) && ( hu_use_rs1_e_i);
  assign hu_op2_byp_wb_e_o     = ( ( hu_wa_wb_i == hu_rs2_e_i ) ) && ( hu_use_rs2_e_i );

endmodule
