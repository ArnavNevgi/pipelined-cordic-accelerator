# Error Analysis

## Overview

The CORDIC accelerator is verified by comparing SystemVerilog RTL simulation outputs against a Python golden reference model.

The Python golden model writes:

- `sim/golden_output.csv`

The RTL testbench writes:

- `sim/rtl_output.csv`

The comparison script writes:

- `reports/accuracy_report.txt`

## Fixed-Point Format

All compared sine and cosine values use signed Q2.14 fixed-point format.

- Total width: 16 bits
- Fractional bits: 14
- Scale factor: 16384
- One LSB: `1 / 16384 = 0.00006103515625`

## Metrics

The comparison script reports:

- Maximum absolute sine error
- Maximum absolute cosine error
- Mean absolute sine error
- Mean absolute cosine error
- RMS sine error
- RMS cosine error
- Maximum sine error in LSBs
- Maximum cosine error in LSBs

## Notes

Small numerical differences are expected because the RTL implementation uses finite-width Q2.14 arithmetic, arithmetic right shifts, and quantized arctangent constants.

Use the generated `reports/accuracy_report.txt` as the source of truth for current accuracy numbers.
