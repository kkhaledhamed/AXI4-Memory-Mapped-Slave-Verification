onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {AXI Interface} -divider Global
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ACLK
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARESETn
add wave -noupdate -expand -group {AXI Interface} -divider {Write Address Channel}
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/AWADDR
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/AWLEN
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/AWSIZE
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/AWVALID
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/AWREADY
add wave -noupdate -expand -group {AXI Interface} -divider {Write Data Channel}
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/WDATA
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/WVALID
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/WLAST
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/WREADY
add wave -noupdate -expand -group {AXI Interface} -divider {Write Response Channel}
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/BRESP
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/BVALID
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/BREADY
add wave -noupdate -expand -group {AXI Interface} -divider {Read Address Channel}
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARADDR
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARLEN
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARSIZE
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARVALID
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/ARREADY
add wave -noupdate -expand -group {AXI Interface} -divider {Read Data Channel}
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/RDATA
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/RRESP
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/RVALID
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/RLAST
add wave -noupdate -expand -group {AXI Interface} /axi_top/axi_vif/RREADY
add wave -noupdate -expand -group {Memory Probe} -divider {Clock / Reset}
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/clk
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/rst_n
add wave -noupdate -expand -group {Memory Probe} -divider {Memory Signals}
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/mem_en
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/mem_we
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/mem_addr
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/mem_wdata
add wave -noupdate -expand -group {Memory Probe} /axi_top/dut/mem_inst/mem_if_inst/mem_rdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 us}

# # ============================================================
# # Group 1: AXI Interface -- one divider per channel
# # ============================================================
# add wave -group "AXI Interface" -divider "Global"
# add wave -group "AXI Interface" /axi_top/axi_vif/ACLK
# add wave -group "AXI Interface" /axi_top/axi_vif/ARESETn

# add wave -group "AXI Interface" -divider "Write Address Channel"
# add wave -group "AXI Interface" /axi_top/axi_vif/AWADDR
# add wave -group "AXI Interface" /axi_top/axi_vif/AWLEN
# add wave -group "AXI Interface" /axi_top/axi_vif/AWSIZE
# add wave -group "AXI Interface" /axi_top/axi_vif/AWVALID
# add wave -group "AXI Interface" /axi_top/axi_vif/AWREADY

# add wave -group "AXI Interface" -divider "Write Data Channel"
# add wave -group "AXI Interface" /axi_top/axi_vif/WDATA
# add wave -group "AXI Interface" /axi_top/axi_vif/WVALID
# add wave -group "AXI Interface" /axi_top/axi_vif/WLAST
# add wave -group "AXI Interface" /axi_top/axi_vif/WREADY

# add wave -group "AXI Interface" -divider "Write Response Channel"
# add wave -group "AXI Interface" /axi_top/axi_vif/BRESP
# add wave -group "AXI Interface" /axi_top/axi_vif/BVALID
# add wave -group "AXI Interface" /axi_top/axi_vif/BREADY

# add wave -group "AXI Interface" -divider "Read Address Channel"
# add wave -group "AXI Interface" /axi_top/axi_vif/ARADDR
# add wave -group "AXI Interface" /axi_top/axi_vif/ARLEN
# add wave -group "AXI Interface" /axi_top/axi_vif/ARSIZE
# add wave -group "AXI Interface" /axi_top/axi_vif/ARVALID
# add wave -group "AXI Interface" /axi_top/axi_vif/ARREADY

# add wave -group "AXI Interface" -divider "Read Data Channel"
# add wave -group "AXI Interface" /axi_top/axi_vif/RDATA
# add wave -group "AXI Interface" /axi_top/axi_vif/RRESP
# add wave -group "AXI Interface" /axi_top/axi_vif/RVALID
# add wave -group "AXI Interface" /axi_top/axi_vif/RLAST
# add wave -group "AXI Interface" /axi_top/axi_vif/RREADY

# # ============================================================
# # Group 2: Memory Probe
# # ============================================================
# add wave -group "Memory Probe" -divider "Clock / Reset"
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/clk
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/rst_n

# add wave -group "Memory Probe" -divider "Memory Signals"
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/mem_en
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/mem_we
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/mem_addr
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/mem_wdata
# add wave -group "Memory Probe" /axi_top/dut/mem_inst/mem_if_inst/mem_rdata