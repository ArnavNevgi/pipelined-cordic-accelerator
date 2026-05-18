# ============================================================
# cordic_artix7.xdc
#
# Timing constraints for the Pipelined CORDIC Hardware Accelerator
#
# Target FPGA:
#   Xilinx Artix-7 xc7a35tcpg236-1
#
# Clock:
#   100 MHz target
#   10 ns period
#
# No physical board is used. Therefore, this file only provides
# timing constraints and does not assign package pins.
# ============================================================

# Main clock: 100 MHz
create_clock -period 10.000 -name clk [get_ports clk]

# Apply generic I/O timing delays for timing analysis.
# Exclude the clock port from input delay constraints.
set input_ports_no_clk [remove_from_collection [all_inputs] [get_ports clk]]

if {[sizeof_collection $input_ports_no_clk] > 0} {
    set_input_delay 1.000 -clock clk $input_ports_no_clk
}

if {[sizeof_collection [all_outputs]] > 0} {
    set_output_delay 1.000 -clock clk [all_outputs]
}