class axi4_lite_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(axi4_lite_scoreboard)

  uvm_tlm_analysis_fifo #(axi4_lite_seq_item) in_fifo;
  uvm_tlm_analysis_fifo #(axi4_lite_seq_item) out_fifo;

  axi4_lite_seq_item exp_wr_q[$];
  axi4_lite_seq_item exp_rd_q[$];

  bit [31:0] ref_mem [bit [31:0]];

  int match_cnt, mismatch_cnt;

  function new(string name = "axi4_lite_scoreboard", uvm_component parent);
    super.new(name, parent);
    match_cnt = 0;
    mismatch_cnt = 0;
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_fifo  = new("in_fifo", this);
    out_fifo = new("out_fifo", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    fork
      ref_model();
      check();
    join_none
  endtask
  task ref_model();
    axi4_lite_seq_item in_tx, exp_tx;
    
    forever begin
      in_fifo.get(in_tx);
      $cast(exp_tx, in_tx.clone());
      if (exp_tx.trans_type == axi4_lite_seq_item::WRITE) begin
        
        if (exp_tx.addr[1:0] != 2'b00) begin
          exp_tx.bresp = 2'b10; // SLVERR
        end
        else if (exp_tx.addr > 32'h3C) begin
          exp_tx.bresp = 2'b11; // DECERR
        end
        else if (exp_tx.addr >= 32'h28 && exp_tx.addr <= 32'h30) begin
          exp_tx.bresp = 2'b10; // SLVERR
        end
        else begin
          bit [31:0] current_val = 32'h0;
          if (ref_mem.exists(exp_tx.addr)) current_val = ref_mem[exp_tx.addr];
          
          if (exp_tx.strb[0]) current_val[7:0]   = exp_tx.data[7:0];
          if (exp_tx.strb[1]) current_val[15:8]  = exp_tx.data[15:8];
          if (exp_tx.strb[2]) current_val[23:16] = exp_tx.data[23:16];
          if (exp_tx.strb[3]) current_val[31:24] = exp_tx.data[31:24];
          
          ref_mem[exp_tx.addr] = current_val;
          exp_tx.bresp = 2'b00; // OKAY
        end
        
        exp_wr_q.push_back(exp_tx);
      end 
            else begin 
        if (exp_tx.addr[1:0] != 2'b00) begin
          exp_tx.rresp = 2'b10; // SLVERR
          exp_tx.data  = 32'h0;
        end
        else if (exp_tx.addr > 32'h3C) begin
          exp_tx.rresp = 2'b11; // DECERR
          exp_tx.data  = 32'h0;
        end
        else if (exp_tx.addr >= 32'h34 && exp_tx.addr <= 32'h38) begin
          exp_tx.rresp = 2'b10; // SLVERR
          exp_tx.data  = 32'h0;
        end
        else begin
          if (ref_mem.exists(exp_tx.addr)) exp_tx.data = ref_mem[exp_tx.addr];
          else exp_tx.data = 32'h0; // Default if never written
          
          exp_tx.rresp = 2'b00; // OKAY
        end
        
        exp_rd_q.push_back(exp_tx);
      end
    end
  endtask

  task check();
    axi4_lite_seq_item out_tx, exp_tx;
    
    forever begin
      out_fifo.get(out_tx);
      
      if (out_tx.trans_type == axi4_lite_seq_item::WRITE) begin
        wait (exp_wr_q.size() > 0); 
        exp_tx = exp_wr_q.pop_front();
        
        if (out_tx.bresp === exp_tx.bresp) begin
          `uvm_info("SCB_PASS", $sformatf("WRITE PASS -> Addr: %0h", out_tx.addr), UVM_LOW)
          match_cnt++;
        end else begin
          `uvm_error("SCB_FAIL", $sformatf("WRITE FAIL -> Addr: %0h | Exp Resp: %0b | Act Resp: %0b", out_tx.addr, exp_tx.bresp, out_tx.bresp))
          mismatch_cnt++;
        end
      end 
      else begin
        wait (exp_rd_q.size() > 0);
        exp_tx = exp_rd_q.pop_front();
        
          if (exp_tx.rresp == 2'b00) begin
          if ((out_tx.data === exp_tx.data) && (out_tx.rresp === exp_tx.rresp)) begin
            `uvm_info("SCB_PASS", $sformatf("READ PASS -> Addr: %0h, Data: %0h", out_tx.addr, out_tx.data), UVM_LOW)
            match_cnt++;
          end else begin
            `uvm_error("SCB_FAIL", $sformatf("READ FAIL -> Addr: %0h | Exp Data: %0h, Resp: %0b | Act Data: %0h, Resp: %0b", 
                       out_tx.addr, exp_tx.data, exp_tx.rresp, out_tx.data, out_tx.rresp))
            mismatch_cnt++;
          end
        end else begin
          if (out_tx.rresp === exp_tx.rresp) begin
            `uvm_info("SCB_PASS", $sformatf("READ ERR PASS -> Addr: %0h, Exp Resp: %0b", out_tx.addr, exp_tx.rresp), UVM_LOW)
            match_cnt++;
          end else begin
            `uvm_error("SCB_FAIL", $sformatf("READ ERR FAIL -> Addr: %0h | Exp Resp: %0b | Act Resp: %0b", out_tx.addr, exp_tx.rresp, out_tx.rresp))
            mismatch_cnt++;
          end
        end
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_REPORT", $sformatf("\n--- Matches: %0d | Mismatches: %0d ---", match_cnt, mismatch_cnt), UVM_NONE)
  endfunction

endclass
