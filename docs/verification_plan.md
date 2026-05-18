# Verification Plan

## Verification Goals

The design is verified against a Python golden reference model and simulation-generated RTL CSV output.

## Test Categories

1. Directed angle tests
2. Randomized angle tests
3. Continuous streaming tests
4. Valid-ready backpressure tests
5. Reset behavior checks
6. Latency and throughput measurement

## Directed Angles

The directed test set includes angles such as:

- `0`
- `+/-pi/12`
- `+/-pi/6`
- `+/-pi/4`
- `+/-pi/3`
- `+/-pi/2`

## Random Testing

Random angles are generated in the current supported range:

```text
-pi/2 to +pi/2 radians
```

The generator uses a fixed seed so the test set is reproducible.

## Simulation Flow

1. Generate golden vectors:

```text
python scripts/gen_golden.py
```

2. Run the default RTL simulation from the repository root in QuestaSim:

```text
do scripts/run_questa.do
```

3. Compare RTL output against golden output:

```text
python scripts/compare_results.py
```

## Pass Criteria

The simulation and comparison pass when:

```text
sent_count = NUM_VECTORS
recv_count = NUM_VECTORS
measured_first_latency >= STAGES
max sine error <= selected tolerance
max cosine error <= selected tolerance
```

The comparison tolerance is defined in `scripts/compare_results.py`.

## Backpressure Verification

The testbench supports randomized valid-ready behavior through plusargs:

```text
+RANDOM_STALLS=0 or 1
+SEED=<integer>
+RTL_CSV=<path>
+METRICS_CSV=<path>
```

In randomized mode, the input source inserts valid gaps and the output sink randomly deasserts `out_ready`. Once the source presents a valid input sample, it holds that sample stable until the input handshake completes.

## Benchmark Flow

Run the Phase 7 benchmark from the repository root in QuestaSim:

```text
do scripts/run_benchmark.do
```

Then generate the report:

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

The continuous streaming output-span throughput should be close to one output per cycle. Randomized backpressure throughput should be lower, with all outputs preserved in order.
