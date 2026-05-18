transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

# Compile RTL
vlog -sv rtl/cordic_pkg.sv
vlog -sv rtl/cordic_core.sv
vlog -sv rtl/cordic_top.sv

# Compile testbench and assertions
vlog -sv tb/cordic_assertions.sv
vlog -sv tb/cordic_tb.sv

# ------------------------------------------------------------
# Benchmark 1: Continuous streaming
# ------------------------------------------------------------

puts "============================================================"
puts "Running continuous streaming benchmark"
puts "============================================================"

vsim -c work.cordic_tb +RANDOM_STALLS=0 +SEED=123 +RTL_CSV=sim/rtl_output_continuous.csv +METRICS_CSV=sim/metrics_continuous.csv -onfinish stop -do "run -all"

quit -sim

# ------------------------------------------------------------
# Benchmark 2: Random input gaps and output backpressure
# ------------------------------------------------------------

puts "============================================================"
puts "Running randomized backpressure benchmark"
puts "============================================================"

vsim -c work.cordic_tb +RANDOM_STALLS=1 +SEED=123 +RTL_CSV=sim/rtl_output_backpressure.csv +METRICS_CSV=sim/metrics_backpressure.csv -onfinish stop -do "run -all"

quit -sim

quit