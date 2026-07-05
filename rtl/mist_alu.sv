import mist_alu_pkg::*;

module mist_alu(
  input  logic [31:0] op_a_i,
  input  logic [31:0] op_b_i,
  input  logic [3:0]  alu_op_i,

  output logic        flag_o,
  output logic [31:0] result_o
);

  logic  arith_op;
  logic  cmp_op;

  assign arith_op = ( alu_op_i inside { [ ALU_ADD:ALU_SLTU ] } );
  assign cmp_op   = ( alu_op_i inside { [ ALU_EQ:ALU_GEU   ] } );

  always_comb begin
    if( arith_op ) begin
      case( alu_op_i )
        ALU_ADD:  result_o = op_a_i +    op_b_i;
        ALU_SUB:  result_o = op_a_i -    op_b_i;
        ALU_XOR:  result_o = op_a_i ^    op_b_i;
        ALU_OR:   result_o = op_a_i |    op_b_i;
        ALU_AND:  result_o = op_a_i &    op_b_i;
        ALU_SLL:  result_o = op_a_i <<   op_b_i[4:0];
        ALU_SRL:  result_o = op_a_i >>   op_b_i[4:0];
        ALU_SRA:  result_o = op_a_i >>>  op_b_i[4:0];
        ALU_SLT:  result_o = ( $signed(op_a_i) < $signed(op_b_i) ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_SLTU: result_o = ( op_a_i < op_b_i                   ) ? ( 1'd1 ) : ( 1'd0 );
        default:  result_o = 32'd0;
      endcase
    end
    else
      result_o = 32'd0;
  end

  always_comb begin
    if( cmp_op ) begin
      case( alu_op_i )
        ALU_EQ:  flag_o = ( op_a_i == op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_NE:  flag_o = ( op_a_i != op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_LT:  flag_o = ( op_a_i <  op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_GE:  flag_o = ( op_a_i >  op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_LTU: flag_o = ( op_a_i <= op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        ALU_GEU: flag_o = ( op_a_i >= op_b_i ) ? ( 1'd1 ) : ( 1'd0 );
        default: flag_o = 1'd0;
      endcase
    end
    else
      flag_o = 1'd0;
  end

endmodule
