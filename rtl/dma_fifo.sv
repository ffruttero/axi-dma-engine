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

localparam int PTR_WIDTH = $clog2(DEPTH);

logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
logic [PTR_WIDTH-1:0] read_ptr, write_ptr;

// -------------------------
  // Combinational full/empty
  // -------------------------
  logic [PTR_WIDTH-1:0] next_wr_ptr, next_rd_ptr;

  assign next_wr_ptr = (write_ptr == DEPTH-1) ? 0 : write_ptr + 1;
  assign next_rd_ptr = (read_ptr == DEPTH-1) ? 0 : read_ptr + 1;

  always_comb begin
    full  = (next_wr_ptr == read_ptr);
    empty = (write_ptr == read_ptr);
  end

// -------------------------
  // Sequential pointer update
  // -------------------------
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    read_ptr <= 0;
    write_ptr <= 0;
  end else begin 
    if (push && !full) begin
      write_ptr <= next_wr_ptr; //When an item is written to FIFO, the write pointer is incremented
    end if (pop && !empty) begin
      read_ptr <= next_rd_ptr; //When an item is read from the FIFO, the read pointer is incremented
    end
  end
end

// -------------------------
// Memory write on push
// -------------------------
always_ff @( posedge clk ) begin
  if (push && !full) begin
    mem[write_ptr] <= wdata;
  end
end

// -------------------------
// Combinational read output
// -------------------------
assign rdata = mem[read_ptr];

endmodule
