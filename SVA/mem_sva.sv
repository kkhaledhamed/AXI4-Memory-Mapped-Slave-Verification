`include "uvm_macros.svh"

module mem_sva #(
    parameter int unsigned DEPTH = 1024
) (
    mem_if.MONITOR mem_if
);

    import uvm_pkg::*;

    // =====================================================
    // Properties
    // =====================================================
    property P1;
        @(posedge mem_if.clk)
        !mem_if.rst_n |-> (!mem_if.mem_en && !mem_if.mem_rdata);
    endproperty

    property P2;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        mem_if.mem_we |-> mem_if.mem_en;
    endproperty

    property P3;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        mem_if.mem_en |-> !$isunknown(mem_if.mem_addr);
    endproperty

    property P4;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        (mem_if.mem_en && !$isunknown(mem_if.mem_addr))
        |-> (mem_if.mem_addr< DEPTH);
    endproperty

    property P5;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        (mem_if.mem_en && mem_if.mem_we)
        |-> !$isunknown(mem_if.mem_wdata);
    endproperty

    property P6;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        (mem_if.mem_en && !mem_if.mem_we)
        |=> !$isunknown(mem_if.mem_rdata);
    endproperty

    property P7;
        @(posedge mem_if.clk) disable iff (!mem_if.rst_n)
        (!mem_if.mem_en || mem_if.mem_we)
        |=> $stable(mem_if.mem_rdata);
    endproperty


    // =====================================================
    // Assertions
    // =====================================================
    reset_assertion: assert property (P1)
        else `uvm_error("MEM_SVA", "Reset behavior failed")

    write_enable_assertion: assert property (P2)
        else `uvm_error("MEM_SVA", "mem_we asserted while mem_en is low")

    address_known_assertion: assert property (P3)
        else `uvm_error("MEM_SVA", "Memory address is X/Z")

    address_range_assertion: assert property (P4)
        else `uvm_error("MEM_SVA", "Memory address out of range")

    write_data_assertion: assert property (P5)
        else `uvm_error("MEM_SVA", "Write data is X/Z")

    read_data_known_assertion: assert property (P6)
        else `uvm_error("MEM_SVA", "Read data is X/Z")

    read_data_stable_assertion: assert property (P7)
        else `uvm_error("MEM_SVA", "Read data changed without a read")

    // =====================================================
    // Coverage
    // =====================================================
    reset_cover: cover property (P1);

    write_enable_cover: cover property (P2);
    
    address_known_cover: cover property (P3);
    
    address_range_cover: cover property (P4);
    
    write_data_cover: cover property (P5);
    
    read_data_cover: cover property (P6);
    
    read_data_stable_cover: cover property (P7);
endmodule : mem_sva