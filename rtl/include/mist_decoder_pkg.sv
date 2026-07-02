package mist_decoder_pkg;

    // Opcodes
    localparam OP_OPCODE      = 5'b01100;
    localparam IMM_OPCODE     = 5'b00100;
    localparam LOAD_OPCODE    = 5'b00000;
    localparam STORE_OPCODE   = 5'b01000;
    localparam BRANCH_OPCODE  = 5'b11000;
    localparam JAL_OPCODE     = 5'b11011;
    localparam JALR_OPCODE    = 5'b11001;
    localparam LUI_OPCODE     = 5'b01101;
    localparam AUIPC_OPCODE   = 5'b00101;
    localparam SYSTEM_OPCODE  = 5'b11100;
    localparam FENCE_OPCODE   = 5'b00011;

    // Writeback source
    localparam EXEC_WB_RESULT = 2'b00;
    localparam LSU_WB_DATA    = 2'b01;
    localparam CSR_WB_DATA    = 2'b10;

endpackage
