module mist_fetch_stage (
  input  logic        clk_i,
  input  logic        rstn_i,

  // From execute stage
  input  logic        alu_flag_e_i,
  input  logic        branch_e_i,
  input  logic        jalr_e_i,
  input  logic        jal_e_i,
  input  logic [31:0] offset_pc_e_i,

  // From Hazard Unit
  input  logic        hu_stall_f_i,
  input  logic        hu_flush_f_i,

  // From Instruction Memory
  input  logic [31:0] sys_instr_i,

  // To Instruction Memory
  output logic [31:0] sys_addr_o,

  // To Decode Stage
  output logic [31:0] instr_f_o,
  output logic [31:0] pc_cur_f_o
);

  logic [31:0] pc_cur;
  logic [31:0] pc_nxt;

  logic [31:0] nop;
  assign       nop = 32'h00000013; // addi x0, x0, x0 used like no operation

  assign sys_addr_o = pc_cur;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      pc_cur <= 32'd0;
    else if( !hu_stall_f_i )
      pc_cur <= pc_nxt;
  end

  assign pc_nxt = ( ( jalr_e_i ) || ( jal_e_i ) || ( branch_e_i && alu_flag_e_i ) ) ? ( offset_pc_e_i  ):
                                                                                      ( pc_cur + 32'd4 );

  // Next PC logic
  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      pc_cur_f_o <= 32'd0;
    else if( !hu_stall_f_i )
      pc_cur_f_o <= pc_cur;
  end

  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      instr_f_o  <= 32'd0;
    end
    else if( ( hu_flush_f_i ) && !( hu_stall_f_i ) )
      instr_f_o  <= nop;
    else if( !hu_stall_f_i ) begin
      instr_f_o  <= sys_instr_i;
    end
  end

endmodule
