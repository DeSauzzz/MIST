module mist_irq_ctrl(
  input  logic        clk_i,
  input  logic        rstn_i,
  input  logic        exception_i,
  input  logic [15:0] irq_req_i,
  input  logic [15:0] mie_i,
  input  logic        mret_i,

  output logic [15:0] irq_ret_o,
  output logic [31:0] irq_cause_o,
  output logic        irq_o
);

  // Exception tracking register
  logic exc_h_ff;
  logic exc_h_set;
  logic exc_h_rst;

  assign exc_h_set =  ( exception_i ) || ( exc_h_ff  );
  assign exc_h_rst =  ( mret_i      );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      exc_h_ff <= 1'd0;
    else
      exc_h_ff <= ( exc_h_set ) && !( exc_h_rst );
  end

  // Interrupt tracking register
  logic irq_h_ff;
  logic irq_h_set;
  logic irq_h_rst;

  assign irq_h_rst = ( mret_i ) && !( exc_h_set );
  assign irq_h_set = ( irq_o  ) ||  ( irq_h_ff  );

  always_ff @( posedge clk_i ) begin
    if( !rstn_i )
      irq_h_ff <= 1'd0;
    else
      irq_h_ff <= ( irq_h_set ) && !( irq_h_rst );
  end

  logic        ds_ready;
  assign       ds_ready = !( ( exc_h_set ) || ( irq_h_ff ) );

  logic [15:0] irq_mask;
  assign       irq_mask = ( irq_req_i ) & ( mie_i );

  mist_daisy_chain daisy_chain(
    .clk_i        ( clk_i       ),
    .rstn_i       ( rstn_i      ),
    .masked_irq_i ( irq_mask    ),
    .irq_ret_i    ( irq_h_rst   ),
    .ready_i      ( ds_ready    ),
    .irq_ret_o    ( irq_ret_o   ),
    .irq_cause_o  ( irq_cause_o ),
    .irq_o        ( irq_o       )
  );

endmodule
