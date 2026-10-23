package mem_agent_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import mem_monitor_pkg::*;

    class mem_agent extends uvm_agent;
        `uvm_component_utils(mem_agent)

        mem_monitor   mem_mon;

        function new (string name = "mem_agent", uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "Memory agent build phase", UVM_LOW)

            mem_mon = mem_monitor ::type_id::create("mem_mon",this);

        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "Memory agent connect phase", UVM_LOW)
        endfunction : connect_phase

    endclass : mem_agent

endpackage : mem_agent_pkg