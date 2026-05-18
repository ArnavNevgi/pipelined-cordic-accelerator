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

# Default simulation output used by compare_results.py
vsim -c work.cordic_tb +RANDOM_STALLS=1 +SEED=123 +RTL_CSV=sim/rtl_output.csv +METRICS_CSV=sim/metrics.csv -do "run -all; quit"

quit