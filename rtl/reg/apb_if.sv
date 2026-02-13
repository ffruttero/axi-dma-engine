interface apb_if #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input logic pclk,
  input logic prsetn
);

logic [ADDR_WIDTH-1:0]  paddr;
logic [2:0]             pprot;
logic                   psel;
logic                   penable;
logic                   pwrite;
logic [DATA_WIDTH-1:0]  pwdata;
logic [DATA_WIDTH-1:0]  prdata;
logic                   pready;
logic                   pslverr;

//Master for driving request::
modport master (
  input pclk, presetn,
  output paddr, psel, penable, pwrite, pwdata, pprot,
  input prdata, pready, pslverr
);

//Slave for driving response::
modport slave (
  input pclk, presetn,
  input paddr, psel, penable, pwrite, pwdata, pprot,
  output prdata, pready, pslverr
);
endinterface
