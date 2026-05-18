# ============================================================
# vivado_reports.tcl
#
# Regenerate reports from post-route checkpoint.
#
# Run from repo root after vivado_impl.tcl has completed:
#   vivado -mode batch -source scripts/vivado_reports.tcl
# ============================================================

set ROOT_DIR [file normalize "."]
set REPORT_DIR "$ROOT_DIR/reports"
set CHECKPOINT "$REPORT_DIR/cordic_post_route.dcp"

file mkdir $REPORT_DIR

if {![file exists $CHECKPOINT]} {
    puts "ERROR: Missing checkpoint: $CHECKPOINT"
    puts "Run scripts/vivado_impl.tcl first."
    exit 1
}

open_checkpoint $CHECKPOINT

report_timing_summary \
    -delay_type max \
    -report_unconstrained \
    -check_timing_verbose \
    -file "$REPORT_DIR/post_route_timing_summary.rpt"

report_utilization \
    -hierarchical \
    -file "$REPORT_DIR/post_route_utilization_hierarchical.rpt"

report_utilization \
    -file "$REPORT_DIR/post_route_utilization.rpt"

report_power \
    -file "$REPORT_DIR/post_route_power.rpt"

report_route_status \
    -file "$REPORT_DIR/route_status.rpt"

report_clock_utilization \
    -file "$REPORT_DIR/post_route_clock_utilization.rpt"

check_timing \
    -verbose \
    -file "$REPORT_DIR/post_route_check_timing.rpt"

puts "Reports regenerated from checkpoint."