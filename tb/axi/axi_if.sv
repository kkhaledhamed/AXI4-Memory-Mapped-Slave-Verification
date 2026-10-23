interface axi_if #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 16,
    parameter MEMORY_DEPTH = 1024
) (
    input bit ACLK
);

    // ============================================================
    // Global Signals
    // ============================================================
    logic ARESETn;

    // ============================================================
    // Write Address Channel
    // ============================================================
    logic [ADDR_WIDTH-1:0] AWADDR;
    logic [7:0]            AWLEN;
    logic [2:0]            AWSIZE;
    logic                  AWVALID;
    logic                  AWREADY;

    // ============================================================
    // Write Data Channel
    // ============================================================
    logic [DATA_WIDTH-1:0] WDATA;
    logic                  WVALID;
    logic                  WLAST;
    logic                  WREADY;

    // ============================================================
    // Write Response Channel
    // ============================================================
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    // ============================================================
    // Read Address Channel
    // ============================================================
    logic [ADDR_WIDTH-1:0] ARADDR;
    logic [7:0]            ARLEN;
    logic [2:0]            ARSIZE;
    logic                  ARVALID;
    logic                  ARREADY;

    // ============================================================
    // Read Data Channel
    // ============================================================
    logic [DATA_WIDTH-1:0] RDATA;
    logic [1:0]            RRESP;
    logic                  RVALID;
    logic                  RLAST;
    logic                  RREADY;


    // ============================================================
    // MASTER, TEST ENVIRONMENT MODPORT
    // ============================================================
    modport MASTER (
        // Global
        input  ACLK,
        output ARESETn,

        // Write Address
        output AWADDR,
        output AWLEN,
        output AWSIZE,
        output AWVALID,
        input  AWREADY,

        // Write Data
        output WDATA,
        output WVALID,
        output WLAST,
        input  WREADY,

        // Write Response
        input  BRESP,
        input  BVALID,
        output BREADY,

        // Read Address
        output ARADDR,
        output ARLEN,
        output ARSIZE,
        output ARVALID,
        input  ARREADY,

        // Read Data
        input  RDATA,
        input  RRESP,
        input  RVALID,
        input  RLAST,
        output RREADY
    );


    // ============================================================
    // SLAVE, DUT MODPORT
    // ============================================================
    modport SLAVE (
        // Global
        input ACLK,
        input ARESETn,

        // Write Address
        input  AWADDR,
        input  AWLEN,
        input  AWSIZE,
        input  AWVALID,
        output AWREADY,

        // Write Data
        input  WDATA,
        input  WVALID,
        input  WLAST,
        output WREADY,

        // Write Response
        output BRESP,
        output BVALID,
        input  BREADY,

        // Read Address
        input  ARADDR,
        input  ARLEN,
        input  ARSIZE,
        input  ARVALID,
        output ARREADY,

        // Read Data
        output RDATA,
        output RRESP,
        output RVALID,
        output RLAST,
        input  RREADY
    );


    // ============================================================
    // MONITOR MODPORT
    // ============================================================
    modport MONITOR (
        // Global
        input ACLK,
        input ARESETn,

        // Write Address
        input AWADDR,
        input AWLEN,
        input AWSIZE,
        input AWVALID,
        input AWREADY,

        // Write Data
        input WDATA,
        input WVALID,
        input WLAST,
        input WREADY,

        // Write Response
        input BRESP,
        input BVALID,
        input BREADY,

        // Read Address
        input ARADDR,
        input ARLEN,
        input ARSIZE,
        input ARVALID,
        input ARREADY,

        // Read Data
        input RDATA,
        input RRESP,
        input RVALID,
        input RLAST,
        input RREADY
    );

endinterface