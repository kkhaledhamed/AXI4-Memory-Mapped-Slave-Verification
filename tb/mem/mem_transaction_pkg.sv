package mem_transaction_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit [1:0] {MEM_IDLE, MEM_WRITE, MEM_READ} mem_access_e;
    
    class mem_transaction extends uvm_sequence_item;

        //////////////// Parameters ////////////////
        parameter DATA_WIDTH   = 32,
                  ADDR_WIDTH   = 10,    
                  MEMORY_DEPTH = 1024;

        // ============================================================
        // Signals
        // ============================================================
        logic                  ARESETn;     

        logic                  mem_en;
        logic                  mem_we;
        logic [ADDR_WIDTH-1:0] mem_addr;   
        logic [DATA_WIDTH-1:0] mem_wdata;
        logic [DATA_WIDTH-1:0] mem_rdata;

        // ============================================================
        // Derived by the monitor at sample time
        // ============================================================
        mem_access_e           access_type;
        time                   sample_time;

        // ============================================================
        // UVM Field Automation
        // ============================================================
        `uvm_object_utils_begin(mem_transaction)

            `uvm_field_int(ARESETn, UVM_DEFAULT)

            `uvm_field_int(mem_en,    UVM_DEFAULT)
            `uvm_field_int(mem_we,    UVM_DEFAULT)
            `uvm_field_int(mem_addr,  UVM_DEFAULT)
            `uvm_field_int(mem_wdata, UVM_DEFAULT)
            `uvm_field_int(mem_rdata, UVM_DEFAULT)

            `uvm_field_enum(mem_access_e, access_type, UVM_DEFAULT)

        `uvm_object_utils_end

        // ============================================================
        // Constructor
        // ============================================================
        function new(string name = "mem_transaction");
            super.new(name);
        endfunction : new

    endclass : mem_transaction

endpackage : mem_transaction_pkg