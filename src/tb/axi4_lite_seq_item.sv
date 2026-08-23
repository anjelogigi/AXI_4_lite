class axi4_lite_seq_item extends uvm_sequence_item;

  typedef enum bit { WRITE = 0, READ = 1 } trans_type_e;
  typedef enum bit [1:0] { AW_W_SAME = 0, AW_FIRST = 1, W_FIRST = 2 } write_order_e;

  rand trans_type_e trans_type;
  rand bit [`ADDR_WIDTH-1:0] addr;
  rand bit [`DATA_WIDTH-1:0] data;
  rand bit [(`DATA_WIDTH/8)-1:0] strb;
  rand bit [2:0] prot;
  rand write_order_e write_order;
  rand int unsigned aw_delay, w_delay, bready_delay, rready_delay;
  
  bit [`DATA_WIDTH-1:0] rdata;
  bit [1:0] resp;

  constraint c_addr { addr inside {[32'h0:32'h3F]}; addr[1:0] == 2'b00; }
  constraint c_strb { strb > 0; }
  constraint c_prot { prot == `DEFAULT_PROT; }
  constraint c_delay { 
    aw_delay inside {[0:5]}; w_delay inside {[0:5]}; 
    bready_delay inside {[0:5]}; rready_delay inside {[0:5]}; 
  }

  `uvm_object_utils(axi4_lite_seq_item)

  function new(string name = "axi4_lite_seq_item");
    super.new(name);
  endfunction

endclass
