`include "defines.svh"

interface axi4_lite_if(input bit aclk, input bit aresetn);

  logic [`ADDR_WIDTH-1:0] awaddr;
  logic [2:0] awprot;
  logic awvalid;
  logic awready;

  logic [`DATA_WIDTH-1:0] wdata;
  logic [(`DATA_WIDTH/8)-1:0] wstrb;
  logic wvalid;
  logic wready;

  logic [1:0] bresp;
  logic bvalid;
  logic bready;

  logic [`ADDR_WIDTH-1:0] araddr;
  logic [2:0] arprot;
  logic arvalid;
  logic arready;

  logic [`DATA_WIDTH-1:0] rdata;
  logic [1:0] rresp;
  logic rvalid;
  logic rready;

  clocking drv_cb @(posedge aclk);
    default input #1 output #1;
    
    output awaddr;
    output awprot;
    output awvalid;
    output wdata;
    output wstrb;
    output wvalid;
    output bready;
    output araddr;
    output arprot;
    output arvalid;
    output rready;
    
    input awready;
    input wready;
    input bresp;
    input bvalid;
    input arready;
    input rdata;
    input rresp;
    input rvalid;
  endclocking
  
  clocking inp_mon_cb @(posedge aclk);
    default input #1 output #1;
    
    input aresetn;
    input awaddr;
    input awprot;
    input awvalid;
    input awready;
    input wdata;
    input wstrb;
    input wvalid;
    input wready;
    input bready;
    input araddr;
    input arprot;
    input arvalid;
    input arready;
    input rready;
  endclocking

  clocking out_mon_cb @(posedge aclk);
    default input #1 output #1;
    
    input aresetn;
    input awaddr;
    input awprot;
    input awvalid;
    input wdata;
    input wstrb;
    input wvalid;
    input bready;
    input araddr;
    input arprot;
    input arvalid;
    input rready;
    input awready;
    input wready;
    input bresp;
    input bvalid;
    input arready;
    input rdata;
    input rresp;
    input rvalid;
  endclocking

  modport INP_DRV (clocking drv_cb);
  modport INP_MON (clocking inp_mon_cb);
  modport OUT_MON (clocking out_mon_cb);

endinterface
