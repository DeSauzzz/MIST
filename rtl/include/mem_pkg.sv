package mem_pkg;

  localparam INSTR_MEM_BYTE_SIZE = 512;
  localparam INSTR_MEM_WORD_SIZE = INSTR_MEM_BYTE_SIZE / 4;
  localparam DATA_MEM_BYTE_SIZE  = 512;
  localparam DATA_MEM_WORD_SIZE  = DATA_MEM_BYTE_SIZE / 4;

  localparam MEM_BYTE   = 3'b000;
  localparam MEM_HALF   = 3'b001;
  localparam MEM_WORD   = 3'b010;
  localparam MEM_BYTE_U = 3'b100;
  localparam MEM_HALF_U = 3'b101;

endpackage
