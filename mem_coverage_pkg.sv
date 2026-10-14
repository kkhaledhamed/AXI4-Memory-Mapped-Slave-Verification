package mem_coverage_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import mem_transaction_pkg::*;

    class mem_coverage extends uvm_component;
        `uvm_component_utils(mem_coverage)

        uvm_analysis_export #(mem_transaction)   mem_analysis_exp;
        uvm_tlm_analysis_fifo #(mem_transaction) mem_cov_fifo;

        mem_transaction transaction;

        covergroup mem_cg;
            option.per_instance = 1;

            cp_mem_en: coverpoint transaction.mem_en {
                bins enabled = {1};
                bins idle    = {0};
            }

            cp_mem_we: coverpoint transaction.mem_we {
                bins write = {1};
                bins read  = {0};
            }

            cp_mem_addr: coverpoint transaction.mem_addr {
                bins zero   = {0};
                bins corner = {14, 15, 16, 30, 31};   // targets BUG-02's suspected %15 masking
                bins mid    = {[32:1021]};
                bins last   = {1022, 1023};
            }

            cp_mem_wdata: coverpoint transaction.mem_wdata iff (transaction.mem_en && transaction.mem_we) {
                bins zero     = {32'h0000_0000};
                bins all_ones = {32'hFFFF_FFFF};
                bins alt_55   = {32'h5555_5555};
                bins alt_AA   = {32'hAAAA_AAAA};
                bins others   = default;
            }

            cp_mem_rdata: coverpoint transaction.mem_rdata iff (transaction.mem_en && !transaction.mem_we) {
                bins zero             = {32'h0000_0000};
                bins all_ones         = {32'hFFFF_FFFF};
                bins upper_nibble_set = {[32'h1000_0000 : 32'hFFFF_FFFF]};
                bins others           = default;
            }

            // Direct BUG-01 detector: an access classified WRITE/READ
            // while ARESETn is LOW should never happen on correct RTL.
            cp_access_during_reset: coverpoint transaction.ARESETn iff (transaction.mem_en) {
                bins during_reset = {0};
                bins normal       = {1};
            }

            cx_mem_addr_x_we: cross cp_mem_addr, cp_mem_we;

        endgroup : mem_cg

        function new (string name = "mem_coverage", uvm_component parent);
            super.new(name, parent);
            mem_cg = new();
            mem_analysis_exp = new("mem_analysis_exp", this);
            mem_cov_fifo     = new("mem_cov_fifo", this);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Memory coverage build phase", UVM_LOW)
        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "Memory coverage connect phase", UVM_LOW)
            mem_analysis_exp.connect(mem_cov_fifo.analysis_export);
        endfunction : connect_phase

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            `uvm_info(get_type_name(), "Memory coverage run phase", UVM_LOW)

            forever begin
                mem_cov_fifo.get(transaction);
                mem_cg.sample();
            end
        endtask : run_phase

    endclass : mem_coverage

endpackage : mem_coverage_pkg