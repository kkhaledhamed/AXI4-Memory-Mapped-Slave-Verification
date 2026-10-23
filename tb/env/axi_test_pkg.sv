package axi_test_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_env_pkg::*; 
    import axi_sequence_pkg::*;
    import common_cfg_pkg::*;

    // Added to make test override
    import axi_driver_pkg::*; 

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
            phase.drop_objection(this, "axi_base_test completed");
        endtask : run_phase

    endclass : axi_base_test

    class axi_error_test extends uvm_test;
        `uvm_component_utils(axi_error_test)

        axi_environment   axi_env;
        common_axi_cfg    axi_cfg;
        common_mem_cfg    mem_cfg;

        function new(string name = "axi_error_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            `uvm_info(get_type_name(), "AXI Error Test Build phase", UVM_LOW)

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
            axi_oor_seq         oor_seq;
            axi_4kb_cross_seq   cross_seq;

            phase.raise_objection(this, "Starting axi_error_test stimulus");

            reset_seq = axi_reset_seq::type_id::create("reset_seq");
            reset_seq.start(axi_env.axi_agt.axi_seqr);

            oor_seq = axi_oor_seq::type_id::create("oor_seq");
            oor_seq.start(axi_env.axi_agt.axi_seqr);

            cross_seq = axi_4kb_cross_seq::type_id::create("cross_seq");
            cross_seq.start(axi_env.axi_agt.axi_seqr);
            
            #100ns;
            phase.drop_objection(this, "axi_error_test completed");
        endtask : run_phase

    endclass : axi_error_test

    class axi_random_test extends uvm_test;
        `uvm_component_utils(axi_random_test)

        axi_environment   axi_env;
        common_axi_cfg    axi_cfg;
        common_mem_cfg    mem_cfg;

        function new(string name = "axi_random_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            `uvm_info(get_type_name(), "AXI Random Test Build phase", UVM_LOW)

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
            axi_reset_seq   reset_seq;
            axi_random_seq  rnd_seq;

            phase.raise_objection(this, "Starting axi_random_test stimulus");

            repeat (8) begin
                reset_seq = axi_reset_seq::type_id::create("reset_seq");
                reset_seq.start(axi_env.axi_agt.axi_seqr);

                rnd_seq = axi_random_seq::type_id::create("rnd_seq");
                rnd_seq.n_txn = 60;
                rnd_seq.start(axi_env.axi_agt.axi_seqr);
            end

            #100ns;
            phase.drop_objection(this, "axi_random_test completed");
        endtask : run_phase

    endclass : axi_random_test

    class axi_override_test extends axi_random_test;
        `uvm_component_utils(axi_override_test)

        function new(string name = "axi_override_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            // the override must be set before super.build_phase() creates the env
            set_type_override_by_type(axi_driver::get_type(), axi_driver_delay::get_type());

            super.build_phase(phase);

            `uvm_info(get_type_name(), "Type override set: axi_driver -> axi_driver_delay", UVM_LOW)
        endfunction : build_phase

        function void end_of_elaboration_phase(uvm_phase phase);
            super.end_of_elaboration_phase(phase);   // prints the topology
            uvm_factory::get().print(0);             // lists the active overrides
        endfunction : end_of_elaboration_phase

    endclass : axi_override_test

endpackage : axi_test_pkg