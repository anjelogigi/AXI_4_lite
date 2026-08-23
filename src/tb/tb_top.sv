`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import axi4_lite_pkg::*; 

module tb_top;

  bit clk;
  bit aresetn;

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    aresetn = 0;
    #20;
    aresetn = 1;
  end

  axi4_lite_if vif (
    .clk(clk),
    .aresetn(aresetn)
  );

  axi4_lite_slave_dut DUT (
    .aclk    (vif.clk),
    .aresetn (vif.aresetn),

    .awaddr  (vif.awaddr),
    .awprot  (vif.awprot),
    .awvalid (vif.awvalid),
    .awready (vif.awready),

    .wdata   (vif.wdata),
    .wstrb   (vif.wstrb),
    .wvalid  (vif.wvalid),
    .wready  (vif.wready),

    .bresp   (vif.bresp),
    .bvalid  (vif.bvalid),
    .bready  (vif.bready),

    .araddr  (vif.araddr),
    .arprot  (vif.arprot),
    .arvalid (vif.arvalid),
    .arready (vif.arready),

    .rdata   (vif.rdata),
    .rresp   (vif.rresp),
    .rvalid  (vif.rvalid),
    .rready  (vif.rready)
  );

  initial begin
    uvm_config_db#(virtual axi4_lite_if)::set(null, "*", "vif", vif);
    run_test();
  end

  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, tb_top);
  end

endmodule
