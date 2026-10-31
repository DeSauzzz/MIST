module tb_coremark;
  localparam logic [31:0] LOG_ADDR = 32'h0002_0000;
  localparam logic [31:0] END_ADDR = 32'h0002_0004;

  logic clk;
  logic rstn;

  integer fd;
  initial fd = $fopen("coremark.log", "w");

  integer endless_loop = 0;

  initial clk  = 1'b0;
  initial rstn = 1'b0;

  initial forever #500 clk = ~clk;

  initial begin
      repeat (10)
      @(posedge clk);
      rstn = 1'b1;
  end

  mist_system DUT(
    .clk_i  ( clk  ),
    .rstn_i ( rstn )
  );

  always_ff @( posedge clk ) begin
    if( ( DUT.mem_addr == LOG_ADDR ) && ( DUT.mem_we ) && ( DUT.mem_req ) && ( DUT.mem_ack ) ) begin
      $write("%c", DUT.mem_wd[7:0]);
      $fwrite(fd, "%c", DUT.mem_wd[7:0]);
    end
  end

  always_ff @( posedge clk ) begin
    if( ( DUT.mem_we ) && ( DUT.mem_addr == END_ADDR ) && ( DUT.mem_req ) && ( DUT.mem_ack ) ) begin
      $display("\n==== CoreMark finished at %0t ====", $time());
      $fclose(fd);
      $finish();
    end
  end

  initial begin
    repeat(40_000_000) @( posedge clk );
    $display("\n==== TIMEOUT ====");
    $fclose(fd);
    $finish;
  end

endmodule
