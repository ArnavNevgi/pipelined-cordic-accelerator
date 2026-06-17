# ============================================================
# vivado_axi_wrapper_synth.tcl
#
# Out-of-context Vivado synthesis check for the ZedBoard
# AXI4-Lite CORDIC wrapper.
#
# Target:
#   Xilinx Zynq-7020 xc7z020clg484-1
#
# Run from repo root:
#   vivado -mode batch -source scripts/vivado_axi_wrapper_synth.tcl
# ============================================================

set PART_NAME "xc7z020clg484-1"
set TOP_NAME  "cordic_axi_lite_wrapper"

set ROOT_DIR [file normalize "."]
set REPORT_DIR "$ROOT_DIR/reports"

file mkdir $REPORT_DIR

puts "============================================================"
puts "CORDIC AXI-Lite Wrapper Vivado Synthesis"
puts "Root directory : $ROOT_DIR"
puts "Part           : $PART_NAME"
puts "Top            : $TOP_NAME"
puts "Report dir     : $REPORT_DIR"
puts "============================================================"

# ------------------------------------------------------------
# Read RTL
# ------------------------------------------------------------

read_verilog -sv "$ROOT_DIR/rtl/cordic_pkg.sv"
read_verilog -sv "$ROOT_DIR/rtl/cordic_core.sv"
read_verilog -sv "$ROOT_DIR/rtl/cordic_top.sv"
read_verilog -sv "$ROOT_DIR/rtl/cordic_axi_lite_wrapper.sv"

# ------------------------------------------------------------
# Out-of-context synthesis
# ------------------------------------------------------------

synth_design -top $TOP_NAME -part $PART_NAME -mode out_of_context

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------

report_utilization \
    -hierarchical \
    -file "$REPORT_DIR/axi_wrapper_synth_utilization_hierarchical.rpt"

report_utilization \
    -file "$REPORT_DIR/axi_wrapper_synth_utilization.rpt"

check_timing \
    -verbose \
    -file "$REPORT_DIR/axi_wrapper_synth_check_timing.rpt"

write_checkpoint -force "$REPORT_DIR/cordic_axi_wrapper_synth.dcp"

puts "============================================================"
puts "AXI-Lite wrapper synthesis check complete."
puts "Generated reports:"
puts "  $REPORT_DIR/axi_wrapper_synth_utilization.rpt"
puts "  $REPORT_DIR/axi_wrapper_synth_check_timing.rpt"
puts "  $REPORT_DIR/cordic_axi_wrapper_synth.dcp"
puts "============================================================"
