# Waveform Notes

## Wave Script

`sim/wave.do` adds the main interface, counters, global pipeline control, valid pipeline, and selected CORDIC pipeline stages.

## Signals to Inspect

- `clk`
- `rst_n`
- `in_valid`
- `in_ready`
- `angle_in`
- `out_valid`
- `out_ready`
- `sin_out`
- `cos_out`
- `pipe_advance`
- `valid_pipe`
- selected `x_pipe`, `y_pipe`, and `z_pipe` entries

## Backpressure Behavior

When `out_valid` is high and `out_ready` is low:

- `pipe_advance` should be low
- `in_ready` should be low
- all pipeline registers should hold their previous values
- the same output sample should remain visible until accepted

When `out_ready` returns high, the pipeline should resume without dropping or reordering samples.
