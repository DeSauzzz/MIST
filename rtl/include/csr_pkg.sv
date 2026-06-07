package csr_pkg;

  localparam CSR_RW      = 3'b000; // Read/Write CSR
  localparam CSR_RS      = 3'b001; // Set CSR
  localparam CSR_RC      = 3'b010; // Clear CSR
  localparam CSR_RW_IMM  = 3'b011; // Read/Write immediate CSR
  localparam CSR_RS_IMM  = 3'b100; // Set CSR immediate
  localparam CSR_RC_IMM  = 3'b101; // Clear CSR immediate
  localparam CSR_ILL     = 3'b111; // CSR illegal

endpackage
