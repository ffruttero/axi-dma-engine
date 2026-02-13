module dma_top #(
   parameter int DATA_WIDTH = 32,
   parameter int ADDR_WIDTH = 32,
   parameter int FIFO_DEPTH = 16,
   parameter int BURST_SIZE = 16
)(
//Global
input logic clk,
input logic rst_n,
//APB Slave Interface
input logic [ADDR_WIDTH-1:0]  paddr,
input logic                   psel,
input logic                   penable,
input logic                   pwrite,
input logic [DATA_WIDTH-1:0]  pwdata,
output logic [DATA_WIDTH-1:0] prdata,
output logic                  prready,
output logic                  pslverr,

//AXI Master Read Address Channel
output logic [ADDR_WIDTH-1:0] araddr,
output logic [7:0]            arlen,
output logic [2:0]            arsize,
output logic [1:0]            arburst,
output logic                  arvalid,
input  logic                  arready,

// AXI Master Read Data Channel
input  logic [DATA_WIDTH-1:0] rdata,
input  logic [1:0]            rresp,
input  logic                  rlast,
input  logic                  rvalid,
output logic                  rready,

// AXI Master Write Address Channel
output logic [ADDR_WIDTH-1:0] awaddr,
output logic [7:0]            awlen,
output logic [2:0]            awsize,
output logic [1:0]            awburst,
output logic                  awvalid,
input  logic                  awready,

// AXI Master Write Data Channel
output logic [DATA_WIDTH-1:0] wdata,
output logic [(DATA_WIDTH/8)-1:0] wstrb,
output logic                  wlast,
output logic                  wvalid,
input  logic                  wready,

// AXI Master Write Response Channel
input  logic [1:0]            bresp,
input  logic                  bvalid,
output logic                  bready,

// IRQ Output
output logic                  irq
);

//Config Registers
logic [ADDR_WIDTH-1:0]  src_addr;
logic [ADDR_WIDTH-1:0]  dst_addr;
logic [31:0]            transfer_len;
logic                   start_pulse;
logic                   irq_enable;

//Status from FSM
logic busy, done, error;
// Write 1 to clear strobes:
logic done_clear, error_clear;

apb_regs #(
   .ADDR_WIDTH(ADDR_WIDTH),
   .DATA_WIDTH(DATA_WIDTH)
) u_apb_regs (
   .clk     (clk),
   .rst_n   (rst_n),
   .paddr   (paddr),
   .psel    (psel),
   .penable (penable),
   .pwrite  (pwrite),
   .pwdata  (pwdata),
   .prdata  (prdata),
   .pready  (pready),
   .pslverr (pslverr),
   //CONFIG outputs
   .src_addr_o    (src_addr),
   .dst_addr_o    (dst_addr),
   .lenght_o      (transfer_len),
   .start_pulse_o (start_pulse),
   .irq_enable_o  (irq_enable),
   //STATUS inputs
   .busy_i        (busy),
   .done_i        (done),
   .error_i       (error),
   .irq_o         (irq),
   //Clear Strobes
   .done_clear_o  (done_clear),
   .error_clear_o (error_clear)
);

//FSM Instance:
logic                   read_enable, write_enable;
logic                   fifo_push, fifo_pop;
logic [ADDR_WIDTH-1:0]  current_src_addr, current_dst_addr;
logic [31:0]            current_burst_len;

dma_ctrl #(
   .BURST_SIZE(BURST_SIZE)
   ) u_dma_ctrl (
   .clk           (clk),
   .rst_n         (rst_n),
   .start_pulse   (start_pulse),
   .done_clear    (done_clear),
   .error_clear   (error_clear),
   .src_addr      (src_addr),
   .dst_addr      (dst_addr),
   .lenght        (transfer_len),
   .fifo_full     (fifo_full),
   .fifo_empty    (fifo_empty),
   .read_done     (read_done),
   .write_done    (write_done),
   .read_error       (read_error),
   .write_error      (write_error),
   .read_enable   (read_enable),
   .write_enable  (write_enable),
   .current_src_addr (current_src_addr),
   .current_dst_addr (current_dst_addr),
   .current_burst_len(current_burst_len),
   .busy             (busy),
   .done             (done),
   .error            (error)
);
dma_fifo #(
   .DATA_WIDTH(DATA_WIDTH),
   .DEPTH(DEPTH)
) u_dma_fifo (
   .clk     (clk),
   .rst_n   (rst_n),
   .push    (fifo_push),
   .wdata   (prdata),
   .pop     (fifo_pop),
   .rdata   (pwdata),
   .full    (fifo_full),
   .empty   (fifo_empty)
);

dma_writter #(
   .ADDR_WIDTH(ADDR_WIDTH),
   .DATA_WIDTH(DATA_WIDTH)
) u_dma_writter (
   .clk(clk),
   .rst_n(rst_n),
   .write_enable(write_enable),
   .current_dst_addr(current_dst_addr),
   .current_burst_len(current_burst_len),
   .fifo_empty(fifo_empty),
   .fifo_pop(fifo_pop),
   .fifo_rdata(pwdata),
   .awaddr(awaddr),
   .awlen(awlen),
   .awsize(awsize),
   .awburst(awburst),
   .awvalid(awvalid),
   .awready(awready),
   .wdata(wdata),
   .wstrb(wstrb),
   .wlast(wlast),
   .wvalid(wvalid),
   .wready(wready),
   .bresp(bresp),
   .bvalid(bvalid),
   .bready(bready),
   .write_done(write_done),
   .write_error(write_error)
);

dma_reader #(
   .ADDR_WIDTH(ADDR_WIDTH),
   .DATA_WIDTH(DATA_WIDTH)
) u_dma_reader (
   .clk(clk),
   .rst_n(rst_n),
   .read_enable(read_enable),
   .current_src_addr(current_src_addr),
   .current_burst_len(current_burst_len),
   .fifo_full(fifo_full),
   .fifo_push(fifo_push),
   .fifo_wdata(wdata),
   .araddr(araddr),
   .arlen(arlen),
   .arsize(arsize),
   .arburst(arburst),
   .arvalid(arvalid),
   .arready(arready),
   .rdata(rdata),
   .rresp(rresp),
   .rlast(rlast),
   .rvalid(rvalid),
   .rready(rready),
   .read_done(read_done),
   .read_error(read_error)
);
endmodule
