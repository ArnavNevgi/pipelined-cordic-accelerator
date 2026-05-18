"""
gen_golden.py

Phase 1 golden vector generator for the Pipelined CORDIC Hardware Accelerator.

This script:
1. Defines Q2.14 fixed-point conversion helpers.
2. Generates directed and randomized input angles.
3. Computes golden sine and cosine values using Python math library.
4. Quantizes angles, sine and cosine values to signed Q2.14.
5. Writes test vectors for the SystemVerilog testbench.
6. Writes golden output CSV for RTL comparison.
7. Generates the Q2.14 arctangent lookup table for RTL.
"""

import math
import random
import csv
from pathlib import Path


# ============================================================
# Fixed-point configuration
# ============================================================

DATA_WIDTH = 16
FRAC_BITS = 14
SCALE = 1 << FRAC_BITS

SIGNED_MIN = -(1 << (DATA_WIDTH - 1))
SIGNED_MAX = (1 << (DATA_WIDTH - 1)) - 1

NUM_RANDOM_TESTS = 1000
RANDOM_SEED = 42

ANGLE_MIN = -math.pi / 2
ANGLE_MAX = math.pi / 2


# ============================================================
# Paths
# ============================================================

ROOT_DIR = Path(__file__).resolve().parents[1]

TB_DIR = ROOT_DIR / "tb"
SIM_DIR = ROOT_DIR / "sim"
REPORTS_DIR = ROOT_DIR / "reports"

TB_DIR.mkdir(exist_ok=True)
SIM_DIR.mkdir(exist_ok=True)
REPORTS_DIR.mkdir(exist_ok=True)

TEST_VECTOR_FILE = TB_DIR / "cordic_test_vectors.hex"
GOLDEN_CSV_FILE = SIM_DIR / "golden_output.csv"
ATAN_TABLE_FILE = REPORTS_DIR / "atan_table_q214.txt"
SUMMARY_FILE = REPORTS_DIR / "golden_generation_summary.txt"


# ============================================================
# Q2.14 helper functions
# ============================================================

def saturate_signed(value: int) -> int:
    """
    Saturate integer to signed 16-bit range.
    """
    if value > SIGNED_MAX:
        return SIGNED_MAX
    if value < SIGNED_MIN:
        return SIGNED_MIN
    return value


def float_to_q214(value: float) -> int:
    """
    Convert floating-point value to signed Q2.14 integer.
    """
    scaled = int(round(value * SCALE))
    return saturate_signed(scaled)


def q214_to_float(value: int) -> float:
    """
    Convert signed Q2.14 integer to floating-point value.
    """
    return value / SCALE


def signed_to_hex16(value: int) -> str:
    """
    Convert signed integer to 16-bit two's complement hexadecimal string.
    """
    value = value & 0xFFFF
    return f"{value:04X}"


def hex16_to_signed(hex_string: str) -> int:
    """
    Convert 16-bit hexadecimal string to signed integer.
    """
    value = int(hex_string, 16)
    if value & 0x8000:
        value -= 0x10000
    return value


# ============================================================
# Test angle generation
# ============================================================

def generate_directed_angles():
    """
    Directed angles in radians.
    """
    return [
        0.0,
        math.pi / 12,
        -math.pi / 12,
        math.pi / 6,
        -math.pi / 6,
        math.pi / 4,
        -math.pi / 4,
        math.pi / 3,
        -math.pi / 3,
        math.pi / 2,
        -math.pi / 2,
    ]


def generate_random_angles(num_tests: int):
    """
    Random angles in the supported CORDIC range.
    """
    random.seed(RANDOM_SEED)
    return [random.uniform(ANGLE_MIN, ANGLE_MAX) for _ in range(num_tests)]


def generate_all_angles():
    """
    Combine directed and randomized angles.
    """
    directed = generate_directed_angles()
    randomized = generate_random_angles(NUM_RANDOM_TESTS)
    return directed + randomized


# ============================================================
# Arctangent table generation
# ============================================================

def generate_atan_table(num_stages: int = 16):
    """
    Generate atan(2^-i) constants in Q2.14.
    """
    table = []
    for i in range(num_stages):
        atan_float = math.atan(2 ** -i)
        atan_q214 = float_to_q214(atan_float)
        table.append((i, atan_float, atan_q214, signed_to_hex16(atan_q214)))
    return table


def write_atan_table():
    """
    Write arctangent lookup table to a report file.
    """
    table = generate_atan_table(16)

    with open(ATAN_TABLE_FILE, "w", encoding="utf-8") as f:
        f.write("CORDIC arctangent lookup table in Q2.14 format\n")
        f.write("Scale factor = 2^14 = 16384\n")
        f.write("\n")
        f.write("index, atan_float_radians, atan_q214_signed, atan_q214_hex\n")

        for index, atan_float, atan_q214, atan_hex in table:
            f.write(f"{index}, {atan_float:.12f}, {atan_q214}, 16'h{atan_hex}\n")

        f.write("\nSystemVerilog localparam format:\n")
        f.write("localparam q2_14_t ATAN_TABLE [0:STAGES-1] = '{\n")

        for index, atan_float, atan_q214, atan_hex in table:
            comma = "," if index < len(table) - 1 else ""
            f.write(f"    16'sd{atan_q214}{comma}  // atan(2^-{index}) = {atan_float:.12f}\n")

        f.write("};\n")


# ============================================================
# Golden output generation
# ============================================================

def write_test_vectors_and_golden_csv():
    """
    Generate input test vectors and golden output CSV.
    """
    angles = generate_all_angles()

    with open(TEST_VECTOR_FILE, "w", encoding="utf-8") as vector_file, \
         open(GOLDEN_CSV_FILE, "w", newline="", encoding="utf-8") as csv_file:

        writer = csv.writer(csv_file)

        writer.writerow([
            "index",
            "angle_float",
            "angle_q214_signed",
            "angle_q214_hex",
            "sin_float",
            "cos_float",
            "sin_q214_signed",
            "sin_q214_hex",
            "cos_q214_signed",
            "cos_q214_hex"
        ])

        for index, angle in enumerate(angles):
            angle_q214 = float_to_q214(angle)
            angle_hex = signed_to_hex16(angle_q214)

            sin_float = math.sin(angle)
            cos_float = math.cos(angle)

            sin_q214 = float_to_q214(sin_float)
            cos_q214 = float_to_q214(cos_float)

            sin_hex = signed_to_hex16(sin_q214)
            cos_hex = signed_to_hex16(cos_q214)

            # Testbench will read one angle per line as 16-bit hex.
            vector_file.write(f"{angle_hex}\n")

            writer.writerow([
                index,
                f"{angle:.12f}",
                angle_q214,
                angle_hex,
                f"{sin_float:.12f}",
                f"{cos_float:.12f}",
                sin_q214,
                sin_hex,
                cos_q214,
                cos_hex
            ])

    return len(angles)


def write_summary(num_vectors: int):
    """
    Write a short summary report.
    """
    cordic_k = 1.0
    for i in range(16):
        cordic_k *= 1.0 / math.sqrt(1 + 2 ** (-2 * i))

    cordic_k_q214 = float_to_q214(cordic_k)

    with open(SUMMARY_FILE, "w", encoding="utf-8") as f:
        f.write("Golden vector generation summary\n")
        f.write("\n")
        f.write(f"Data width: {DATA_WIDTH} bits\n")
        f.write(f"Fixed-point format: Q2.14\n")
        f.write(f"Fractional bits: {FRAC_BITS}\n")
        f.write(f"Scale factor: {SCALE}\n")
        f.write(f"Signed range: {SIGNED_MIN} to {SIGNED_MAX}\n")
        f.write(f"Angle range: {-math.pi / 2:.12f} to {math.pi / 2:.12f} radians\n")
        f.write(f"Directed tests: {len(generate_directed_angles())}\n")
        f.write(f"Random tests: {NUM_RANDOM_TESTS}\n")
        f.write(f"Total vectors: {num_vectors}\n")
        f.write(f"Random seed: {RANDOM_SEED}\n")
        f.write("\n")
        f.write(f"CORDIC gain compensation K: {cordic_k:.12f}\n")
        f.write(f"CORDIC K in Q2.14 signed integer: {cordic_k_q214}\n")
        f.write(f"CORDIC K in Q2.14 hex: 16'h{signed_to_hex16(cordic_k_q214)}\n")


# ============================================================
# Main
# ============================================================

def main():
    print("Generating Phase 1 CORDIC golden model files...")

    num_vectors = write_test_vectors_and_golden_csv()
    write_atan_table()
    write_summary(num_vectors)

    print("Done.")
    print(f"Generated {num_vectors} test vectors.")
    print(f"Wrote: {TEST_VECTOR_FILE}")
    print(f"Wrote: {GOLDEN_CSV_FILE}")
    print(f"Wrote: {ATAN_TABLE_FILE}")
    print(f"Wrote: {SUMMARY_FILE}")


if __name__ == "__main__":
    main()
