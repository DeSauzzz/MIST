// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

import mist_csr_pkg::*;

module mist_csr(

  input  logic        clk_i,
  input  logic        rstn_i,
  input  logic        trap_i,

  input  logic [31:0] instr_i,
  input  logic [ 2:0] opcode_i,

  input  logic [11:0] addr_i,
  input  logic [31:0] pc_i,
  input  logic [31:0] mcause_i,
  input  logic [31:0] rs1_data_i,
  input  logic [31:0] imm_data_i,
  input  logic        write_enable_i,

  output logic [31:0] read_data_o,
  output logic [31:0] mie_o,
  output logic [31:0] mepc_o,
  output logic [31:0] mtvec_o
);

  // Execution of CSR operation
  logic [31:0] csr_data;

  always_comb begin
    case( opcode_i )
      CSR_RW:     csr_data =  ( rs1_data_i );
      CSR_RS:     csr_data =  ( rs1_data_i ) | ( read_data_o );
      CSR_RC:     csr_data = ~( rs1_data_i ) & ( read_data_o );
      CSR_RW_IMM: csr_data =  ( imm_data_i );
      CSR_RS_IMM: csr_data =  ( imm_data_i ) | ( read_data_o );
      CSR_RC_IMM: csr_data = ~( imm_data_i ) & ( read_data_o );
      default:    csr_data = 32'd0;
    endcase
  end

  // CSR Memory
  logic [31:0] mie_ff;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mie_ff <= 32'd0;
    else if( ( write_enable_i ) && ( addr_i == MIE_ADDR ) )
      mie_ff <= csr_data;
  end

  logic [31:0] mtvec_ff;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mtvec_ff <= 32'd0;
    else if( ( write_enable_i ) && ( addr_i == MTVEC_ADDR ) )
      mtvec_ff <= csr_data;
  end

  logic [31:0] mscratch_ff;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mscratch_ff <= 32'd0;
    else if( ( write_enable_i ) && ( addr_i == MSCRATCH_ADDR ) )
      mscratch_ff <= csr_data;
  end

  logic [31:0] mepc_mux;
  logic [31:0] mepc_ff;

  assign mepc_mux = ( trap_i ) ? ( pc_i ) : ( csr_data );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mepc_ff <= 32'd0;
    else if( ( ( write_enable_i ) && ( addr_i == MEPC_ADDR ) ) || ( trap_i ) )
      mepc_ff <= mepc_mux;
  end

  logic [31:0] mcause_mux;
  logic [31:0] mcause_ff;

  assign mcause_mux = ( trap_i ) ? ( mcause_i ) : ( csr_data );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mcause_ff <= 32'd0;
    else if( ( ( write_enable_i ) && ( addr_i == MCAUSE_ADDR ) ) || ( trap_i ) )
      mcause_ff <= mcause_mux;
  end

  logic [31:0] mtval_mux;
  logic [31:0] mtval_ff;

  assign mtval_mux = ( trap_i ) ? ( instr_i ) : ( csr_data );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mtval_ff <= 32'd0;
    else if( ( ( write_enable_i ) && ( addr_i == MTVAL_ADDR ) ) || ( trap_i ) )
      mtval_ff <= mtval_mux;
  end

  // Output data
  always_comb begin
    case( addr_i )
      MIE_ADDR:      read_data_o = mie_ff;
      MTVEC_ADDR:    read_data_o = mtvec_ff;
      MSCRATCH_ADDR: read_data_o = mscratch_ff;
      MEPC_ADDR:     read_data_o = mepc_ff;
      MCAUSE_ADDR:   read_data_o = mcause_ff;
      MTVAL_ADDR:    read_data_o = mtval_ff;
      default:       read_data_o = 32'd0;
    endcase
  end

  assign mie_o   = mie_ff;
  assign mepc_o  = mepc_ff;
  assign mtvec_o = mtvec_ff;

endmodule
