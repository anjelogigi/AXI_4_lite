`ifndef AXI4_LITE_PKG_SV
`define AXI4_LITE_PKG_SV

package axi4_lite_pkg;

  import uvm_pkg::*;
  
  `include "uvm_macros.svh"
  `include "axi4_lite_seq_item.sv"
  `include "axi4_lite_seqs.sv" 
  `include "axi4_lite_sequencer.sv"
  `include "axi4_lite_driver.sv"
  `include "input_monitor.sv"
   `include "output_monitor.sv"
  `include "input_agent.sv"
  `include "output_agent.sv"
  `include "axi4_lite_scoreboard.sv"
  `include "axi4_lite_subscriber.sv"
  `include "axi4_lite_env.sv"
  `include "axi4_lite_test.sv"

endpackage : axi4_lite_pkg

`endif
