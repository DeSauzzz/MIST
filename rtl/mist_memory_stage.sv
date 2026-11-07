// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

module mist_memory_stage(
  input  logic        clk_i,
  input  logic        rstn_i,

  input  logic        trap_m_i,

  // From execute stage
  input  logic [31:0] comp_result_e_i, // Can be data memory address

  input  logic [4:0]  gpr_wa_e_i,
  input  logic        gpr_we_e_i,

  input  logic        ill_instr_e_i,

  input  logic [2:0]  csr_op_e_i,
  input  logic        csr_we_e_i,

  input  logic        lsu_req_e_i,
  input  logic        lsu_we_e_i,
  input  logic [2:0]  lsu_size_e_i,
  input  logic [31:0] lsu_wd_e_i,

  input  logic        mret_e_i,
  input  logic [1:0]  wb_sel_e_i,

  // From Hazard unit
  input  logic        hu_stall_m_i,
  input  logic        hu_flush_m_i,

  // To Hazard unit
  output logic [31:0] hu_comp_res_m_o,
  output logic [31:0] hu_mem_data_m_o,
  output logic [4:0]  hu_wa_m_o,
  output logic        hu_mem_req_m_o,
  output logic        hu_mem_we_m_o,
  output logic        hu_stall_req_m_o,
  output logic        hu_gpr_we_m_o,

  // From data memory
  input  logic [31:0] mem_rd_m_i,
  input  logic        mem_ack_m_i,

  // To data memory
  output logic [3:0]  mem_be_m_o,
  output logic        mem_req_m_o,
  output logic        mem_we_m_o,
  output logic [31:0] mem_addr_m_o,
  output logic [31:0] mem_wd_m_o,

  // To writeback stage
  output logic [31:0] lsu_rd_m_o,

  output logic [31:0] comp_result_m_o,

  output logic [4:0]  gpr_wa_m_o,
  output logic        gpr_we_m_o,

  output logic [1:0]  wb_sel_m_o
);

  // LSU logic
  logic [31:0] lsu_rd;

  mist_lsu m_lsu(
    .clk_i           ( clk_i            ),
    .rstn_i          ( rstn_i           ),

    .lsu_size_i      ( lsu_size_e_i     ),
    .lsu_req_i       ( lsu_req_e_i      ),
    .lsu_we_i        ( lsu_we_e_i       ),
    .lsu_addr_i      ( comp_result_e_i  ),
    .lsu_wd_i        ( lsu_wd_e_i       ),
    .lsu_rd_o        ( lsu_rd           ),

    .mem_be_o        ( mem_be_m_o       ),
    .mem_req_o       ( mem_req_m_o      ),
    .mem_we_o        ( mem_we_m_o       ),
    .mem_addr_o      ( mem_addr_m_o     ),
    .mem_wd_o        ( mem_wd_m_o       ),
    .mem_rd_i        ( mem_rd_m_i       ),
    .mem_ack_i       ( mem_ack_m_i      ),

    .lsu_trap_i      ( trap_m_i         ),
    .lsu_stall_req_o ( hu_stall_req_m_o )
  );

  // To Hazard Unit
  assign hu_comp_res_m_o = comp_result_e_i;
  assign hu_mem_data_m_o = lsu_rd;
  assign hu_wa_m_o       = gpr_wa_e_i;
  assign hu_mem_req_m_o  = lsu_req_e_i;
  assign hu_mem_we_m_o   = lsu_we_e_i;
  assign hu_gpr_we_m_o   = gpr_we_e_i;

  // To writeback stage
  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      lsu_rd_m_o      <= lsu_rd;
      comp_result_m_o <= 32'd0;
      gpr_wa_m_o      <= 5'd0;
      gpr_we_m_o      <= 1'd0;
      wb_sel_m_o      <= 2'd0;
    end
    else if( ( hu_flush_m_i ) && !( hu_stall_m_i ) ) begin
      lsu_rd_m_o      <= lsu_rd;
      comp_result_m_o <= 32'd0;
      gpr_wa_m_o      <= 5'd0;
      gpr_we_m_o      <= 1'd0;
      wb_sel_m_o      <= 2'd0;
    end
    else if( !hu_stall_m_i ) begin
      lsu_rd_m_o      <= lsu_rd;
      comp_result_m_o <= comp_result_e_i;
      gpr_wa_m_o      <= gpr_wa_e_i;
      gpr_we_m_o      <= gpr_we_e_i;
      wb_sel_m_o      <= wb_sel_e_i;
    end
  end

endmodule
