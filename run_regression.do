# ==================================================================
#   AXI4 memory UVM regression
#   * loops over TESTS x SEEDS
#   * merges all UCDBs and writes text + html coverage reports
#   * scans every log and writes a PASS/FAIL regression summary
# ==================================================================

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
# Add test class names here as the test library grows
set tests      {axi_base_test}

# Number of random seeds per test. Leave seed_list empty to draw
# random seeds, or fill it to replay exact seeds (e.g. a failing one).
set num_seeds  5
set seed_list  {}
# set seed_list {74865 738726}

set top        axi_top
set cov_dir    cov_results
set log_dir    logs

file mkdir $cov_dir
file mkdir $log_dir

# ------------------------------------------------------------------
# Compile (code coverage: branch, condition, expression, statement,
# fsm, toggle) -- covercells so the DUT internals are instrumented
# ------------------------------------------------------------------
if {[file exists work]} { vdel -lib work -all }
vlib work
vlog -f axi_files.list +cover=bcesft -covercells

# ------------------------------------------------------------------
# Seed list: random unless the user pinned seeds above
# ------------------------------------------------------------------
if {[llength $seed_list] == 0} {
    for {set s 0} {$s < $num_seeds} {incr s} {
        lappend seed_list [expr {int(rand() * 1000000)}]
    }
}

# Keep a record of exactly which seeds were used
set fh [open "$cov_dir/seeds_used.txt" w]
puts $fh "tests: $tests"
puts $fh "seeds: $seed_list"
close $fh

# ------------------------------------------------------------------
# Regression loop: every test with every seed
# ------------------------------------------------------------------
set run_id 0
set run_names {}

foreach test $tests {
    foreach seed $seed_list {

        set run_name "${test}_seed${seed}"
        set ucdb_file "$cov_dir/cov_${run_name}.ucdb"
        set log_file  "$log_dir/${run_name}.log"
        lappend run_names $run_name

        puts "=============================================================="
        puts "Run $run_id : test=$test  seed=$seed"
        puts "=============================================================="

        # -sv_seed is the Questa switch that seeds SystemVerilog /
        # UVM randomization (+ntb_random_seed is a Synopsys switch)
        vsim -voptargs=+acc work.$top -coverage -sv_seed $seed \
             +UVM_TESTNAME=$test +UVM_VERBOSITY=UVM_LOW \
             -l $log_file -do "
            coverage save -onexit $ucdb_file;
            run -all;
            quit -sim;
        "

        incr run_id
    }
}

# ------------------------------------------------------------------
# Merge every run's coverage and generate reports
# ------------------------------------------------------------------
puts "Merging [llength $run_names] coverage databases..."
vcover merge $cov_dir/merged_cov.ucdb {*}[glob $cov_dir/cov_*.ucdb]

# Everything: code coverage + functional covergroups
vcover report $cov_dir/merged_cov.ucdb -details -output $cov_dir/cov_report.txt
vcover report $cov_dir/merged_cov.ucdb -details -html -output $cov_dir/cov_report_html

# Covergroups only (functional coverage snippet for the PDF)
vcover report $cov_dir/merged_cov.ucdb -cvg -details -output $cov_dir/func_cov_report.txt

# ------------------------------------------------------------------
# Regression summary: scan each log for the UVM severity counts
# ------------------------------------------------------------------
set sum_fh [open "$cov_dir/regression_summary.txt" w]
puts $sum_fh [format "%-40s %8s %8s  %s" "RUN" "UVM_ERR" "UVM_FATAL" "RESULT"]
puts $sum_fh [string repeat "-" 72]

set total_fail 0
foreach run_name $run_names {
    set errs 0
    set fats 0
    set lf [open "$log_dir/${run_name}.log" r]
    set contents [read $lf]
    close $lf

    if {[regexp {UVM_ERROR\s*:\s*(\d+)} $contents -> n]} { set errs $n }
    if {[regexp {UVM_FATAL\s*:\s*(\d+)} $contents -> n]} { set fats $n }

    if {$errs == 0 && $fats == 0} { set res PASS } else { set res FAIL ; incr total_fail }
    puts $sum_fh [format "%-40s %8d %8d  %s" $run_name $errs $fats $res]
}

puts $sum_fh [string repeat "-" 72]
puts $sum_fh "runs: [llength $run_names]   failed: $total_fail"
close $sum_fh

puts "=============================================================="
puts "Regression done: [llength $run_names] runs, $total_fail failed"
puts "  summary : $cov_dir/regression_summary.txt"
puts "  coverage: $cov_dir/cov_report.txt  (and cov_report_html/)"
puts "  seeds   : $cov_dir/seeds_used.txt"
puts "=============================================================="
