# Pipelined CORDIC Hardware Accelerator Benchmark

## Overview

This project implements a 16-stage pipelined CORDIC hardware accelerator in SystemVerilog for sine and cosine computation using signed Q2.14 fixed-point arithmetic.

The implemented flow currently covers:

- Python golden reference and Q2.14 test-vector generation
- SystemVerilog CORDIC package and 16-stage RTL core
- Rotation-mode CORDIC with precomputed atan constants
- Valid-ready streaming with output backpressure support
- QuestaSim testbench for continuous and randomized stall modes
- RTL-vs-golden CSV comparison and error reporting
- Latency and throughput benchmark report generation

Vivado scripts and Artix-7 constraints are present for future synthesis work, but this repository should not be treated as having completed synthesis, timing closure, or utilization reporting yet.

## Target FPGA

- Device family: Xilinx Artix-7
- Example part: xc7a35tcpg236-1
- Clock target for benchmark reporting: 100 MHz
- Hardware board: Not required

## Design Features

- Rotation-mode CORDIC algorithm
- Signed Q2.14 input angle, sine output, and cosine output
- Supported angle range: `-pi/2` to `+pi/2` radians
- 16 CORDIC iterations
- Gain-compensated initial `x` value using `CORDIC_K = 9949`
- Multiplier-free shift-add datapath
- Global-stall valid-ready interface
- One sine/cosine output pair per cycle in continuous streaming after pipeline fill

## Repository Structure

```text
pipelined-cordic-accelerator/
|-- rtl/            SystemVerilog RTL
|-- tb/             SystemVerilog testbench
|-- scripts/        Python, QuestaSim, and future Vivado scripts
|-- sim/            Generated simulation CSV outputs
|-- constraints/    Artix-7 XDC constraints
|-- reports/        Generated golden, accuracy, and benchmark reports
|-- docs/           Project documentation
`-- images/         Diagrams and screenshots
```

## Regenerate Golden Data

```text
python scripts/gen_golden.py
```

Generated files:

- `tb/cordic_test_vectors.hex`
- `sim/golden_output.csv`
- `reports/atan_table_q214.txt`
- `reports/golden_generation_summary.txt`

## Run RTL Simulation

From the repository root in QuestaSim:

```text
do scripts/run_questa.do
```

The default simulation writes:

- `sim/rtl_output.csv`
- `sim/metrics.csv`

## Accuracy Report

```text
python scripts/compare_results.py
```

The generated report is stored at:

- `reports/accuracy_report.txt`

## Latency and Throughput Benchmark

The benchmark flow runs:

1. Continuous streaming with no random stalls
2. Randomized input valid gaps and output backpressure

From the repository root in QuestaSim:

```text
do scripts/run_benchmark.do
```

Then generate the benchmark summary:

```text
python scripts/generate_benchmark_report.py
```

Generated benchmark files:

- `sim/metrics_continuous.csv`
- `sim/metrics_backpressure.csv`
- `sim/rtl_output_continuous.csv`
- `sim/rtl_output_backpressure.csv`
- `reports/benchmark_summary.md`
- `reports/benchmark_summary.txt`

## Vivado Synthesis and Implementation

The design targets a Xilinx Artix-7 FPGA:

```text
xc7a35tcpg236-1

Run synthesis:

vivado -mode batch -source scripts/vivado_synth.tcl

Run implementation:

vivado -mode batch -source scripts/vivado_impl.tcl

Generated reports include:

reports/synth_timing_summary.rpt
reports/synth_utilization.rpt
reports/post_route_timing_summary.rpt
reports/post_route_utilization.rpt
reports/route_status.rpt
reports/post_route_power.rpt

The design is constrained for a 100 MHz target clock using:

constraints/cordic_artix7.xdc