package axi_transaction_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    typedef enum bit [1:0] {AXI_RESET, AXI_WRITE, AXI_READ} axi_op_e;
    
    class axi_transaction extends uvm_sequence_item;

   	//////////////// Parameters ////////////////
  	parameter MAX_BURST_LEN = 16,
              DATA_WIDTH    = 32,
              ADDR_WIDTH    = 16,
              MEMORY_DEPTH  = 1024;

        // ============================================================
        // Reset
        // ============================================================
        logic ARESETn = 1'b1;               // Driven procedurally by the driver, never randomized
        rand int unsigned reset_cycles;     // Only meaningful when operation_type == AXI_RESET

        // Read/Write Enum
        rand axi_op_e operation_type;

        // ============================================================
        // Write Address Channel
        // ============================================================
        rand bit [ADDR_WIDTH-1:0]   AWADDR;
        rand logic [7:0]  AWLEN;
        rand logic [2:0]  AWSIZE;

        // ============================================================
        // Write Data Channel
        // ============================================================
        rand logic [DATA_WIDTH-1:0] WDATA[];

        // ============================================================
        // Read Address Channel
        // ============================================================
        rand logic [ADDR_WIDTH-1:0] ARADDR;
        rand logic [7:0]  ARLEN;
        rand logic [2:0]  ARSIZE;

        
        /*==================== Non-randomized drive-side ====================*/
    	logic AWVALID, WVALID, WLAST, BREADY, ARVALID, RREADY;

	    /*==================== Sampled by the Monitor ====================*/
	    logic                      AWREADY;

	    logic                      WREADY;
	    
	    logic [1:0]                BRESP;
	    logic                      BVALID;

	    logic                      ARREADY;

	    logic [DATA_WIDTH-1:0]     RDATA[];
	    logic [1:0]                RRESP;
	    logic                      RVALID;
	    logic                      RLAST;

        // set by the sequence before randomization
        bit burst_en = 0;   



        // ============================================================
        // UVM Field Automation
        // ============================================================
        `uvm_object_utils_begin(axi_transaction)

            `uvm_field_int(ARESETn,    UVM_DEFAULT)

            `uvm_field_int(AWADDR, UVM_DEFAULT)
            `uvm_field_int(AWLEN,  UVM_DEFAULT)
            `uvm_field_int(AWSIZE, UVM_DEFAULT)
            `uvm_field_int(AWVALID, UVM_DEFAULT)
            `uvm_field_int(AWREADY, UVM_DEFAULT)

            `uvm_field_array_int(WDATA,  UVM_DEFAULT)
            `uvm_field_int(WLAST,  UVM_DEFAULT)
            `uvm_field_int(WVALID,  UVM_DEFAULT)
            `uvm_field_int(WREADY,  UVM_DEFAULT)

            `uvm_field_int(BRESP,  UVM_DEFAULT)
            `uvm_field_int(BVALID,  UVM_DEFAULT)
            `uvm_field_int(BREADY,  UVM_DEFAULT)

            `uvm_field_int(ARADDR, UVM_DEFAULT)
            `uvm_field_int(ARLEN,  UVM_DEFAULT)
            `uvm_field_int(ARSIZE, UVM_DEFAULT)
            `uvm_field_int(ARVALID, UVM_DEFAULT)
            `uvm_field_int(ARREADY, UVM_DEFAULT)

            `uvm_field_array_int(RDATA,  UVM_DEFAULT)
            `uvm_field_int(RRESP,  UVM_DEFAULT)
            `uvm_field_int(RLAST,  UVM_DEFAULT)
            `uvm_field_int(RVALID,  UVM_DEFAULT)
            `uvm_field_int(RREADY,  UVM_DEFAULT)

            `uvm_field_enum(axi_op_e, operation_type, UVM_DEFAULT)
            `uvm_field_int(burst_en, UVM_DEFAULT)

        `uvm_object_utils_end


        // ============================================================
        // Constructor
        // ============================================================
        function new(string name = "axi_transaction");
            super.new(name);
        endfunction : new


        // ============================================================
        // Constraints
        // ============================================================
        constraint reset_cycles_c {
            reset_cycles inside {[3:6]};
        }

        constraint burst_len_c {
            (burst_en == 0) -> (AWLEN == 0 && ARLEN == 0);
            (burst_en == 1) -> 
                (AWLEN inside {[0:MAX_BURST_LEN-1]} &&
                 ARLEN inside {[0:MAX_BURST_LEN-1]});
        }

        constraint wdata_size_c {
            solve AWLEN before WDATA;
            WDATA.size() == AWLEN + 1;
        }

    endclass : axi_transaction

endpackage : axi_transaction_pkg

