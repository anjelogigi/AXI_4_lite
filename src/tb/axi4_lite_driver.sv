class axi4_lite_driver extends uvm_driver #(axi4_lite_seq_item);
  `uvm_component_utils(axi4_lite_driver)
  
  virtual axi4_lite_if vif;
  
  function new(string name="axi4_lite_driver", uvm_component parent);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual axi4_lite_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV", "Could not get virtual interface 'vif' from config DB")
    end
  endfunction
  
  task run_phase(uvm_phase phase);
    reset_signals();
    
    wait(vif.aresetn == 1'b1);
    
    forever begin
      seq_item_port.get_next_item(req);
      
      `uvm_info("DRV", $sformatf("Driving Transaction: \n%s", req.convert2string()), UVM_HIGH)
      
      if (req.trans_type == axi4_lite_seq_item::WRITE) begin
        drive_write(req);
      end else begin
        drive_read(req);
      end
      
      seq_item_port.item_done();
    end
  endtask
  
  task reset_signals();
    vif.awvalid <= 1'b0;
    vif.wvalid  <= 1'b0;
    vif.bready  <= 1'b0;
    vif.arvalid <= 1'b0;
    vif.rready  <= 1'b0;
  endtask
  
  task drive_write(axi4_lite_seq_item req);
    if (req.write_order == axi4_lite_seq_item::AW_FIRST) begin
      drive_aw_channel(req);
      drive_w_channel(req);
    end 
    else if (req.write_order == axi4_lite_seq_item::W_FIRST) begin
      drive_w_channel(req);
      drive_aw_channel(req);
    end 
    else begin
      fork
        drive_aw_channel(req);
        drive_w_channel(req);
      join
    end
  
    @(posedge vif.aclk);
    vif.bready <= 1'b1;
    do @(posedge vif.aclk); while (vif.bvalid == 1'b0);
    req.resp = vif.bresp; 
    vif.bready <= 1'b0;
  endtask
  
  task drive_aw_channel(axi4_lite_seq_item req);
    @(posedge vif.aclk);
    vif.awaddr  <= req.addr;
    vif.awprot  <= req.prot;
    vif.awvalid <= 1'b1;
    do @(posedge vif.aclk); while (vif.awready == 1'b0);
    vif.awvalid <= 1'b0;
  endtask
  
  task drive_w_channel(axi4_lite_seq_item req);
    @(posedge vif.aclk);
    vif.wdata  <= req.data;
    vif.wstrb  <= req.strb;
    vif.wvalid <= 1'b1;
    do @(posedge vif.aclk); while (vif.wready == 1'b0);
    vif.wvalid <= 1'b0;
  endtask
  
  task drive_read(axi4_lite_seq_item req);
    @(posedge vif.aclk);
    vif.araddr  <= req.addr;
    vif.arprot  <= req.prot;
    vif.arvalid <= 1'b1;
    do @(posedge vif.aclk); while (vif.arready == 1'b0);
    vif.arvalid <= 1'b0;
  
    vif.rready <= 1'b1;
    do @(posedge vif.aclk); while (vif.rvalid == 1'b0);
    req.rdata = vif.rdata;
    req.resp  = vif.rresp;
    vif.rready <= 1'b0;
  endtask
  
endclass
