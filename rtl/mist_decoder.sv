// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

import mist_decoder_pkg::*;
import mist_alu_pkg::*;
import mist_csr_pkg::*;

module mist_decoder(
  input  logic [31:0] instr_i,

  output logic        ill_instr_o,
  output logic        use_rs1_o,
  output logic        use_rs2_o,

  output logic [2:0]  csr_op_o,
  output logic        csr_we_o,

  output logic        branch_o,
  output logic        jalr_o,
  output logic        jal_o,

  output logic        lsu_req_o,
  output logic        lsu_we_o,
  output logic [2:0]  lsu_size_o,

  output logic [1:0]  alu_op_a_sel_o,
  output logic [2:0]  alu_op_b_sel_o,
  output logic [3:0]  alu_op_o,

  output logic        gpr_we_o,
  output logic        mret_o,
  output logic [1:0]  wb_sel_o
);

  localparam ecall  = 32'h00000073;
  localparam ebreak = 32'h00100073;
  localparam mret   = 32'h30200073;

  // Init logic
  logic [4:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode      = instr_i[6:2];
  assign funct3      = instr_i[14:12];
  assign funct7      = instr_i[31:25];

  assign mret_o      = ( instr_i == mret );
  assign use_rs1_o   = opcode inside { JALR_OPCODE,
                                       BRANCH_OPCODE,
                                       LOAD_OPCODE,
                                       STORE_OPCODE,
                                       IMM_OPCODE,
                                       OP_OPCODE
                                     };
  assign use_rs2_o   = opcode inside { BRANCH_OPCODE,
                                       STORE_OPCODE,
                                       OP_OPCODE
                                     };

  // illegal instruction logic
  logic       ill_instr;
  logic       ill_system;
  logic       ill_load;
  logic       ill_store;
  logic       ill_branch;
  logic       ill_jalr;
  logic       ill_fence;
  logic       ill_op;
  logic       ill_op_imm;
  logic       ill_opcode;

  assign ill_system  = ( opcode == SYSTEM_OPCODE ) && ( funct3 == 3'd4 );
  assign ill_load    = ( opcode == LOAD_OPCODE   ) && ( funct3 inside { 3'd3, 3'd6, 3'd7 } );
  assign ill_store   = ( opcode == STORE_OPCODE  ) && ( funct3 > 3'd2  );
  assign ill_branch  = ( opcode == BRANCH_OPCODE ) && ( funct3 inside { 3'd2, 3'd3 } );
  assign ill_jalr    = ( opcode == JALR_OPCODE   ) && ( funct3 != 3'd0 );
  assign ill_fence   = ( opcode == FENCE_OPCODE  ) && ( funct3 != 3'd0 );
  assign ill_op      = ( opcode == OP_OPCODE     ) && ( ( funct3 == 3'b000 ) && !( funct7 inside { 7'b0000000, 7'b0100000 } )
                                                     || ( funct3 == 3'b001 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b010 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b011 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b100 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b101 ) && !( funct7 inside { 7'b0000000, 7'b0100000 } )
                                                     || ( funct3 == 3'b110 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b111 ) &&  ( funct7 != 7'b0000000                     )
                                                      );
  assign ill_op_imm  = ( opcode == IMM_OPCODE    ) && ( ( funct3 == 3'b001 ) &&  ( funct7 != 7'b0000000                     )
                                                     || ( funct3 == 3'b101 ) && !( funct7 inside { 7'b0000000, 7'b0100000 } )
                                                      );
  assign ill_opcode  = !( opcode inside { OP_OPCODE, IMM_OPCODE, LOAD_OPCODE, STORE_OPCODE, BRANCH_OPCODE, JAL_OPCODE,
                                          JALR_OPCODE, LUI_OPCODE, AUIPC_OPCODE, SYSTEM_OPCODE, FENCE_OPCODE } );
  assign ill_instr   = ( instr_i[1:0] != 2'b11   ) || ( instr_i == ecall ) || ( instr_i == ebreak ) || ( ill_system ) || ( ill_load ) || ( ill_store ) ||
                       ( ill_branch ) || ( ill_jalr ) || ( ill_fence ) || ( ill_op ) || ( ill_op_imm ) || ( ill_opcode );

  assign ill_instr_o = ( ill_instr );

  // CSR's logic
  assign csr_we_o    = ( opcode == SYSTEM_OPCODE ) && !( ill_instr ) && ( instr_i != mret );
  assign csr_op_o    = ( ( opcode == SYSTEM_OPCODE ) && !( ill_instr ) ) ? ( funct3 ) : ( CSR_ILL );

  // Branch logic
  assign branch_o    = ( opcode == BRANCH_OPCODE ) && !( ill_instr );
  assign jal_o       = ( opcode == JAL_OPCODE    ) && !( ill_instr );
  assign jalr_o      = ( opcode == JALR_OPCODE   ) && !( ill_instr );

  // Memory logic
  assign lsu_req_o   = ( opcode inside { LOAD_OPCODE, STORE_OPCODE } ) && !( ill_instr );
  assign lsu_we_o    = ( opcode == STORE_OPCODE                      ) && !( ill_instr );
  assign lsu_size_o  = ( funct3 );

  // ALU logic
  always_comb begin
    case( { funct7[5], funct3, opcode } ) inside
      // Branch op's
      { 1'd?, 3'd0, BRANCH_OPCODE }: alu_op_o = ALU_EQ;
      { 1'd?, 3'd1, BRANCH_OPCODE }: alu_op_o = ALU_NE;
      { 1'd?, 3'd4, BRANCH_OPCODE }: alu_op_o = ALU_LT;
      { 1'd?, 3'd5, BRANCH_OPCODE }: alu_op_o = ALU_GE;
      { 1'd?, 3'd6, BRANCH_OPCODE }: alu_op_o = ALU_LTU;
      { 1'd?, 3'd7, BRANCH_OPCODE }: alu_op_o = ALU_GEU;
      // Imm op's
      { 1'd?, 3'd0, IMM_OPCODE    }: alu_op_o = ALU_ADD;
      { 1'd?, 3'd2, IMM_OPCODE    }: alu_op_o = ALU_SLT;
      { 1'd?, 3'd3, IMM_OPCODE    }: alu_op_o = ALU_SLTU;
      { 1'd?, 3'd4, IMM_OPCODE    }: alu_op_o = ALU_XOR;
      { 1'd?, 3'd6, IMM_OPCODE    }: alu_op_o = ALU_OR;
      { 1'd?, 3'd7, IMM_OPCODE    }: alu_op_o = ALU_AND;
      { 1'd0, 3'd1, IMM_OPCODE    }: alu_op_o = ALU_SLL;
      { 1'd0, 3'd5, IMM_OPCODE    }: alu_op_o = ALU_SRL;
      { 1'd1, 3'd5, IMM_OPCODE    }: alu_op_o = ALU_SRA;
      // RS op's
      { 1'd0, 3'd0, OP_OPCODE     }: alu_op_o = ALU_ADD;
      { 1'd1, 3'd0, OP_OPCODE     }: alu_op_o = ALU_SUB;
      { 1'd?, 3'd1, OP_OPCODE     }: alu_op_o = ALU_SLL;
      { 1'd?, 3'd2, OP_OPCODE     }: alu_op_o = ALU_SLT;
      { 1'd?, 3'd3, OP_OPCODE     }: alu_op_o = ALU_SLTU;
      { 1'd?, 3'd4, OP_OPCODE     }: alu_op_o = ALU_XOR;
      { 1'd0, 3'd5, OP_OPCODE     }: alu_op_o = ALU_SRL;
      { 1'd1, 3'd5, OP_OPCODE     }: alu_op_o = ALU_SRA;
      { 1'd?, 3'd6, OP_OPCODE     }: alu_op_o = ALU_OR;
      { 1'd?, 3'd7, OP_OPCODE     }: alu_op_o = ALU_AND;
      default:                       alu_op_o = ALU_ADD;
    endcase
  end

  always_comb begin
    case( opcode )
      OP_OPCODE,
      IMM_OPCODE,
      BRANCH_OPCODE,
      LOAD_OPCODE,
      JALR_OPCODE,
      STORE_OPCODE: alu_op_a_sel_o = OP_A_RS1;
      LUI_OPCODE:   alu_op_a_sel_o = OP_A_ZERO;
      default:      alu_op_a_sel_o = OP_A_CURR_PC;
    endcase
  end

  always_comb begin
    case( opcode )
      BRANCH_OPCODE,
      OP_OPCODE:     alu_op_b_sel_o = OP_B_RS2;
      STORE_OPCODE:  alu_op_b_sel_o = OP_B_IMM_S;
      LOAD_OPCODE,
      JALR_OPCODE,
      IMM_OPCODE:    alu_op_b_sel_o = OP_B_IMM_I;
      LUI_OPCODE,
      AUIPC_OPCODE:  alu_op_b_sel_o = OP_B_IMM_U;
      default:       alu_op_b_sel_o = OP_B_INCR;
    endcase
  end

  // gpr and wb
  assign gpr_we_o = !( ill_instr ) && ( instr_i != mret ) && ( opcode inside { OP_OPCODE, IMM_OPCODE, LOAD_OPCODE, JAL_OPCODE, JALR_OPCODE,
                                                                               LUI_OPCODE, AUIPC_OPCODE, SYSTEM_OPCODE } );
  always_comb begin
    case( opcode )
      OP_OPCODE,
      IMM_OPCODE,
      JAL_OPCODE,
      JALR_OPCODE,
      LUI_OPCODE,
      AUIPC_OPCODE:  wb_sel_o = EXEC_WB_RESULT;
      SYSTEM_OPCODE: wb_sel_o = CSR_WB_DATA;
      LOAD_OPCODE:   wb_sel_o = LSU_WB_DATA;
      default:       wb_sel_o = EXEC_WB_RESULT;
    endcase
  end

endmodule
