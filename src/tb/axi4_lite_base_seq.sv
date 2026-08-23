class axi4_lite_base_seq extends uvm_sequence #(axi4_lite_seq_item);
  `uvm_object_utils(axi4_lite_base_seq)

  function new(string name = "axi4_lite_base_seq"); 
    super.new(name); 
  endfunction

  task send_write(input bit [`ADDR_WIDTH-1:0] addr, input bit [`DATA_WIDTH-1:0] data, input bit [(`DATA_WIDTH/8)-1:0] strb, input bit [2:0] prot = `DEFAULT_PROT, input axi4_lite_seq_item::write_order_e order = axi4_lite_seq_item::AW_W_SAME);
    req = axi4_lite_seq_item::type_id::create("req");
    start_item(req);
    req.trans_type = axi4_lite_seq_item::WRITE; 
    req.addr = addr; 
    req.data = data; 
    req.strb = strb; 
    req.prot = prot; 
    req.write_order = order;
    finish_item(req);
  endtask

  task send_read(input bit [`ADDR_WIDTH-1:0] addr, input bit [2:0] prot = `DEFAULT_PROT);
    req = axi4_lite_seq_item::type_id::create("req");
    start_item(req);
    req.trans_type = axi4_lite_seq_item::READ; 
    req.addr = addr; 
    req.prot = prot;
    finish_item(req);
  endtask
endclass

class axi4_lite_basic_write_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_basic_write_seq)
  function new(string name="axi4_lite_basic_write_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h04, 32'h1234_5678, 4'b1111, `DEFAULT_PROT, axi4_lite_seq_item::AW_W_SAME); 
  endtask
endclass

class axi4_lite_basic_read_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_basic_read_seq)
  function new(string name="axi4_lite_basic_read_seq"); super.new(name); endfunction
  task body(); 
    send_read(32'h04, `DEFAULT_PROT); 
  endtask
endclass

class axi4_lite_write_read_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_write_read_seq)
  function new(string name="axi4_lite_write_read_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h10, 32'hDEAD_BEEF, 4'b1111); 
    send_read(32'h10); 
  endtask
endclass

class axi4_lite_multiple_write_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_multiple_write_seq)
  function new(string name="axi4_lite_multiple_write_seq"); super.new(name); endfunction
  task body(); 
    for(int i=0; i<10; i++) 
      send_write(32'h04+(i*4), $urandom(), 4'b1111); 
  endtask
endclass

class axi4_lite_multiple_read_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_multiple_read_seq)
  function new(string name="axi4_lite_multiple_read_seq"); super.new(name); endfunction
  task body(); 
    for(int i=0; i<10; i++) 
      send_read(32'h04+(i*4)); 
  endtask
endclass

class axi4_lite_aw_first_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_aw_first_seq)
  function new(string name="axi4_lite_aw_first_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h08, 32'hAAAA_5555, 4'b1111, `DEFAULT_PROT, axi4_lite_seq_item::AW_FIRST); 
  endtask
endclass

class axi4_lite_w_first_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_w_first_seq)
  function new(string name="axi4_lite_w_first_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h0C, 32'h5555_AAAA, 4'b1111, `DEFAULT_PROT, axi4_lite_seq_item::W_FIRST); 
  endtask
endclass

class axi4_lite_random_aw_w_delay_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_random_aw_w_delay_seq)
  function new(string name="axi4_lite_random_aw_w_delay_seq"); super.new(name); endfunction
  task body(); 
    repeat(10) begin 
      req = axi4_lite_seq_item::type_id::create("req"); 
      start_item(req); 
      assert(req.randomize() with {trans_type == axi4_lite_seq_item::WRITE;}); 
      finish_item(req); 
    end 
  endtask
endclass

class axi4_lite_simultaneous_read_write_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_simultaneous_read_write_seq)
  function new(string name="axi4_lite_simultaneous_read_write_seq"); super.new(name); endfunction
  task body(); 
    fork 
      send_write(32'h20, 32'h1111_2222, 4'b1111); 
      send_read(32'h24); 
    join 
  endtask
endclass

class axi4_lite_read_write_interleave_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_read_write_interleave_seq)
  function new(string name="axi4_lite_read_write_interleave_seq"); super.new(name); endfunction
  task body(); 
    fork 
      begin 
        for(int i=0; i<5; i++) send_write(32'h40+(i*4), $urandom, 4'b1111); 
      end 
      begin 
        for(int i=0; i<5; i++) send_read(32'h60+(i*4)); 
      end 
    join 
  endtask
endclass

class axi4_lite_back_to_back_write_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_back_to_back_write_seq)
  function new(string name="axi4_lite_back_to_back_write_seq"); super.new(name); endfunction
  task body(); 
    repeat(5) send_write(32'h10, $urandom(), 4'b1111); 
  endtask
endclass

class axi4_lite_back_to_back_read_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_back_to_back_read_seq)
  function new(string name="axi4_lite_back_to_back_read_seq"); super.new(name); endfunction
  task body(); 
    repeat(5) send_read(32'h10); 
  endtask
endclass

class axi4_lite_delayed_bready_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_delayed_bready_seq)
  function new(string name="axi4_lite_delayed_bready_seq"); super.new(name); endfunction
  task body(); 
    req = axi4_lite_seq_item::type_id::create("req"); 
    start_item(req); 
    assert(req.randomize() with {trans_type == axi4_lite_seq_item::WRITE;}); 
    finish_item(req); 
  endtask
endclass

class axi4_lite_delayed_rready_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_delayed_rready_seq)
  function new(string name="axi4_lite_delayed_rready_seq"); super.new(name); endfunction
  task body(); 
    req = axi4_lite_seq_item::type_id::create("req"); 
    start_item(req); 
    assert(req.randomize() with {trans_type == axi4_lite_seq_item::READ;}); 
    finish_item(req); 
  endtask
endclass

class axi4_lite_wstrb_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_wstrb_seq)
  function new(string name="axi4_lite_wstrb_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h00, 32'h1122_3344, 4'b0001); 
    send_write(32'h04, 32'h5566_7788, 4'b0010); 
    send_write(32'h08, 32'h99AA_BBCC, 4'b0100); 
    send_write(32'h0C, 32'hDDEE_FF00, 4'b1000); 
    send_write(32'h10, 32'h1234_5678, 4'b1111); 
  endtask
endclass

class axi4_lite_invalid_address_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_invalid_address_seq)
  function new(string name="axi4_lite_invalid_address_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h40, 32'h1234_5678, 4'b1111); 
    send_read(32'h40); 
    send_write(32'h80, 32'hAAAA_BBBB, 4'b1111); 
    send_read(32'h80); 
  endtask
endclass

class axi4_lite_unaligned_address_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_unaligned_address_seq)
  function new(string name="axi4_lite_unaligned_address_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h01, 32'h1234_5678, 4'b1111); 
    send_write(32'h02, 32'hAAAA_BBBB, 4'b1111); 
    send_write(32'h03, 32'hCCCC_DDDD, 4'b1111); 
    send_read(32'h01); 
    send_read(32'h02); 
    send_read(32'h03); 
  endtask
endclass

class axi4_lite_read_only_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_read_only_seq)
  function new(string name="axi4_lite_read_only_seq"); super.new(name); endfunction
  task body(); 
    send_read(32'h28); 
    send_read(32'h2C); 
    send_read(32'h30); 
  endtask
endclass

class axi4_lite_write_only_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_write_only_seq)
  function new(string name="axi4_lite_write_only_seq"); super.new(name); endfunction
  task body(); 
    send_write(32'h34, 32'hAAAA_AAAA, 4'b1111); 
    send_write(32'h38, 32'hBBBB_BBBB, 4'b1111); 
  endtask
endclass

class axi4_lite_random_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_random_seq)
  function new(string name="axi4_lite_random_seq"); super.new(name); endfunction
  task body(); 
    repeat(100) begin 
      req = axi4_lite_seq_item::type_id::create("req"); 
      start_item(req); 
      assert(req.randomize()); 
      finish_item(req); 
    end 
  endtask
endclass

class axi4_lite_concurrent_random_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_concurrent_random_seq)
  function new(string name="axi4_lite_concurrent_random_seq"); super.new(name); endfunction
  task body(); 
    fork 
      begin 
        axi4_lite_random_seq r1 = axi4_lite_random_seq::type_id::create("r1"); 
        r1.start(m_sequencer); 
      end 
      begin 
        axi4_lite_random_seq r2 = axi4_lite_random_seq::type_id::create("r2"); 
        r2.start(m_sequencer); 
      end 
    join 
  endtask
endclass

class axi4_lite_reset_during_transaction_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_reset_during_transaction_seq)
  function new(string name="axi4_lite_reset_during_transaction_seq"); super.new(name); endfunction
  task body(); 
    req = axi4_lite_seq_item::type_id::create("req"); 
    start_item(req); 
    assert(req.randomize()); 
    finish_item(req); 
  endtask
endclass

class axi4_lite_regression_seq extends axi4_lite_base_seq;
  `uvm_object_utils(axi4_lite_regression_seq)
  function new(string name="axi4_lite_regression_seq"); super.new(name); endfunction

  task body();
    axi4_lite_basic_write_seq seq_basic_wr = axi4_lite_basic_write_seq::type_id::create("seq_basic_wr");
    axi4_lite_basic_read_seq seq_basic_rd = axi4_lite_basic_read_seq::type_id::create("seq_basic_rd");
    axi4_lite_write_read_seq seq_wr_rd = axi4_lite_write_read_seq::type_id::create("seq_wr_rd");
    axi4_lite_multiple_write_seq seq_mult_wr = axi4_lite_multiple_write_seq::type_id::create("seq_mult_wr");
    axi4_lite_multiple_read_seq seq_mult_rd = axi4_lite_multiple_read_seq::type_id::create("seq_mult_rd");
    axi4_lite_aw_first_seq seq_aw_first = axi4_lite_aw_first_seq::type_id::create("seq_aw_first");
    axi4_lite_w_first_seq seq_w_first = axi4_lite_w_first_seq::type_id::create("seq_w_first");
    axi4_lite_random_aw_w_delay_seq seq_rand_delay = axi4_lite_random_aw_w_delay_seq::type_id::create("seq_rand_delay");
    axi4_lite_simultaneous_read_write_seq seq_simult = axi4_lite_simultaneous_read_write_seq::type_id::create("seq_simult");
    axi4_lite_read_write_interleave_seq seq_interleave = axi4_lite_read_write_interleave_seq::type_id::create("seq_interleave");
    axi4_lite_back_to_back_write_seq seq_b2b_wr = axi4_lite_back_to_back_write_seq::type_id::create("seq_b2b_wr");
    axi4_lite_back_to_back_read_seq seq_b2b_rd = axi4_lite_back_to_back_read_seq::type_id::create("seq_b2b_rd");
    axi4_lite_delayed_bready_seq seq_dly_bready = axi4_lite_delayed_bready_seq::type_id::create("seq_dly_bready");
    axi4_lite_delayed_rready_seq seq_dly_rready = axi4_lite_delayed_rready_seq::type_id::create("seq_dly_rready");
    axi4_lite_wstrb_seq seq_wstrb = axi4_lite_wstrb_seq::type_id::create("seq_wstrb");
    axi4_lite_invalid_address_seq seq_inv_addr = axi4_lite_invalid_address_seq::type_id::create("seq_inv_addr");
    axi4_lite_unaligned_address_seq seq_unaligned = axi4_lite_unaligned_address_seq::type_id::create("seq_unaligned");
    axi4_lite_read_only_seq seq_rd_only = axi4_lite_read_only_seq::type_id::create("seq_rd_only");
    axi4_lite_write_only_seq seq_wr_only = axi4_lite_write_only_seq::type_id::create("seq_wr_only");
    axi4_lite_concurrent_random_seq seq_conc_rand = axi4_lite_concurrent_random_seq::type_id::create("seq_conc_rand");
    axi4_lite_reset_during_transaction_seq seq_rst_tx = axi4_lite_reset_during_transaction_seq::type_id::create("seq_rst_tx");

    `uvm_info(get_name(), "STARTING FULL AXI4-LITE REGRESSION SEQUENCE", UVM_LOW)
    
    seq_basic_wr.start(m_sequencer); 
    seq_basic_rd.start(m_sequencer); 
    seq_wr_rd.start(m_sequencer);
    seq_mult_wr.start(m_sequencer); 
    seq_mult_rd.start(m_sequencer); 
    seq_aw_first.start(m_sequencer);
    seq_w_first.start(m_sequencer); 
    seq_rand_delay.start(m_sequencer); 
    seq_simult.start(m_sequencer);
    seq_interleave.start(m_sequencer); 
    seq_b2b_wr.start(m_sequencer); 
    seq_b2b_rd.start(m_sequencer);
    seq_dly_bready.start(m_sequencer); 
    seq_dly_rready.start(m_sequencer); 
    seq_wstrb.start(m_sequencer);
    seq_inv_addr.start(m_sequencer); 
    seq_unaligned.start(m_sequencer); 
    seq_rd_only.start(m_sequencer);
    seq_wr_only.start(m_sequencer); 
    seq_conc_rand.start(m_sequencer); 
    seq_rst_tx.start(m_sequencer);
    
    `uvm_info(get_name(), "FULL AXI4-LITE REGRESSION SEQUENCE COMPLETE", UVM_LOW)
  endtask
endclass
