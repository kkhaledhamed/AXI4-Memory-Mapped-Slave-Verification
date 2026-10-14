package axi_sequence_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;

    // Abstract base -- deliberately does nothing on its own. It exists
    // so every concrete sequence shares one parent type, matching the
    // Sequences sheet (SEQ-01). Nothing should ever call
    // axi_base_sequence::start() directly.
    class axi_base_sequence extends uvm_sequence #(axi_transaction);
        `uvm_object_utils(axi_base_sequence)

        function new (string name = "axi_base_sequence");
            super.new(name);
        endfunction : new

        task body();
            // Intentionally empty -- concrete sequences below provide
            // real behavior. Do not add stimulus here.
        endtask : body

    endclass : axi_base_sequence


    // ------------------------------------------------------------
    // axi_reset_seq (SEQ-00) -- drives one reset pulse through the
    // normal sequencer/driver path. reset_cycles is left rand so the
    // driver/DUT see a randomized pulse width each time this runs
    // (constrained 3-6 in the transaction), rather than a fixed value.
    // ------------------------------------------------------------
    class axi_reset_seq extends axi_base_sequence;
        `uvm_object_utils(axi_reset_seq)

        function new (string name = "axi_reset_seq");
            super.new(name);
        endfunction : new

        task body();
            axi_transaction req;

            req = axi_transaction::type_id::create("reset_item");
            start_item(req);

            if (!req.randomize() with { operation_type == AXI_RESET; })
                `uvm_fatal(get_type_name(), "axi_reset_seq: randomize() failed")

            `uvm_info(get_type_name(),
                $sformatf("Issuing reset pulse for %0d cycles", req.reset_cycles), UVM_MEDIUM)

            finish_item(req);
        endtask : body

    endclass : axi_reset_seq

    // add to axi_sequence_pkg, alongside axi_base_sequence and axi_reset_seq

    // ------------------------------------------------------------
    // axi_write_read_seq (SEQ-04) -- writes a known value to an address,
    // then reads the same address back. Primary data-integrity vector,
    // and the sequence that actually exercises the write->memory->read
    // ------------------------------------------------------------
    class axi_write_read_seq extends axi_base_sequence;
        `uvm_object_utils(axi_write_read_seq)

        rand bit [15:0] addr;
        rand bit [31:0] data;

        constraint addr_c { addr inside {[16'h0000 : 16'h0FFC]}; addr[1:0] == 2'b00; }

        function new (string name = "axi_write_read_seq");
            super.new(name);
        endfunction : new

        task body();
            axi_transaction wr_item;
            axi_transaction rd_item;

            // ---- Write ----
            wr_item = axi_transaction::type_id::create("wr_item");
            start_item(wr_item);
            if (!wr_item.randomize() with {
                    operation_type == AXI_WRITE;
                    burst_en == 0;
                    AWADDR == local::addr;
                    WDATA[0] == local::data;
                })
                `uvm_fatal(get_type_name(), "axi_write_read_seq: write randomize() failed")
            finish_item(wr_item);

            // ---- Read back the same address ----
            rd_item = axi_transaction::type_id::create("rd_item");
            start_item(rd_item);
            if (!rd_item.randomize() with {
                    operation_type == AXI_READ;
                    burst_en == 0;
                    ARADDR == local::addr;
                })
                `uvm_fatal(get_type_name(), "axi_write_read_seq: read randomize() failed")
            finish_item(rd_item);

            `uvm_info(get_type_name(),
                $sformatf("WRITE-READ addr=0x%0h data=0x%0h", addr, data), UVM_MEDIUM)
        endtask : body

    endclass : axi_write_read_seq


    class axi_corner_addr_seq extends axi_base_sequence;
        `uvm_object_utils(axi_corner_addr_seq)


        local int unsigned word_addrs[] = '{0, 14, 15, 16, 30, 31, 1023};

        function new (string name = "axi_corner_addr_seq");
            super.new(name);
        endfunction : new

        task body();
            foreach (word_addrs[i]) begin
                bit [15:0] byte_addr = word_addrs[i] * 4;
                bit [31:0] pattern;
                axi_transaction wr_item;
                axi_transaction rd_item;

                // Alternate patterns across the sweep: all-ones is the
                // strongest single pattern for catching a truncating
                // bitmask (e.g. the suspected 'hFFF_FFFF 28-bit mask),
                // all-zero and a walking pattern cover the rest.
                case (i % 3)
                    0: pattern = 32'hFFFF_FFFF;
                    1: pattern = 32'h0000_0000;
                    default: pattern = (32'h0000_0001 << (i % 32));
                endcase

                // ---- Write ----
                wr_item = axi_transaction::type_id::create($sformatf("corner_wr_%0d", i));
                start_item(wr_item);
                if (!wr_item.randomize() with {
                        operation_type == AXI_WRITE;
                        burst_en == 0;
                        AWADDR == byte_addr;
                        WDATA[0] == pattern;
                    })
                    `uvm_fatal(get_type_name(),
                        $sformatf("corner write randomize() failed at word_addr=%0d", word_addrs[i]))
                finish_item(wr_item);

                // ---- Read back the same address ----
                rd_item = axi_transaction::type_id::create($sformatf("corner_rd_%0d", i));
                start_item(rd_item);
                if (!rd_item.randomize() with {
                        operation_type == AXI_READ;
                        burst_en == 0;
                        ARADDR == byte_addr;
                    })
                    `uvm_fatal(get_type_name(),
                        $sformatf("corner read randomize() failed at word_addr=%0d", word_addrs[i]))
                finish_item(rd_item);

                `uvm_info(get_type_name(),
                    $sformatf("CORNER word_addr=%0d byte_addr=0x%0h pattern=0x%0h",
                        word_addrs[i], byte_addr, pattern), UVM_MEDIUM)
            end
        endtask : body

    endclass : axi_corner_addr_seq

endpackage : axi_sequence_pkg