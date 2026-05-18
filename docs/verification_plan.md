# Verification Methodology

## Verification Goals

The verification flow checks that the CORDIC RTL:

- Accepts and preserves signed Q2.14 input angles.
- Produces sine and cosine outputs in the expected order.
- Matches the Python golden reference within the selected fixed-point tolerance.
- Preserves all transactions during valid-ready backpressure.
- Holds input and output data stable during stalled handshakes.
- Completes continuous and randomized simulations without assertion failures.
- Produces reproducible accuracy, latency, and throughput evidence.

## Test Vector Generation

`scripts/gen_golden.py` generates the input vectors and golden reference data. It writes:

- `tb/cordic_test_vectors.hex`
- `sim/golden_output.csv`
- `reports/atan_table_q214.txt`
- `reports/golden_generation_summary.txt`

The generator uses signed Q2.14 conversion with 14 fractional bits and a scale factor of 16384. It also records the CORDIC gain compensation constant and arctangent lookup table.

## Directed Tests

The directed set covers representative points in the supported angle range:

- `0`
- `+/-pi/12`
- `+/-pi/6`
- `+/-pi/4`
- `+/-pi/3`
- `+/-pi/2`

These values exercise zero angle behavior, positive and negative rotations, and range endpoints.

## Randomized Tests

The random test set contains angles generated uniformly in:

```text
-pi/2 to +pi/2 radians
```

The random seed is fixed so the vector set is reproducible. The current generated set contains 1011 total samples, including directed and random vectors.

## Backpressure Tests

The QuestaSim testbench supports two operating modes:

- Continuous streaming with `in_valid` high and `out_ready` high.
- Randomized input valid gaps and randomized output backpressure.

The testbench accepts plusargs:

```text
+RANDOM_STALLS=0 or 1
+SEED=<integer>
+RTL_CSV=<path>
+METRICS_CSV=<path>
```

When randomized stalls are enabled, the input source holds `angle_in` stable while `in_valid` is high and `in_ready` is low. The output monitor records only accepted output handshakes, preserving ordering through the CSV index.

## Assertion Checks

Simulation-time SystemVerilog assertions are implemented in `tb/cordic_assertions.sv`. They check:

- Reset clears visible output valid.
- Accepted input angles are not unknown.
- Valid output sine and cosine values are not unknown.
- Input data remains stable when `in_valid` is high and `in_ready` is low.
- Output data remains stable when `out_valid` is high and `out_ready` is low.
- Accepted output count never exceeds accepted input count.
- `out_valid` is not asserted without a prior unconsumed input transaction.

The assertion module is compiled by the QuestaSim scripts used for the default simulation and benchmark simulations.

## Golden Model Comparison

`scripts/compare_results.py` reads:

- `sim/golden_output.csv`
- `sim/rtl_output.csv`

The script verifies row count, output index, input angle ordering, signed Q2.14 sine output, and signed Q2.14 cosine output. It computes maximum absolute error, mean absolute error, RMS error, and LSB error.

## Pass Criteria

The simulation and comparison pass when:

```text
sent_count = NUM_VECTORS
recv_count = NUM_VECTORS
measured_first_latency >= STAGES
max sine error <= selected tolerance
max cosine error <= selected tolerance
no SystemVerilog assertion failures
```

The current accuracy tolerance is defined in `scripts/compare_results.py`.

## Generated Evidence

The verification and benchmark flow produces:

- `sim/rtl_output.csv`
- `sim/rtl_output_continuous.csv`
- `sim/rtl_output_backpressure.csv`
- `sim/metrics.csv`
- `sim/metrics_continuous.csv`
- `sim/metrics_backpressure.csv`
- `reports/accuracy_report.txt`
- `reports/benchmark_summary.md`
- `reports/benchmark_summary.txt`

The current generated reports show PASS accuracy across 1011 samples, a continuous output-span throughput of `1.000000 outputs/cycle`, and a randomized backpressure output-span throughput of `0.713479 outputs/cycle`.
