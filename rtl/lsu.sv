import mem_pkg::*;

module lsu(
  input  logic        clk_i,
  input  logic        rstn_i,

  // Core Side
  input  logic [2:0]  lsu_size_i,
  input  logic        lsu_req_i,
  input  logic        lsu_we_i,
  input  logic [31:0] lsu_addr_i,
  input  logic [31:0] lsu_wd_i,
  output logic [31:0] lsu_rd_o,

  // Memory Side
  output logic [3:0]  mem_be_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_addr_o,
  output logic [31:0] mem_wd_o,
  input  logic [31:0] mem_rd_i,
  input  logic        mem_ack_i,

  // Control and status signals
  output logic        lsu_stall_req_o
);

  enum logic [1:0] {
    LSU_IDLE_S,
    LSU_MEM_S,
    LSU_ACK_S
  } state_lsu, next_state_lsu;

  logic [31:0] lsu_rd_ff;

  assign mem_req_o       = ( lsu_req_i ) && ( state_lsu == LSU_MEM_S ) &&
                           ( lsu_size_i inside { MEM_BYTE, MEM_HALF, MEM_WORD, MEM_BYTE_U, MEM_HALF_U } );
  assign mem_we_o        = ( lsu_we_i   );

  assign lsu_stall_req_o = ( state_lsu == LSU_MEM_S );

  always_comb begin
    case( lsu_size_i )
      MEM_WORD: mem_be_o = 4'b1111;
      MEM_HALF: mem_be_o = ( lsu_addr_i[1] == 1'd1 ) ? ( 4'b1100 ) : ( 4'b0011 );
      MEM_BYTE: mem_be_o = 4'b0001 << lsu_addr_i[1:0];
      default:  mem_be_o = 4'b0000;
    endcase
  end

  always_comb begin
    case( lsu_size_i )
      MEM_WORD:   mem_addr_o = { lsu_addr_i[31:2], 2'b00 };
      MEM_HALF,
      MEM_HALF_U: mem_addr_o = { lsu_addr_i[31:1], 1'b0  };
      MEM_BYTE,
      MEM_BYTE_U: mem_addr_o = lsu_addr_i;
      default:    mem_addr_o = 32'd0;
    endcase
  end

  always_comb begin
    case( lsu_size_i )
      MEM_BYTE: mem_wd_o = { 4{ lsu_wd_i[7:0]  } };
      MEM_HALF: mem_wd_o = { 2{ lsu_wd_i[15:0] } };
      MEM_WORD: mem_wd_o = lsu_wd_i;
      default:  mem_wd_o = 32'd0;
    endcase
  end

  always_comb begin
    case( lsu_size_i )
      MEM_BYTE:   lsu_rd_o = { { 24{lsu_rd_ff[7]}  }, lsu_rd_ff[7:0]  };
      MEM_BYTE_U: lsu_rd_o = { 24'd0, lsu_rd_ff[7:0]  };
      MEM_HALF:   lsu_rd_o = { { 16{lsu_rd_ff[15]} }, lsu_rd_ff[15:0] };
      MEM_HALF_U: lsu_rd_o = { 16'd0, lsu_rd_ff[15:0] };
      MEM_WORD:   lsu_rd_o = lsu_rd_ff;
      default:    lsu_rd_o = 32'd0;
    endcase
  end

  ////////////////
  // Datakeeper //
  ////////////////

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      lsu_rd_ff <= 32'd0;
    else if( ( mem_ack_i ) && !( lsu_we_i ) )
      lsu_rd_ff <= mem_rd_i;
  end

  ///////////////////////////
  // FSM for Memory Access //
  ///////////////////////////

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      state_lsu <= LSU_IDLE_S;
    else
      state_lsu <= next_state_lsu;
  end

  always_comb begin
    case( state_lsu )
      LSU_IDLE_S: next_state_lsu = ( lsu_req_i ) ? ( LSU_MEM_S ) : ( state_lsu );
      LSU_MEM_S:  next_state_lsu = ( mem_ack_i ) ? ( LSU_ACK_S ) : ( state_lsu );
      LSU_ACK_S:  next_state_lsu = LSU_IDLE_S;
      default:    next_state_lsu = LSU_IDLE_S;
    endcase
  end

endmodule
