module mist_predecode(
  input  logic [9:0] pd_instr_i,

  output logic [4:0] rs1_addr_o,
  output logic [4:0] rs2_addr_o
);

  assign rs1_addr_o = pd_instr_i[4:0];
  assign rs2_addr_o = pd_instr_i[9:5];

endmodule
