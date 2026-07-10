import decoder_pkg::*;
import alu_pkg::*;
import csr_pkg::*;
import mem_pkg::*;

module tb_decoder#(parameter ITER=30000)();

  int err_cnt;

  logic        clk;
  logic        rstn;
  logic [31:0] instr;

  ////////////////////
  // Signals to DUT //
  ////////////////////

  logic        ill_instr;

  logic [2:0]  csr_op;
  logic        csr_we;

  logic        branch;
  logic        jalr;
  logic        jal;

  logic        lsu_req;
  logic        lsu_we;
  logic [2:0]  lsu_size;

  logic [1:0]  alu_op_a_sel;
  logic [2:0]  alu_op_b_sel;
  logic [3:0]  alu_op;

  logic        gpr_we;
  logic        mret;
  logic [1:0]  wb_sel;

  ///////////////////////
  // Reference signals //
  ///////////////////////

  logic        exp_ill_instr;

  logic [2:0]  exp_csr_op;
  logic        exp_csr_we;

  logic        exp_branch;
  logic        exp_jalr;
  logic        exp_jal;

  logic        exp_lsu_req;
  logic        exp_lsu_we;
  logic [2:0]  exp_lsu_size;

  logic [1:0]  exp_alu_op_a_sel;
  logic [2:0]  exp_alu_op_b_sel;
  logic [3:0]  exp_alu_op;

  logic        exp_gpr_we;
  logic        exp_mret;
  logic [1:0]  exp_wb_sel;

  initial             clk   = 1'd1;
  initial forever #10 clk   = ~clk;

  initial             rstn  = 1'd0;
  initial         #20 rstn  = 1'd1;

  initial             instr = 32'd0;

  mailbox gen = new();

  ///////////////////////////
  // Instruction Generator //
  ///////////////////////////

  // Generator for R2R intructions
  task gen_type_R(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == OP_OPCODE;
          instr[31:25] inside { 7'b0000000, 7'b0100000 };
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2]   == OP_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == OP_OPCODE;
          instr[31:25] != 7'b0000000;
          instr[31:25] != 7'b0100000;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for Immediate instructions
  task gen_type_I(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == IMM_OPCODE;
          instr[31:25] inside { 7'b0000000, 7'b0100000 };
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2]   == IMM_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == IMM_OPCODE;
          instr[14:12] inside { 3'd1, 3'd5 };
          instr[31:25] != 7'b0000000;
          instr[31:25] != 7'b0100000;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for Load instructions
  task gen_type_L(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == LOAD_OPCODE;
          instr[14:12] inside {3'd0, 3'd1, 3'd2, 3'd4, 3'd5};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2]   == LOAD_OPCODE;
          instr[14:12] inside {3'd0, 3'd1, 3'd2, 3'd4, 3'd5};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == LOAD_OPCODE;
          instr[14:12] inside {3'd3, 3'd6, 3'd7};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for Store intructions
  task gen_type_S(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == STORE_OPCODE;
          instr[14:12] inside {[0:2]};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == STORE_OPCODE;
          instr[14:12] inside {[0:2]};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == STORE_OPCODE;
          instr[14:12] inside {[3:7]};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for Branch instructions
  task gen_type_B(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == BRANCH_OPCODE;
          instr[14:12] inside {3'd0, 3'd1, 3'd4, 3'd5, 3'd6, 3'd7};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == BRANCH_OPCODE;
          instr[14:12] inside {3'd0, 3'd1, 3'd4, 3'd5, 3'd6, 3'd7};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == BRANCH_OPCODE;
          instr[14:12] inside {3'd2, 3'd3};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for JAL instruction
  task gen_type_J(int command);
    logic [31:0] instr;
    if( command > 1 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == JAL_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == JAL_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for JALR instruction
  task gen_type_JR(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
        instr[1:0]   == 2'b11;
        instr[6:2]   == JALR_OPCODE;
        instr[14:12] == 3'b000;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
        instr[1:0]   inside {[0:2]};
        instr[6:2]   == JALR_OPCODE;
        instr[14:12] == 3'b000;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
        instr[1:0]   == 2'b11;
        instr[6:2]   == JALR_OPCODE;
        instr[14:12] inside {[1:7]};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for LUI intruction
  task gen_type_LUI(int command);
    logic [31:0] instr;
    if( command > 1 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == LUI_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == LUI_OPCODE;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for AUIPC instruction
  task gen_type_auipc(int command);
    logic [31:0] instr;
    if( command > 1 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == AUIPC_OPCODE;
      } ) begin
          $error("Can't randomize instruction");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == AUIPC_OPCODE;
      } ) begin
          $error("Can't randomize instruction");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for CSR, ECALL and EBREAK instructions
  task gen_type_system(int command);
    logic [31:0] instr;
    if( command > 3 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] == 2'b11;
          instr[6:2] == SYSTEM_OPCODE;
          instr[14:12] inside {3'd1, 3'd2, 3'd3, 3'd5, 3'd6, 3'd7};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0] inside {[0:2]};
          instr[6:2] == SYSTEM_OPCODE;
          instr[14:12] inside {3'd1, 3'd2, 3'd3, 3'd5, 3'd6, 3'd7};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 1 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == SYSTEM_OPCODE;
          instr[14:12] == 3'd4;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
        instr inside {32'h00000073, 32'h00100073, 32'h30200073};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  // Generator for FENCE instruction
  task gen_type_fence(int command);
    logic [31:0] instr;
    if( command > 2 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == FENCE_OPCODE;
          instr[14:12] == 3'd0;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else if( command == 0 ) begin
      if( !std::randomize(instr) with {
          instr[1:0]   inside {[0:2]};
          instr[6:2]   == FENCE_OPCODE;
          instr[14:12] == 3'd0;
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    else begin
      if( !std::randomize(instr) with {
          instr[1:0]   == 2'b11;
          instr[6:2]   == FENCE_OPCODE;
          instr[14:12] inside {[1:7]};
      } ) begin
          $error("Can't randomize instruction!");
          $finish;
      end
    end
    gen.put(instr);
  endtask

  /////////////////////////
  // Instruction grabber //
  /////////////////////////

  task instr_grabber(inout logic [31:0] instr);
    @( posedge clk )
    gen.get(instr);
  endtask

  ///////////////////////
  // Start of the test //
  ///////////////////////

  initial begin
    $display("=============================================");
    $display("= R2R instructions phase start at time: %0t =", $time);
    $display("=============================================");

    repeat(ITER) gen_type_R($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("===================================================");
    $display("= Immediate instructions phase start at time: %0t =", $time);
    $display("===================================================");

    repeat(ITER) gen_type_I($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("==============================================");
    $display("= Load instructions phase start at time: %0t =", $time);
    $display("==============================================");

    repeat(ITER) gen_type_L($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("===============================================");
    $display("= Store instructions phase start at time: %0t =", $time);
    $display("===============================================");

    repeat(ITER) gen_type_S($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("================================================");
    $display("= Branch instructions phase start at time: %0t =", $time);
    $display("================================================");

    repeat(ITER) gen_type_B($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("============================================");
    $display("= JAL instruction phase start at time: %0t =", $time);
    $display("============================================");

    repeat(ITER/100) gen_type_J($urandom_range(0, 10));
    repeat(ITER/100) instr_grabber(instr);

    $display("=============================================");
    $display("= JALR instruction phase start at time: %0t =", $time);
    $display("=============================================");

    repeat(ITER) gen_type_JR($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("============================================");
    $display("= LUI instruction phase start at time: %0t =", $time);
    $display("============================================");

    repeat(ITER/100) gen_type_LUI($urandom_range(0, 10));
    repeat(ITER/100) instr_grabber(instr);

    $display("==============================================");
    $display("= AUIPC instruction phase start at time: %0t =", $time);
    $display("==============================================");

    repeat(ITER/100) gen_type_auipc($urandom_range(0, 10));
    repeat(ITER/100) instr_grabber(instr);

    $display("================================================");
    $display("= SYSTEM instructions phase start at time: %0t =", $time);
    $display("================================================");

    repeat(ITER) gen_type_system($urandom_range(0, 10));
    repeat(ITER) instr_grabber(instr);

    $display("===============================================");
    $display("= FENCE instruction phase start at time: %0t =", $time);
    $display("===============================================");

    repeat(ITER/100) gen_type_fence($urandom_range(0, 10));
    repeat(ITER/100) instr_grabber(instr);

    $display("==============");
    $display("= TEST ENDED =");
    $display("==============");
    $display("Number of errors: %0d", err_cnt);
    $finish;
  end

  ///////////////////////
  // Reference Decoder //
  ///////////////////////

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];

  always_comb begin
    exp_ill_instr    = 1'd1;
    exp_csr_op       = CSR_ILL;
    exp_csr_we       = 1'd0;
    exp_branch       = 1'd0;
    exp_jalr         = 1'd0;
    exp_jal          = 1'd0;
    exp_lsu_req      = 1'd0;
    exp_lsu_we       = 1'd0;
    exp_lsu_size     = funct3;
    exp_alu_op_a_sel = OP_A_CURR_PC;
    exp_alu_op_b_sel = OP_B_INCR;
    exp_alu_op       = ALU_ADD;
    exp_gpr_we       = 1'd0;
    exp_mret         = 1'd0;
    exp_wb_sel       = EXEC_WB_RESULT;
    case( opcode )
      { OP_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_ADD;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else if( funct7 == 7'b0100000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SUB;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b001:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SLL;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b010:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SLT;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b011:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SLTU;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b100:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_XOR;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b101:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SRL;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else if( funct7 == 7'b0100000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SRA;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b110:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_OR;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b111:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_AND;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_RS2;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            default:
                  exp_ill_instr    = 1'd1;
          endcase
        end
      { IMM_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            3'b001:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SLL;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_IMM_I;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b010:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_SLT;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            3'b011:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_SLTU;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            3'b100:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_XOR;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            3'b101:
              begin
                if( funct7 == 7'b0000000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SRL;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_IMM_I;
                  exp_gpr_we       = 1'd1;
                end
                else if( funct7 == 7'b0100000 ) begin
                  exp_ill_instr    = 1'd0;
                  exp_alu_op       = ALU_SRA;
                  exp_alu_op_a_sel = OP_A_RS1;
                  exp_alu_op_b_sel = OP_B_IMM_I;
                  exp_gpr_we       = 1'd1;
                end
                else
                  exp_ill_instr    = 1'd1;
              end
            3'b110:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_OR;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            3'b111:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op       = ALU_AND;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_gpr_we       = 1'd1;
              end
            default:
                exp_ill_instr    = 1'd1;
          endcase
        end
      { LOAD_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                exp_ill_instr    = 1'd0;
                exp_lsu_req      = 1'd1;
                exp_gpr_we       = 1'd1;
                exp_lsu_size     = MEM_BYTE;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_wb_sel       = LSU_WB_DATA;
              end
            3'b001:
              begin
                exp_ill_instr    = 1'd0;
                exp_lsu_req      = 1'd1;
                exp_gpr_we       = 1'd1;
                exp_lsu_size     = MEM_HALF;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_wb_sel       = LSU_WB_DATA;
              end
            3'b010:
              begin
                exp_ill_instr    = 1'd0;
                exp_lsu_req      = 1'd1;
                exp_gpr_we       = 1'd1;
                exp_lsu_size     = MEM_WORD;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_wb_sel       = LSU_WB_DATA;
              end
            3'b100:
              begin
                exp_ill_instr    = 1'd0;
                exp_lsu_req      = 1'd1;
                exp_gpr_we       = 1'd1;
                exp_lsu_size     = MEM_BYTE_U;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_wb_sel       = LSU_WB_DATA;
              end
            3'b101:
              begin
                exp_ill_instr    = 1'd0;
                exp_lsu_req      = 1'd1;
                exp_gpr_we       = 1'd1;
                exp_lsu_size     = MEM_HALF_U;
                exp_alu_op       = ALU_ADD;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_I;
                exp_wb_sel       = LSU_WB_DATA;
              end
            default:
                exp_ill_instr    = 1'd1;
          endcase
        end
      { STORE_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_S;
                exp_alu_op       = ALU_ADD;
                exp_lsu_req      = 1'd1;
                exp_lsu_we       = 1'd1;
                exp_lsu_size     = MEM_BYTE;
              end
            3'b001:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_S;
                exp_alu_op       = ALU_ADD;
                exp_lsu_req      = 1'd1;
                exp_lsu_we       = 1'd1;
                exp_lsu_size     = MEM_HALF;
              end
            3'b010:
              begin
                exp_ill_instr    = 1'd0;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_IMM_S;
                exp_alu_op       = ALU_ADD;
                exp_lsu_req      = 1'd1;
                exp_lsu_we       = 1'd1;
                exp_lsu_size     = MEM_WORD;
              end
            default:
                exp_ill_instr    = 1'd1;
          endcase
        end
      { BRANCH_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_EQ;
              end
            3'b001:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_NE;
              end
            3'b100:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_LT;
              end
            3'b101:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_GE;
              end
            3'b110:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_LTU;
              end
            3'b111:
              begin
                exp_ill_instr    = 1'd0;
                exp_branch       = 1'd1;
                exp_alu_op_a_sel = OP_A_RS1;
                exp_alu_op_b_sel = OP_B_RS2;
                exp_alu_op       = ALU_GEU;
              end
            default:
                exp_ill_instr    = 1'd1;
          endcase
        end
      { JAL_OPCODE, 2'b11 }:
        begin
          exp_ill_instr = 1'd0;
          exp_jal       = 1'd1;
          exp_gpr_we    = 1'd1;
        end
      { JALR_OPCODE, 2'b11 }:
        begin
          if( funct3 == 3'b000 ) begin
            exp_ill_instr = 1'd0;
            exp_jalr      = 1'd1;
            exp_gpr_we    = 1'd1;
          end
          else
            exp_ill_instr = 1'd1;
        end
      { LUI_OPCODE, 2'b11 }:
        begin
          exp_ill_instr    = 1'd0;
          exp_alu_op_a_sel = OP_A_ZERO;
          exp_alu_op_b_sel = OP_B_IMM_U;
          exp_alu_op       = ALU_ADD;
          exp_gpr_we       = 1'd1;
        end
      { AUIPC_OPCODE, 2'b11 }:
        begin
          exp_ill_instr    = 1'd0;
          exp_alu_op_a_sel = OP_A_CURR_PC;
          exp_alu_op_b_sel = OP_B_IMM_U;
          exp_alu_op       = ALU_ADD;
          exp_gpr_we       = 1'd1;
        end
      { SYSTEM_OPCODE, 2'b11 }:
        begin
          case( funct3 )
            3'b000:
              begin
                if( instr[31:28] != 4'b0011 )
                  exp_ill_instr = 1'd1;
                else begin
                  exp_ill_instr = 1'd0;
                  exp_mret      = 1'd1;
                  exp_wb_sel    = CSR_WB_DATA;
                end
              end
            3'b001:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RW;
                exp_wb_sel    = CSR_WB_DATA;
              end
            3'b010:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RS;
                exp_wb_sel    = CSR_WB_DATA;
              end
            3'b011:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RC;
                exp_wb_sel    = CSR_WB_DATA;
              end
            3'b101:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RW_IMM;
                exp_wb_sel    = CSR_WB_DATA;
              end
            3'b110:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RS_IMM;
                exp_wb_sel    = CSR_WB_DATA;
              end
            3'b111:
              begin
                exp_ill_instr = 1'd0;
                exp_csr_we    = 1'd1;
                exp_gpr_we    = 1'd1;
                exp_csr_op    = CSR_RC_IMM;
                exp_wb_sel    = CSR_WB_DATA;
              end
            default:
                exp_ill_instr = 1'd1;
          endcase
        end
      { FENCE_OPCODE, 2'b11 }:
        begin
          if( funct3 == 3'd0 )
            exp_ill_instr = 1'd0;
          else
            exp_ill_instr = 1'd1;
        end
      default:
        begin
          exp_ill_instr    = 1'd1;
          exp_csr_op       = CSR_ILL;
          exp_csr_we       = 1'd0;
          exp_branch       = 1'd0;
          exp_jalr         = 1'd0;
          exp_jal          = 1'd0;
          exp_lsu_req      = 1'd0;
          exp_lsu_we       = 1'd0;
          exp_lsu_size     = funct3;
          exp_alu_op_a_sel = OP_A_CURR_PC;
          exp_alu_op_b_sel = OP_B_INCR;
          exp_alu_op       = ALU_ADD;
          exp_gpr_we       = 1'd0;
          exp_mret         = 1'd0;
          exp_wb_sel       = EXEC_WB_RESULT;
        end
    endcase
  end

  ////////////////
  // Assertions //
  ////////////////

  ill_instr_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_ill_instr === ill_instr )
  )
  else begin
    err_cnt++;
    $error("\nInvalid ill_instr! Instructions = %32b; opcode = %7b; expected ill_instr = %1b; real ill_instr = %1b. Time: %t",
            instr, opcode, exp_ill_instr, ill_instr, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  csr_op_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_csr_op === csr_op )
  )
  else begin
    err_cnt++;
    $error("\nInvalid csr_op! Instructions = %32b; opcode = %7b; expected csr_op = %3b; real csr_op = %3b. Time: %t",
            instr, opcode, exp_csr_op, csr_op, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  csr_we_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_csr_we === csr_we )
  )
  else begin
    err_cnt++;
    $error("\nInvalid csr_we! Instructions = %32b; opcode = %7b; expected csr_we = %1b; real csr_we = %1b. Time: %t",
            instr, opcode, exp_csr_we, csr_we, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  branch_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_branch === branch )
  )
  else begin
    err_cnt++;
    $error("\nInvalid branch! Instructions = %32b; opcode = %7b; expected branch = %1b; real branch = %1b. Time: %t",
            instr, opcode, exp_branch, branch, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  jalr_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_jalr === jalr )
  )
  else begin
    err_cnt++;
    $error("\nInvalid jalr! Instructions = %32b; opcode = %7b; expected jalr = %1b; real jalr = %1b. Time: %t",
            instr, opcode, exp_jalr, jalr, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  jal_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_jal === jal )
  )
  else begin
    err_cnt++;
    $error("\nInvalid jal! Instructions = %32b; opcode = %7b; expected jal = %1b; real jal = %1b. Time: %t",
            instr, opcode, exp_jal, jal, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  lsu_req_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_lsu_req === lsu_req )
  )
  else begin
    err_cnt++;
    $error("\nInvalid lsu_req! Instructions = %32b; opcode = %7b; expected lsu_req = %1b; real lsu_req = %1b. Time: %t",
            instr, opcode, exp_lsu_req, lsu_req, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  lsu_we_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_lsu_we === lsu_we )
  )
  else begin
    err_cnt++;
    $error("\nInvalid lsu_we! Instructions = %32b; opcode = %7b; expected lsu_we = %1b; real lsu_we = %1b. Time: %t",
            instr, opcode, exp_lsu_we, lsu_we, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  lsu_size_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_lsu_size === lsu_size )
  )
  else begin
    err_cnt++;
    $error("\nInvalid lsu_size! Instructions = %32b; opcode = %7b; expected lsu_size = %3b; real lsu_size = %3b. Time: %t",
            instr, opcode, exp_lsu_size, lsu_size, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  alu_op_a_sel_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_alu_op_a_sel === alu_op_a_sel )
  )
  else begin
    err_cnt++;
    $error("\nInvalid alu_op_a_sel! Instructions = %32b; opcode = %7b; expected alu_op_a_sel = %2b; real alu_op_a_sel = %2b. Time: %t",
            instr, opcode, exp_alu_op_a_sel, alu_op_a_sel, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  alu_op_b_sel_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_alu_op_b_sel === alu_op_b_sel )
  )
  else begin
    err_cnt++;
    $error("\nInvalid alu_op_b_sel! Instructions = %32b; opcode = %7b; expected alu_op_a_sel = %3b; real alu_op_a_sel = %3b. Time: %t",
            instr, opcode, exp_alu_op_b_sel, alu_op_b_sel, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  alu_op_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_alu_op === alu_op )
  )
  else begin
    err_cnt++;
    $error("\nInvalid alu_op! Instructions = %32b; opcode = %7b; expected alu_op = %4b; real alu_op = %4b. Time: %t",
            instr, opcode, exp_alu_op, alu_op, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  gpr_we_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_gpr_we === gpr_we )
  )
  else begin
    err_cnt++;
    $error("\nInvalid gpr_we! Instructions = %32b; opcode = %7b; expected gpr_we = %1b; real gpr_we = %1b. Time: %t",
            instr, opcode, exp_gpr_we, gpr_we, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  mret_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_mret === mret )
  )
  else begin
    err_cnt++;
    $error("\nInvalid mret! Instructions = %32b; opcode = %7b; expected mret = %1b; real mret = %1b. Time: %t",
            instr, opcode, exp_mret, mret, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  wb_sel_check: assert property (
    @( negedge clk )
     disable iff( !rstn )
     ( exp_wb_sel === wb_sel )
  )
  else begin
    err_cnt++;
    $error("\nInvalid wb_sel! Instructions = %32b; opcode = %7b; expected wb_sel = %2b; real wb_sel = %2b. Time: %t",
            instr, opcode, exp_wb_sel, wb_sel, $time);
    if( err_cnt == 10 ) begin
      $display("\nTest has been stopped after 10 errors");
      $stop();
    end
  end

  /////////
  // DUT //
  /////////

  decoder DUT(
    .instr_i        ( instr        ),

    .ill_instr_o    ( ill_instr    ),

    .csr_op_o       ( csr_op       ),
    .csr_we_o       ( csr_we       ),

    .branch_o       ( branch       ),
    .jalr_o         ( jalr         ),
    .jal_o          ( jal          ),

    .lsu_req_o      ( lsu_req      ),
    .lsu_we_o       ( lsu_we       ),
    .lsu_size_o     ( lsu_size     ),

    .alu_op_a_sel_o ( alu_op_a_sel ),
    .alu_op_b_sel_o ( alu_op_b_sel ),
    .alu_op_o       ( alu_op       ),

    .gpr_we_o       ( gpr_we       ),
    .mret_o         ( mret         ),
    .wb_sel_o       ( wb_sel       )
  );

endmodule
