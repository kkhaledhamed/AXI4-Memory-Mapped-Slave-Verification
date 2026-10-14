package axi_driver_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;
    import common_cfg_pkg::*;

    class axi_driver extends uvm_driver #(axi_transaction);

        `uvm_component_utils(axi_driver)
        common_axi_cfg axi_cfg;

        virtual axi_if.MASTER vif;

        function new(string name = "axi_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI driver build phase", UVM_LOW)

            if (!uvm_config_db#(virtual axi_if)::get(this, "", "AXI_Virtual_Interface", vif))
                `uvm_fatal(get_type_name(), "Failed to get axi driver interface")
        endfunction : build_phase

        task run_phase(uvm_phase phase);
            `uvm_info(get_type_name(), "AXI driver run phase", UVM_LOW)

            drive_idle();

            forever begin
                axi_transaction item;
                seq_item_port.get_next_item(item);

                case (item.operation_type)
                    AXI_RESET : do_reset(item);
                    AXI_WRITE : do_write(item);
                    AXI_READ  : do_read(item);
                    default   : `uvm_error(get_type_name(),
                                    $sformatf("Unknown operation_type: %0d", item.operation_type))
                endcase

                seq_item_port.item_done();
            end
        endtask : run_phase

        // ------------------------------------------------------------
        // Idle drive levels, applied once before the first item.
        // Each do_* task is responsible for returning its own channel
        // to idle when it finishes.
        // ------------------------------------------------------------
        task drive_idle();
            vif.ARESETn <= 1'b1;
            vif.AWVALID <= 1'b0;
            vif.WVALID  <= 1'b0;
            vif.WLAST   <= 1'b0;
            vif.BREADY  <= 1'b1;   // default HIGH per spec unless a test overrides
            vif.ARVALID <= 1'b0;
            vif.RREADY  <= 1'b1;   // default HIGH per spec unless a test overrides
        endtask : drive_idle

        // ------------------------------------------------------------
        // Reset: drive ARESETn low for item.reset_cycles clocks, then
        // release. Touches nothing else.
        // ------------------------------------------------------------
        task do_reset(axi_transaction item);
            `uvm_info(get_type_name(),
                $sformatf("Driving reset for %0d cycles", item.reset_cycles), UVM_MEDIUM)

            @(posedge vif.ACLK);
            vif.ARESETn <= 1'b0;

            repeat (item.reset_cycles) @(posedge vif.ACLK);

            vif.ARESETn <= 1'b1;
            @(posedge vif.ACLK);
        endtask : do_reset

        // ------------------------------------------------------------
        // Write: one AW handshake, then AWLEN+1 W beats, then one B.
        // burst_en==0 forces AWLEN==0 upstream
        // ------------------------------------------------------------
        task do_write(axi_transaction item);
            int unsigned num_beats = item.AWLEN + 1;

            // Sanity check: catches a solve-order/constraint mistake
            if (item.WDATA.size() != num_beats)
                `uvm_error(get_type_name(),
                    $sformatf("WDATA.size()=%0d does not match AWLEN+1=%0d",
                        item.WDATA.size(), num_beats))

            // ---- Write Address Channel ----
            @(posedge vif.ACLK);
            vif.AWADDR  <= item.AWADDR;
            vif.AWLEN   <= item.AWLEN;
            vif.AWSIZE  <= item.AWSIZE;
            vif.AWVALID <= 1'b1;

            do @(posedge vif.ACLK); while (!vif.AWREADY);
            vif.AWVALID <= 1'b0;

            // ---- Write Data Channel ----
            for (int unsigned i = 0; i < num_beats; i++) begin
                vif.WDATA  <= item.WDATA[i];
                vif.WLAST  <= (i == num_beats - 1);
                vif.WVALID <= 1'b1;

                do @(posedge vif.ACLK); while (!vif.WREADY);
            end
            vif.WVALID <= 1'b0;
            vif.WLAST  <= 1'b0;

            // ---- Write Response Channel ----
            do @(posedge vif.ACLK); while (!vif.BVALID);
            item.BRESP = vif.BRESP;

            `uvm_info(get_type_name(),
                $sformatf("WRITE addr=0x%0h beats=%0d burst_en=%0d resp=%0b",
                    item.AWADDR, num_beats, item.burst_en, item.BRESP), UVM_MEDIUM)
        endtask : do_write

        // ----------------------------------------------------------------------
        // Read: one AR handshake, then ARLEN+1 R beats collected into item.RDATA 
        // ----------------------------------------------------------------------
        task do_read(axi_transaction item);
            int unsigned num_beats = item.ARLEN + 1;

            item.RDATA = new[num_beats];

            // ---- Read Address Channel: once ----
            @(posedge vif.ACLK);
            vif.ARADDR  <= item.ARADDR;
            vif.ARLEN   <= item.ARLEN;
            vif.ARSIZE  <= item.ARSIZE;
            vif.ARVALID <= 1'b1;

            do @(posedge vif.ACLK); while (!vif.ARREADY);
            vif.ARVALID <= 1'b0;

            // ---- Read Data Channel----
            for (int unsigned i = 0; i < num_beats; i++) begin
                do @(posedge vif.ACLK); while (!vif.RVALID);
                item.RDATA[i] = vif.RDATA;
                item.RRESP    = vif.RRESP; 
                item.RLAST    = vif.RLAST;
            end

            // Sanity check: DUT should assert RLAST exactly on the final beat.
            if (!item.RLAST)
                `uvm_warning(get_type_name(),
                    $sformatf("Expected RLAST on final beat (%0d) but RLAST was low", num_beats - 1))

            `uvm_info(get_type_name(),
                $sformatf("READ addr=0x%0h beats=%0d burst_en=%0d resp=%0b",
                    item.ARADDR, num_beats, item.burst_en, item.RRESP), UVM_MEDIUM)
        endtask : do_read

    endclass : axi_driver

endpackage : axi_driver_pkg