# ============================================================
# create_zedboard_project.tcl
#
# Full Vivado project-mode flow for the ZedBoard CORDIC demo.
#
# Run from repo root:
#   vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl
#
# Fast project/BD generation without bitstream:
#   vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl -tclargs -no_bitstream
#
# Optional board override:
#   vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl -tclargs -board_part <board_part_vlnv>
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR   [file normalize [file join $SCRIPT_DIR ../..]]

set PROJECT_NAME      "cordic_zedboard"
set PART_NAME         "xc7z020clg484-1"
set BD_NAME           "cordic_zedboard_bd"
set CORDIC_BASE_ADDR  0x43C00000
set BUILD_BITSTREAM   1
set JOBS              4
set USER_BOARD_PART   ""

for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]

    switch -- $arg {
        -no_bitstream {
            set BUILD_BITSTREAM 0
        }
        -build_bitstream {
            set BUILD_BITSTREAM 1
        }
        -jobs {
            incr i
            set JOBS [lindex $argv $i]
        }
        -board_part {
            incr i
            set USER_BOARD_PART [lindex $argv $i]
        }
        -base_addr {
            incr i
            set CORDIC_BASE_ADDR [lindex $argv $i]
        }
        default {
            error "Unknown argument: $arg"
        }
    }
}

set ZEDBOARD_DIR "$ROOT_DIR/zedboard"
set VIVADO_DIR   "$ZEDBOARD_DIR/vivado"
set BUILD_DIR    "$VIVADO_DIR/build"
set PROJECT_DIR  "$BUILD_DIR/$PROJECT_NAME"
set IP_REPO_DIR  "$VIVADO_DIR/ip_repo"
set XSA_DIR      "$ZEDBOARD_DIR/hw"
set XSA_FILE     "$XSA_DIR/cordic_zedboard.xsa"

proc find_zedboard_part {} {
    foreach pattern {"*zedboard*" "*zed_board*" "*zed*"} {
        set parts [get_board_parts -quiet $pattern]
        if {[llength $parts] > 0} {
            return [lindex $parts 0]
        }
    }

    return ""
}

puts "============================================================"
puts "ZedBoard CORDIC Vivado Flow"
puts "Root directory  : $ROOT_DIR"
puts "Project dir     : $PROJECT_DIR"
puts "Part            : $PART_NAME"
puts "BD name         : $BD_NAME"
puts "CORDIC base addr: $CORDIC_BASE_ADDR"
puts "Build bitstream : $BUILD_BITSTREAM"
puts "============================================================"

file mkdir $BUILD_DIR
file mkdir $XSA_DIR

# Package the RTL wrapper as Vivado IP before opening the main project.
source "$SCRIPT_DIR/package_cordic_ip.tcl"

create_project $PROJECT_NAME $PROJECT_DIR -part $PART_NAME -force

if {$USER_BOARD_PART ne ""} {
    set board_part $USER_BOARD_PART
} else {
    set board_part [find_zedboard_part]
}

if {$board_part eq ""} {
    error "No ZedBoard board_part was found. Install ZedBoard board files, or rerun with -tclargs -board_part <board_part_vlnv>."
}

puts "Using board_part: $board_part"
set_property board_part $board_part [current_project]

set_property ip_repo_paths [list $IP_REPO_DIR] [current_project]
update_ip_catalog

source "$SCRIPT_DIR/create_block_design.tcl"

set bd_files [get_files -quiet "$PROJECT_DIR/$PROJECT_NAME.srcs/sources_1/bd/$BD_NAME/$BD_NAME.bd"]
if {[llength $bd_files] == 0} {
    set bd_files [get_files -quiet "*/$BD_NAME.bd"]
}

if {[llength $bd_files] == 0} {
    error "Could not locate generated block design file for $BD_NAME."
}

set bd_file [lindex $bd_files 0]
generate_target all $bd_file

set wrapper_file [make_wrapper -files $bd_file -top]
add_files -norecurse $wrapper_file
set_property top "${BD_NAME}_wrapper" [current_fileset]
update_compile_order -fileset sources_1

if {$BUILD_BITSTREAM} {
    puts "============================================================"
    puts "Launching synthesis and implementation."
    puts "============================================================"

    launch_runs synth_1 -jobs $JOBS
    wait_on_run synth_1

    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
        error "synth_1 did not complete successfully."
    }

    launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
    wait_on_run impl_1

    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
        error "impl_1 did not complete successfully."
    }

    write_hw_platform -fixed -include_bit -force -file $XSA_FILE

    puts "============================================================"
    puts "Bitstream and hardware platform generated."
    puts "XSA: $XSA_FILE"
    puts "============================================================"
} else {
    puts "============================================================"
    puts "Project and block design generated without bitstream."
    puts "Rerun without -no_bitstream to generate the .bit and .xsa."
    puts "============================================================"
}
