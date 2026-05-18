# ============================================================
# vivado_project.tcl
#
# Optional Vivado project-mode setup script.
#
# Run from repo root:
#   vivado -mode batch -source scripts/vivado_project.tcl
# ============================================================

set PROJECT_NAME "cordic_accelerator"
set PROJECT_DIR  "./vivado_project"
set PART_NAME    "xc7a35tcpg236-1"
set TOP_NAME     "cordic_top"

create_project $PROJECT_NAME $PROJECT_DIR -part $PART_NAME -force

add_files -fileset sources_1 ./rtl/cordic_pkg.sv
add_files -fileset sources_1 ./rtl/cordic_core.sv
add_files -fileset sources_1 ./rtl/cordic_top.sv

set_property file_type SystemVerilog [get_files ./rtl/cordic_pkg.sv]
set_property file_type SystemVerilog [get_files ./rtl/cordic_core.sv]
set_property file_type SystemVerilog [get_files ./rtl/cordic_top.sv]

add_files -fileset constrs_1 ./constraints/cordic_artix7.xdc

set_property top $TOP_NAME [current_fileset]

update_compile_order -fileset sources_1

puts "Vivado project created at $PROJECT_DIR"