module mist_fetch_stage #(
  parameter INIT_IMEM = "program.mem"
)(
  input  logic        clk_i,
  input  logic        rstn_i,

  // From Write-back stage
  input  logic        jalr_wb_i,
  input  logic        branch_jal_wb_i,
  input  logic [31:0] offset_pc_wb_i,
  input  logic [31:0] offset_alu_wb_i,

  // From Hazard Unit
  input  logic        hu_stall_f_i,
  input  logic        hu_flush_f_i,

  // To Decode Stage
  output logic [31:0] instr_f_o,
  output logic [31:0] pc_cur_f_o
);

  logic [31:0] instr_cur;

  logic [31:0] pc_cur;
  logic [31:0] pc_nxt;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      pc_cur <= 32'd0;
    else
      pc_cur <= pc_nxt;
  end

  assign pc_nxt = ( jalr_wb_i       ) ? ( pc_cur + offset_alu_wb_i ):
                  ( branch_jal_wb_i ) ? ( pc_cur + offset_pc_wb_i  ):
                                        ( pc_cur + 32'd4           );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i ) begin
      instr_f_o  <= 32'd0;
      pc_cur_f_o <= 32'd0;
    end
    else if( hu_flush_f_i ) begin
      instr_f_o  <= 32'd0;
      pc_cur_f_o <= 32'd0;
    end
    else if( !hu_stall_f_i ) begin
      instr_f_o  <= instr_cur;
      pc_cur_f_o <= pc_cur;
    end
  end

  mist_instr_mem #(
    .INIT_IMEM(INIT_IMEM)
  ) f_imem (
    .read_addr_i ( pc_cur    ),
    .read_data_o ( instr_cur )
  );

endmodule
