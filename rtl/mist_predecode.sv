module mist_predecode(
  input  logic [16:0] pd_instr_i,

  output logic [4:0] rs1_addr_o,
  output logic [4:0] rs2_addr_o,
  output logic [6:0] opcode_o
);

  assign rs1_addr_o = pd_instr_i[4:  0];
  assign rs2_addr_o = pd_instr_i[9:  5];
  assign opcode_o   = pd_instr_i[16:10];

endmodule
