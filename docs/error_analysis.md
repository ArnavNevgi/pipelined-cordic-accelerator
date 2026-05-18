# Error Analysis

## Comparison Method

The numerical comparison flow checks the RTL output CSV against the Python golden reference CSV. The Python generator computes floating-point sine and cosine values using the Python math library, then quantizes those values into signed Q2.14 format. The RTL simulation writes accepted sine/cosine outputs in the same signed Q2.14 format.

The comparison script is:

```text
python scripts/compare_results.py
```

It reads:

- `sim/golden_output.csv`
- `sim/rtl_output.csv`

It writes:

- `reports/accuracy_report.txt`

## Error Units

One Q2.14 LSB is:

```text
1 / 16384 = 0.00006103515625
```

An error of 8 LSBs corresponds to:

```text
8 / 16384 = 0.00048828125
```

The report includes both LSB error and decimal fixed-point error.

## Current Results

The current generated accuracy report compares 1011 samples.

| Metric | Result |
|---|---:|
| Accuracy status | PASS |
| Max absolute sine error | 8 LSBs |
| Max absolute cosine error | 8 LSBs |
| Max absolute sine error, decimal | 0.000488281250 |
| Max absolute cosine error, decimal | 0.000488281250 |

Detailed mean absolute error and RMS error values are recorded in `reports/accuracy_report.txt`.

## Why Quantization Error Is Expected

The RTL CORDIC result is not expected to match the Python floating-point reference exactly. Small differences are introduced by:

- Q2.14 quantization of input angles.
- Q2.14 quantization of arctangent constants.
- Q2.14 gain compensation.
- Finite 16-bit signed datapath arithmetic.
- Arithmetic right shifts in each CORDIC stage.
- The finite number of CORDIC iterations.

The observed maximum error of 8 LSBs is within the selected comparison tolerance and is consistent with a compact fixed-point CORDIC implementation.
