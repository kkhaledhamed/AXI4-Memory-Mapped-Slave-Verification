# Toggle exclusions
coverage exclude -du axi4 -togglenode ARSIZE
coverage exclude -du axi4 -togglenode AWSIZE
coverage exclude -du axi4 -togglenode read_size
coverage exclude -du axi4 -togglenode write_size
coverage exclude -du axi4 -togglenode read_addr_incr
coverage exclude -du axi4 -togglenode write_addr_incr
coverage exclude -du axi4 -togglenode {read_state[2]}
coverage exclude -du axi4 -togglenode {write_state[2]}
coverage exclude -du axi4 -togglenode {BRESP[0]}
coverage exclude -du axi4 -togglenode {RRESP[0]}
coverage exclude -du axi4 -togglenode {AWLEN[7:4]}
coverage exclude -du axi4 -togglenode {ARLEN[7:4]}
coverage exclude -du axi4 -togglenode {write_burst_len[7:4]}
coverage exclude -du axi4 -togglenode {read_burst_len[7:4]}
coverage exclude -du axi4 -togglenode {write_burst_cnt[7:4]}
coverage exclude -du axi4 -togglenode {read_burst_cnt[7:4]}
coverage exclude -du axi4_memory -togglenode j

# FSM transitions 
coverage exclude -du axi4 -ftrans write_state {W_ADDR->W_IDLE}
coverage exclude -du axi4 -ftrans write_state {W_DATA->W_IDLE}
coverage exclude -du axi4 -ftrans read_state {R_ADDR->R_IDLE}
coverage exclude -du axi4 -ftrans read_state {R_WAIT->R_IDLE}

# Branch exclusions
coverage exclude -src rtl/Fixed_RTL/axi4.v -line 167 -code b
coverage exclude -src rtl/Fixed_RTL/axi4.v -line 198 -code b

# Condition exclusions
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 256 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 231 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 217 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 217 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 217 3
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 198 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 198 3
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 178 4
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 167 1
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 167 3
coverage exclude -src rtl/Fixed_RTL/axi4.v -feccondrow 148 3


