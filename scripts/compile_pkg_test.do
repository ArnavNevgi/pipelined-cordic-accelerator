transcript on

if {![file exists rtl/cordic_pkg.sv]} {
    error "Run this script from the repository root: do scripts/compile_pkg_test.do"
}

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv rtl/cordic_pkg.sv
vlog -sv tb/cordic_pkg_compile_test.sv

vsim -c -onfinish stop work.cordic_pkg_compile_test
run -all

quit
