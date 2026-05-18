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

# Compile testbench
vlog -sv tb/cordic_tb.sv

# Run simulation
vsim -c work.cordic_tb -do "run -all; quit"

quit
