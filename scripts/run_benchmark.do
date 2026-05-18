transcript on

if {![file exists rtl/cordic_pkg.sv]} {
    error "Run this script from the repository root: do scripts/run_benchmark.do"
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

# ------------------------------------------------------------
# Benchmark 1: Continuous streaming
# ------------------------------------------------------------

puts "============================================================"
puts "Running continuous streaming benchmark"
puts "============================================================"

vsim -c -onfinish stop work.cordic_tb +RANDOM_STALLS=0 +SEED=123 +RTL_CSV=sim/rtl_output_continuous.csv +METRICS_CSV=sim/metrics_continuous.csv
run -all
quit -sim

# ------------------------------------------------------------
# Benchmark 2: Random input gaps and output backpressure
# ------------------------------------------------------------

puts "============================================================"
puts "Running randomized backpressure benchmark"
puts "============================================================"

vsim -c -onfinish stop work.cordic_tb +RANDOM_STALLS=1 +SEED=123 +RTL_CSV=sim/rtl_output_backpressure.csv +METRICS_CSV=sim/metrics_backpressure.csv
run -all

quit
