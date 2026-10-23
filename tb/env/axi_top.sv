module axi_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import axi_pkg::*;

    // ------------------------------------------------------------
    // Parameters 
    // ------------------------------------------------------------
    parameter DATA_WIDTH   = 32;
    parameter ADDR_WIDTH   = 16;
    parameter MEMORY_DEPTH = 1024;

    // ------------------------------------------------------------
    // Clock generation 
    // ------------------------------------------------------------
    bit ACLK;
    initial begin 
    	forever #5 ACLK = ~ACLK;
    end	

    // ------------------------------------------------------------
    // AXI interface instance 
    // ------------------------------------------------------------
    axi_if #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) axi_vif (.ACLK(ACLK));

    // ------------------------------------------------------------
    // axi4 slave instantiation
    // ------------------------------------------------------------
    axi4 #(
        .DATA_WIDTH  (DATA_WIDTH),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) dut (
        .ACLK   (axi_vif.ACLK),
        .ARESETn(axi_vif.ARESETn),

        .AWADDR (axi_vif.AWADDR),
        .AWLEN  (axi_vif.AWLEN),
        .AWSIZE (axi_vif.AWSIZE),
        .AWVALID(axi_vif.AWVALID),
        .AWREADY(axi_vif.AWREADY),

        .WDATA  (axi_vif.WDATA),
        .WVALID (axi_vif.WVALID),
        .WLAST  (axi_vif.WLAST),
        .WREADY (axi_vif.WREADY),

        .BRESP  (axi_vif.BRESP),
        .BVALID (axi_vif.BVALID),
        .BREADY (axi_vif.BREADY),

        .ARADDR (axi_vif.ARADDR),
        .ARLEN  (axi_vif.ARLEN),
        .ARSIZE (axi_vif.ARSIZE),
        .ARVALID(axi_vif.ARVALID),
        .ARREADY(axi_vif.ARREADY),

        .RDATA  (axi_vif.RDATA),
        .RRESP  (axi_vif.RRESP),
        .RVALID (axi_vif.RVALID),
        .RLAST  (axi_vif.RLAST),
        .RREADY (axi_vif.RREADY)
    );

    // ------------------------------------------------------------
    // Memory interface 
    // ------------------------------------------------------------
    bind axi4_memory mem_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH($clog2(DEPTH)),
        .DEPTH     (DEPTH)
    ) mem_if_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .mem_en   (mem_en),
        .mem_we   (mem_we),
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata)
    );


    // ------------------------------------------------------------
    // bind the Memory SVA with it's instance
    // ------------------------------------------------------------
    bind axi4_memory mem_sva #(
        .DEPTH(DEPTH)
    ) memory_assertions (
        .mem_if(mem_if_inst)
    );

    // ------------------------------------------------------------
    // AXI assertions and coverage
    // ------------------------------------------------------------
    axi_sva axi_assertions (
        .axi_if(axi_vif)
    );

    // ------------------------------------------------------------
    // UVM config_db + run_test
    // ------------------------------------------------------------
    initial begin
        uvm_config_db #(uvm_active_passive_enum)::set(
            null, "uvm_test_top.axi_env.axi_agt", "is_active", UVM_ACTIVE);

        uvm_config_db #(virtual axi_if)::set(
            null, "uvm_test_top.axi_env.axi_agt.*", "AXI_Virtual_Interface", axi_vif);

        uvm_config_db #(virtual mem_if)::set(
            null, "uvm_test_top.axi_env.mem_agt.*", "MEM_Virtual_Interface",
            dut.mem_inst.mem_if_inst);

        run_test("uvm_test_top");
    end

endmodule : axi_top