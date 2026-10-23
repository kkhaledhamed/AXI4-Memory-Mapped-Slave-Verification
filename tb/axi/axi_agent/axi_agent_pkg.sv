package axi_agent_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_driver_pkg::*;
    import axi_monitor_pkg::*;
    import axi_sequencer_pkg::*;
    
    class axi_agent extends uvm_agent;
        `uvm_component_utils(axi_agent)

        axi_driver    axi_drv;
        axi_sequencer axi_seqr;
        axi_monitor   axi_mon;

        uvm_active_passive_enum is_active = UVM_ACTIVE;

        function new (string name = "axi_agent", uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI agent build phase", UVM_LOW)
            if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active))
                `uvm_fatal(get_type_name(), "Failed to get axi agent enum value")

            if (is_active == UVM_ACTIVE) begin
                axi_drv       = axi_driver     ::type_id::create("axi_drv",this);
                axi_seqr      = axi_sequencer  ::type_id::create("axi_seqr",this);
            end

            axi_mon = axi_monitor ::type_id::create("axi_mon",this);

        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "AXI agent connect phase", UVM_LOW)
            if (is_active == UVM_ACTIVE) begin
                axi_drv.seq_item_port.connect(axi_seqr.seq_item_export);
            end
        endfunction : connect_phase

    endclass : axi_agent

endpackage : axi_agent_pkg