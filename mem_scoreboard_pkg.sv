package mem_scoreboard_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import mem_transaction_pkg::*;

    class mem_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(mem_scoreboard)

        uvm_analysis_export #(mem_transaction)   mem_analysis_exp;
        uvm_tlm_analysis_fifo #(mem_transaction) mem_scb_fifo;

        localparam int unsigned MEMORY_DEPTH = 1024;

        bit [31:0] shadow_mem[MEMORY_DEPTH];
        bit        shadow_valid[MEMORY_DEPTH];

        // ------------------------------------------------------------
        // A read request is classified on the cycle mem_en/mem_addr
        // assert, but axi4_memory's registered read output needs one
        // more clock before mem_rdata reflects that address (the same
        // latency the BUG-04 fix added to the AXI read FSM). So a read
        // seen THIS cycle is checked against mem_rdata on the NEXT
        // cycle, not this one.
        // ------------------------------------------------------------
        bit                              pending_read;
        bit [$clog2(MEMORY_DEPTH)-1:0]   pending_read_addr;

        int unsigned pass_count;
        int unsigned error_count;

        function new (string name = "mem_scoreboard", uvm_component parent);
            super.new(name, parent);
            mem_analysis_exp = new("mem_analysis_exp", this);
            mem_scb_fifo     = new("mem_scb_fifo", this);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Memory scoreboard build phase", UVM_LOW)

            foreach (shadow_mem[i]) begin
                shadow_mem[i]   = 32'h0;
                shadow_valid[i] = 1'b0;
            end

            pending_read = 1'b0;
        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "Memory scoreboard connect phase", UVM_LOW)
            mem_analysis_exp.connect(mem_scb_fifo.analysis_export);
        endfunction : connect_phase

        task run_phase(uvm_phase phase);
            mem_transaction transaction;
            super.run_phase(phase);
            `uvm_info(get_type_name(), "Memory scoreboard run phase", UVM_LOW)

            forever begin
                mem_scb_fifo.get(transaction);
                check_access(transaction);
            end
        endtask : run_phase

        function void check_access(mem_transaction t);

            // ---- Resolve any read that was requested last cycle, using
            //      THIS cycle's mem_rdata (one-cycle registered latency) ----
            if (pending_read) begin
                bit [31:0] expected = shadow_valid[pending_read_addr]
                                     ? shadow_mem[pending_read_addr]
                                     : 32'h0;

                if (t.mem_rdata !== expected) begin
                    `uvm_error(get_type_name(),
                        $sformatf("MEM READ MISMATCH: addr=0x%0h expected=0x%0h actual=0x%0h",
                            pending_read_addr, expected, t.mem_rdata))
                    error_count++;
                end
                else begin
                    pass_count++;
                    `uvm_info(get_type_name(),
                        $sformatf("MEM READ PASS: addr=0x%0h data=0x%0h",
                            pending_read_addr, t.mem_rdata), UVM_HIGH)
                end

                pending_read = 1'b0;
            end

            // ---- Startup-transient guard ----
            if ($isunknown(t.ARESETn) || $isunknown(t.mem_en) || $isunknown(t.mem_addr))
                return;

            // ---- Reset content check: mem_rdata must be 0 during reset ----
            if (!t.ARESETn) begin
                if (!$isunknown(t.mem_rdata) && (t.mem_rdata !== 32'h0)) begin
                    `uvm_error(get_type_name(),
                        $sformatf("MEM RESET CONTENT CHECK: ARESETn=0 but mem_rdata=0x%0h (expected 0x0)",
                            t.mem_rdata))
                    error_count++;
                end
                else begin
                    pass_count++;
                end
            end

            // ---- Reset activity check: no write/read allowed during reset ----
            if ((t.access_type != MEM_IDLE) && !t.ARESETn) begin
                `uvm_error(get_type_name(),
                    $sformatf("MEM %s observed while ARESETn=0 (in reset) addr=0x%0h -- reset-polarity violation",
                        (t.access_type == MEM_WRITE) ? "WRITE" : "READ", t.mem_addr))
                error_count++;
                return;
            end

            if (t.access_type == MEM_IDLE)
                return;

            if (t.access_type == MEM_WRITE) begin
                if (t.mem_addr >= MEMORY_DEPTH) begin
                    `uvm_error(get_type_name(),
                        $sformatf("MEM WRITE addr=0x%0h out of range (DEPTH=%0d)",
                            t.mem_addr, MEMORY_DEPTH))
                    error_count++;
                    return;
                end

                shadow_mem[t.mem_addr]   = t.mem_wdata;
                shadow_valid[t.mem_addr] = 1'b1;
                pass_count++;

                `uvm_info(get_type_name(),
                    $sformatf("MEM WRITE addr=0x%0h data=0x%0h", t.mem_addr, t.mem_wdata), UVM_HIGH)
            end
            else begin // MEM_READ
                if (t.mem_addr >= MEMORY_DEPTH) begin
                    `uvm_error(get_type_name(),
                        $sformatf("MEM READ addr=0x%0h out of range (DEPTH=%0d)",
                            t.mem_addr, MEMORY_DEPTH))
                    error_count++;
                    return;
                end

                // Don't check mem_rdata THIS cycle -- it hasn't caught up
                // to this address yet. Remember it and check next sample.
                pending_read      = 1'b1;
                pending_read_addr = t.mem_addr;
            end
        endfunction : check_access

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);

            `uvm_info(get_type_name(),
                $sformatf("MEM SCOREBOARD SUMMARY: Passed = %0d, Failed = %0d, Total = %0d",
                          pass_count, error_count, pass_count + error_count),
                UVM_NONE)
        endfunction : report_phase

    endclass : mem_scoreboard

endpackage : mem_scoreboard_pkg