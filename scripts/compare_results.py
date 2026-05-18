"""
compare_results.py

Compares RTL CORDIC outputs against Python golden sine/cosine outputs.

Inputs:
    sim/golden_output.csv
    sim/rtl_output.csv

Outputs:
    reports/accuracy_report.txt

Metrics:
    - Max absolute sine error
    - Max absolute cosine error
    - Mean absolute sine error
    - Mean absolute cosine error
    - RMS sine error
    - RMS cosine error
    - Max sine error in LSBs
    - Max cosine error in LSBs
"""

import csv
import math
from pathlib import Path


# ============================================================
# Fixed-point configuration
# ============================================================

DATA_WIDTH = 16
FRAC_BITS = 14
SCALE = 1 << FRAC_BITS

# This tolerance is intentionally realistic for fixed-point CORDIC.
# Later, after we inspect real output, we can tighten it.
MAX_ALLOWED_ERROR_LSB = 8


# ============================================================
# Paths
# ============================================================

ROOT_DIR = Path(__file__).resolve().parents[1]

GOLDEN_CSV = ROOT_DIR / "sim" / "golden_output.csv"
RTL_CSV = ROOT_DIR / "sim" / "rtl_output.csv"
REPORT_FILE = ROOT_DIR / "reports" / "accuracy_report.txt"


# ============================================================
# Helper functions
# ============================================================

def q214_to_float(value: int) -> float:
    """
    Convert signed Q2.14 integer to float.
    """
    return value / SCALE


def read_golden_csv(path: Path):
    """
    Read golden output CSV.

    Expected columns:
        index
        angle_float
        angle_q214_signed
        angle_q214_hex
        sin_float
        cos_float
        sin_q214_signed
        sin_q214_hex
        cos_q214_signed
        cos_q214_hex
    """
    rows = []

    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        for row in reader:
            rows.append({
                "index": int(row["index"]),
                "angle_float": float(row["angle_float"]),
                "angle_q214": int(row["angle_q214_signed"]),
                "sin_float": float(row["sin_float"]),
                "cos_float": float(row["cos_float"]),
                "sin_q214": int(row["sin_q214_signed"]),
                "cos_q214": int(row["cos_q214_signed"]),
            })

    return rows


def read_rtl_csv(path: Path):
    """
    Read RTL output CSV.

    Expected columns:
        index
        angle_q214_signed
        sin_q214_signed
        cos_q214_signed
        cycle
    """
    rows = []

    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)

        for row in reader:
            rows.append({
                "index": int(row["index"]),
                "angle_q214": int(row["angle_q214_signed"]),
                "sin_q214": int(row["sin_q214_signed"]),
                "cos_q214": int(row["cos_q214_signed"]),
                "cycle": int(row["cycle"]),
            })

    return rows


def mean(values):
    return sum(values) / len(values) if values else 0.0


def rms(values):
    return math.sqrt(sum(v * v for v in values) / len(values)) if values else 0.0


# ============================================================
# Main comparison
# ============================================================

def main():
    print("Running RTL vs golden comparison...")

    if not GOLDEN_CSV.exists():
        raise FileNotFoundError(f"Missing golden CSV: {GOLDEN_CSV}")

    if not RTL_CSV.exists():
        raise FileNotFoundError(f"Missing RTL CSV: {RTL_CSV}")

    golden_rows = read_golden_csv(GOLDEN_CSV)
    rtl_rows = read_rtl_csv(RTL_CSV)

    if len(golden_rows) != len(rtl_rows):
        raise RuntimeError(
            f"Row count mismatch: golden={len(golden_rows)}, rtl={len(rtl_rows)}"
        )

    sin_errors_float = []
    cos_errors_float = []

    sin_errors_lsb = []
    cos_errors_lsb = []

    mismatches = []

    for g, r in zip(golden_rows, rtl_rows):
        index = g["index"]

        if index != r["index"]:
            raise RuntimeError(
                f"Index mismatch: golden index={index}, rtl index={r['index']}"
            )

        if g["angle_q214"] != r["angle_q214"]:
            raise RuntimeError(
                f"Angle mismatch at index {index}: "
                f"golden angle={g['angle_q214']}, rtl angle={r['angle_q214']}"
            )

        sin_error_lsb = r["sin_q214"] - g["sin_q214"]
        cos_error_lsb = r["cos_q214"] - g["cos_q214"]

        sin_error_float = q214_to_float(sin_error_lsb)
        cos_error_float = q214_to_float(cos_error_lsb)

        sin_errors_lsb.append(sin_error_lsb)
        cos_errors_lsb.append(cos_error_lsb)

        sin_errors_float.append(sin_error_float)
        cos_errors_float.append(cos_error_float)

        if abs(sin_error_lsb) > MAX_ALLOWED_ERROR_LSB or abs(cos_error_lsb) > MAX_ALLOWED_ERROR_LSB:
            mismatches.append({
                "index": index,
                "angle_float": g["angle_float"],
                "angle_q214": g["angle_q214"],
                "golden_sin": g["sin_q214"],
                "rtl_sin": r["sin_q214"],
                "sin_error_lsb": sin_error_lsb,
                "golden_cos": g["cos_q214"],
                "rtl_cos": r["cos_q214"],
                "cos_error_lsb": cos_error_lsb,
                "cycle": r["cycle"],
            })

    abs_sin_lsb = [abs(e) for e in sin_errors_lsb]
    abs_cos_lsb = [abs(e) for e in cos_errors_lsb]

    abs_sin_float = [abs(e) for e in sin_errors_float]
    abs_cos_float = [abs(e) for e in cos_errors_float]

    max_abs_sin_lsb = max(abs_sin_lsb)
    max_abs_cos_lsb = max(abs_cos_lsb)

    max_abs_sin_float = max(abs_sin_float)
    max_abs_cos_float = max(abs_cos_float)

    mean_abs_sin_float = mean(abs_sin_float)
    mean_abs_cos_float = mean(abs_cos_float)

    rms_sin_float = rms(sin_errors_float)
    rms_cos_float = rms(cos_errors_float)

    pass_status = (
        max_abs_sin_lsb <= MAX_ALLOWED_ERROR_LSB and
        max_abs_cos_lsb <= MAX_ALLOWED_ERROR_LSB
    )

    REPORT_FILE.parent.mkdir(exist_ok=True)

    with open(REPORT_FILE, "w", encoding="utf-8") as f:
        f.write("CORDIC RTL vs Golden Accuracy Report\n")
        f.write("====================================\n\n")

        f.write("Configuration\n")
        f.write("-------------\n")
        f.write(f"Data width: {DATA_WIDTH} bits\n")
        f.write("Fixed-point format: Q2.14\n")
        f.write(f"Fractional bits: {FRAC_BITS}\n")
        f.write(f"Scale factor: {SCALE}\n")
        f.write(f"Total compared samples: {len(golden_rows)}\n")
        f.write(f"Maximum allowed error: {MAX_ALLOWED_ERROR_LSB} LSBs\n\n")

        f.write("Error Metrics\n")
        f.write("-------------\n")
        f.write(f"Max absolute sine error   : {max_abs_sin_lsb} LSBs, {max_abs_sin_float:.12f}\n")
        f.write(f"Max absolute cosine error : {max_abs_cos_lsb} LSBs, {max_abs_cos_float:.12f}\n")
        f.write(f"Mean absolute sine error  : {mean_abs_sin_float:.12f}\n")
        f.write(f"Mean absolute cosine error: {mean_abs_cos_float:.12f}\n")
        f.write(f"RMS sine error            : {rms_sin_float:.12f}\n")
        f.write(f"RMS cosine error          : {rms_cos_float:.12f}\n\n")

        f.write("Pass/Fail\n")
        f.write("---------\n")
        f.write(f"Status: {'PASS' if pass_status else 'FAIL'}\n")
        f.write(f"Number of samples above tolerance: {len(mismatches)}\n\n")

        if mismatches:
            f.write("First mismatches\n")
            f.write("----------------\n")
            for m in mismatches[:20]:
                f.write(
                    "index={index}, angle={angle_float:.12f}, "
                    "sin_golden={golden_sin}, sin_rtl={rtl_sin}, sin_err={sin_error_lsb}, "
                    "cos_golden={golden_cos}, cos_rtl={rtl_cos}, cos_err={cos_error_lsb}, "
                    "cycle={cycle}\n".format(**m)
                )

    print("Comparison complete.")
    print(f"Compared samples: {len(golden_rows)}")
    print(f"Max sine error  : {max_abs_sin_lsb} LSBs, {max_abs_sin_float:.12f}")
    print(f"Max cosine error: {max_abs_cos_lsb} LSBs, {max_abs_cos_float:.12f}")
    print(f"Mean abs sine error  : {mean_abs_sin_float:.12f}")
    print(f"Mean abs cosine error: {mean_abs_cos_float:.12f}")
    print(f"RMS sine error  : {rms_sin_float:.12f}")
    print(f"RMS cosine error: {rms_cos_float:.12f}")
    print(f"Status: {'PASS' if pass_status else 'FAIL'}")
    print(f"Wrote report: {REPORT_FILE}")

    if not pass_status:
        raise SystemExit("FAIL: Accuracy exceeded tolerance.")


if __name__ == "__main__":
    main()