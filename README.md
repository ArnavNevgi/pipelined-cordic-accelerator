@"
# Pipelined CORDIC Hardware Accelerator Benchmark

## Overview

This project implements a 16-stage pipelined CORDIC hardware accelerator in SystemVerilog for sine and cosine computation using Q2.14 fixed-point arithmetic.

The design targets FPGA and RTL engineering roles by demonstrating a complete hardware development flow:

- SystemVerilog RTL design
- 16-stage pipelined datapath
- Valid-ready streaming interface
- Fixed-point arithmetic
- Python golden reference model
- Directed and randomized simulation
- RTL versus golden output comparison
- Numerical error analysis
- Vivado synthesis for Xilinx Artix-7
- Timing and resource utilization reports

## Target FPGA

- Device: Xilinx Artix-7
- Part: xc7a35tcpg236-1
- Clock target: 100 MHz
- Hardware board: Not required

## Design Features

- Rotation-mode CORDIC algorithm
- Q2.14 fixed-point input and output format
- 16 pipeline stages
- Precomputed arctangent lookup table
- Multiplier-free shift-add datapath
- Valid-ready streaming interface
- One sine/cosine output pair per cycle after pipeline fill

## Repository Structure

pipelined-cordic-accelerator/
├── rtl/            # SystemVerilog RTL
├── tb/             # SystemVerilog testbench
├── scripts/        # Python, QuestaSim and Vivado scripts
├── sim/            # Simulation outputs
├── constraints/    # Vivado XDC constraints
├── reports/        # Timing, utilization and accuracy reports
├── docs/           # Project documentation
└── images/         # Diagrams and screenshots

