# CORDIC Latency and Throughput Benchmark

## Overview

This report summarizes simulation-measured latency and throughput for the 16-stage pipelined CORDIC sine/cosine accelerator.

## Benchmark Configuration

| Parameter | Value |
|---|---:|
| Number of input vectors | 1011 |
| Clock period | 10 ns |
| Clock target | 100 MHz |
| Pipeline depth | 16 stages |
| Output per transaction | One sine/cosine pair |

## Results

| Benchmark | First latency cycles | Active cycles | Output span cycles | Throughput active window | Throughput output span |
|---|---:|---:|---:|---:|---:|
| Continuous streaming | 17 | 1028 | 1011 | 0.983463 outputs/cycle (98.346 M outputs/s) | 1.000000 outputs/cycle (100.000 M outputs/s) |
| Randomized backpressure | 17 | 1434 | 1417 | 0.705021 outputs/cycle (70.502 M outputs/s) | 0.713479 outputs/cycle (71.348 M outputs/s) |

## Interpretation

In continuous streaming mode, the CORDIC pipeline should approach one sine/cosine output pair per cycle after the initial pipeline fill. The active-window throughput includes the initial pipeline latency, while output-span throughput measures only the output production interval.

In randomized backpressure mode, throughput decreases because the valid-ready interface stalls the entire pipeline when the downstream consumer deasserts `out_ready`. The pass condition is that all outputs are preserved in order and the RTL output still matches the Python golden model.

## Generated Files

- `sim/metrics_continuous.csv`
- `sim/metrics_backpressure.csv`
- `sim/rtl_output_continuous.csv`
- `sim/rtl_output_backpressure.csv`
