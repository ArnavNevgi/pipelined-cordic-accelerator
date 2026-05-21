# ============================================================
# create_project.tcl
#
# Quartus Prime project creation for the 16-stage pipelined
# CORDIC accelerator.
#
# Run from this directory:
#   quartus_sh -t create_project.tcl
#
# Generated Quartus project files are kept under:
#   quartus/build/
# ============================================================

set PROJECT_NAME "cordic_quartus"
set REVISION_NAME "cordic_quartus"
set TOP_NAME "cordic_top"
set DEVICE_NAME "5CSEMA5F31C6"

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set BUILD_DIR [file join $SCRIPT_DIR "build"]
set PROJECT_OUTPUT_DIR "output_files"

file mkdir $BUILD_DIR

puts "============================================================"
puts "CORDIC Quartus Project Creation"
puts "Script dir      : $SCRIPT_DIR"
puts "Build dir       : $BUILD_DIR"
puts "Project         : $PROJECT_NAME"
puts "Revision        : $REVISION_NAME"
puts "Top entity      : $TOP_NAME"
puts "Target device   : $DEVICE_NAME"
puts "============================================================"

# If the installed Quartus supports get_part_list, check that the
# requested Cyclone V device exists before creating the project.
if {![catch {get_part_list -family "Cyclone V"} cyclone_v_parts]} {
    if {[lsearch -exact $cyclone_v_parts $DEVICE_NAME] < 0} {
        puts "ERROR: Device $DEVICE_NAME was not found in this Quartus installation."
        puts "Available Cyclone V devices reported by Quartus:"
        foreach part $cyclone_v_parts {
            puts "  $part"
        }
        puts "Edit DEVICE_NAME in quartus/create_project.tcl to one of the supported devices."
        exit 2
    }
} else {
    puts "INFO: Could not query the installed Cyclone V device list; continuing with $DEVICE_NAME."
}

cd $BUILD_DIR

catch {project_close}

project_new $PROJECT_NAME -revision $REVISION_NAME -overwrite

# ------------------------------------------------------------
# Device and compile setup
# ------------------------------------------------------------

set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE $DEVICE_NAME
set_global_assignment -name TOP_LEVEL_ENTITY $TOP_NAME
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY $PROJECT_OUTPUT_DIR
set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"
set_global_assignment -name VERILOG_INPUT_VERSION SYSTEMVERILOG_2005

# ------------------------------------------------------------
# RTL sources
#
# These paths are relative to quartus/build, where the generated
# .qpf/.qsf files are written.
# ------------------------------------------------------------

set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/cordic_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/cordic_core.sv
set_global_assignment -name SYSTEMVERILOG_FILE ../../rtl/cordic_top.sv

# ------------------------------------------------------------
# Timing constraints
# ------------------------------------------------------------

set_global_assignment -name SDC_FILE ../cordic_quartus.sdc

# ------------------------------------------------------------
# No-board compile notes
#
# There are intentionally no physical package pin assignments in this
# project. Non-clock top-level ports are marked as virtual pins so this
# remains a cross-vendor implementation check rather than a board build.
# ------------------------------------------------------------

foreach port_name {rst_n in_valid in_ready out_valid out_ready} {
    set_instance_assignment -name VIRTUAL_PIN ON -to $port_name
}

foreach bus_name {angle_in cos_out sin_out} {
    set bus_port [format {%s[*]} $bus_name]
    set_instance_assignment -name VIRTUAL_PIN ON -to $bus_port
}

export_assignments
project_close

cd $SCRIPT_DIR

puts "============================================================"
puts "Quartus project created."
puts "Project path:"
puts "  [file join $BUILD_DIR ${PROJECT_NAME}.qpf]"
puts ""
puts "To compile manually:"
puts "  cd quartus/build"
puts "  quartus_sh --flow compile $PROJECT_NAME"
puts "============================================================"
