
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
        axi_if.RVALID |->
            !$isunknown({
                axi_if.RDATA,
                axi_if.RRESP,
                axi_if.RLAST
            });
    endproperty


    // P5: AW payload must be known whenever AWVALID is HIGH.
    property P5;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.AWVALID |->
            !$isunknown({
                axi_if.AWADDR,
                axi_if.AWLEN,
                axi_if.AWSIZE
            });
    endproperty


    // P6: W payload must be known whenever WVALID is HIGH.
    property P6;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.WVALID |->
            !$isunknown({
                axi_if.WDATA,
                axi_if.WLAST
            });
    endproperty


    // P7: AR payload must be known whenever ARVALID is HIGH.
    property P7;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.ARVALID |->
            !$isunknown({
                axi_if.ARADDR,
                axi_if.ARLEN,
                axi_if.ARSIZE
            });
    endproperty


    // P8: BRESP must be OKAY or SLVERR for this DUT.
    property P8;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.BVALID |->
            (axi_if.BRESP inside {2'b00, 2'b10});
    endproperty


    // P9: RRESP must be OKAY or SLVERR for this DUT.
    property P9;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.RVALID |->
            (axi_if.RRESP inside {2'b00, 2'b10});
    endproperty


    // P10: RLAST must not be asserted without RVALID.
    property P10;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        axi_if.RLAST |-> axi_if.RVALID;
    endproperty


    // P11: An accepted final write beat must be followed
    // by BVALID no later than 10 sampled clock cycles.
    property P11;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.WVALID && axi_if.WREADY && axi_if.WLAST)
        |-> ##[0:10] axi_if.BVALID;
    endproperty


    // P12: A single-beat read must return a final read beat.
    property P12;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (
            axi_if.ARVALID &&
            axi_if.ARREADY &&
            (axi_if.ARLEN == 8'd0)
        )
        |-> ##[1:20] (
            axi_if.RVALID &&
            axi_if.RLAST
        );
    endproperty


    // P13: A single-beat write must accept a beat with WLAST.
    property P13;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (
            axi_if.AWVALID &&
            axi_if.AWREADY &&
            (axi_if.AWLEN == 8'd0)
        )
        |-> ##[1:20] (
            axi_if.WVALID &&
            axi_if.WREADY &&
            axi_if.WLAST
        );
    endproperty


    // =====================================================
    // Assertions
    // Each assertion references its property.
    // =====================================================

    reset_assertion: assert property (P1)
        else `uvm_error("AXI_SVA",
            "VALID signal asserted during reset")

    control_known_assertion: assert property (P2)
        else `uvm_error("AXI_SVA",
            "AXI control signal contains X/Z")

    bresp_assertion: assert property (P3)
        else `uvm_error("AXI_SVA",
            "BRESP contains X/Z while BVALID is HIGH")

    rresp_assertion: assert property (P4)
        else `uvm_error("AXI_SVA",
            "Read payload contains X/Z while RVALID is HIGH")

    aw_payload_assertion: assert property (P5)
        else `uvm_error("AXI_SVA",
            "AW payload contains X/Z")

    w_payload_assertion: assert property (P6)
        else `uvm_error("AXI_SVA",
            "W payload contains X/Z")

    ar_payload_assertion: assert property (P7)
        else `uvm_error("AXI_SVA",
            "AR payload contains X/Z")

    bresp_value_assertion: assert property (P8)
        else `uvm_error("AXI_SVA",
            "BRESP is not OKAY or SLVERR")

    rresp_value_assertion: assert property (P9)
        else `uvm_error("AXI_SVA",
            "RRESP is not OKAY or SLVERR")

    rlast_assertion: assert property (P10)
        else `uvm_error("AXI_SVA",
            "RLAST asserted without RVALID")

    write_response_assertion: assert property (P11)
        else `uvm_error("AXI_SVA",
            "No BVALID within 10 cycles after accepted WLAST")

    single_read_assertion: assert property (P12)
        else `uvm_error("AXI_SVA",
            "Single-beat read did not return a final read beat")

    single_write_assertion: assert property (P13)
        else `uvm_error("AXI_SVA",
            "Single-beat write did not accept WLAST")


    // =====================================================
    // Coverage
    // Reuse the same properties; do not repeat their logic.
    // =====================================================

    reset_cover:          cover property (P1);

    control_known_cover:  cover property (P2);
    bresp_cover:          cover property (P3);
    rresp_cover:          cover property (P4);

    aw_payload_cover:     cover property (P5);
    w_payload_cover:      cover property (P6);
    ar_payload_cover:     cover property (P7);

    bresp_value_cover:    cover property (P8);
    rresp_value_cover:    cover property (P9);
    rlast_cover:          cover property (P10);

    write_response_cover: cover property (P11);
    single_read_cover:    cover property (P12);
    single_write_cover:   cover property (P13);


    // =====================================================
    // Handshake coverage
    // These are events, not assertions that must happen
    // on every clock cycle.
    // =====================================================

    property C_AW_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.AWVALID && axi_if.AWREADY);
    endproperty

    property C_AR_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.ARVALID && axi_if.ARREADY);
    endproperty

    property C_W_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.WVALID && axi_if.WREADY);
    endproperty

    property C_B_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.BVALID && axi_if.BREADY);
    endproperty

    property C_R_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (axi_if.RVALID && axi_if.RREADY);
    endproperty

    property C_RLAST_HANDSHAKE;
        @(posedge axi_if.ACLK)
        disable iff (axi_if.ARESETn !== 1'b1)
        (
            axi_if.RVALID &&
            axi_if.RREADY &&
            axi_if.RLAST
        );
    endproperty

    aw_handshake_cover:    cover property (C_AW_HANDSHAKE);
    ar_handshake_cover:    cover property (C_AR_HANDSHAKE);
    w_handshake_cover:     cover property (C_W_HANDSHAKE);
    b_handshake_cover:     cover property (C_B_HANDSHAKE);
    r_handshake_cover:     cover property (C_R_HANDSHAKE);
    rlast_handshake_cover: cover property (C_RLAST_HANDSHAKE);

endmodule : axi_sva
