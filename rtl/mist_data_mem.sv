import mist_mem_pkg::DATA_MEM_BYTE_SIZE;
import mist_mem_pkg::DATA_MEM_WORD_SIZE;

module mist_data_mem#(
  parameter INIT_DMEM = ""
)(
  input  logic        clk_i,
  input  logic        rstn_i,

  input  logic [3:0]  mem_be_i,
  input  logic        mem_req_i,
  input  logic        mem_we_i,
  input  logic [31:0] mem_addr_i,
  input  logic [31:0] mem_wd_i,

  output logic [31:0] mem_rd_o,
  output logic        mem_ack_o
);

  logic [31:0] memory [DATA_MEM_WORD_SIZE];

  initial begin
    $readmemh(INIT_DMEM, memory);
  end

  // Acknowledge from memory
  logic mem_ack_ff;

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      mem_ack_ff <= 1'd0;
    else if( mem_ack_ff )
      mem_ack_ff <= 1'd0;
    else if( mem_req_i )
      mem_ack_ff <= 1'd1;
  end

  // Memory logic
  logic [31:0] mem_rd_ff;
  logic [31:0] mem_addr_sh;

  assign mem_addr_sh = ( mem_addr_i[31:0] >> 2 );

  always_ff @( posedge clk_i ) begin
    if( ( mem_req_i ) && !( mem_we_i ) )
      mem_rd_ff <= memory[mem_addr_sh];
    else if( ( mem_req_i ) && ( mem_we_i ) ) begin
      if( mem_be_i[0] ) memory[mem_addr_sh][7:  0] <= mem_wd_i[7:  0];
      if( mem_be_i[1] ) memory[mem_addr_sh][15: 8] <= mem_wd_i[15: 8];
      if( mem_be_i[2] ) memory[mem_addr_sh][23:16] <= mem_wd_i[23:16];
      if( mem_be_i[3] ) memory[mem_addr_sh][31:24] <= mem_wd_i[31:24];
    end
  end

  assign mem_ack_o   = mem_ack_ff;
  assign mem_rd_o    = mem_rd_ff;

endmodule
