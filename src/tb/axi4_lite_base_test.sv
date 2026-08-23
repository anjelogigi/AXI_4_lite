`ifndef AXI4_LITE_TEST_SV
`define AXI4_LITE_TEST_SV

class axi4_lite_base_test extends uvm_test;
  `uvm_component_utils(axi4_lite_base_test)

  axi4_lite_env env;

  function new(string name = "axi4_lite_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = axi4_lite_env::type_id::create("env", this);
    
    uvm_top.set_timeout(10ms, 0);
  endfunction

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);
    
    uvm_top.print_topology();
    
    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info(get_name(), "=======================================", UVM_NONE)
      `uvm_error(get_name(), "      TEST FAILED DUE TO ERRORS        ")
      `uvm_info(get_name(), "=======================================", UVM_NONE)
    end else begin
      `uvm_info(get_name(), "=======================================", UVM_NONE)
      `uvm_info(get_name(), "         TEST PASSED SUCCESSFULLY      ", UVM_NONE)
      `uvm_info(get_name(), "=======================================", UVM_NONE)
    end
  endfunction

endclass


class axi4_lite_regression_test extends axi4_lite_base_test;
  `uvm_component_utils(axi4_lite_regression_test)

  function new(string name = "axi4_lite_regression_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_lite_regression_seq seq;
    
    super.run_phase(phase);
    
    seq = axi4_lite_regression_seq::type_id::create("seq");
    
    phase.raise_objection(this, "Starting AXI4-Lite Regression Sequence");
    
    `uvm_info("TEST", "Starting Regression Sequence...", UVM_LOW)
    
    seq.start(env.in_agent.seqr);
    
    #200ns; 
    
    `uvm_info("TEST", "Regression Sequence Complete.", UVM_LOW)
    
    phase.drop_objection(this, "Finished AXI4-Lite Regression Sequence");
  endtask

endclass


class axi4_lite_basic_test extends axi4_lite_base_test;
  `uvm_component_utils(axi4_lite_basic_test)

  function new(string name = "axi4_lite_basic_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    axi4_lite_write_read_seq seq;
    
    super.run_phase(phase);
    
    seq = axi4_lite_write_read_seq::type_id::create("seq");
    
    phase.raise_objection(this, "Starting Basic Write/Read Test");
    
    `uvm_info("TEST", "Starting Basic Write/Read Sequence...", UVM_LOW)
    seq.start(env.in_agent.seqr);
    #100ns;
    
    phase.drop_objection(this, "Finished Basic Write/Read Test");
  endtask

endclass

`endif
