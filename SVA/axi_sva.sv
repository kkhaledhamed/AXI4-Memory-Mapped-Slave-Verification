`include "uvm_macros.svh"

module axi_sva (
    axi_if.MONITOR axi_if
);

    import uvm_pkg::*;

    // =====================================================
    // Properties
    // =====================================================

    // P1: VALID signals must be LOW during reset.
    property P1;
        @(posedge axi_if.ACLK)
        (axi_if.ARESETn === 1'b0) |-> (
            (axi_if.AWVALID === 1'b0) &&
            (axi_if.WVALID  === 1'b0) &&
            (axi_if.BVALID  === 1'b0) &&
            (axi_if.ARVALID === 1'b0) &&
            (axi_if.RVALID  === 1'b0)
        );
    endproperty

    // P2: AXI handshake control signals must be known.
    property P2;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        !$isunknown({
            axi_if.AWVALID, axi_if.AWREADY,
            axi_if.WVALID,  axi_if.WREADY,
            axi_if.BVALID,  axi_if.BREADY,
            axi_if.ARVALID, axi_if.ARREADY,
            axi_if.RVALID,  axi_if.RREADY
        });
    endproperty

    // P3: BRESP must be known whenever BVALID is HIGH.
    property P3;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.BVALID |-> !$isunknown(axi_if.BRESP);
    endproperty

    // P4: Read payload must be known whenever RVALID is HIGH.
    property P4;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.RVALID |-> !$isunknown({axi_if.RDATA, axi_if.RRESP, axi_if.RLAST});
    endproperty

    // P5: AW payload must be known whenever AWVALID is HIGH.
    property P5;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.AWVALID |-> !$isunknown({axi_if.AWADDR, axi_if.AWLEN, axi_if.AWSIZE});
    endproperty

    // P6: W payload must be known whenever WVALID is HIGH.
    property P6;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.WVALID |-> !$isunknown({axi_if.WDATA, axi_if.WLAST});
    endproperty

    // P7: AR payload must be known whenever ARVALID is HIGH.
    property P7;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.ARVALID |-> !$isunknown({axi_if.ARADDR, axi_if.ARLEN, axi_if.ARSIZE});
    endproperty

    // P8: Write address handshake occurs.
    property P8;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.AWVALID && axi_if.AWREADY);
    endproperty

    // P9: Read address handshake occurs.
    property P9;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.ARVALID && axi_if.ARREADY);
    endproperty

    // P10: Write response handshake occurs.
    property P10;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.BVALID && axi_if.BREADY);
    endproperty

    // P11: Read data handshake occurs.
    property P11;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.RVALID && axi_if.RREADY);
    endproperty

    // P12: Write data handshake occurs.
    property P12;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.WVALID && axi_if.WREADY);
    endproperty

    // P13: Final read beat is accepted.
    property P13;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.RVALID && axi_if.RREADY && axi_if.RLAST);
    endproperty

    // P14: BRESP is only OKAY or SLVERR.
    property P14;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.BVALID |-> (axi_if.BRESP inside {2'b00, 2'b10});
    endproperty

    // P15: RRESP is only OKAY or SLVERR.
    property P15;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.RVALID |-> (axi_if.RRESP inside {2'b00, 2'b10});
    endproperty

    // P16: BVALID rises only right after the last write data beat is accepted.
    property P16;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.BVALID && !$past(axi_if.BVALID))
        |-> $past(axi_if.WVALID && axi_if.WREADY && axi_if.WLAST);
    endproperty

    // P17: The last write data beat is followed by a response.
    property P17;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.WVALID && axi_if.WREADY && axi_if.WLAST)
        |-> ##[1:10] axi_if.BVALID;
    endproperty

    // P18: A single-beat read returns one beat with RLAST.
    property P18;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.ARVALID && axi_if.ARREADY && axi_if.ARLEN == 8'd0)
        |-> ##[1:20] (axi_if.RVALID && axi_if.RLAST);
    endproperty

    // P19: A single-beat write must have WLAST on its data beat.
    property P19;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.AWVALID && axi_if.AWREADY && axi_if.AWLEN == 8'd0)
        |-> ##[1:20] (axi_if.WVALID && axi_if.WREADY && axi_if.WLAST);
    endproperty


    // =====================================================
    // Assertions
    // =====================================================

    reset_assertion: assert property (P1)
        else `uvm_error("AXI_SVA", "VALID signal asserted during reset")

    control_known_assertion: assert property (P2)
        else `uvm_error("AXI_SVA", "AXI control signal contains X/Z")

    bresp_assertion: assert property (P3)
        else `uvm_error("AXI_SVA", "BRESP contains X/Z while BVALID is HIGH")

    rresp_assertion: assert property (P4)
        else `uvm_error("AXI_SVA", "Read payload contains X/Z while RVALID is HIGH")

    aw_payload_assertion: assert property (P5)
        else `uvm_error("AXI_SVA", "AW payload contains X/Z")

    w_payload_assertion: assert property (P6)
        else `uvm_error("AXI_SVA", "W payload contains X/Z")

    ar_payload_assertion: assert property (P7)
        else `uvm_error("AXI_SVA", "AR payload contains X/Z")

    bresp_value_assertion: assert property (P14)
        else `uvm_error("AXI_SVA", "BRESP is not OKAY or SLVERR")

    rresp_value_assertion: assert property (P15)
        else `uvm_error("AXI_SVA", "RRESP is not OKAY or SLVERR")

    bvalid_origin_assertion: assert property (P16)
        else `uvm_error("AXI_SVA", "BVALID raised before the last write beat was accepted")

    bresp_follows_wlast_assertion: assert property (P17)
        else `uvm_error("AXI_SVA", "No write response after the last write beat")

    single_read_assertion: assert property (P18)
        else `uvm_error("AXI_SVA", "Single-beat read did not return one beat with RLAST")

    single_write_assertion: assert property (P19)
        else `uvm_error("AXI_SVA", "Single-beat write did not have WLAST on its data beat")


    // =====================================================
    // Coverage
    // =====================================================

    reset_cover:             cover property (P1);

    control_known_cover:     cover property (P2);
    bresp_cover:             cover property (P3);
    rresp_cover:             cover property (P4);
    aw_payload_cover:        cover property (P5);
    w_payload_cover:         cover property (P6);
    ar_payload_cover:        cover property (P7);

    aw_handshake_cover:      cover property (P8);
    ar_handshake_cover:      cover property (P9);
    b_handshake_cover:       cover property (P10);
    r_handshake_cover:       cover property (P11);
    w_handshake_cover:       cover property (P12);
    rlast_handshake_cover:   cover property (P13);

    bresp_value_cover:       cover property (P14);
    rresp_value_cover:       cover property (P15);
    bvalid_origin_cover:     cover property (P16);
    bresp_follows_wlast_cover: cover property (P17);
    single_read_cover:       cover property (P18);
    single_write_cover:      cover property (P19);

endmodule : axi_sva
