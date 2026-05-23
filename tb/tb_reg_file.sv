module tb_reg_file();

  int err_cnt;
  int test_case;

  logic        clk;
  logic        wr_en;

  logic [4:0]  wr_addr;
  logic [4:0]  rd_addr1;
  logic [4:0]  rd_addr2;

  logic [31:0] wr_data;
  logic [31:0] rd_data1;
  logic [31:0] rd_data2;

  logic [31:0] test_data [32];

  //////////////////////////
  // Start Initialization //
  //////////////////////////

  initial begin
    clk      = 1'd0;
    wr_en    = 1'd0;

    wr_addr  = 5'd0;
    rd_addr1 = 5'd0;
    rd_addr2 = 5'd0;

    wr_data  = 32'd0;
    rd_data1 = 32'd0;
    rd_data2 = 32'd0;
  end

  initial forever #10 clk = ~clk;

  //////////////////////
  // Update test_data //
  //////////////////////

  task upd_test_data(int SEED);
    for( int i = 0; i < 32; i++ ) begin
      test_data[i] = $random();
    end
  endtask

  /////////////////////////
  // WRITE/READ ALL TEST //
  /////////////////////////

  task write_all();
    wr_en = 1'd1;
    for( int i = 0; i < 32; i++ ) begin
      @( posedge clk );
      wr_addr = i;
      wr_data = test_data[i];
      @( negedge clk );
      $display("Write: reg[%0d] = 0x%0h", i, test_data[i]);
    end
    wr_en = 1'd0;
  endtask

  task automatic read_all(ref logic [4:0] rd_addr, ref logic [31:0] rd_data);
    for( int i = 0; i < 32; i++ ) begin
      @( posedge clk )
      rd_addr = i;
      @( negedge clk )
      if( ( rd_data !== 32'd0 ) && ( rd_addr === 5'd0 ) ) begin
        $display("ERROR (ALL Test): reg[%0d] expected 0x%0h, got 0x%0h", i, 32'd0, rd_data);
        err_cnt++;
      end
      else if( ( rd_data !== test_data[i] ) && ( ( rd_addr !== 5'd0 ) ) ) begin
        $display("ERROR (ALL Test): reg[%0d] expected 0x%0h, got 0x%0h", i, test_data[i], rd_data);
        err_cnt++;
      end
      else
        $display("OK (ALL Test): reg[%0d] = 0x%0h", i, rd_data);
    end
  endtask

  ///////////////////////////
  // READ AFTER WRITE TEST //
  ///////////////////////////

  task automatic read_after_write(ref logic [4:0] rd_addr, ref logic [31:0] rd_data);
    wr_en = 1'd1;
    for( int i = 0; i < 31; i++ ) begin
      @( posedge clk )
      wr_addr  = i;
      rd_addr = i;
      wr_data  = test_data[i];
      @( negedge clk )
      $display("Write: reg[%0d] = 0x%0h", i, test_data[i]);
      if( ( rd_data !== 32'd0 ) && ( rd_addr === 5'd0 ) ) begin
        $display("ERROR (RAW Test): reg[%0d] expected 0x%0h, got 0x%0h", i, 32'd0, rd_data);
        err_cnt++;
      end
      else if( ( rd_data !== test_data[i] ) && ( rd_addr !== 5'd0 ) ) begin
        $display("ERROR (RAW Test): reg[%0d] expected 0x%0h, got 0x%0h", i, test_data[i], rd_data);
        err_cnt++;
      end
      else
        $display("OK (RAW Test): reg[%0d] = 0x%0h", i, rd_data);
    end
    wr_en = 1'd0;
  endtask

  ///////////////////////////
  // WRITE AFTER READ TEST //
  ///////////////////////////

  initial begin
    test_case = 0;
    fork
      begin: test
        forever begin
          upd_test_data(test_case);
          write_all();
          $display("[%0t] READ ALL TEST FOR rd_addr1, rd_data1", $time);
          read_all(rd_addr1, rd_data1);
          $display("[%0t] READ ALL TEST FOR rd_addr2, rd_data2", $time);
          read_all(rd_addr2, rd_data2);
          test_case++;
          upd_test_data(test_case);
          $display("[%0t] READ AFTER WRITE TEST FOR rd_addr1, rd_data1", $time);
          read_after_write(rd_addr1, rd_data1);
          $display("[%0t] READ AFTER WRITE TEST FOR rd_addr2, rd_data2", $time);
          read_after_write(rd_addr2, rd_data2);
          test_case++;
        end
      end

      begin: timeout
        #100_000
        $display("[%0t] Timeout reached!", $time);
      end
    join_any
    disable test;
    if( err_cnt == 0 ) begin
      $display("===========================");
      $display("= Test ended with success =");
      $display("===========================");
    end
    else begin
      $display("===============");
      $display("= Test failed =");
      $display("===============");
    end
    $finish;
  end

  reg_file DUT(
    .clk_i      ( clk      ),
    .wr_en_i    ( wr_en    ),

    .wr_addr_i  ( wr_addr  ),
    .rd_addr1_i ( rd_addr1 ),
    .rd_addr2_i ( rd_addr2 ),

    .wr_data_i  ( wr_data  ),
    .rd_data1_o ( rd_data1 ),
    .rd_data2_o ( rd_data2 )
  );

endmodule
