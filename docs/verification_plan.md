# Verification Plan

## Verification Goals

The design will be verified against a Python golden reference model.

## Test Categories

1. Directed angle tests
2. Randomized angle tests
3. Continuous streaming tests
4. Valid-ready backpressure tests
5. Reset behavior tests
6. Latency and throughput measurement

## Directed Angles

The directed test set will include:

- 0
- pi/6
- -pi/6
- pi/4
- -pi/4
- pi/3
- -pi/3
- pi/2
- -pi/2

## Random Testing

Random angles will be generated in the range:

-pi/2 to +pi/2

## Pass Criteria

RTL sine and cosine outputs must match the Python fixed-point CORDIC model within the selected fixed-point tolerance.
## Phase 4 Basic Simulation

The first SystemVerilog testbench performs a basic end-to-end simulation of the 16-stage CORDIC pipeline.

### Testbench Behavior

- Reads Q2.14 angle vectors from `tb/cordic_test_vectors.hex`
- Drives one angle per clock cycle
- Keeps `out_ready` high
- Captures `sin_out` and `cos_out`
- Writes RTL results to `sim/rtl_output.csv`
- Checks that the number of received outputs matches the number of sent inputs
- Measures first-output latency

### Current Limitation

The Phase 4 testbench does not yet compare RTL output against the Python golden model. Numerical comparison is added in the next phase.

