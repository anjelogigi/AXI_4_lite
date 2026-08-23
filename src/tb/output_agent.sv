class output_agent extends uvm_agent;
  `uvm_component_utils(output_agent)

  output_monitor mon;

  function new(string name = "output_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mon = output_monitor::type_id::create("mon", this);
  endfunction

endclass
