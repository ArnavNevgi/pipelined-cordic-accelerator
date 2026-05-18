quietly WaveActivateNextPane {} 0

add wave -divider "Clock and Reset"
add wave -radix binary sim:/cordic_tb/clk
add wave -radix binary sim:/cordic_tb/rst_n

add wave -divider "Input Interface"
add wave -radix binary   sim:/cordic_tb/in_valid
add wave -radix binary   sim:/cordic_tb/in_ready
add wave -radix decimal  sim:/cordic_tb/angle_in

add wave -divider "Output Interface"
add wave -radix binary   sim:/cordic_tb/out_valid
add wave -radix binary   sim:/cordic_tb/out_ready
add wave -radix decimal  sim:/cordic_tb/sin_out
add wave -radix decimal  sim:/cordic_tb/cos_out

add wave -divider "Pipeline Control"
add wave -radix binary sim:/cordic_tb/dut/u_cordic_core/pipe_advance

add wave -divider "Counters"
add wave -radix decimal sim:/cordic_tb/sent_count
add wave -radix decimal sim:/cordic_tb/recv_count
add wave -radix decimal sim:/cordic_tb/cycle_count

add wave -divider "DUT Pipeline Valid"
add wave sim:/cordic_tb/dut/u_cordic_core/valid_pipe

add wave -divider "CORDIC Stage 0"
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/x_pipe(0)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/y_pipe(0)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/z_pipe(0)

add wave -divider "CORDIC Stage 8"
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/x_pipe(8)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/y_pipe(8)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/z_pipe(8)

add wave -divider "CORDIC Stage 16"
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/x_pipe(16)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/y_pipe(16)
add wave -radix decimal sim:/cordic_tb/dut/u_cordic_core/z_pipe(16)

run -all
wave zoom full
