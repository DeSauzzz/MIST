// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

import mist_alu_pkg::OP_A_RS1;
import mist_alu_pkg::OP_A_CURR_PC;
import mist_alu_pkg::OP_A_ZERO;

import mist_alu_pkg::OP_B_RS2;
import mist_alu_pkg::OP_B_INCR;
import mist_alu_pkg::OP_B_IMM_I;
import mist_alu_pkg::OP_B_IMM_U;
import mist_alu_pkg::OP_B_IMM_S;

module mist_decode_stage(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From fetch stage
  input  logic [31:0] instr_f_i,
  input  logic [31:0] pc_cur_f_i,

  // From wb stage
  input  logic [4:0]  gpr_wa_wb_i,
  input  logic [31:0] gpr_wd_wb_i,
  input  logic        gpr_we_wb_i,

  // From Hazard Unit
  input  logic        hu_stall_d_i,
  input  logic        hu_flush_d_i,

  input  logic        hu_solver_wb_d_i,
  input  logic        hu_op1_byp_wb_d_i,
  input  logic        hu_op2_byp_wb_d_i,

  // To Hazard Unit
  output logic [4:0]  hu_rs1_d_o,
  output logic [4:0]  hu_rs2_d_o,

  output logic        hu_use_rs1_d_o,
  output logic        hu_use_rs2_d_o,

  // To execute stage
  output logic [31:0] imm_b_d_o,
  output logic [31:0] imm_j_d_o,

  output logic [31:0] op_a_d_o,
  output logic [31:0] op_b_d_o,

  output logic [4:0]  gpr_rs1_addr_d_o,
  output logic [4:0]  gpr_rs2_addr_d_o,
  output logic [4:0]  gpr_wa_d_o,
  output logic        gpr_we_d_o,

  output logic        ill_instr_d_o,
  output logic        use_rs1_d_o,
  output logic        use_rs2_d_o,

  output logic [2:0]  csr_op_d_o,
  output logic        csr_we_d_o,

  output logic        branch_d_o,
  output logic        jalr_d_o,
  output logic        jal_d_o,

  output logic        lsu_req_d_o,
  output logic        lsu_we_d_o,
  output logic [2:0]  lsu_size_d_o,
  output logic [31:0] lsu_wd_d_o,

  output logic [3:0]  alu_op_d_o,

  output logic        mret_d_o,
  output logic [1:0]  wb_sel_d_o,

  output logic [31:0] pc_cur_d_o
);

  // Sign-extend logic
  logic [31:0] imm_i; // Immediate I-type
  logic [31:0] imm_u; // Immediate U-type
  logic [31:0] imm_s; // Immediate S-type
  logic [31:0] imm_j; // Immediate J-type
  logic [31:0] imm_b; // Immediate B-type

  mist_signextend #(
    .IN_WIDTH (12),
    .OUT_WIDTH(32)
  ) d_extend_imm_i (
    .data_i ( instr_f_i[31:20] ),
    .data_o ( imm_i            )
  );

  mist_signextend #(
    .IN_WIDTH (12),
    .OUT_WIDTH(32)
  ) d_extend_imm_s (
    .data_i ( { instr_f_i[31:25], instr_f_i[11:7] } ),
    .data_o ( imm_s )
  );

  mist_signextend #(
    .IN_WIDTH (32),
    .OUT_WIDTH(32)
  ) d_extend_imm_u (
    .data_i ( { instr_f_i[31:12], 12'd0 } ),
    .data_o ( imm_u )
  );

  mist_signextend #(
    .IN_WIDTH (13),
    .OUT_WIDTH(32)
  ) d_extend_imm_b (
    .data_i ( { instr_f_i[31], instr_f_i[7], instr_f_i[30:25], instr_f_i[11:8], 1'd0 } ),
    .data_o ( imm_b )
  );

  mist_signextend #(
    .IN_WIDTH (20),
    .OUT_WIDTH(32)
  ) d_extend_imm_j (
    .data_i ( { instr_f_i[31], instr_f_i[19:12], instr_f_i[20], instr_f_i[30:21], 1'd0 } ),
    .data_o ( imm_j )
  );

  // Decoder logic
  logic        ill_instr;
  logic        use_rs1;
  logic        use_rs2;

  logic [2:0]  csr_op;
  logic        csr_we;

  logic        branch;
  logic        jalr;
  logic        jal;

  logic        lsu_req;
  logic        lsu_we;
  logic [2:0]  lsu_size;

  logic [1:0]  alu_op_a_sel;
  logic [2:0]  alu_op_b_sel;
  logic [3:0]  alu_op;

  logic        d_gpr_we;
  logic        mret;
  logic [1:0]  wb_sel;

  mist_decoder d_decoder (
    .instr_i        ( instr_f_i    ),

    .ill_instr_o    ( ill_instr    ),
    .use_rs1_o      ( use_rs1      ),
    .use_rs2_o      ( use_rs2      ),

    .csr_op_o       ( csr_op       ),
    .csr_we_o       ( csr_we       ),

    .branch_o       ( branch       ),
    .jalr_o         ( jalr         ),
    .jal_o          ( jal          ),

    .lsu_req_o      ( lsu_req      ),
    .lsu_we_o       ( lsu_we       ),
    .lsu_size_o     ( lsu_size     ),

    .alu_op_a_sel_o ( alu_op_a_sel ),
    .alu_op_b_sel_o ( alu_op_b_sel ),
    .alu_op_o       ( alu_op       ),

    .gpr_we_o       ( d_gpr_we     ),
    .mret_o         ( mret         ),
    .wb_sel_o       ( wb_sel       )
  );

  // Register File logic
  logic [4:0]  gpr_rs1_addr;
  logic [4:0]  gpr_rs2_addr;

  logic [4:0]  gpr_wr_addr;

  logic [31:0] gpr_rd_data1;
  logic [31:0] gpr_rd_data2;

  assign gpr_rs1_addr    = instr_f_i[19:15];
  assign gpr_rs2_addr    = instr_f_i[24:20];

  assign gpr_wr_addr     = instr_f_i[11:7];

  mist_gpr d_gpr (
    .clk_i        ( clk_i              ),

    .hu_solver_i  ( hu_solver_wb_d_i  ),
    .hu_op1_byp_i ( hu_op1_byp_wb_d_i ),
    .hu_op2_byp_i ( hu_op2_byp_wb_d_i ),

    .wr_en_i      ( gpr_we_wb_i       ),

    .wr_addr_i    ( gpr_wa_wb_i       ),

    .rd_addr1_i   ( gpr_rs1_addr      ),
    .rd_addr2_i   ( gpr_rs2_addr      ),

    .wr_data_i    ( gpr_wd_wb_i       ),

    .rd_data1_o   ( gpr_rd_data1      ),
    .rd_data2_o   ( gpr_rd_data2      )
  );

  // To Hazard Unit
  assign hu_rs1_d_o      = gpr_rs1_addr;
  assign hu_rs2_d_o      = gpr_rs2_addr;

  assign hu_use_rs1_d_o  = use_rs1;
  assign hu_use_rs2_d_o  = use_rs2;

  // Operand selection logic
  logic [31:0] op_a;
  logic [31:0] op_b;

  always_comb begin
    case( alu_op_a_sel )
      OP_A_RS1:     op_a = gpr_rd_data1;
      OP_A_CURR_PC: op_a = pc_cur_f_i;
      default:      op_a = 32'd0;
    endcase
  end

  always_comb begin
    case( alu_op_b_sel )
      OP_B_RS2:     op_b = gpr_rd_data2;
      OP_B_INCR:    op_b = 32'd4;
      OP_B_IMM_I:   op_b = imm_i;
      OP_B_IMM_U:   op_b = imm_u;
      OP_B_IMM_S:   op_b = imm_s;
    endcase
  end

  // To execute stage
  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      imm_b_d_o        <= 32'd0;
      imm_j_d_o        <= 32'd0;
      gpr_rs1_addr_d_o <= 5'd0;
      gpr_rs2_addr_d_o <= 5'd0;
      gpr_wa_d_o       <= 5'd0;
      gpr_we_d_o       <= 1'd0;
      ill_instr_d_o    <= 1'd0;
      use_rs1_d_o      <= 1'd0;
      use_rs2_d_o      <= 1'd0;
      csr_op_d_o       <= 3'd0;
      csr_we_d_o       <= 1'd0;
      branch_d_o       <= 1'd0;
      jalr_d_o         <= 1'd0;
      jal_d_o          <= 1'd0;
      lsu_req_d_o      <= 1'd0;
      lsu_we_d_o       <= 1'd0;
      lsu_size_d_o     <= 3'd0;
      lsu_wd_d_o       <= 32'd0;
      alu_op_d_o       <= 4'd0;
      mret_d_o         <= 1'd0;
      wb_sel_d_o       <= 2'd0;
      op_a_d_o         <= 32'd0;
      op_b_d_o         <= 32'd0;
      pc_cur_d_o       <= 32'd0;
    end
    else if( ( hu_flush_d_i ) && !( hu_stall_d_i ) ) begin
      imm_b_d_o        <= 32'd0;
      imm_j_d_o        <= 32'd0;
      gpr_rs1_addr_d_o <= 5'd0;
      gpr_rs2_addr_d_o <= 5'd0;
      gpr_wa_d_o       <= 5'd0;
      gpr_we_d_o       <= 1'd0;
      ill_instr_d_o    <= 1'd0;
      use_rs1_d_o      <= 1'd0;
      use_rs2_d_o      <= 1'd0;
      csr_op_d_o       <= 3'd0;
      csr_we_d_o       <= 1'd0;
      branch_d_o       <= 1'd0;
      jalr_d_o         <= 1'd0;
      jal_d_o          <= 1'd0;
      lsu_req_d_o      <= 1'd0;
      lsu_we_d_o       <= 1'd0;
      lsu_size_d_o     <= 3'd0;
      lsu_wd_d_o       <= 32'd0;
      alu_op_d_o       <= 4'd0;
      mret_d_o         <= 1'd0;
      wb_sel_d_o       <= 2'd0;
      op_a_d_o         <= 32'd0;
      op_b_d_o         <= 32'd0;
    end
    else if( !hu_stall_d_i ) begin
      imm_b_d_o        <= imm_b;
      imm_j_d_o        <= imm_j;
      gpr_rs1_addr_d_o <= gpr_rs1_addr;
      gpr_rs2_addr_d_o <= gpr_rs2_addr;
      gpr_wa_d_o       <= gpr_wr_addr;
      gpr_we_d_o       <= d_gpr_we;
      ill_instr_d_o    <= ill_instr;
      use_rs1_d_o      <= use_rs1;
      use_rs2_d_o      <= use_rs2;
      csr_op_d_o       <= csr_op;
      csr_we_d_o       <= csr_we;
      branch_d_o       <= branch;
      jalr_d_o         <= jalr;
      jal_d_o          <= jal;
      lsu_req_d_o      <= lsu_req;
      lsu_we_d_o       <= lsu_we;
      lsu_size_d_o     <= lsu_size;
      lsu_wd_d_o       <= gpr_rd_data2; // TODO: Can be broken
      alu_op_d_o       <= alu_op;
      mret_d_o         <= mret;
      wb_sel_d_o       <= wb_sel;
      op_a_d_o         <= op_a;
      op_b_d_o         <= op_b;
      pc_cur_d_o       <= pc_cur_f_i;
    end
  end

endmodule
