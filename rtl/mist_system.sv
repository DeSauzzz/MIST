module mist_system #(
  parameter INIT_IMEM = "instr.mem",
  parameter INIT_DMEM = "data.mem"
)(
  input logic clk_i,
  input logic rstn_i
);

  localparam [31:0] TIMER_ADDR = 32'h0001_0000;

  // Instruction Memory Interface
  logic [31:0] instr_addr;
  logic [31:0] instr_data;

  // Data Memory Interface
  logic [31:0] mem_addr;
  logic [31:0] mem_wd;
  logic [31:0] mem_rd;
  logic [3:0]  mem_be;
  logic        mem_req;
  logic        mem_we;
  logic        mem_ack;

  // TODO: Optimize it
  logic [31:0] timer_dat;
  logic [31:0] dat2core;

  assign dat2core = ( mem_addr == TIMER_ADDR ) ? ( timer_dat ) : ( mem_rd );

  mist_core core (
    .clk_i        ( clk_i      ),
    .rstn_i       ( rstn_i     ),

    // Interrupt Controller Interface
    // TODO

    // Instruction Memory Interface
    .instr_i      ( instr_data ),
    .instr_addr_o ( instr_addr ),

    // Data Memory Interface
    .mem_ack_i    ( mem_ack    ),
    .mem_rd_i     ( dat2core   ),

    .mem_addr_o   ( mem_addr   ),
    .mem_wd_o     ( mem_wd     ),
    .mem_be_o     ( mem_be     ),
    .mem_req_o    ( mem_req    ),
    .mem_we_o     ( mem_we     )
  );

  mist_data_mem #(
    .INIT_DMEM(INIT_DMEM)
  ) dmem (
    .clk_i        ( clk_i      ),
    .rstn_i       ( rstn_i     ),

    .mem_be_i     ( mem_be     ),
    .mem_req_i    ( mem_req    ),
    .mem_we_i     ( mem_we     ),
    .mem_addr_i   ( mem_addr   ),
    .mem_wd_i     ( mem_wd     ),

    .mem_rd_o     ( mem_rd     ),
    .mem_ack_o    ( mem_ack    )
  );

  mist_instr_mem #(
    .INIT_IMEM(INIT_IMEM)
  ) imem (
    .read_addr_i  ( instr_addr ),
    .read_data_o  ( instr_data )
  );

  mist_timer timer(
    .clk_i   ( clk_i     ),
    .rstn_i  ( rstn_i    ),
    .timer_o ( timer_dat )
  );

endmodule
