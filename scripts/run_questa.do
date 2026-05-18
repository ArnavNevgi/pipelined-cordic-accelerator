transcript on

if {![file exists rtl/cordic_pkg.sv]} {
    error "Run this script from the repository root: do scripts/run_questa.do"
}

file mkdir sim

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Compile RTL
vlog -sv rtl/cordic_pkg.sv
vlog -sv rtl/cordic_core.sv
vlog -sv rtl/cordic_top.sv

# Compile testbench
vlog -sv tb/cordic_tb.sv

# Default simulation output used by compare_results.py
vsim -c -onfinish stop work.cordic_tb +RANDOM_STALLS=1 +SEED=123 +RTL_CSV=sim/rtl_output.csv +METRICS_CSV=sim/metrics.csv
run -all

quit
