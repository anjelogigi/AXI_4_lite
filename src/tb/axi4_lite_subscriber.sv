class axi4_lite_subscriber extends uvm_subscriber #(axi4_lite_seq_item);
  `uvm_component_utils(axi4_lite_subscriber)

  axi4_lite_seq_item req;

  covergroup axi4_lite_cg;
    option.per_instance = 1;
    option.name = "axi4_lite_functional_coverage";

    cp_trans_type: coverpoint req.trans_type {
      bins write_trans = {axi4_lite_seq_item::WRITE};
      bins read_trans  = {axi4_lite_seq_item::READ};
    }

    cp_bresp: coverpoint req.bresp {
      bins resp_okay   = {2'b00};
      bins resp_exokay = {2'b01};
      bins resp_slverr = {2'b10};
      bins resp_decerr = {2'b11};
      ignore_bins ignore_reads = cp_bresp with (req.trans_type == axi4_lite_seq_item::READ);
    }

    cp_rresp: coverpoint req.rresp {
      bins resp_okay   = {2'b00};
      bins resp_exokay = {2'b01};
      bins resp_slverr = {2'b10};
      bins resp_decerr = {2'b11};
      ignore_bins ignore_writes = cp_rresp with (req.trans_type == axi4_lite_seq_item::WRITE);
    }

    cp_addr_alignment: coverpoint req.addr[1:0] {
      bins aligned   = {2'b00};
      bins unaligned = {2'b01, 2'b10, 2'b11}; 
    }

    cp_addr_regions: coverpoint req.addr {
      bins normal_rw     = {[32'h00 : 32'h24], 32'h3C};
      bins status_ro     = {[32'h28 : 32'h30]};
      bins command_wo    = {[32'h34 : 32'h38]};
      bins out_of_bounds = {[32'h40 : 32'hFFFF_FFFF]};
    }

    cp_data_vals: coverpoint req.data {
      bins all_zeros   = {32'h0000_0000};
      bins all_ones    = {32'hFFFF_FFFF};
      bins alt_1_0     = {32'hAAAA_AAAA};
      bins alt_0_1     = {32'h5555_5555};
      bins others      = default;
    }

    cp_wstrb: coverpoint req.strb {
      bins all_bytes   = {4'b1111};
      bins single_byte = {4'b0001, 4'b0010, 4'b0100, 4'b1000};
      bins half_word   = {4'b0011, 4'b1100};
      bins others      = default;
      ignore_bins ignore_reads = cp_wstrb with (req.trans_type == axi4_lite_seq_item::READ);
    }

    cp_prot: coverpoint req.prot {
      bins unpriv_secure_data   = {3'b000};
      bins priv_secure_data     = {3'b001};
      bins unpriv_nonsec_data   = {3'b010};
      bins priv_nonsec_data     = {3'b011};
      bins unpriv_secure_inst   = {3'b100};
      bins priv_secure_inst     = {3'b101};
      bins unpriv_nonsec_inst   = {3'b110};
      bins priv_nonsec_inst     = {3'b111};
    }

    cross_type_x_align: cross cp_trans_type, cp_addr_alignment;

    cross_type_x_prot: cross cp_trans_type, cp_prot;

    cross_wstrb_x_bresp: cross cp_wstrb, cp_bresp {
      ignore_bins ignore_read_cross = cross_wstrb_x_bresp intersect {
        binsof(cp_bresp.ignore_reads)
      };
    }

    cross_type_x_region: cross cp_trans_type, cp_addr_regions;

  endcovergroup

  function new(string name = "axi4_lite_subscriber", uvm_component parent);
    super.new(name, parent);
    axi4_lite_cg = new();
  endfunction

  virtual function void write(axi4_lite_seq_item t);
    req = t; 
    
    axi4_lite_cg.sample();
    
    `uvm_info("COV", $sformatf("Sampled Transaction: %s to Addr: %0h | Current Coverage = %0.2f%%", 
              req.trans_type.name(), req.addr, axi4_lite_cg.get_inst_coverage()), UVM_DEBUG)
  endfunction

endclass
