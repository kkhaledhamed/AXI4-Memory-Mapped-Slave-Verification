package mem_monitor_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import mem_transaction_pkg::*;

    class mem_monitor extends uvm_monitor;

        `uvm_component_utils(mem_monitor)

        // ------------------------------------------------------------
        // Memory monitor interface
        // ------------------------------------------------------------
        virtual mem_if.MONITOR vif;

        uvm_analysis_port #(mem_transaction) mem_ap;


        // ------------------------------------------------------------
        // Constructor
        // ------------------------------------------------------------
        function new(string name = "mem_monitor",
                     uvm_component parent = null);

            super.new(name, parent);

            mem_ap = new("mem_ap", this);

        endfunction : new


        // ------------------------------------------------------------
        // Build phase
        // ------------------------------------------------------------
        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            `uvm_info(get_type_name(),
                      "Memory monitor build phase",
                      UVM_LOW)

            if (!uvm_config_db#(virtual mem_if)::get(
                    this,
                    "",
                    "MEM_Virtual_Interface",
                    vif)) begin

                `uvm_fatal(get_type_name(),
                    "Failed to get memory monitor interface")

            end

        endfunction : build_phase


        // ------------------------------------------------------------
        // Run phase
        // ------------------------------------------------------------
        task run_phase(uvm_phase phase);

            `uvm_info(get_type_name(),
                      "Memory monitor run phase",
                      UVM_LOW)

            watch_memory();

        endtask : run_phase


        // ------------------------------------------------------------
        // Monitor memory interface
        // ------------------------------------------------------------
        task watch_memory();

            forever begin

                mem_transaction item;


                // ----------------------------------------------------
                // Wait for memory clock edge
                // ----------------------------------------------------
                @(posedge vif.clk);
                #1;


                // ----------------------------------------------------
                // Create transaction
                // ----------------------------------------------------
                item = mem_transaction::type_id::create("mem_item");


                // ----------------------------------------------------
                // Sample MEMORY-SIDE signals only
                // ----------------------------------------------------
                item.ARESETn     = vif.rst_n;
                item.mem_en      = vif.mem_en;
                item.mem_we      = vif.mem_we;
                item.mem_addr    = vif.mem_addr;
                item.mem_wdata   = vif.mem_wdata;
                item.mem_rdata   = vif.mem_rdata;
                item.sample_time = $time;


                // ----------------------------------------------------
                // Determine memory access type
                // ----------------------------------------------------
                if ($isunknown(vif.mem_en) || !vif.mem_en) begin

                    item.access_type = MEM_IDLE;

                end
                else if ($isunknown(vif.mem_we)) begin

                    item.access_type = MEM_IDLE;

                end
                else if (vif.mem_we) begin

                    item.access_type = MEM_WRITE;

                end
                else begin

                    item.access_type = MEM_READ;

                end


                // ----------------------------------------------------
                // Debug information
                // ----------------------------------------------------
                `uvm_info(get_type_name(),
                    $sformatf(
                        "MEM SAMPLE: rst_n=%0b mem_en=%0b mem_we=%0b addr=0x%0h wdata=0x%0h rdata=0x%0h access=%s @%0t",
                        item.ARESETn,
                        item.mem_en,
                        item.mem_we,
                        item.mem_addr,
                        item.mem_wdata,
                        item.mem_rdata,
                        item.access_type.name(),
                        item.sample_time),
                    UVM_MEDIUM)


                // ----------------------------------------------------
                // Send transaction to scoreboard/coverage
                // ----------------------------------------------------
                mem_ap.write(item);

            end

        endtask : watch_memory


    endclass : mem_monitor

endpackage : mem_monitor_pkg