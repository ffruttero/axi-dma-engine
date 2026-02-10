module dma_reader #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
)(
  input  logic                  clk,
  input  logic                  rst_n,

  // Control from FSM
  input  logic                  read_enable,
  input  logic [ADDR_WIDTH-1:0] current_src_addr,
  input  logic [31:0]           current_burst_len,

  // FIFO
  input  logic                  fifo_full,
  output logic                  fifo_push,
  output logic [DATA_WIDTH-1:0] fifo_wdata,

  // AXI Read Address Channel
  output logic [ADDR_WIDTH-1:0] araddr,
  output logic [7:0]            arlen,
  output logic [2:0]            arsize,
  output logic [1:0]            arburst,
  output logic                  arvalid,
  input  logic                  arready,

  // AXI Read Data Channel
  input  logic [DATA_WIDTH-1:0] rdata,
  input  logic [1:0]            rresp,
  input  logic                  rlast,
  input  logic                  rvalid,
  output logic                  rready,

  // Status
  output logic                  read_done,
  output logic                  read_error
);

  // ------------------------------------------------------------
  // Internal state
  // ------------------------------------------------------------
  logic         pending;         // Tracks whether a burst is active
  logic [7:0]   beats_expected;  // Total beats this burst
  logic [7:0]   beats_received;  // Counter of received beats
  logic         ar_sent;
  logic         error_seen;

  localparam int BEAT_BYTES = DATA_WIDTH / 8;

  // ------------------------------------------------------------
  // Address Phase Control
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_sent <= 0;
    end else if (read_enable) begin
      ar_sent <= 0;
    end else if (!ar_sent && arvalid && arready) begin
      ar_sent <= 1;
    end
  end

  //arvalid once per read_enable. ar_sent deasserts it after succesfull handshake:
  assign arvalid = (read_enable && !ar_sent);
  assign araddr  = current_src_addr;
  assign arlen   = (beats_expected > 0) ? (beats_expected - 1) : 0;
  assign arsize  = $clog2(BEAT_BYTES); // typically 2 for 32-bit
  assign arburst = 2'b01;              // INCR

  // ------------------------------------------------------------
  // Burst Size Conversion
  // ------------------------------------------------------------
  always_comb begin
    beats_expected = current_burst_len / BEAT_BYTES;
    if (beats_expected == 0)
      beats_expected = 1; // para garantizar al menos un beat, y evitar arlen = -1.
  end

  // ------------------------------------------------------------
  // Data Phase Handling
  // ------------------------------------------------------------
  assign rready     = !fifo_full;
  assign fifo_wdata = rdata;
  assign fifo_push  = rvalid && rready;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      beats_received <= 0;
    end else if (rvalid && rready) begin
      beats_received <= beats_received + 1;
    end else if (!pending) begin
      beats_received <= 0;
    end
  end

  // ------------------------------------------------------------
  // Pending burst tracker
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      pending <= 0;
    else if (read_enable)
      pending <= 1;
    else if (rvalid && rready && rlast)
      pending <= 0;
  end

  // ------------------------------------------------------------
  // Error tracking
  // ------------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      error_seen <= 0;
    else if (read_enable)
      error_seen <= 0;
    else if (rvalid && (rresp != 2'b00))
      error_seen <= 1;
  end

  // ------------------------------------------------------------
  // Completion
  // ------------------------------------------------------------
  assign read_done  = (rvalid && rready && rlast);
  assign read_error = error_seen;

endmodule
