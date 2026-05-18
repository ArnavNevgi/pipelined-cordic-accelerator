# ============================================================
# vivado_synth.tcl
#
# Non-project-mode Vivado synthesis script for the 16-stage
# pipelined CORDIC accelerator.
#
# Target:
#   Xilinx Artix-7 xc7a35tcpg236-1
#
# Run from repo root:
#   vivado -mode batch -source scripts/vivado_synth.tcl
# ============================================================

set PART_NAME "xc7a35tcpg236-1"
set TOP_NAME  "cordic_top"

set ROOT_DIR [file normalize "."]
set REPORT_DIR "$ROOT_DIR/reports"

file mkdir $REPORT_DIR

puts "============================================================"
puts "CORDIC Vivado Synthesis"
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

# ------------------------------------------------------------
# Read constraints
# ------------------------------------------------------------

read_xdc "$ROOT_DIR/constraints/cordic_artix7.xdc"

# ------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------

synth_design -top $TOP_NAME -part $PART_NAME

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------

report_timing_summary \
    -delay_type max \
    -report_unconstrained \
    -check_timing_verbose \
    -file "$REPORT_DIR/synth_timing_summary.rpt"

report_utilization \
    -hierarchical \
    -file "$REPORT_DIR/synth_utilization_hierarchical.rpt"

report_utilization \
    -file "$REPORT_DIR/synth_utilization.rpt"

report_power \
    -file "$REPORT_DIR/synth_power.rpt"

report_clock_utilization \
    -file "$REPORT_DIR/synth_clock_utilization.rpt"

check_timing \
    -verbose \
    -file "$REPORT_DIR/synth_check_timing.rpt"

# ------------------------------------------------------------
# Save synthesized checkpoint
# ------------------------------------------------------------

write_checkpoint -force "$REPORT_DIR/cordic_synth.dcp"

puts "============================================================"
puts "Synthesis complete."
puts "Generated reports:"
puts "  $REPORT_DIR/synth_timing_summary.rpt"
puts "  $REPORT_DIR/synth_utilization.rpt"
puts "  $REPORT_DIR/synth_power.rpt"
puts "  $REPORT_DIR/cordic_synth.dcp"
puts "============================================================"