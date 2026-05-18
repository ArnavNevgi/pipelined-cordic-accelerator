@"
# Architecture

## Overview

The design is a 16-stage pipelined CORDIC accelerator for sine and cosine computation.

## Algorithm

The accelerator uses rotation-mode CORDIC. Each pipeline stage performs one micro-rotation using shift-add arithmetic.

## Pipeline

Each stage contains registered x, y and z values.

```text
Input angle -> Stage 0 -> Stage 1 -> ... -> Stage 15 -> sine/cosine output

## Interface

The design uses a valid-ready streaming interface.

## Target Throughput

After pipeline fill, the target throughput is one sine/cosine output pair per clock cycle.

## Target Latency

The expected latency is 16 pipeline stages.

## Phase 3 RTL Core

The first RTL version implements a 16-stage always-advancing CORDIC pipeline.

### Current Behavior

- `in_ready` is always asserted.
- A new input can be accepted every clock cycle.
- `out_valid` is delayed through a 16-stage valid pipeline.
- `out_ready` is part of the interface but is not used yet.
- Full stall-aware backpressure support will be added in a later phase.

### Pipeline Registers

Each stage stores:

- `x_pipe[i]`
- `y_pipe[i]`
- `z_pipe[i]`
- `valid_pipe[i]`

### CORDIC Initialization

At input handshake:

```text
x_0 = CORDIC_K
y_0 = 0
z_0 = input angle
Expected Latency

The expected latency is 16 clock cycles from input handshake to output valid.

