interface mem_if #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,   // matches axi4_memory: $clog2(1024) = 10
    parameter DEPTH      = 1024
) (
    input logic                  clk,
    input logic                  rst_n,
    input logic                  mem_en,
    input logic                  mem_we,
    input logic [ADDR_WIDTH-1:0] mem_addr,
    input logic [DATA_WIDTH-1:0] mem_wdata,
    input logic [DATA_WIDTH-1:0] mem_rdata
);

    // ============================================================
    // MONITOR MODPORT -- passive only, no driver exists for this
    // agent; every signal is read-only from the testbench side
    // ============================================================
    modport MONITOR (
        input clk,
        input rst_n,
        input mem_en,
        input mem_we,
        input mem_addr,
        input mem_wdata,
        input mem_rdata
    );

endinterface : mem_if