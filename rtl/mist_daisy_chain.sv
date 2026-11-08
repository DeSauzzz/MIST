// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

module mist_daisy_chain(
  input  logic        clk_i,
  input  logic        rstn_i,

  input  logic [15:0] masked_irq_i,
  input  logic        irq_ret_i,
  input  logic        ready_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  // Daisy Chain generation
  logic [15:0] cause;
  logic [15:0] irq_req;

  genvar i;
  generate
    assign cause  [0] =  ( masked_irq_i[0] ) && ( ready_i );
    assign irq_req[0] = !( cause       [0] ) && ( ready_i );
    for( i = 1; i < 16; i++ ) begin : daisy_chain_gen
      assign cause  [i] =  ( masked_irq_i[i] ) && ( irq_req[i-1] );
      assign irq_req[i] = !( cause       [i] ) && ( irq_req[i-1] );
    end
  endgenerate

  // Output logic
  logic [15:0] cause_ff;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      cause_ff <= 16'd0;
    else if( irq_o )
      cause_ff <= cause;
  end

  assign irq_o       = |cause;
  assign irq_ret_o   = ( irq_ret_i ) ? ( cause_ff ) : ( 16'd0 );
  assign irq_cause_o = { 12'h800, cause, 4'h0 };

endmodule
