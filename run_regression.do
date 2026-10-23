# AXI4 regression: run every test with every seed, merge coverage, report
set tests {axi_base_test axi_error_test axi_random_test axi_override_test}
#set seeds {1 2 3 4 5}
set seeds {1}

# Clean old results (old .ucdb files would otherwise be merged into this run)
file delete -force cov_results
file delete -force logs
if {[file exists work]} { vdel -lib work -all }

file mkdir cov_results
file mkdir logs

# Compile with code coverage
vlib work
vlog -f scripts/axi_files.list +cover -covercells 

# Run each test with each seed
foreach test $tests {
    foreach seed $seeds {
        vsim -voptargs=+acc work.axi_top -coverage -assertdebug -sv_seed $seed \
             +UVM_TESTNAME=$test +UVM_VERBOSITY=UVM_LOW \
             -l logs/${test}_seed${seed}.log \
             -do "coverage save -onexit -du work.axi4 -du work.axi4_memory cov_results/run_${test}_seed${seed}.ucdb; run -all; quit -sim"
    }
}

# Merge all runs, then apply the exclusions to the merged result
vcover merge cov_results/merged.ucdb {*}[glob cov_results/run_*.ucdb]

vsim -viewcov cov_results/merged.ucdb
do scripts/exclusion.do
coverage save cov_results/merged_excl.ucdb
quit -sim

# Reports (code + functional coverage)
vcover report cov_results/merged_excl.ucdb -details -annotate -all -output cov_results/cov_report.txt


# UVM error / fatal count of each run
foreach log [lsort [glob logs/*.log]] {
    set f [open $log r]
    set txt [read $f]
    close $f
    set e "?"
    set fa "?"
    regexp {UVM_ERROR\s*:\s*(\d+)} $txt -> e
    regexp {UVM_FATAL\s*:\s*(\d+)} $txt -> fa
    puts "[file tail $log]   UVM_ERROR=$e   UVM_FATAL=$fa"
}
