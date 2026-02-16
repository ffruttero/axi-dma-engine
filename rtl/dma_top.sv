module dma_top #(
  parameter int DATA_WIDTH = 32,
  parameter int ADDR_WIDTH = 32,
  parameter int FIFO_DEPTH = 16,
  parameter int BURST_SIZE = 16
)(
  // Global
  input  logic                   clk,
  input  logic                   rst_n,

  // APB Slave (discrete pins)
  input  logic [ADDR_WIDTH-1:0]  paddr,
  input  logic [2:0]             pprot,
  input  logic                   psel,
  input  logic                   penable,
  input  logic                   pwrite,
  input  logic [DATA_WIDTH-1:0]  pwdata,
  output logic [DATA_WIDTH-1:0]  prdata,
  output logic                   prready,
  output logic                   pslverr,

  // AXI Master Read Address Channel
  output logic [ADDR_WIDTH-1:0]  araddr,
  output logic [7:0]             arlen,
  output logic [2:0]             arsize,
  output logic [1:0]             arburst,
  output logic                   arvalid,
  input  logic                   arready,

  // AXI Master Read Data Channel
  input  logic [DATA_WIDTH-1:0]  rdata,
  input  logic [1:0]             rresp,
  input  logic                   rlast,
  input  logic                   rvalid,
  output logic                   rready,

  // AXI Master Write Address Channel
  output logic [ADDR_WIDTH-1:0]  awaddr,
  output logic [7:0]             awlen,
  output logic [2:0]             awsize,
  output logic [1:0]             awburst,
  output logic                   awvalid,
  input  logic                   awready,

  // AXI Master Write Data Channel
  output logic [DATA_WIDTH-1:0]  wdata,
  output logic [(DATA_WIDTH/8)-1:0] wstrb,
  output logic                   wlast,
  output logic                   wvalid,
  input  logic                   wready,

  // AXI Master Write Response Channel
  input  logic [1:0]             bresp,
  input  logic                   bvalid,
  output logic                   bready,

  // IRQ Output
  output logic                   irq
);

  // ------------------------------------------------------------
  // APB interface bridge (pins <-> interface)
  // ------------------------------------------------------------
  apb_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) apb (
    .pclk   (clk),
    .prsetn (rst_n)
  );

  // drive interface inputs from top pins
  assign apb.paddr   = paddr;
  assign apb.pprot   = pprot;
  assign apb.psel    = psel;
  assign apb.penable = penable;
  assign apb.pwrite  = pwrite;
  assign apb.pwdata  = pwdata;

  // drive top outputs from interface outputs
  assign prdata  = apb.prdata;
  assign prready = apb.pready;
  assign pslverr = apb.pslverr;

  // ------------------------------------------------------------
  // Config from APB regs
  // ------------------------------------------------------------
  logic [ADDR_WIDTH-1:0] src_addr;
  logic [ADDR_WIDTH-1:0] dst_addr;
  logic [31:0]           transfer_len;
  logic                  start_pulse;
  logic                  irq_enable;

  // Status (core-level)
  logic busy;
  logic done_lvl, error_lvl;       // levels from dma_ctrl (if that’s what it currently outputs)
  logic done_pulse, error_pulse;   // pulses into apb_regs

  // Edge detect to create pulses (one cycle) for regblock. DMA is sending level outputs
  logic done_lvl_d, error_lvl_d;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      done_lvl_d  <= 1'b0;
      error_lvl_d <= 1'b0;
    end else begin
      done_lvl_d  <= done_lvl;
      error_lvl_d <= error_lvl;
    end
  end
  assign done_pulse  = done_lvl  & ~done_lvl_d;
  assign error_pulse = error_lvl & ~error_lvl_d;

  apb_regs #(
    .ADDR_WIDTH(ADDR_WIDTH)
  ) u_apb_regs (
    .apb            (apb),

    .src_addr_o     (src_addr),
    .dst_addr_o     (dst_addr),
    .length_o       (transfer_len),
    .start_pulse_o  (start_pulse),
    .irq_enable_o   (irq_enable),

    .busy_i         (busy),
    .done_pulse_i   (done_pulse),
    .error_pulse_i  (error_pulse),

    .done_sticky_o  (/* optional export */),
    .error_sticky_o (/* optional export */),
    .irq_o          (irq)
  );

  // ------------------------------------------------------------
  // FIFO between reader and writer
  // ------------------------------------------------------------
  logic                  fifo_full, fifo_empty;
  logic                  fifo_push, fifo_pop;
  logic [DATA_WIDTH-1:0] fifo_wdata, fifo_rdata;

  dma_fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH     (FIFO_DEPTH)
  ) u_dma_fifo (
    .clk   (clk),
    .rst_n (rst_n),
    .push  (fifo_push),
    .wdata (fifo_wdata),
    .pop   (fifo_pop),
    .rdata (fifo_rdata),
    .full  (fifo_full),
    .empty (fifo_empty)
  );

  // ------------------------------------------------------------
  // DMA control / FSM
  // ------------------------------------------------------------
  logic                  read_enable, write_enable;
  logic [ADDR_WIDTH-1:0] current_src_addr, current_dst_addr;
  logic [31:0]           current_burst_len;
  logic                  read_done, write_done;
  logic                  read_error, write_error;

  dma_ctrl #(
    .BURST_SIZE(BURST_SIZE)
  ) u_dma_ctrl (
    .clk              (clk),
    .rst_n            (rst_n),
    .start_pulse      (start_pulse),

    .src_addr         (src_addr),
    .dst_addr         (dst_addr),
    .length           (transfer_len),

    .fifo_full        (fifo_full),
    .fifo_empty       (fifo_empty),

    .read_done        (read_done),
    .write_done       (write_done),
    .read_error       (read_error),
    .write_error      (write_error),

    .read_enable      (read_enable),
    .write_enable     (write_enable),
    .current_src_addr (current_src_addr),
    .current_dst_addr (current_dst_addr),
    .current_burst_len(current_burst_len),

    .busy             (busy),
    .done             (done_lvl),     // if your ctrl outputs level
    .error            (error_lvl)     // if your ctrl outputs level
  );

  // ------------------------------------------------------------
  // DMA Writer (FIFO -> AXI W)
  // ------------------------------------------------------------
  dma_writer #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_dma_writer (
    .clk              (clk),
    .rst_n            (rst_n),

    .write_enable     (write_enable),
    .current_dst_addr (current_dst_addr),
    .current_burst_len(current_burst_len),

    .fifo_empty       (fifo_empty),
    .fifo_pop         (fifo_pop),
    .fifo_rdata       (fifo_rdata),

    .awaddr           (awaddr),
    .awlen            (awlen),
    .awsize           (awsize),
    .awburst          (awburst),
    .awvalid          (awvalid),
    .awready          (awready),

    .wdata            (wdata),
    .wstrb            (wstrb),
    .wlast            (wlast),
    .wvalid           (wvalid),
    .wready           (wready),

    .bresp            (bresp),
    .bvalid           (bvalid),
    .bready           (bready),

    .write_done       (write_done),
    .write_error      (write_error)
  );

  // ------------------------------------------------------------
  // DMA Reader (AXI R -> FIFO)
  // ------------------------------------------------------------
  dma_reader #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_dma_reader (
    .clk              (clk),
    .rst_n            (rst_n),

    .read_enable      (read_enable),
    .current_src_addr (current_src_addr),
    .current_burst_len(current_burst_len),

    .fifo_full        (fifo_full),
    .fifo_push        (fifo_push),
    .fifo_wdata       (fifo_wdata),

    .araddr           (araddr),
    .arlen            (arlen),
    .arsize           (arsize),
    .arburst          (arburst),
    .arvalid          (arvalid),
    .arready          (arready),

    .rdata            (rdata),
    .rresp            (rresp),
    .rlast            (rlast),
    .rvalid           (rvalid),
    .rready           (rready),

    .read_done        (read_done),
    .read_error       (read_error)
  );

endmodule
