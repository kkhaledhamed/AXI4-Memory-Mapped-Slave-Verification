package axi_monitor_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;
    import common_cfg_pkg::*;

    class axi_monitor extends uvm_monitor;

        `uvm_component_utils(axi_monitor)
        common_axi_cfg axi_cfg;

        virtual axi_if.MONITOR vif;

        uvm_analysis_port #(axi_transaction) axi_ap;

        function new(string name = "axi_monitor", uvm_component parent = null);
            super.new(name, parent);
            axi_ap = new("axi_ap", this);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI monitor build phase", UVM_LOW)

            if (!uvm_config_db#(virtual axi_if)::get(this, "", "AXI_Virtual_Interface", vif))
                `uvm_fatal(get_type_name(), "Failed to get axi monitor interface")
        endfunction : build_phase

        task run_phase(uvm_phase phase);
            `uvm_info(get_type_name(), "AXI monitor run phase", UVM_LOW)

            fork
                watch_reset();
                watch_write();
                watch_read();
            join
        endtask : run_phase

        // ------------------------------------------------------------
        // Reset observation
        // ------------------------------------------------------------
        task watch_reset();
            forever begin
                @(negedge vif.ARESETn);
                begin
                    axi_transaction item;
                    int unsigned cycles = 0;

                    do begin
                        @(posedge vif.ACLK);
                        cycles++;
                    end while (!vif.ARESETn);

                    item = axi_transaction::type_id::create("mon_reset_item");
                    item.operation_type = AXI_RESET;
                    item.reset_cycles   = cycles;

                    `uvm_info(get_type_name(),
                        $sformatf("MON RESET observed width=%0d cycles", cycles), UVM_MEDIUM)

                    axi_ap.write(item);
                end
            end
        endtask : watch_reset

        // ------------------------------------------------------------
        // Write channel observation -- samples AW, then AWLEN+1 WDATA
        // beats (checking WLAST lands exactly on the final beat), then B.
        // ------------------------------------------------------------
        task watch_write();
            forever begin
                axi_transaction item;
                int unsigned    num_beats;
                int unsigned    beat_cnt;

                do @(posedge vif.ACLK); while (!(vif.AWVALID && vif.AWREADY));

                item = axi_transaction::type_id::create("mon_write_item");
                item.operation_type = AXI_WRITE;
                item.AWADDR = vif.AWADDR;
                item.AWLEN  = vif.AWLEN;
                item.AWSIZE = vif.AWSIZE;

                num_beats  = item.AWLEN + 1;
                item.WDATA = new[num_beats];

                beat_cnt = 0;
                while (beat_cnt < num_beats) begin
                    @(posedge vif.ACLK);
                    if (vif.WVALID && vif.WREADY) begin
                        item.WDATA[beat_cnt] = vif.WDATA;

                        if ((beat_cnt == num_beats - 1) && !vif.WLAST)
                            `uvm_warning(get_type_name(),
                                $sformatf("MON WRITE: expected WLAST on beat %0d (AWLEN=%0d) but WLAST was low",
                                    beat_cnt, item.AWLEN))
                        if ((beat_cnt != num_beats - 1) && vif.WLAST)
                            `uvm_warning(get_type_name(),
                                $sformatf("MON WRITE: WLAST asserted early on beat %0d (expected on %0d)",
                                    beat_cnt, num_beats - 1))

                        beat_cnt++;
                    end
                end

                do @(posedge vif.ACLK); while (!(vif.BVALID && vif.BREADY));
                item.BRESP = vif.BRESP;

                `uvm_info(get_type_name(),
                    $sformatf("MON WRITE addr=0x%0h beats=%0d resp=%0b",
                        item.AWADDR, num_beats, item.BRESP), UVM_MEDIUM)

                axi_ap.write(item);
            end
        endtask : watch_write

        task watch_read();
            forever begin
                axi_transaction item;
                int unsigned    expected_beats;
                int unsigned    beat_cnt;
                logic           last_seen;

                do @(posedge vif.ACLK); while (!(vif.ARVALID && vif.ARREADY));

                item = axi_transaction::type_id::create("mon_read_item");
                item.operation_type = AXI_READ;
                item.ARADDR = vif.ARADDR;
                item.ARLEN  = vif.ARLEN;
                item.ARSIZE = vif.ARSIZE;

                expected_beats = item.ARLEN + 1;
                item.RDATA     = new[0];
                beat_cnt        = 0;
                last_seen       = 1'b0;

                while (!last_seen) begin
                    @(posedge vif.ACLK);
                    if (vif.RVALID && vif.RREADY) begin
                        item.RDATA = new[beat_cnt + 1](item.RDATA);
                        item.RDATA[beat_cnt] = vif.RDATA;
                        item.RRESP = vif.RRESP;
                        item.RLAST = vif.RLAST;

                        if ((beat_cnt == expected_beats - 1) && !vif.RLAST)
                            `uvm_warning(get_type_name(),
                                $sformatf("MON READ: expected RLAST on beat %0d (ARLEN=%0d) but RLAST was low",
                                    beat_cnt, item.ARLEN))
                        if ((beat_cnt != expected_beats - 1) && vif.RLAST)
                            `uvm_warning(get_type_name(),
                                $sformatf("MON READ: RLAST asserted early on beat %0d (expected on %0d)",
                                    beat_cnt, expected_beats - 1))

                        last_seen = vif.RLAST;
                        beat_cnt++;
                    end
                end

                if (beat_cnt != expected_beats)
                    `uvm_warning(get_type_name(),
                        $sformatf("MON READ: observed %0d beats before RLAST, expected %0d from ARLEN",
                            beat_cnt, expected_beats))

                `uvm_info(get_type_name(),
                    $sformatf("MON READ addr=0x%0h beats=%0d resp=%0b",
                        item.ARADDR, beat_cnt, item.RRESP), UVM_MEDIUM)

                axi_ap.write(item);
            end
        endtask : watch_read

    endclass : axi_monitor

endpackage : axi_monitor_pkg