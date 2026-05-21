# ============================================================
# run_quartus.tcl
#
# Wrapper for creating and compiling the Quartus project, then extracting
# GitHub-friendly text summaries.
#
# Run from quartus/:
#   quartus_sh -t run_quartus.tcl
# ============================================================

set SCRIPT_DIR [file dirname [file normalize [info script]]]
cd $SCRIPT_DIR

source [file join $SCRIPT_DIR "create_project.tcl"]

cd $BUILD_DIR

puts "============================================================"
puts "CORDIC Quartus Full Compile"
puts "Project       : $PROJECT_NAME"
puts "Revision      : $REVISION_NAME"
puts "Build dir     : $BUILD_DIR"
puts "============================================================"

project_open $PROJECT_NAME -revision $REVISION_NAME
load_package flow

set compile_failed [catch {execute_flow -compile} compile_message]
project_close

cd $SCRIPT_DIR

if {$compile_failed} {
    puts "ERROR: Quartus compile failed:"
    puts $compile_message
} else {
    puts "Quartus compile completed successfully."
}

set python_cmd ""
if {[auto_execok python] ne ""} {
    set python_cmd "python"
} elseif {[auto_execok py] ne ""} {
    set python_cmd "py"
}

if {$python_cmd eq ""} {
    puts "WARNING: Python was not found on PATH; skipping report extraction."
    puts "Run python extract_quartus_reports.py from quartus/ after compile."
} else {
    if {$python_cmd eq "py"} {
        set extract_failed [catch {exec py -3 [file join $SCRIPT_DIR "extract_quartus_reports.py"]} extract_message]
    } else {
        set extract_failed [catch {exec python [file join $SCRIPT_DIR "extract_quartus_reports.py"]} extract_message]
    }

    puts $extract_message

    if {$extract_failed} {
        puts "WARNING: Quartus report extraction failed."
    }
}

if {$compile_failed} {
    exit 1
}

puts "============================================================"
puts "Quartus flow complete."
puts "Curated reports:"
puts "  ../reports/quartus/timing_summary.txt"
puts "  ../reports/quartus/utilization_summary.txt"
puts "  ../reports/quartus/fit_summary.txt"
puts "  ../reports/quartus/quartus_compile.log"
puts "============================================================"
