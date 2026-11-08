// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Artem Matyukhin

module tb_riscv_tests;
  localparam logic [31:0] RESULT_ADDR = 32'h0002_0008;

  logic clk;
  logic rstn;

  initial clk = 1'd0;
  initial rstn = 1'd0;
  initial forever #10 clk = ~clk;
  initial begin
    repeat (10)
    @(posedge clk);
    rstn = 1'b1;
  end

  mist_system DUT (
    .clk_i(clk),
    .rstn_i(rstn)
  );

  always @(posedge clk)
    if( ( DUT.mem_req ) && ( DUT.mem_we ) && ( DUT.mem_ack ) && ( DUT.mem_addr == RESULT_ADDR ) ) begin
      if      (DUT.mem_wd == 32'd1)          $display("RESULT: PASS");
      else if (DUT.mem_wd == 32'hFFFF_FFFF)  $display("RESULT: FAIL (TESTNUM = 0)");
      else                                   $display("RESULT: FAIL (test #%0d)", DUT.mem_wd >> 1);
      $finish;
    end

  initial begin
    repeat (200_000) @(posedge clk);
    $display("RESULT: TIMEOUT");
    $finish;
  end

endmodule
