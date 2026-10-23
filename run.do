# Create work library only if it does not exist
if {![file exists work]} {
    vlib work
    vmap work work
}

# Compile source files
vlog -f scripts/axi_files.list +cover -covercells

# Run the simulation
vsim -voptargs="+acc" work.axi_top +UVM_TESTNAME=axi_random_test -cover

# Load coverage exclusions before/during run
if {[file exists scripts/exclusion.do]} {
    do scripts/exclusion.do
}

# Load waveform settings
if {[file exists scripts/wave.do]} {
    do scripts/wave.do
}

# Run simulation and save coverage database
run -all