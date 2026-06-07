package alu_pkg;

  // Arithmetic operations
  localparam ALU_ADD      = 4'b0000;
  localparam ALU_SUB      = 4'b0001;
  localparam ALU_XOR      = 4'b0010;
  localparam ALU_OR       = 4'b0011;
  localparam ALU_AND      = 4'b0100;
  localparam ALU_SLL      = 4'b0101;
  localparam ALU_SRL      = 4'b0110;
  localparam ALU_SRA      = 4'b0111;
  localparam ALU_SLT      = 4'b1000;
  localparam ALU_SLTU     = 4'b1001;

  // Compare operations
  localparam ALU_EQ       = 4'b1010;
  localparam ALU_NE       = 4'b1011;
  localparam ALU_LT       = 4'b1100;
  localparam ALU_GE       = 4'b1101;
  localparam ALU_LTU      = 4'b1110;
  localparam ALU_GEU      = 4'b1111;

  // Operand A selector
  localparam OP_A_RS1     = 2'b00;
  localparam OP_A_CURR_PC = 2'b01;
  localparam OP_A_ZERO    = 2'b10;

  // Operand B selector
  localparam OP_B_RS2     = 3'b000;
  localparam OP_B_INCR    = 3'b001;
  localparam OP_B_IMM_I   = 3'b010;
  localparam OP_B_IMM_U   = 3'b011;
  localparam OP_B_IMM_S   = 3'b100;

endpackage
