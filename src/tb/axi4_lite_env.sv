class axi4_lite_env extends uvm_env;
  `uvm_component_utils(axi4_lite_env)

  input_agent          in_agent;
  output_agent         out_agent;
  axi4_lite_scoreboard scb;
  axi4_lite_subscriber sub;

  function new(string name = "axi4_lite_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    in_agent = input_agent::type_id::create("in_agent", this);

    uvm_config_db#(uvm_active_passive_enum)::set(this, "out_agent", "is_active", UVM_PASSIVE);
    out_agent = output_agent::type_id::create("out_agent", this);

    scb = axi4_lite_scoreboard::type_id::create("scb", this);

    sub = axi4_lite_subscriber::type_id::create("sub", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    in_agent.mon.ap.connect(scb.in_fifo.analysis_export);

    out_agent.mon.ap.connect(scb.out_fifo.analysis_export);

    out_agent.mon.ap.connect(sub.analysis_export);
  endfunction
  
endclass
