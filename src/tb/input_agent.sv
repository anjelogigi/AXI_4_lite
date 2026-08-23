class input_agent extends uvm_agent;
  `uvm_component_utils(input_agent)

  axi4_lite_sequencer seqr;
  axi4_lite_driver    drv;
  input_monitor       mon;

  function new(string name = "input_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mon = input_monitor::type_id::create("mon", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      seqr = axi4_lite_sequencer::type_id::create("seqr", this);
      drv  = axi4_lite_driver::type_id::create("drv", this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  endfunction

endclass
