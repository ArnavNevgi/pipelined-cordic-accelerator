# Fixed-Point Format

## Q2.14 Summary

The CORDIC core uses signed Q2.14 fixed-point values for input angle, sine output, cosine output, datapath state, arctangent constants, and gain compensation.

| Field | Value |
|---|---:|
| Total width | 16 bits |
| Sign bits | 1 |
| Integer magnitude bits | 1 |
| Fractional bits | 14 |
| Scale factor | 16384 |
| Minimum signed integer | -32768 |
| Maximum signed integer | 32767 |
| Approximate numeric range | -2.0 to +1.9999 |
| Resolution | 0.00006103515625 |

## Conversion Rules

Floating-point values are quantized by scaling by `2^14`, rounding to the nearest integer, and saturating to the signed 16-bit range:

```text
q214 = round(value * 16384)
```

The inverse conversion is:

```text
value = q214 / 16384
```

Negative values are represented in two's-complement form when written to hexadecimal vector files.

## Conversion Examples

| Decimal value | Q2.14 signed integer | Hex representation |
|---:|---:|---:|
| 0.0 | 0 | 16'h0000 |
| 1.0 | 16384 | 16'h4000 |
| 0.5 | 8192 | 16'h2000 |
| -0.5 | -8192 | 16'hE000 |
| -1.0 | -16384 | 16'hC000 |

## Angle Representation

Input angles are represented in radians using signed Q2.14 format. The current supported angle range is:

```text
-pi/2 to +pi/2 radians
```

This range fits comfortably inside Q2.14 because `pi/2` is approximately `1.570796`.

## Output Representation

The sine and cosine outputs are signed Q2.14 values. Since sine and cosine are bounded by `-1.0` and `+1.0`, their results fit within the Q2.14 numeric range.

## Quantization Notes

Quantization occurs in several places:

- Python converts floating-point directed and random angles into Q2.14 test vectors.
- Python converts floating-point sine and cosine reference values into Q2.14 golden outputs.
- Python generates `atan(2^-i)` constants in Q2.14 format.
- RTL arithmetic uses finite 16-bit signed values and arithmetic right shifts.

These effects are expected to introduce small LSB-level differences between the RTL CORDIC result and the Python math-library reference. The generated accuracy report captures the observed error metrics.

## CORDIC Constants

The gain compensation constant is:

```text
CORDIC_K = round(0.607252935103 * 16384) = 9949
```

The arctangent lookup table is generated with:

```text
ATAN_TABLE[i] = round(atan(2^-i) * 16384)
```

The generated constants are documented in `reports/atan_table_q214.txt`.
