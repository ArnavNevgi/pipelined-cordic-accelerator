# Waveform Inspection Guide

## Purpose

Waveform inspection is useful for reviewing handshake timing, pipeline fill/drain behavior, and backpressure preservation. The project includes `sim/wave.do` to add the most relevant signals to a QuestaSim waveform window.

This document is an inspection guide only. It does not claim that waveform screenshots are included.

## Recommended Signals

Top-level control:

- `clk`
- `rst_n`

Input interface:

- `in_valid`
- `in_ready`
- `angle_in`

Output interface:

- `out_valid`
- `out_ready`
- `sin_out`
- `cos_out`

Testbench counters:

- `sent_count`
- `recv_count`
- `cycle_count`

Pipeline control and state:

- `pipe_advance`
- `valid_pipe`
- selected `x_pipe`, `y_pipe`, and `z_pipe` entries

## Continuous Streaming Behavior

With randomized stalls disabled:

- `in_ready` should remain high after reset.
- `out_ready` should remain high.
- Accepted inputs should advance once per cycle.
- After pipeline fill, accepted outputs should occur once per cycle.
- The output-span throughput should match the benchmark result of `1.000000 outputs/cycle`.

## Backpressure Behavior

When `out_valid` is high and `out_ready` is low:

- `pipe_advance` should be low.
- `in_ready` should be low.
- `sin_out` and `cos_out` should remain stable.
- Internal pipeline registers should hold their previous values.

When `out_ready` returns high, the pipeline should resume without dropping or reordering samples.

## Reset Behavior

During reset:

- `out_valid` should be low.
- Pipeline valid bits should be cleared.
- No output transaction should be accepted.

The assertion module also checks reset-visible output valid behavior during simulation.
