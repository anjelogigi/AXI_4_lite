class output_monitor extends uvm_monitor;
  `uvm_component_utils(output_monitor)
  
  virtual axi4_lite_if vif;
  uvm_analysis_port #(axi4_lite_seq_item) ap;
  
  function new(string name = "output_monitor", uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("OUT_MON", "Could not get virtual interface 'vif'")
    end
  endfunction
  
  task run_phase(uvm_phase phase);
    wait(vif.aresetn == 1'b1);
    
    fork
      capture_full_writes();
      capture_full_reads();
    join
  endtask
  
  task capture_full_writes();
    axi4_lite_seq_item trans;
    forever begin
      trans = axi4_lite_seq_item::type_id::create("trans");
      trans.trans_type = axi4_lite_seq_item::WRITE;
      
      fork
        begin
          do @(posedge vif.aclk); while (!(vif.awvalid && vif.awready));
          trans.addr = vif.awaddr;
          trans.prot = vif.awprot;
        end
        begin
          do @(posedge vif.aclk); while (!(vif.wvalid && vif.wready));
          trans.data = vif.wdata;
          trans.strb = vif.wstrb;
        end
      join
      
      do @(posedge vif.aclk); while (!(vif.bvalid && vif.bready));
      trans.resp = vif.bresp;
      
      `uvm_info("OUT_MON", $sformatf("Sending Full Write Transaction to SCB:\n%s", trans.convert2string()), UVM_HIGH)
      ap.write(trans);
    end
  endtask
  
  task capture_full_reads();
    axi4_lite_seq_item trans;
    forever begin
      trans = axi4_lite_seq_item::type_id::create("trans");
      trans.trans_type = axi4_lite_seq_item::READ;
      
      do @(posedge vif.aclk); while (!(vif.arvalid && vif.arready));
      trans.addr = vif.araddr;
      trans.prot = vif.arprot;
      
      do @(posedge vif.aclk); while (!(vif.rvalid && vif.rready));
      trans.rdata = vif.rdata;
      trans.resp  = vif.rresp;
      
      `uvm_info("OUT_MON", $sformatf("Sending Full Read Transaction to SCB:\n%s", trans.convert2string()), UVM_HIGH)
      ap.write(trans);
    end
  endtask
endclass
