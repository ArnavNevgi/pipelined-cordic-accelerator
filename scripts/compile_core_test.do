transcript on

if {![file exists rtl/cordic_pkg.sv]} {
    error "Run this script from the repository root: do scripts/compile_core_test.do"
}

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv rtl/cordic_pkg.sv
vlog -sv rtl/cordic_core.sv
vlog -sv rtl/cordic_top.sv

quit
