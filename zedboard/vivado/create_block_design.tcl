# ============================================================
# create_block_design.tcl
#
# Create the ZedBoard PS/PL block design for the CORDIC AXI4-Lite IP.
#
# This script expects an open Vivado project with the packaged CORDIC IP
# repository already added to ip_repo_paths.
# ============================================================

if {[current_project -quiet] eq ""} {
    error "create_block_design.tcl requires an open Vivado project."
}

if {![info exists BD_NAME]} {
    set BD_NAME "cordic_zedboard_bd"
}

if {![info exists CORDIC_BASE_ADDR]} {
    set CORDIC_BASE_ADDR 0x43C00000
}

set CORDIC_ADDR_RANGE 0x00010000
set CORDIC_IP_VLNV   "cordic.local:user:cordic_axi_lite:1.0"

puts "============================================================"
puts "Creating ZedBoard CORDIC block design"
puts "BD name          : $BD_NAME"
puts "CORDIC IP        : $CORDIC_IP_VLNV"
puts "CORDIC base addr : $CORDIC_BASE_ADDR"
puts "============================================================"

set existing_bd [get_files -quiet */$BD_NAME.bd]
if {[llength $existing_bd] > 0} {
    remove_files $existing_bd
}

create_bd_design $BD_NAME
current_bd_design $BD_NAME

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

set ps7_cell [get_bd_cells processing_system7_0]

set automation_status [catch {
    apply_bd_automation \
        -rule xilinx.com:bd_rule:processing_system7 \
        -config {apply_board_preset "1" make_external "FIXED_IO, DDR"} \
        $ps7_cell
} automation_msg]

if {$automation_status != 0} {
    error "Failed to apply ZedBoard processing_system7 board preset. Make sure the ZedBoard board files are installed and board_part is set. Vivado message: $automation_msg"
}

set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_EN_RST0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100.000000} \
] $ps7_cell

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_SI {1} \
] [get_bd_cells axi_interconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
create_bd_cell -type ip -vlnv $CORDIC_IP_VLNV cordic_axi_lite_0

# 100 MHz clock and synchronous reset tree.
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins axi_interconnect_0/ACLK] \
    [get_bd_pins axi_interconnect_0/S00_ACLK] \
    [get_bd_pins axi_interconnect_0/M00_ACLK] \
    [get_bd_pins rst_ps7_0_100M/slowest_sync_clk] \
    [get_bd_pins cordic_axi_lite_0/s_axi_aclk]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins rst_ps7_0_100M/ext_reset_in]

connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] \
    [get_bd_pins axi_interconnect_0/ARESETN] \
    [get_bd_pins axi_interconnect_0/S00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M00_ARESETN] \
    [get_bd_pins cordic_axi_lite_0/s_axi_aresetn]

# AXI4-Lite path from Zynq PS GP0 master to CORDIC slave.
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
    [get_bd_intf_pins cordic_axi_lite_0/S_AXI]

assign_bd_address

set ps_addr_space [get_bd_addr_spaces processing_system7_0/Data]
set cordic_seg [get_bd_addr_segs -quiet cordic_axi_lite_0/S_AXI/reg0]

if {[llength $cordic_seg] == 0} {
    set cordic_seg [get_bd_addr_segs -quiet cordic_axi_lite_0/S_AXI/S_AXI_reg]
}

if {[llength $cordic_seg] == 0} {
    error "Could not find the CORDIC AXI address segment after address assignment."
}

assign_bd_address \
    -target_address_space $ps_addr_space \
    -offset $CORDIC_BASE_ADDR \
    -range $CORDIC_ADDR_RANGE \
    $cordic_seg

regenerate_bd_layout
validate_bd_design
save_bd_design

puts "============================================================"
puts "Block design validated."
puts "CORDIC AXI base address: $CORDIC_BASE_ADDR"
puts "CORDIC AXI range       : $CORDIC_ADDR_RANGE"
puts "============================================================"
