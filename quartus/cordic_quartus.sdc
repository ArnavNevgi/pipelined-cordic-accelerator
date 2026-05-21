# ============================================================
# cordic_quartus.sdc
#
# Intel Quartus TimeQuest constraints for the pipelined CORDIC
# accelerator implementation check.
#
# Target:
#   Intel Cyclone V 5CSEMA5F31C6
#
# Clock:
#   100 MHz target
#   10.000 ns period
#
# This is a no-board FPGA implementation compile. There are no package
# pin assignments and no board-level input/output timing budgets here.
# The constraint set is intended to check the internal registered
# datapath against a 100 MHz clock on a Cyclone V target.
# ============================================================

# Main design clock: 100 MHz.
create_clock -name clk -period 10.000 [get_ports {clk}]

# Let TimeQuest derive a conservative clock uncertainty model for the
# selected Intel FPGA family and speed grade.
derive_clock_uncertainty

# rst_n is an asynchronous active-low reset in the RTL. No external reset
# release timing is claimed in this boardless implementation run.
set_false_path -from [get_ports {rst_n}]

# No set_input_delay or set_output_delay constraints are applied because
# this project does not define an external board, companion device, or
# package pin timing budget. Add board-specific I/O constraints before
# making any hardware integration timing claim.
