package axi_env_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_agent_pkg::*;
    import mem_agent_pkg::*;
    import axi_coverage_pkg::*;
    import axi_scoreboard_pkg::*;
    import mem_coverage_pkg::*;
    import mem_scoreboard_pkg::*;
    import common_cfg_pkg::*;
    
    class axi_environment extends uvm_env;
        `uvm_component_utils(axi_environment)

        axi_agent      axi_agt;
        mem_agent      mem_agt;
        axi_coverage   axi_cov;
        axi_scoreboard axi_scb;
        mem_coverage   mem_cov;
        mem_scoreboard mem_scb;
        common_axi_cfg axi_cfg;
        common_mem_cfg mem_cfg;

        function new(string name = "axi_env", uvm_component parent);
            super.new(name, parent);
        endfunction : new

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            `uvm_info(get_type_name(), "AXI env build phase", UVM_LOW)
            axi_agt = axi_agent::type_id::create("axi_agt",this);
            mem_agt = mem_agent::type_id::create("mem_agt",this);
            axi_cov = axi_coverage::type_id::create("axi_cov",this);
            axi_scb = axi_scoreboard::type_id::create("axi_scb",this);
            mem_cov = mem_coverage::type_id::create("mem_cov",this);
            mem_scb = mem_scoreboard::type_id::create("mem_scb",this);

            if (!uvm_config_db#(common_axi_cfg)::get(this, "", "AXI_Common_Configurations", axi_cfg))
                `uvm_fatal(get_type_name(), "Failed to get test -> env AXI Common Configurations")

            if (!uvm_config_db#(common_mem_cfg)::get(this, "", "MEM_Common_Configurations", mem_cfg))
                `uvm_fatal(get_type_name(), "Failed to get test -> env MEM Common Configurations")

        endfunction : build_phase

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            `uvm_info(get_type_name(), "AXI env connect phase", UVM_LOW)
            
            axi_agt.axi_drv.axi_cfg=axi_cfg;
            axi_agt.axi_mon.axi_cfg=axi_cfg;

            axi_agt.axi_mon.axi_ap.connect(axi_scb.axi_analysis_exp);
            axi_agt.axi_mon.axi_ap.connect(axi_cov.axi_analysis_exp);

            mem_agt.mem_mon.mem_ap.connect(mem_scb.mem_analysis_exp);
            mem_agt.mem_mon.mem_ap.connect(mem_cov.mem_analysis_exp);
        endfunction : connect_phase


    endclass : axi_environment

endpackage : axi_env_pkg