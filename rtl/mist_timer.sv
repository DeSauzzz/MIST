// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

module mist_timer(
  input  logic        clk_i,
  input  logic        rstn_i,

  output logic [31:0] timer_o
);

  logic [31:0] timer_ff;
  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      timer_ff <= 32'd0;
    else
      timer_ff <= timer_ff + 1'd1;
  end
  assign timer_o = timer_ff;

endmodule
