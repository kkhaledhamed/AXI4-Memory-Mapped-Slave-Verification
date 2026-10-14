package axi_coverage_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;

    class axi_coverage extends uvm_component;
        `uvm_component_utils(axi_coverage)

        uvm_analysis_export #(axi_transaction)   axi_analysis_exp;
        uvm_tlm_analysis_fifo #(axi_transaction) axi_cov_fifo;

        axi_transaction transaction;

        // ------------------------------------------------------------
        // CG-001..013, CG-017, CG-018 from the Func Cov plan
        // ------------------------------------------------------------
        covergroup axi_cg;
            option.per_instance = 1;

            cp_op: coverpoint transaction.operation_type {
                bins reset = {AXI_RESET};
                bins write = {AXI_WRITE};
                bins read  = {AXI_READ};
            }

            cp_burst_en: coverpoint transaction.burst_en {
                bins single = {0};
                bins burst  = {1};
            }

            cp_awlen: coverpoint transaction.AWLEN iff (transaction.operation_type == AXI_WRITE) {
                bins len0  = {0};
                bins short = {[1:3]};
                bins mid   = {[4:15]};
            }

            cp_arlen: coverpoint transaction.ARLEN iff (transaction.operation_type == AXI_READ) {
                bins len0  = {0};
                bins short = {[1:3]};
                bins mid   = {[4:15]};
            }

            cp_bresp: coverpoint transaction.BRESP iff (transaction.operation_type == AXI_WRITE) {
                bins okay    = {2'b00};
                bins slverr  = {2'b10};
                bins illegal = {2'b01, 2'b11};
            }

            cp_rresp: coverpoint transaction.RRESP iff (transaction.operation_type == AXI_READ) {
                bins okay    = {2'b00};
                bins slverr  = {2'b10};
                bins illegal = {2'b01, 2'b11};
            }

            cp_awaddr_region: coverpoint transaction.AWADDR iff (transaction.operation_type == AXI_WRITE) {
                bins zero      = {0};
                bins low       = {[4:1020]};
                bins mid       = {[1024:3068]};
                bins high      = {[3072:4088]};
                bins last_word = {4092};
            }

            cp_araddr_region: coverpoint transaction.ARADDR iff (transaction.operation_type == AXI_READ) {
                bins zero      = {0};
                bins low       = {[4:1020]};
                bins mid       = {[1024:3068]};
                bins high      = {[3072:4088]};
                bins last_word = {4092};
            }

            cp_reset_cycles: coverpoint transaction.reset_cycles iff (transaction.operation_type == AXI_RESET) {
                bins short_reset = {[3:4]};
                bins long_reset  = {[5:6]};
            }

            cx_write_region_x_resp: cross cp_awaddr_region, cp_bresp;
            cx_read_region_x_resp:  cross cp_araddr_region, cp_rresp;
            cx_op_x_burst:          cross cp_op, cp_burst_en;

        endgroup : axi_cg

        function new (string name = "axi_coverage", uvm_component parent);
            super.new(name, parent);
            axi_cg = new();
            axi_analysis_exp = new("analysis_exp", this);
            axi_cov_fifo     = new("cov_fifo", this);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI coverage build phase", UVM_LOW)
        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "AXI coverage connect phase", UVM_LOW)
            axi_analysis_exp.connect(axi_cov_fifo.analysis_export);
        endfunction : connect_phase

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            `uvm_info(get_type_name(), "AXI coverage run phase", UVM_LOW)

            forever begin
                axi_cov_fifo.get(transaction);
                axi_cg.sample();
            end
        endtask : run_phase

    endclass : axi_coverage

endpackage : axi_coverage_pkg