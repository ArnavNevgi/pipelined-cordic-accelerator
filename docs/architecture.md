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
