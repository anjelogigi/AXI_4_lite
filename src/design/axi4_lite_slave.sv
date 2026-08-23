// =============================================================================
// AXI4-Lite Slave (Subordinate) — Register File
// =============================================================================

module axi4_lite_slave #(
    parameter DATA_WIDTH        = 32,
    parameter ADDR_WIDTH        = 32,
    parameter MEM_DEPTH         = 16,
    parameter [2:0] DEFAULT_PROT = 3'b000
)(
    input  wire                       ACLK,
    input  wire                       ARESETn,

    input  wire [ADDR_WIDTH-1:0]      AWADDR,
    input  wire [2:0]                 AWPROT,
    input  wire                       AWVALID,
    output reg                        AWREADY,

    input  wire [DATA_WIDTH-1:0]      WDATA,
    input  wire [(DATA_WIDTH/8)-1:0]  WSTRB,
    input  wire                       WVALID,
    output reg                        WREADY,

    output reg  [1:0]                 BRESP,
    output reg                        BVALID,
    input  wire                       BREADY,

    input  wire [ADDR_WIDTH-1:0]      ARADDR,
    input  wire [2:0]                 ARPROT,
    input  wire                       ARVALID,
    output reg                        ARREADY,

    output reg  [DATA_WIDTH-1:0]      RDATA,
    output reg  [1:0]                 RRESP,
    output reg                        RVALID,
    input  wire                       RREADY
);

    // -------------------------------------------------------------------
    // AXI response encodings
    // -------------------------------------------------------------------
    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_EXOKAY = 2'b01;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;

    // -------------------------------------------------------------------
    // Register file storage
    // -------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    integer i;

    // -------------------------------------------------------------------
    // Write FSM states
    // -------------------------------------------------------------------
    localparam W_IDLE = 3'd0,
               W_BOTH = 3'd1,
               W_ADDR = 3'd2,
               W_DATA = 3'd3,
               W_RESP = 3'd4;

    reg [2:0] w_state, w_next;

    reg [ADDR_WIDTH-1:0] awaddr_latched;
    reg [DATA_WIDTH-1:0] wdata_latched;
    reg [(DATA_WIDTH/8)-1:0] wstrb_latched;

    wire aw_hs = AWVALID && AWREADY;
    wire w_hs  = WVALID  && WREADY;
    wire b_hs  = BVALID  && BREADY;

    // -------------------------------------------------------------------
    // Write address decode helpers
    // -------------------------------------------------------------------
    wire [ADDR_WIDTH-1:0] aw_word_addr = awaddr_latched >> 2;
    wire aw_unaligned = (awaddr_latched[1:0] != 2'b00);
    wire aw_in_range  = (aw_word_addr < MEM_DEPTH);

    function automatic bit is_write_only(input [ADDR_WIDTH-1:0] word_idx);
        is_write_only = (word_idx >= 10 && word_idx <= 12);
    endfunction

    function automatic bit is_read_only_wr(input [ADDR_WIDTH-1:0] word_idx);
        is_read_only_wr = (word_idx >= 13 && word_idx <= 14);
    endfunction

    // -------------------------------------------------------------------
    // Write FSM: sequential state register
    // -------------------------------------------------------------------
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            w_state <= W_IDLE;
        else
            w_state <= w_next;
    end

    // -------------------------------------------------------------------
    // Write FSM: next-state logic
    // -------------------------------------------------------------------
    always @(*) begin
        w_next = w_state;
        case (w_state)
            W_IDLE: begin
                if (aw_hs && w_hs)
                    w_next = W_RESP;
                else if (aw_hs)
                    w_next = W_DATA;
                else if (w_hs)
                    w_next = W_ADDR;
                else
                    w_next = W_BOTH;
            end
            W_BOTH: begin
                if (aw_hs && w_hs)
                    w_next = W_RESP;
                else if (aw_hs)
                    w_next = W_DATA;
                else if (w_hs)
                    w_next = W_ADDR;
            end
            W_ADDR: begin
                if (w_hs)
                    w_next = W_RESP;
            end
            W_DATA: begin
                if (aw_hs)
                    w_next = W_RESP;
            end
            W_RESP: begin
                if (b_hs)
                    w_next = W_IDLE;
            end
            default: w_next = W_IDLE;
        endcase
    end

    // -------------------------------------------------------------------
    // AWREADY / WREADY generation
    // -------------------------------------------------------------------
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWREADY <= 1'b0;
            WREADY  <= 1'b0;
        end else begin
            case (w_state)
                W_IDLE, W_BOTH: begin
                    AWREADY <= 1'b1;
                    WREADY  <= 1'b1;
                end
                W_ADDR: begin
                    AWREADY <= 1'b1;
                    WREADY  <= 1'b0;
                end
                W_DATA: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b1;
                end
                W_RESP: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b0;
                end
                default: begin
                    AWREADY <= 1'b0;
                    WREADY  <= 1'b0;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------
    // Latch address/data when handshakes occur
    // -------------------------------------------------------------------
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            awaddr_latched <= {ADDR_WIDTH{1'b0}};
            wdata_latched  <= {DATA_WIDTH{1'b0}};
            wstrb_latched  <= {(DATA_WIDTH/8){1'b0}};
        end else begin
            if (aw_hs)
                awaddr_latched <= AWADDR;
            if (w_hs) begin
                wdata_latched <= WDATA;
                wstrb_latched <= WSTRB;
            end
        end
    end

    // -------------------------------------------------------------------
    // BVALID / BRESP generation + memory write
    // -------------------------------------------------------------------
    reg write_fire;
    always @(*) begin
        write_fire = (w_state == W_RESP) && !BVALID;
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            BVALID <= 1'b0;
            BRESP  <= RESP_OKAY;
        end else begin
            if (w_state == W_RESP && !BVALID) begin
                BVALID <= 1'b1;

                if (aw_unaligned) begin
                    BRESP <= RESP_SLVERR;
                end else if (!aw_in_range) begin
                    BRESP <= RESP_DECERR;
                end else if (is_read_only_wr(aw_word_addr)) begin
                    BRESP <= RESP_SLVERR;
                end else begin
                    BRESP <= RESP_OKAY;
                end
            end else if (b_hs) begin
                BVALID <= 1'b0;
            end
        end
    end

    // Actual memory write (byte-strobe aware)
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                mem[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (w_state == W_RESP && !BVALID &&
                !aw_unaligned && aw_in_range && !is_read_only_wr(aw_word_addr)) begin

                if (wstrb_latched[0])
                    mem[aw_word_addr][7:0]   <= wdata_latched[7:0];
                if (wstrb_latched[1])
                    mem[aw_word_addr][15:8]  <= wdata_latched[15:8];
                if (wstrb_latched[2])
                    mem[aw_word_addr][23:16] <= wdata_latched[23:16];
                mem[aw_word_addr][31:24] <= wdata_latched[31:24];
            end
        end
    end

    // -------------------------------------------------------------------
    // Read FSM states
    // -------------------------------------------------------------------
    localparam R_IDLE = 1'b0,
               R_DATA = 1'b1;

    reg r_state, r_next;
    reg [ADDR_WIDTH-1:0] araddr_latched;

    wire ar_hs = ARVALID && ARREADY;
    wire r_hs  = RVALID  && RREADY;

    wire [ADDR_WIDTH-1:0] ar_word_addr = araddr_latched >> 2;
    wire ar_unaligned = (araddr_latched[1:0] != 2'b00);
    wire ar_in_range  = (ar_word_addr < MEM_DEPTH);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            r_state <= R_IDLE;
        else
            r_state <= r_next;
    end

    always @(*) begin
        r_next = r_state;
        case (r_state)
            R_IDLE: if (ar_hs) r_next = R_DATA;
            R_DATA: if (r_hs)  r_next = R_IDLE;
            default: r_next = R_IDLE;
        endcase
    end

    // ARREADY generation
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            ARREADY <= 1'b0;
        else begin
            case (r_state)
                R_IDLE:  ARREADY <= 1'b1;
                R_DATA:  ARREADY <= 1'b0;
                default: ARREADY <= 1'b0;
            endcase
        end
    end

    // Latch read address
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            araddr_latched <= {ADDR_WIDTH{1'b0}};
        else if (ar_hs)
            araddr_latched <= ARADDR;
    end

    // RVALID / RDATA / RRESP generation
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            RVALID <= 1'b0;
            RDATA  <= {DATA_WIDTH{1'b0}};
            RRESP  <= RESP_OKAY;
        end else begin
            if (r_state == R_DATA && !RVALID) begin
                RVALID <= 1'b1;

                if (ar_unaligned) begin
                    RRESP <= RESP_SLVERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end else if (!ar_in_range) begin
                    RRESP <= RESP_DECERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end else if (is_write_only(ar_word_addr)) begin
                    RRESP <= RESP_SLVERR;
                    RDATA <= {DATA_WIDTH{1'b0}};
                end else begin
                    RRESP <= RESP_OKAY;
                    RDATA <= mem[ar_word_addr];
                end
            end else if (r_hs) begin
                RVALID <= 1'b0;
            end
        end
    end

    wire word15_blocked = (aw_word_addr == 15);

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
        end else begin
            if (w_state == W_RESP && !BVALID && word15_blocked && !aw_unaligned) begin
                BRESP <= RESP_DECERR;
            end
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            mem[0] <= 32'hDEAD_0000;
        end
    end
endmodule
