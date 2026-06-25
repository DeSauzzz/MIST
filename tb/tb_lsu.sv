import mem_pkg::*;

module tb_lsu#(parameter ITER=100000)();

  int   err_cnt;
  logic clk;
  logic rstn;

  initial             clk  = 1'd0;
  initial forever #10 clk  = ~clk;

  initial             rstn = 1'd0;
  initial         #50 rstn = 1'd1;

  typedef struct packed {
    // From memory side
    logic [31:0] mem_rd;

    // From core side
    logic [31:0] lsu_wd;
    logic [31:0] lsu_addr;
    logic        lsu_we;
    logic        lsu_req;
    logic [2:0]  lsu_size;
  } lsu_packet;

  ////////////////////
  // Signals to DUT //
  ////////////////////

  logic [2:0]  lsu_size;
  logic        lsu_req;
  logic        lsu_we;
  logic [31:0] lsu_addr;
  logic [31:0] lsu_wd;
  logic [31:0] lsu_rd;

  logic [3:0]  mem_be;
  logic        mem_req;
  logic        mem_we;
  logic [31:0] mem_addr;
  logic [31:0] mem_wd;
  logic [31:0] mem_rd;
  logic        mem_ack;

  logic        lsu_stall;

  mailbox#(lsu_packet) mbx = new();

  initial mem_ack = 1'd0;
  initial begin
    lsu_size = '0;
    lsu_req  = '0;
    lsu_we   = '0;
    lsu_addr = '0;
    lsu_wd   = '0;
    mem_rd   = '0;
  end

  logic [31:0] lsu_rd_ff;
  always_ff @( posedge clk ) begin
    if( !rstn )
      lsu_rd_ff <= 32'd0;
    else if( !( lsu_we ) && ( mem_ack ) )
      lsu_rd_ff <= mem_rd;
  end

  // Generator for valid requests
  task gen_vld();
    lsu_packet exp_lsu;
    if( !std::randomize(exp_lsu) with {
        exp_lsu[2:0] inside { MEM_BYTE, MEM_BYTE_U, MEM_HALF, MEM_HALF_U, MEM_WORD };
        exp_lsu[3] == 1'd1;
    } ) begin
        $error("Can't randomize request!");
        $finish;
    end
    mbx.put(exp_lsu);
  endtask

  // Requests grabber
  task drv_vld();
    lsu_packet exp_lsu;
    @( posedge clk )
    mbx.get(exp_lsu);
    lsu_size = exp_lsu.lsu_size;
    lsu_req  = exp_lsu.lsu_req;
    lsu_we   = exp_lsu.lsu_we;
    lsu_addr = exp_lsu.lsu_addr;
    lsu_wd   = exp_lsu.lsu_wd;
    mem_rd   = exp_lsu.mem_rd;
    #50
    @( posedge clk )
    mem_ack  = 1'd1;
    @( posedge clk )
    mem_ack  = 1'd0;
  endtask

  initial begin

    $display("===================================");
    $display("= Valid request phase was started =");
    $display("===================================");

    repeat(ITER) gen_vld();
    wait( rstn );
    repeat(ITER) drv_vld();

    $display("==============");
    $display("= TEST ENDED =");
    $display("==============");
    $display("Number of errors: %0d", err_cnt);
    $finish;
  end

  ////////////////
  // Assertions //
  ////////////////

  // Setting up stall request check
  stall_setup_test: assert property (
  @( posedge clk )
  disable iff( !rstn )
  ( lsu_req ) && !( lsu_stall ) |-> ##[1:2] ( lsu_stall )
  ) else begin
    err_cnt++;
    $error("\nInvalid stall request (Set up check). at this time it must be high. Real stall: %1d", lsu_stall);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Setting down stall request check
  stall_setdown_test: assert property (
    @( posedge clk )
    disable iff( !rstn )
    ( lsu_req ) && ( mem_ack ) |-> ##1 !( lsu_stall )
  ) else begin
    err_cnt++;
    $error("\nInvalid stall request (Set down check). at this time it must be high. Real stall: %1d", lsu_stall);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Byte enable check for BYTE request
  sequence byte0_check;
    ( lsu_addr[1:0] === 2'd0 ) && ( mem_be === 4'b0001 );
  endsequence

  sequence byte1_check;
    ( lsu_addr[1:0] === 2'd1 ) && ( mem_be === 4'b0010 );
  endsequence

  sequence byte2_check;
    ( lsu_addr[1:0] === 2'd2 ) && ( mem_be === 4'b0100 );
  endsequence

  sequence byte3_check;
    ( lsu_addr[1:0] === 2'd3 ) && ( mem_be === 4'b1000 );
  endsequence

  wd_be_byte_test: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( lsu_req ) && ( lsu_we ) && ( lsu_size === MEM_BYTE ) |-> ( byte0_check ) or ( byte1_check ) or ( byte2_check ) or ( byte3_check )
  ) else begin
    err_cnt++;
    $error("\nInvalid Byte Enable for BYTE request. Received mem_be: %4b", mem_be);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Byte enable check for HALF request
  sequence byte01_check;
    ( lsu_addr[1] ) && ( mem_be === 4'b1100 );
  endsequence

  sequence byte23_check;
    !( lsu_addr[1] ) && ( mem_be === 4'b0011 );
  endsequence

  wd_be_half_test: assert property (
  @( negedge clk )
  disable iff( !rstn )
  ( lsu_req ) && ( lsu_we ) && ( lsu_size === MEM_HALF ) |-> ( byte01_check ) or ( byte23_check )
  ) else begin
    err_cnt++;
    $error("\nInvalid Byte Enable for HALF request. Received mem_be: %4b", mem_be);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Byte Enable check for WORD request
  wd_be_word_test: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( lsu_req ) && ( lsu_we ) && ( lsu_size === MEM_WORD ) |-> ( mem_be === 4'b1111 )
  ) else begin
    err_cnt++;
    $error("\nInvalid Byte Enable for WORD request. Received mem_be: %4b", mem_be);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Write Byte Check
  wd_byte_write_test: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( mem_ack ) && ( lsu_size === MEM_BYTE ) && ( lsu_req ) && ( lsu_we ) |-> ( mem_wd === { 4{ lsu_wd[7:0]  } } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Write Data on BYTE request. Expected: %32h; Real: %32h", { 4{ lsu_wd[7:0]  } }, mem_wd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Write Half-Word Check
  wd_half_write_test: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( mem_ack ) && ( lsu_size === MEM_HALF ) && ( lsu_req ) && ( lsu_we ) |-> ( mem_wd === { 2{ lsu_wd[15:0]  } } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Write Data on HALF request. Expected: %32h; Real: %32h", { 2{ lsu_wd[15:0]  } }, mem_wd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Write Word Check
  wd_word_write_test: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( mem_ack ) && ( lsu_size === MEM_WORD ) && ( lsu_req ) && ( lsu_we ) |-> ( mem_wd === lsu_wd )
  ) else begin
    err_cnt++;
    $error("\nInvalid Write Data on WORD request. Expected: %32h; Real: %32h", lsu_wd, mem_wd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Read Byte Check
  rd_byte_read_test: assert property (
    @( negedge clk)
    disable iff( !rstn )
    ( lsu_req ) && !( lsu_we ) && ( lsu_size === MEM_BYTE ) && ( mem_ack ) |-> ##1 ( lsu_rd === { { 24{lsu_rd_ff[7]}  }, lsu_rd_ff[7:0]  } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Read Data on BYTE request. Expected: %8h; Real: %8h", { { 24{lsu_rd_ff[7]}  }, lsu_rd_ff[7:0]  }, lsu_rd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Read Unsigned Byte Check
  rd_byte_u_read_test: assert property (
    @( negedge clk)
    disable iff( !rstn )
    ( lsu_req ) && !( lsu_we ) && ( lsu_size === MEM_BYTE_U ) && ( mem_ack ) |-> ##1 ( lsu_rd === { 24'd0, lsu_rd_ff[7:0]  } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Read Data on BYTE_U request. Expected: %8h; Real: %8h", { 24'd0, lsu_rd_ff[7:0]  }, lsu_rd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Read Half Check
  rd_half_read_test: assert property (
    @( negedge clk)
    disable iff( !rstn )
    ( lsu_req ) && !( lsu_we ) && ( lsu_size === MEM_HALF ) && ( mem_ack ) |-> ##1 ( lsu_rd === { { 16{lsu_rd_ff[15]} }, lsu_rd_ff[15:0] } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Read Data on HALF request. Expected: %8h; Real: %8h", { { 16{lsu_rd_ff[15]} }, lsu_rd_ff[15:0] }, lsu_rd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Read Unsigned Half Check
  rd_half_u_read_test: assert property (
    @( negedge clk)
    disable iff( !rstn )
    ( lsu_req ) && !( lsu_we ) && ( lsu_size === MEM_HALF_U ) && ( mem_ack ) |-> ##1 ( lsu_rd === { 16'd0, lsu_rd_ff[15:0] } )
  ) else begin
    err_cnt++;
    $error("\nInvalid Read Data on HALF_U request. Expected: %8h; Real: %8h", { 16'd0, lsu_rd_ff[15:0] }, lsu_rd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Read Word Check
  rd_word_read_test: assert property (
    @( negedge clk)
    disable iff( !rstn )
    ( lsu_req ) && !( lsu_we ) && ( lsu_size === MEM_WORD ) && ( mem_ack ) |-> ##1 ( lsu_rd === lsu_rd_ff )
  ) else begin
    err_cnt++;
    $error("\nInvalid Read Data on WORD request. Expected: %8h; Real: %8h", lsu_rd_ff, lsu_rd);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  // Address word Check
  addr_word_check: assert property (
    @( negedge clk )
    disable iff( !rstn )
    ( lsu_req ) && ( lsu_size === MEM_WORD ) |-> mem_addr[1:0] === 2'd0
  ) else begin
    err_cnt++;
    $error("\nInvalid Address on WORD request. Expected: %8h; Real: %8h", {mem_addr[31:2], 2'd0}, mem_addr);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  /////////
  // DUT //
  /////////

  lsu DUT(
    .clk_i           ( clk       ),
    .rstn_i          ( rstn      ),

    .lsu_size_i      ( lsu_size  ),
    .lsu_req_i       ( lsu_req   ),
    .lsu_we_i        ( lsu_we    ),
    .lsu_addr_i      ( lsu_addr  ),
    .lsu_wd_i        ( lsu_wd    ),
    .lsu_rd_o        ( lsu_rd    ),

    .mem_be_o        ( mem_be    ),
    .mem_req_o       ( mem_req   ),
    .mem_we_o        ( mem_we    ),
    .mem_addr_o      ( mem_addr  ),
    .mem_wd_o        ( mem_wd    ),
    .mem_rd_i        ( mem_rd    ),
    .mem_ack_i       ( mem_ack   ),

    .lsu_stall_req_o ( lsu_stall )
  );

endmodule
