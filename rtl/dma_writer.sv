module dma_writer #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
)(
  input  logic                      clk,
  input  logic                      rst_n,
  // Control from FSM
  input  logic                      write_enable,         // Triggers a new write burst
  input  logic [ADDR_WIDTH-1:0]     current_dst_addr,     // Address to write to
  input  logic [31:0]               current_burst_len,    // Bytes to write
  // FIFO interface (data source)
  input  logic                      fifo_empty,
  output logic                      fifo_pop,
  input  logic [DATA_WIDTH-1:0]     fifo_rdata,
  // AXI Write Address Channel
  output logic [ADDR_WIDTH-1:0]     awaddr,
  output logic [7:0]                awlen,
  output logic [2:0]                awsize,
  output logic [1:0]                awburst,
  output logic                      awvalid,
  input  logic                      awready,
  // AXI Write Data Channel
  output logic [DATA_WIDTH-1:0]     wdata,
  output logic [(DATA_WIDTH/8)-1:0] wstrb,
  output logic                      wlast,
  output logic                      wvalid,
  input  logic                      wready,
  // AXI Write Response Channel
  input  logic [1:0]                bresp,
  input  logic                      bvalid,
  output logic                      bready,
  // Completion and error
  output logic                      write_done,   // High for 1 cycle when burst ends
  output logic                      write_error   // Sticky high on BRESP error
);
  // ------------------------------------------------------------
  // Internal state
  // ------------------------------------------------------------
  logic         pending;         // Tracks whether a burst is active
  logic [7:0]   beats_expected;  // Total beats this burst
  logic [7:0]   beats_sent;  // Counter of sent beats
  logic         burst_active;
  logic         aw_sent;
  logic         error_seen;

  localparam int BEAT_BYTES = DATA_WIDTH / 8;

  //awvalid once per write_enable. aw_sent will deassert it
  assign awvalid = (write_enable && !aw_sent);
  assign awaddr = current_dst_addr;
  assign awlen = (beats_expected > 0) ? (beats_expected - 1) : 0;
  assign awsize = $clog2(BEAT_BYTES);
  assign awburst = 2'b01; //INCR

  // ------------------------------------------------------------
  // Address Phase Control
  // ------------------------------------------------------------
  always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n) begin
      aw_sent <= 0;
    end else if (write_enable) begin
      aw_sent <= 0;
    end else if (awvalid && awready && !aw_sent) begin
      aw_sent <= 1;
    end
  end
  // ------------------------------------------------------------
  // Burst Size Conversion
  // ------------------------------------------------------------
  always_comb begin
    beats_expected = current_burst_len / BEAT_BYTES;
    if (beats_expected == 0)
      beats_expected = 1; // para garantizar al menos un beat, y evitar arlen = -1.
  end

  // ------------------------------------------------------------
  // Data Phase Handling (W)
  // ------------------------------------------------------------
  assign fifo_pop = wvalid && wready;
  assign wdata = fifo_rdata;
  assign wlast = (beats_sent == beats_expected - 1);
  assign wstrb = '1;
  assign burst_active = (beats_sent < beats_expected);
  assign wvalid = burst_active && !fifo_empty;


  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      beats_sent <= 0;
    end else if (write_enable) begin
      beats_sent <= 0;
    end else if (wvalid && wready) begin
      beats_sent <= beats_sent + 1;
    end
  end
  // ------------------------------------------------------------
  // Write Response Channel (B)
  // ------------------------------------------------------------
  assign bready = 1'b1; //Always ready to accept write response

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      write_done <= 0;
    end else if (write_enable) begin
      write_done <= 0;
    end else if (bvalid && bready) begin
      write_done <= 1;
    end
  end

  assign write_error = error_seen;
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      error_seen <= 0;
    end else if (write_enable) begin
      error_seen <= 0;
    end else if (bvalid && (bresp != 2'b00)) begin
      error_seen <= 1;
    end
  end

endmodule
