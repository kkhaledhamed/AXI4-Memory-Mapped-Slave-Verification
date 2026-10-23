package axi_sequence_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import axi_transaction_pkg::*;

    class axi_base_sequence extends uvm_sequence #(axi_transaction);
        `uvm_object_utils(axi_base_sequence)

        function new (string name = "axi_base_sequence");
            super.new(name);
        endfunction : new

        task body();
            // Intentionally empty
        endtask : body

    endclass : axi_base_sequence

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

                // Walking ones  
                pattern = (32'h0000_0001 << (i % 32));

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


    class axi_oor_seq extends axi_base_sequence;
        `uvm_object_utils(axi_oor_seq)

        local bit [15:0] oor_addrs[] = '{16'h1000, 16'h1004, 16'h8000, 16'hFFFC};

        function new(string name = "axi_oor_seq");
            super.new(name);
        endfunction

        task do_write(bit [15:0] addr, bit [31:0] data);
            axi_transaction t = axi_transaction::type_id::create("oor_wr");
            start_item(t);
            if (!t.randomize() with { operation_type == AXI_WRITE; burst_en == 0;
                                      AWADDR == addr; WDATA[0] == data; })
                `uvm_fatal(get_type_name(), "write randomize() failed")
            finish_item(t);
        endtask

        task do_read(bit [15:0] addr);
            axi_transaction t = axi_transaction::type_id::create("oor_rd");
            start_item(t);
            if (!t.randomize() with { operation_type == AXI_READ; burst_en == 0; ARADDR == addr; })
                `uvm_fatal(get_type_name(), "read randomize() failed")
            finish_item(t);
        endtask

        task body();
            do_write(16'h0000, 32'hA5A5_A5A5);   // victim word 0
            do_write(16'h0004, 32'h5A5A_5A5A);   // victim word 1

            foreach (oor_addrs[i]) begin
                do_write(oor_addrs[i], 32'hDEAD_0000 + i);
                do_read (oor_addrs[i]);
            end

            do_read(16'h0000);   // victims must be intact
            do_read(16'h0004);
        endtask
    endclass : axi_oor_seq


    class axi_4kb_cross_seq extends axi_base_sequence;
        `uvm_object_utils(axi_4kb_cross_seq)

        // {start byte address, AWLEN}
        local bit [15:0] cross_addr[]  = '{16'h0FF0, 16'h0FFC, 16'h0FC4};
        local bit [7:0]  cross_len[]   = '{8'd7,     8'd1,     8'd15};   // all end past 0x1000
        local bit [15:0] legal_addr[]  = '{16'h0FC0, 16'h0FA0, 16'h0FF8};
        local bit [7:0]  legal_len[]   = '{8'd15,    8'd15,    8'd1};    // all end at or before 0x1000

        function new(string name = "axi_4kb_cross_seq");
            super.new(name);
        endfunction

        task burst(bit [15:0] addr, bit [7:0] len);
            axi_transaction w = axi_transaction::type_id::create("blk_wr");
            axi_transaction r = axi_transaction::type_id::create("blk_rd");

            start_item(w);
            w.burst_en = 1;
            if (!w.randomize() with { operation_type == AXI_WRITE; burst_en == 1; AWADDR == addr; AWLEN == len; })
                `uvm_fatal(get_type_name(), "burst write randomize() failed")
            finish_item(w);

            start_item(r);
            r.burst_en = 1;
            if (!r.randomize() with { operation_type == AXI_READ; burst_en == 1; ARADDR == addr; ARLEN == len; })
                `uvm_fatal(get_type_name(), "burst read randomize() failed")
            finish_item(r);

            `uvm_info(get_type_name(),
                $sformatf("BURST addr=0x%0h beats=%0d end=0x%0h", addr, len + 1, addr + (len + 1) * 4),
                UVM_MEDIUM)
        endtask

        task body();
            foreach (cross_addr[i]) burst(cross_addr[i], cross_len[i]);   // expect SLVERR
            foreach (legal_addr[i]) burst(legal_addr[i], legal_len[i]);   // expect OKAY
        endtask
    endclass : axi_4kb_cross_seq


    class axi_random_seq extends axi_base_sequence;
        `uvm_object_utils(axi_random_seq)

        int unsigned n_txn = 100;   

        rand bit        is_burst;
        rand bit [15:0] addr;

        constraint addr_c {
            addr dist {
                0              := 1,   // zero
                [4:1020]       :/ 3,   // low
                [1024:3068]    :/ 3,   // mid
                [3072:4028]    :/ 1,   // high
                [4032:4088]    :/ 4,   // high, top of the page
                4092           := 1,   // last_word
                [4096:65000]   :/ 3    // out of range
            };
        }

        function new (string name = "axi_random_seq");
            super.new(name);
        endfunction : new

        task body();
            axi_transaction wr_item;
            axi_transaction rd_item;

            repeat (n_txn) begin
                if (!this.randomize())
                    `uvm_fatal(get_type_name(), "axi_random_seq: randomize() failed")

                // ---- Write ----
                wr_item = axi_transaction::type_id::create("rnd_wr");
                start_item(wr_item);
                wr_item.burst_en = is_burst;
                if (!wr_item.randomize() with {
                        operation_type == AXI_WRITE;
                        AWADDR == local::addr;
                    })
                    `uvm_fatal(get_type_name(), "axi_random_seq: write randomize() failed")
                finish_item(wr_item);

                // ---- Read back the same address ----
                rd_item = axi_transaction::type_id::create("rnd_rd");
                start_item(rd_item);
                rd_item.burst_en = is_burst;
                if (!rd_item.randomize() with {
                        operation_type == AXI_READ;
                        ARADDR == local::addr;
                    })
                    `uvm_fatal(get_type_name(), "axi_random_seq: read randomize() failed")
                finish_item(rd_item);
            end
        endtask : body

    endclass : axi_random_seq


endpackage : axi_sequence_pkg