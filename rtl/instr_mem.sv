import mem_pkg::INSTR_MEM_WORD_SIZE;
import mem_pkg::INSTR_MEM_BYTE_SIZE;

module instr_mem(
  input  logic [31:0] read_addr_i,
  output logic [31:0] read_data_o
);

  logic [31:0] ROM [INSTR_MEM_WORD_SIZE];

  initial begin
    $readmemh("program.mem", ROM);
  end

  assign read_data_o = ROM[read_addr_i[$clog2(INSTR_MEM_BYTE_SIZE)-1:2]];

endmodule
