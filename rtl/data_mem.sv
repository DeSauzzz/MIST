import mem_pkg::DATA_MEM_BYTE_SIZE;
import mem_pkg::DATA_MEM_WORD_SIZE;

module data_mem(
  input  logic clk_i,
  input  logic rstn_i,

  input  logic [3:0]  mem_be_i,
  input  logic        mem_req_i,
  input  logic        mem_we_i,
  input  logic [31:0] mem_addr_i,
  input  logic [31:0] mem_wd_i,

  output logic [31:0] mem_rd_o,
  output logic        mem_ack_o
);

  logic [31:0] memory [DATA_MEM_WORD_SIZE];

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

  // Select data that will be written to memory
  logic [31:0] wr_data;
  always_comb begin
    case( mem_be_i )
      4'b1111: wr_data = mem_wd_i;
      4'b0011: wr_data = mem_wd_i[15: 0];
      4'b1100: wr_data = mem_wd_i[31:16];
      4'b0001: wr_data = mem_wd_i[7:  0];
      4'b0010: wr_data = mem_wd_i[15: 8];
      4'b0100: wr_data = mem_wd_i[24:16];
      4'b1000: wr_data = mem_wd_i[31:25];
      default: wr_data = 32'd0;
    endcase
  end

  // Memory logic
  logic [31:0] rd_data_ff;

  always_ff @( posedge clk_i ) begin
    if( ( mem_req_i ) && !( mem_we_i ) )
      rd_data_ff <= memory[mem_addr_i];
    else if( ( mem_req_i ) && ( mem_we_i ) )
      memory[mem_addr_i] <= wr_data;
  end

  assign mem_ack_o   = mem_ack_ff;
  assign read_data_o = rd_data_ff;

endmodule
