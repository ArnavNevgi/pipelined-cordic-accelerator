# Fixed-Point Format

## Q2.14 Format

The design uses signed Q2.14 fixed-point arithmetic.

- Total width: 16 bits
- Fractional bits: 14
- Scale factor: 2^14 = 16384
- Approximate range: -2.0 to +1.9999
- Resolution: 1 / 16384 = 0.000061

## Angle Format

Input angles are represented in radians using Q2.14 format.

Initial supported angle range:

-pi/2 to +pi/2

## Output Format

Sine and cosine outputs are also represented using signed Q2.14 format.