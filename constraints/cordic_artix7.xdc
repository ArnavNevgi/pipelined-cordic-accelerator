# ============================================================
# Xilinx Artix-7 timing constraints
# Target: xc7a35tcpg236-1
# Clock: 100 MHz
# ============================================================

create_clock -period 10.000 -name clk [get_ports clk]

# Generic input and output delays for synthesis/timing analysis.
# No physical board is used in this project.
set input_ports [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  1.000 -clock clk $input_ports
set_output_delay 1.000 -clock clk [all_outputs]
