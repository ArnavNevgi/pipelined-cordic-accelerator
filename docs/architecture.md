# Architecture

## Overview

The design is a 16-stage pipelined CORDIC accelerator for sine and cosine computation in signed Q2.14 fixed-point format.

## Algorithm

The accelerator uses rotation-mode CORDIC. Each stage performs one micro-rotation using only additions, subtractions, arithmetic right shifts, and a precomputed arctangent constant.

For stage `i`:

```text
if z >= 0:
  x_next = x - (y >>> i)
  y_next = y + (x >>> i)
  z_next = z - atan(2^-i)
else:
  x_next = x + (y >>> i)
  y_next = y - (x >>> i)
  z_next = z + atan(2^-i)
```

## Initialization

At an accepted input handshake:

```text
x_0 = CORDIC_K
y_0 = 0
z_0 = input angle
```

`CORDIC_K` is the reciprocal CORDIC gain quantized to Q2.14.

## Pipeline

The RTL stores registered `x`, `y`, `z`, and valid state for the input stage and each of the 16 iteration stages:

```text
Input handshake -> Stage 0 -> Stage 1 -> ... -> Stage 16 -> sine/cosine output
```

The output mapping is:

```text
cos_out = x_pipe[STAGES]
sin_out = y_pipe[STAGES]
```

## Valid-Ready Interface

The core exposes a streaming valid-ready interface:

- `in_valid`
- `in_ready`
- `out_valid`
- `out_ready`

The current implementation uses a global stall for output backpressure.

```text
pipe_advance = out_ready || !valid_pipe[STAGES]
in_ready     = pipe_advance
```

When `out_valid` is high and `out_ready` is low, all pipeline registers hold their values. This preserves the output sample and every in-flight transaction. When the output is ready, the whole pipeline advances together.

## Throughput and Latency

Under continuous downstream readiness, the pipeline produces one sine/cosine pair per cycle after filling. The benchmark report measures both active-window throughput and output-span throughput.

The datapath contains 16 CORDIC iteration stages. The testbench latency metric is measured from accepted input transaction to accepted output transaction, so it includes registered valid-ready handshaking at the output.
