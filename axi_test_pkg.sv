package axi_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_env_pkg::*;
    import axi_sequence_pkg::*;
    import common_cfg_pkg::*;

    class axi_base_test extends uvm_test;
        `uvm_component_utils(axi_base_test)

        axi_environment   axi_env;
        common_axi_cfg    axi_cfg;
        common_mem_cfg    mem_cfg;

        function new(string name = "axi_base_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            `uvm_info(get_type_name(), "AXI Base Test Build phase", UVM_LOW)

            axi_env = axi_environment::type_id::create("axi_env", this);
            axi_cfg = common_axi_cfg::type_id::create("axi_cfg");
            mem_cfg = common_mem_cfg::type_id::create("mem_cfg");

            uvm_config_db#(common_axi_cfg)::set(null, "*", "AXI_Common_Configurations", axi_cfg);
            uvm_config_db#(common_mem_cfg)::set(null, "*", "MEM_Common_Configurations", mem_cfg);

        endfunction : build_phase

        function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);
            `uvm_info(get_type_name(), "Starting AXI end of elaboration phase", UVM_LOW)
            uvm_top.print_topology();
        endfunction : end_of_elaboration_phase

        task run_phase(uvm_phase phase);
            axi_reset_seq       reset_seq;
            axi_write_read_seq  wr_rd_seq;
            axi_corner_addr_seq corner_seq;

            phase.raise_objection(this, "Starting axi_base_test stimulus");

            reset_seq = axi_reset_seq::type_id::create("reset_seq");
            reset_seq.start(axi_env.axi_agt.axi_seqr);

            wr_rd_seq = axi_write_read_seq::type_id::create("wr_rd_seq");
            if (!wr_rd_seq.randomize())
                `uvm_fatal(get_type_name(), "axi_base_test: wr_rd_seq.randomize() failed")
            wr_rd_seq.start(axi_env.axi_agt.axi_seqr);

            corner_seq = axi_corner_addr_seq::type_id::create("corner_seq");
            corner_seq.start(axi_env.axi_agt.axi_seqr);

            #100ns;
            phase.drop_objection(this, "axi_base_test stimulus complete");
        endtask : run_phase

    endclass : axi_base_test

endpackage : axi_test_pkg