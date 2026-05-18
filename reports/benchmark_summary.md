# CORDIC Latency and Throughput Benchmark

## Overview

This report summarizes simulation-measured latency and throughput for the 16-stage pipelined CORDIC sine/cosine accelerator. The benchmark uses the same 1011-vector dataset as the accuracy comparison.

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

In continuous streaming mode, the pipeline produces one sine/cosine output pair per cycle after the initial fill. The output-span throughput captures this steady output production interval.

In randomized backpressure mode, throughput is lower because the valid-ready interface stalls the full pipeline whenever the downstream sink deasserts `out_ready`. This behavior is intentional: the global stall preserves output data and every in-flight transaction.

The active-window throughput includes the initial latency from first accepted input to final accepted output, while output-span throughput measures only the interval from first accepted output to final accepted output.

## Generated Files

- `sim/metrics_continuous.csv`
- `sim/metrics_backpressure.csv`
- `sim/rtl_output_continuous.csv`
- `sim/rtl_output_backpressure.csv`
- `reports/benchmark_summary.txt`
