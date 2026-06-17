# ============================================================
# package_cordic_ip.tcl
#
# Package the CORDIC AXI4-Lite wrapper as reusable Vivado IP.
#
# Run from repo root:
#   vivado -mode batch -source zedboard/vivado/package_cordic_ip.tcl
#
# This script is also sourced by create_zedboard_project.tcl before the
# ZedBoard project is created.
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set ROOT_DIR   [file normalize [file join $SCRIPT_DIR ../..]]

if {![info exists PART_NAME]} {
    set PART_NAME "xc7z020clg484-1"
}

if {![info exists IP_REPO_DIR]} {
    set IP_REPO_DIR "$ROOT_DIR/zedboard/vivado/ip_repo"
}

set IP_NAME       "cordic_axi_lite"
set IP_VERSION    "1.0"
set IP_VENDOR     "cordic.local"
set IP_LIBRARY    "user"
set IP_TAXONOMY   "/UserIP"
set IP_ROOT_DIR   "$IP_REPO_DIR/$IP_NAME"
set PACKAGER_DIR  "$ROOT_DIR/zedboard/vivado/build/ip_packager"
set PACKAGER_PROJ "$PACKAGER_DIR/cordic_ip_packager"

if {[current_project -quiet] ne ""} {
    error "package_cordic_ip.tcl must be run before opening the ZedBoard project, or as a standalone batch script."
}

file mkdir $IP_REPO_DIR
file mkdir $PACKAGER_DIR

puts "============================================================"
puts "Packaging CORDIC AXI4-Lite IP"
puts "Root directory : $ROOT_DIR"
puts "IP repository  : $IP_REPO_DIR"
puts "IP root        : $IP_ROOT_DIR"
puts "Part           : $PART_NAME"
puts "============================================================"

create_project cordic_ip_packager $PACKAGER_PROJ -part $PART_NAME -force

add_files -fileset sources_1 "$ROOT_DIR/rtl/cordic_pkg.sv"
add_files -fileset sources_1 "$ROOT_DIR/rtl/cordic_core.sv"
add_files -fileset sources_1 "$ROOT_DIR/rtl/cordic_top.sv"
add_files -fileset sources_1 "$ROOT_DIR/rtl/cordic_axi_lite_wrapper.sv"

set_property file_type SystemVerilog [get_files "$ROOT_DIR/rtl/cordic_pkg.sv"]
set_property file_type SystemVerilog [get_files "$ROOT_DIR/rtl/cordic_core.sv"]
set_property file_type SystemVerilog [get_files "$ROOT_DIR/rtl/cordic_top.sv"]
set_property file_type SystemVerilog [get_files "$ROOT_DIR/rtl/cordic_axi_lite_wrapper.sv"]

set_property top cordic_axi_lite_wrapper [current_fileset]
update_compile_order -fileset sources_1

ipx::package_project \
    -root_dir $IP_ROOT_DIR \
    -vendor $IP_VENDOR \
    -library $IP_LIBRARY \
    -taxonomy $IP_TAXONOMY \
    -import_files \
    -force

set core [ipx::current_core]

set_property name                 $IP_NAME $core
set_property display_name         "CORDIC AXI4-Lite Accelerator" $core
set_property description          "One-sample-at-a-time AXI4-Lite wrapper for the Q2.14 pipelined CORDIC sine/cosine accelerator." $core
set_property vendor_display_name  "CORDIC Project" $core
set_property company_url          "http://www.example.com" $core
set_property version              $IP_VERSION $core
set_property supported_families   {zynq Production artix7 Production} $core

# Let Vivado infer the AXI4-Lite, clock, and reset interfaces from the
# standard s_axi_* port names, then tighten the metadata needed by IP Integrator.
ipx::infer_bus_interfaces xilinx.com:interface:aximm_rtl:1.0 $core
ipx::infer_bus_interfaces xilinx.com:signal:clock_rtl:1.0 $core
ipx::infer_bus_interfaces xilinx.com:signal:reset_rtl:1.0 $core

set s_axi_bus [ipx::get_bus_interfaces -quiet -of_objects $core S_AXI]
if {[llength $s_axi_bus] == 0} {
    set s_axi_bus [ipx::get_bus_interfaces -quiet -of_objects $core s_axi]
    if {[llength $s_axi_bus] > 0} {
        set_property name S_AXI $s_axi_bus
        set s_axi_bus [ipx::get_bus_interfaces -quiet -of_objects $core S_AXI]
    }
}

if {[llength $s_axi_bus] == 0} {
    error "Failed to infer S_AXI bus interface for cordic_axi_lite_wrapper."
}

set_property interface_mode slave $s_axi_bus
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 $s_axi_bus
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 $s_axi_bus

if {[llength [ipx::get_bus_parameters -quiet -of_objects $s_axi_bus DATA_WIDTH]] > 0} {
    set_property value 32 [ipx::get_bus_parameters -of_objects $s_axi_bus DATA_WIDTH]
}

if {[llength [ipx::get_bus_parameters -quiet -of_objects $s_axi_bus PROTOCOL]] > 0} {
    set_property value AXI4LITE [ipx::get_bus_parameters -of_objects $s_axi_bus PROTOCOL]
}

if {[llength [ipx::get_bus_parameters -quiet -of_objects $s_axi_bus FREQ_HZ]] > 0} {
    set_property value 100000000 [ipx::get_bus_parameters -of_objects $s_axi_bus FREQ_HZ]
}

set clk_bus [ipx::get_bus_interfaces -of_objects $core s_axi_aclk]
if {[llength $clk_bus] == 0} {
    set clk_bus [ipx::get_bus_interfaces -of_objects $core S_AXI_ACLK]
}

if {[llength $clk_bus] > 0} {
    if {[llength [ipx::get_bus_parameters -quiet -of_objects $clk_bus ASSOCIATED_BUSIF]] == 0} {
        ipx::add_bus_parameter ASSOCIATED_BUSIF $clk_bus
    }
    set_property value S_AXI [ipx::get_bus_parameters -of_objects $clk_bus ASSOCIATED_BUSIF]

    if {[llength [ipx::get_bus_parameters -quiet -of_objects $clk_bus ASSOCIATED_RESET]] == 0} {
        ipx::add_bus_parameter ASSOCIATED_RESET $clk_bus
    }
    set_property value s_axi_aresetn [ipx::get_bus_parameters -of_objects $clk_bus ASSOCIATED_RESET]

    if {[llength [ipx::get_bus_parameters -quiet -of_objects $clk_bus FREQ_HZ]] == 0} {
        ipx::add_bus_parameter FREQ_HZ $clk_bus
    }
    set_property value 100000000 [ipx::get_bus_parameters -of_objects $clk_bus FREQ_HZ]
}

set rst_bus [ipx::get_bus_interfaces -of_objects $core s_axi_aresetn]
if {[llength $rst_bus] == 0} {
    set rst_bus [ipx::get_bus_interfaces -of_objects $core S_AXI_ARESETN]
}

if {[llength $rst_bus] > 0} {
    if {[llength [ipx::get_bus_parameters -quiet -of_objects $rst_bus POLARITY]] == 0} {
        ipx::add_bus_parameter POLARITY $rst_bus
    }
    set_property value ACTIVE_LOW [ipx::get_bus_parameters -of_objects $rst_bus POLARITY]
}

set inferred_memory_map [ipx::get_memory_maps -quiet -of_objects $core s_axi]
if {[llength $inferred_memory_map] > 0} {
    set_property name S_AXI $inferred_memory_map
}

if {[llength [ipx::get_memory_maps -quiet -of_objects $core S_AXI]] == 0} {
    ipx::add_memory_map S_AXI $core
}

set memory_map [ipx::get_memory_maps -of_objects $core S_AXI]

if {[llength [ipx::get_address_blocks -of_objects $memory_map reg0]] == 0} {
    ipx::add_address_block reg0 $memory_map
}

set address_block [ipx::get_address_blocks -of_objects $memory_map reg0]
set_property range 4096 $address_block
set_property width 32   $address_block

set_property slave_memory_map_ref S_AXI $s_axi_bus

ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::check_integrity $core
ipx::save_core $core

close_project

puts "============================================================"
puts "CORDIC AXI4-Lite IP packaged successfully."
puts "VLNV: $IP_VENDOR:$IP_LIBRARY:$IP_NAME:$IP_VERSION"
puts "============================================================"
