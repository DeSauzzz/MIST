package mist_csr_pkg;

  localparam CSR_RW        = 3'b001;  // Read/Write CSR
  localparam CSR_RS        = 3'b010;  // Set CSR
  localparam CSR_RC        = 3'b011;  // Clear CSR
  localparam CSR_RW_IMM    = 3'b101;  // Read/Write immediate CSR
  localparam CSR_RS_IMM    = 3'b110;  // Set CSR immediate
  localparam CSR_RC_IMM    = 3'b111;  // Clear CSR immediate
  localparam CSR_ILL       = 3'b000;  // CSR illegal

  localparam MIE_ADDR      = 12'h304;
  localparam MTVEC_ADDR    = 12'h305;
  localparam MSCRATCH_ADDR = 12'h340;
  localparam MEPC_ADDR     = 12'h341;
  localparam MCAUSE_ADDR   = 12'h342;
  localparam MTVAL_ADDR    = 12'h343;

endpackage
