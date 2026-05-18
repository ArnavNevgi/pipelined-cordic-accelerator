transcript on

if {[file exists work]} {
    vdel -lib work -all
}

vlib work
vmap work work

vlog -sv rtl/cordic_pkg.sv
vlog -sv tb/cordic_pkg_compile_test.sv

vsim -c work.cordic_pkg_compile_test -do "run -all; quit"

quit
