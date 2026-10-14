package common_cfg_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    class common_axi_cfg extends uvm_object;
        `uvm_object_utils(common_axi_cfg)

        function new (string name = "common_axi_cfg");
            super.new(name);
        endfunction : new

        event stimulus_sent_e;

    endclass : common_axi_cfg

    class common_mem_cfg extends uvm_object;
        `uvm_object_utils(common_mem_cfg)

        function new (string name = "common_mem_cfg");
            super.new(name);
        endfunction : new

        // event stimulus_sent_e;

    endclass : common_mem_cfg

endpackage : common_cfg_pkg