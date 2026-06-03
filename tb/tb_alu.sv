import alu_pkg::*;

module tb_alu#(parameter SEED=25)();

  ////////////////
  // Init logic //
  ////////////////

  logic [31:0] a_op;
  logic [31:0] b_op;
  logic [3:0]  alu_op;
  logic        flag;
  logic [31:0] result;

  logic        clk;
  logic [31:0] expected_result;
  logic        expected_flag;

  int iter_cnt;
  int err_cnt;
  int end_of_op;
  int end_of_test;

  initial             clk = 1'b0;
  initial forever #10 clk = ~clk;

  initial begin
    a_op        = 32'd0;
    b_op        = 32'd0;
    alu_op      = 4'd0;
    flag        = 1'd0;
    result      = 32'd0;
    end_of_test = 0;
    end_of_op   = 0;
  end

  task automatic main(int SEED);
    while( !end_of_test ) begin
      case( alu_op )
        ALU_ADD:
          begin
            expected_result = a_op + b_op;
            expected_flag   = 1'd0;
          end
        ALU_SUB:
          begin
            expected_result = a_op - b_op;
            expected_flag   = 1'd0;
          end
        ALU_XOR:
          begin
            expected_result = a_op ^ b_op;
            expected_flag   = 1'd0;
          end
        ALU_OR:
          begin
            expected_result = a_op | b_op;
            expected_flag   = 1'd0;
          end
        ALU_AND:
          begin
            expected_result = a_op & b_op;
            expected_flag   = 1'd0;
          end
        ALU_SLL:
          begin
            expected_result = a_op << b_op[4:0];
            expected_flag   = 1'd0;
          end
        ALU_SRL:
          begin
            expected_result = a_op >> b_op[4:0];
            expected_flag   = 1'd0;
          end
        ALU_SRA:
          begin
            expected_result = a_op >>> b_op[4:0];
            expected_flag   = 1'd0;
          end
        ALU_SLT:
          begin
            expected_result = ( $signed(a_op) < $signed(b_op) ) ? ( 1'd1 ) : ( 1'd0 );
            expected_flag   = 1'd0;
          end
        ALU_SLTU:
          begin
            expected_result = ( a_op < b_op ) ? ( 1'd1 ) : ( 1'd0 );
            expected_flag   = 1'd0;
          end
        ALU_EQ:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op == b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
        ALU_NE:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op != b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
        ALU_LT:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op < b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
        ALU_GE:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op > b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
        ALU_LTU:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op <= b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
        ALU_GEU:
          begin
            expected_result = 32'd0;
            expected_flag   = ( a_op >= b_op ) ? ( 1'd1 ) : ( 1'd0 );
          end
      endcase
      @( posedge clk )
      change_operands(iter_cnt + SEED, a_op, b_op);
      iter_cnt++;
      change_operation(end_of_op);
      op_checked(iter_cnt);
      complete(end_of_op, alu_op);
    end
  endtask

  task automatic change_operands(int SEED, ref logic [31:0] a_op, ref logic [31:0] b_op);
    a_op = $random(SEED);
    b_op = $random(SEED);
  endtask

  task automatic change_operation( ref int end_of_op );
    if( end_of_op )
      alu_op = alu_op + 1'd1;
  endtask

  task automatic op_checked( ref int iter_cnt );
    if( iter_cnt == 10000 ) begin
      end_of_op = 1'd1;
      iter_cnt  = 0;
    end
    else
      end_of_op = 1'd0;
  endtask

  task automatic complete( ref int end_of_op, ref logic [3:0] alu_op );
    if( ( end_of_op ) && ( alu_op == 4'hF ) )
      end_of_test  = 1'd1;
  endtask

  initial begin
    main(SEED);
    if( end_of_test ) begin
      $display("==============");
      $display("= TEST ENDED =");
      $display("==============");
      $display("Number of errors: %0d", err_cnt);
      $finish;
    end
  end

  alu DUT (
    .a_op_i   ( a_op   ),
    .b_op_i   ( b_op   ),
    .alu_op_i ( alu_op ),
    .flag_o   ( flag   ),
    .result_o ( result )
  );

  alu_check: assert property (
    @(negedge clk)
    (expected_result === result) and (expected_flag === flag)
  )
  else begin
    err_cnt++;
    $error("\nOperatin: %0h; Operand A = %0h, Operand B = %0h;\nExpected result = %0h, Real result = %0h;\nExpected flag = %0h, Real flag = %0h",
    alu_op, a_op, b_op, expected_result, result, expected_flag, flag);
    if(err_cnt == 10) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

endmodule
