module dma_fifo #(
  parameter int DATA_WIDTH = 32,
  parameter int DEPTH      = 16
)(
  input  logic                  clk,
  input  logic                  rst_n,

  input  logic                  push,
  input  logic [DATA_WIDTH-1:0] wdata,
  input  logic                  pop,
  output logic [DATA_WIDTH-1:0] rdata,

  output logic                  full,
  output logic                  empty
);
endmodule
