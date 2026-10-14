vlib work
vlog -f axi_files.list +cover -covercells
vsim -voptargs="+acc" work.axi_top +UVM_TESTNAME=axi_base_test
do wave.do
run -all