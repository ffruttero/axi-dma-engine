module apb_regs #(
  parameter int ADDR_WIDTH = 32
)(
  //APB Slave Interface
  apb_if.slave apb,
  //CONFIG outputs to DMA core:
  output logic [ADDR_WIDTH-1:0] src_addr_o,
  output logic [ADDR_WIDTH-1:0] dst_addr_o,
  output logic [31:0] length_o,
  output logic start_pulse_o,
  output logic irq_enable_o,
  //Status inputs from DMA core:
  input logic busy_i,
  input logic done_pulse_i,
  input logic error_pulse_i,
  //Sticky status output
  output logic done_sticky_o,
  output logic error_sticky_o,
  //IRQ output
  output logic irq_o
);

  localparam logic [5:0] ADDR_SRC     = 6'd0;
  localparam logic [5:0] ADDR_DST     = 6'd1;
  localparam logic [5:0] ADDR_LENGTH  = 6'd2;
  localparam logic [5:0] ADDR_CONTROL = 6'd3;
  localparam logic [5:0] ADDR_STATUS  = 6'd4;

  logic secure_access, apb_access, wr_en, rd_en, irq_enable_r, done_sticky_r, error_sticky_r;
  logic [ADDR_WIDTH-1:0] src_addr_r, dst_addr_r;
  logic [5:0] addr; //Gives us space up to 0xFC (64 registers)
  logic [31:0] length_r;

  assign apb_access = apb.penable && apb.psel;
  assign secure_access = apb_access && !apb.pprot[1];
  assign wr_en = secure_access && apb.pwrite;
  assign rd_en = secure_access && !apb.pwrite;
  assign addr = apb.paddr[7:2];
  assign src_addr_o = src_addr_r;
  assign dst_addr_o = dst_addr_r;
  assign length_o = length_r;
  assign irq_enable_o = irq_enable_r;
  assign done_sticky_o = done_sticky_r;
  assign error_sticky_o = error_sticky_r;
  assign irq_o = irq_enable_o && (error_sticky_o || done_sticky_o);
  assign apb.pready = 1'b1;
  assign apb.pslverr = apb_access && apb.pready && apb.pprot[1]; //Error when trying to perform non-secure access

  always_ff @(posedge apb.pclk or negedge apb.prsetn) begin
  if (!apb.prsetn) begin
    src_addr_r   <= '0;
    dst_addr_r   <= '0;
    length_r     <= '0;
    irq_enable_r <= 1'b0;
    done_sticky_r <= 1'b0;
    error_sticky_r <= 1'b0;
    start_pulse_o <= 1'b0;
  end else begin
    // default pulses to 0
    start_pulse_o <= 1'b0;
    if (wr_en) begin
      unique case (addr)
        ADDR_SRC: if(!busy_i) src_addr_r <= apb.pwdata;
        ADDR_DST: if(!busy_i) dst_addr_r <= apb.pwdata; //0x04 >> 2 --> addr = paddr[7:2]
        ADDR_LENGTH: if(!busy_i) length_r <= apb.pwdata;
        ADDR_CONTROL: begin
          irq_enable_r <= apb.pwdata[1];      // can be changed anytime (or gate with !busy if you want)
          if (!busy_i && apb.pwdata[0])
          start_pulse_o <= 1'b1;            // pulse only when START=1 and not busy
        end
        ADDR_STATUS: begin
          if (apb.pwdata[1] == 1'b1) done_sticky_r <= 1'b0;
          if (apb.pwdata[2] == 1'b1) error_sticky_r <= 1'b0;
        end
      endcase
    end
    //Done/error pulses have higher prio than clear.
    if(done_pulse_i) done_sticky_r <= 1'b1; 
    if(error_pulse_i) error_sticky_r <= 1'b1;
  end
end

always_comb begin
  apb.prdata = 32'h0;
  if (rd_en) begin
    unique case (addr)
      ADDR_SRC:     apb.prdata = src_addr_r;
      ADDR_DST:     apb.prdata = dst_addr_r;
      ADDR_LENGTH:  apb.prdata = length_r;
      ADDR_CONTROL: apb.prdata = {30'b0, irq_enable_r, 1'b0};
      ADDR_STATUS:  apb.prdata = {28'b0, irq_o, error_sticky_r, done_sticky_r, busy_i};
      default:      apb.prdata = 32'h0;
    endcase
  end
end

endmodule
