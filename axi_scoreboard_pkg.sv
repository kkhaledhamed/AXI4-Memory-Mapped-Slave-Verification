package axi_scoreboard_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;

    class axi_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(axi_scoreboard)

        uvm_analysis_export #(axi_transaction)   axi_analysis_exp;
        uvm_tlm_analysis_fifo #(axi_transaction) axi_scb_fifo;

        localparam int unsigned MEMORY_DEPTH = 1024;
        localparam int unsigned WORD_BYTES   = 4;     
        localparam bit [15:0]   BOUNDARY_MASK = 16'hFFF;

        bit [31:0] shadow_mem[MEMORY_DEPTH];
        bit        shadow_valid[MEMORY_DEPTH];   

        int unsigned pass_count;
        int unsigned error_count;

        function new (string name = "axi_scoreboard", uvm_component parent);
            super.new(name, parent);
            axi_analysis_exp = new("analysis_exp", this);
            axi_scb_fifo     = new("scb_fifo", this);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI scoreboard build phase", UVM_LOW)

            foreach (shadow_mem[i]) begin
                shadow_mem[i]   = 32'h0;
                shadow_valid[i] = 1'b0;
            end
        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "AXI scoreboard connect phase", UVM_LOW)
            axi_analysis_exp.connect(axi_scb_fifo.analysis_export);
        endfunction : connect_phase

        task run_phase(uvm_phase phase);
            axi_transaction transaction;
            super.run_phase(phase);
            `uvm_info(get_type_name(), "AXI scoreboard run phase", UVM_LOW)

            forever begin
                axi_scb_fifo.get(transaction);

                case (transaction.operation_type)
                    AXI_WRITE : check_write(transaction);
                    AXI_READ  : check_read(transaction);
                    AXI_RESET : `uvm_info(get_type_name(),
                                    $sformatf("Reset observed (%0d cycles) -- no data checked",
                                        transaction.reset_cycles), UVM_MEDIUM)
                    default   : `uvm_error(get_type_name(), "Unknown operation_type on scoreboard fifo")
                endcase
            end
        endtask : run_phase


        function void check_write(axi_transaction t);
            int unsigned num_beats = t.AWLEN + 1;
            bit          any_beat_illegal = 1'b0;

            for (int unsigned i = 0; i < num_beats; i++) begin
                bit [15:0] byte_addr  = t.AWADDR + (i * WORD_BYTES);
                // starting position inside 4-KB block + burst size
                bit        crosses_4k = ((t.AWADDR & BOUNDARY_MASK) + (num_beats * WORD_BYTES)) > (BOUNDARY_MASK + 1);
                bit        in_range   = (byte_addr >> 2) < MEMORY_DEPTH;
                bit        legal      = in_range && !crosses_4k;

                if (!legal)
                    any_beat_illegal = 1'b1;

                if (legal) begin
                    int unsigned word_addr = byte_addr >> 2;
                    shadow_mem[word_addr]   = t.WDATA[i];
                    shadow_valid[word_addr] = 1'b1;
                end
            end

            if (any_beat_illegal) begin
                if (t.BRESP != 2'b10) begin
                    `uvm_error(get_type_name(),
                        $sformatf("WRITE addr=0x%0h: expected SLVERR for illegal access, got BRESP=%0b",
                            t.AWADDR, t.BRESP))
                    error_count++;
                end
                else begin
                    pass_count++;
                end
            end
            else begin
                if (t.BRESP != 2'b00) begin
                    `uvm_error(get_type_name(),
                        $sformatf("WRITE addr=0x%0h: expected OKAY for legal access, got BRESP=%0b",
                            t.AWADDR, t.BRESP))
                    error_count++;
                end
                else begin
                    pass_count++;
                    `uvm_info(get_type_name(),
                        $sformatf("WRITE addr=0x%0h beats=%0d PASS", t.AWADDR, num_beats), UVM_MEDIUM)
                end
            end
        endfunction : check_write

        function void check_read(axi_transaction t);
            int unsigned num_beats = t.ARLEN + 1;
            bit          any_beat_illegal = 1'b0;

            if (t.RDATA.size() != num_beats) begin
                `uvm_error(get_type_name(),
                    $sformatf("READ addr=0x%0h: monitor captured %0d beats, expected %0d from ARLEN",
                        t.ARADDR, t.RDATA.size(), num_beats))
                error_count++;
                return;
            end

            for (int unsigned i = 0; i < num_beats; i++) begin
                bit [15:0]   byte_addr  = t.ARADDR + (i * WORD_BYTES);
                bit          crosses_4k = ((t.ARADDR & BOUNDARY_MASK) + (num_beats * WORD_BYTES)) > (BOUNDARY_MASK + 1);
                bit          in_range   = (byte_addr >> 2) < MEMORY_DEPTH;
                bit          legal      = in_range && !crosses_4k;
                bit [31:0]   expected;

                if (!legal) begin
                    any_beat_illegal = 1'b1;
                    expected = 32'h0;

                    if (t.RDATA[i] !== expected) begin
                        `uvm_error(get_type_name(),
                            $sformatf("READ addr=0x%0h beat=%0d: illegal access expected RDATA=0, got 0x%0h",
                                byte_addr, i, t.RDATA[i]))
                        error_count++;
                    end
                    else
                        pass_count++;
                end
                else begin
                    int unsigned word_addr = byte_addr >> 2;
                    expected = shadow_valid[word_addr] ? shadow_mem[word_addr] : 32'h0;

                    if (t.RDATA[i] !== expected) begin
                        `uvm_error(get_type_name(),
                            $sformatf("READ addr=0x%0h beat=%0d MISMATCH: expected=0x%0h actual=0x%0h",
                                byte_addr, i, expected, t.RDATA[i]))
                        error_count++;
                    end
                    else begin
                        pass_count++;
                        `uvm_info(get_type_name(),
                            $sformatf("READ addr=0x%0h beat=%0d data=0x%0h PASS", byte_addr, i, t.RDATA[i]),
                            UVM_HIGH)
                    end
                end
            end

            if (any_beat_illegal && (t.RRESP != 2'b10)) begin
                `uvm_error(get_type_name(),
                    $sformatf("READ addr=0x%0h: expected SLVERR for illegal access, got RRESP=%0b",
                        t.ARADDR, t.RRESP))
                error_count++;
            end
            else if (!any_beat_illegal && (t.RRESP != 2'b00)) begin
                `uvm_error(get_type_name(),
                    $sformatf("READ addr=0x%0h: expected OKAY for legal access, got RRESP=%0b",
                        t.ARADDR, t.RRESP))
                error_count++;
            end
        endfunction : check_read

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);

            `uvm_info(get_type_name(),
                $sformatf("AXI SCOREBOARD SUMMARY: Passed = %0d, Failed = %0d, Total = %0d",
                          pass_count, error_count, pass_count + error_count),
                UVM_NONE)
        endfunction : report_phase

    endclass : axi_scoreboard

endpackage : axi_scoreboard_pkg