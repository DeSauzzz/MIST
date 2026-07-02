import mist_mem_pkg::INSTR_MEM_WORD_SIZE;
import mist_mem_pkg::INSTR_MEM_BYTE_SIZE;

module mist_instr_mem#(
  parameter INIT_IMEM = ""
)(
  input  logic [31:0] read_addr_i,
  output logic [31:0] read_data_o
);

  logic [31:0] ROM [INSTR_MEM_WORD_SIZE];

  initial begin
    $readmemh(INIT_IMEM, ROM);
  end

  assign read_data_o = ROM[read_addr_i[$clog2(INSTR_MEM_BYTE_SIZE)-1:2]];

endmodule
