package axi_sequencer_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;
    
    class axi_sequencer extends uvm_sequencer #(axi_transaction);
        `uvm_component_utils(axi_sequencer)

        function new (string name = "axi_sequencer", uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI sequencer build phase", UVM_LOW)
        endfunction : build_phase

    endclass : axi_sequencer

endpackage : axi_sequencer_pkg