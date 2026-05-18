"""
generate_benchmark_report.py

Generates latency and throughput benchmark reports for the pipelined CORDIC accelerator.

Inputs:
    sim/metrics_continuous.csv
    sim/metrics_backpressure.csv

Outputs:
    reports/benchmark_summary.md
    reports/benchmark_summary.txt
"""

import csv
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]

METRICS_CONTINUOUS = ROOT_DIR / "sim" / "metrics_continuous.csv"
METRICS_BACKPRESSURE = ROOT_DIR / "sim" / "metrics_backpressure.csv"

REPORT_MD = ROOT_DIR / "reports" / "benchmark_summary.md"
REPORT_TXT = ROOT_DIR / "reports" / "benchmark_summary.txt"


def read_single_metrics_csv(path: Path) -> dict:
    if not path.exists():
        raise FileNotFoundError(f"Missing metrics file: {path}")

    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if len(rows) != 1:
        raise RuntimeError(f"Expected exactly one metrics row in {path}, found {len(rows)}")

    row = rows[0]

    int_fields = [
        "random_stalls",
        "seed",
        "num_vectors",
        "clk_period_ns",
        "first_input_cycle",
        "first_output_cycle",
        "last_input_cycle",
        "last_output_cycle",
        "first_latency_cycles",
        "active_cycles",
        "output_span_cycles",
    ]

    float_fields = [
        "throughput_active_outputs_per_cycle",
        "throughput_output_span_outputs_per_cycle",
    ]

    result = {}

    for field in int_fields:
        result[field] = int(row[field])

    for field in float_fields:
        result[field] = float(row[field])

    return result


def outputs_per_second(outputs_per_cycle: float, clk_period_ns: int) -> float:
    clk_freq_hz = 1.0 / (clk_period_ns * 1e-9)
    return outputs_per_cycle * clk_freq_hz


def format_mops(value_per_second: float) -> str:
    return f"{value_per_second / 1e6:.3f} M outputs/s"


def write_markdown_report(continuous: dict, backpressure: dict):
    REPORT_MD.parent.mkdir(exist_ok=True)

    continuous_active_rate = outputs_per_second(
        continuous["throughput_active_outputs_per_cycle"],
        continuous["clk_period_ns"],
    )

    continuous_span_rate = outputs_per_second(
        continuous["throughput_output_span_outputs_per_cycle"],
        continuous["clk_period_ns"],
    )

    backpressure_active_rate = outputs_per_second(
        backpressure["throughput_active_outputs_per_cycle"],
        backpressure["clk_period_ns"],
    )

    backpressure_span_rate = outputs_per_second(
        backpressure["throughput_output_span_outputs_per_cycle"],
        backpressure["clk_period_ns"],
    )

    with open(REPORT_MD, "w", encoding="utf-8") as f:
        f.write("# CORDIC Latency and Throughput Benchmark\n\n")

        f.write("## Overview\n\n")
        f.write(
            "This report summarizes simulation-measured latency and throughput "
            "for the 16-stage pipelined CORDIC sine/cosine accelerator.\n\n"
        )

        f.write("## Benchmark Configuration\n\n")
        f.write("| Parameter | Value |\n")
        f.write("|---|---:|\n")
        f.write(f"| Number of input vectors | {continuous['num_vectors']} |\n")
        f.write(f"| Clock period | {continuous['clk_period_ns']} ns |\n")
        f.write("| Clock target | 100 MHz |\n")
        f.write("| Pipeline depth | 16 stages |\n")
        f.write("| Output per transaction | One sine/cosine pair |\n\n")

        f.write("## Results\n\n")
        f.write("| Benchmark | First latency cycles | Active cycles | Output span cycles | Throughput active window | Throughput output span |\n")
        f.write("|---|---:|---:|---:|---:|---:|\n")

        f.write(
            f"| Continuous streaming | "
            f"{continuous['first_latency_cycles']} | "
            f"{continuous['active_cycles']} | "
            f"{continuous['output_span_cycles']} | "
            f"{continuous['throughput_active_outputs_per_cycle']:.6f} outputs/cycle "
            f"({format_mops(continuous_active_rate)}) | "
            f"{continuous['throughput_output_span_outputs_per_cycle']:.6f} outputs/cycle "
            f"({format_mops(continuous_span_rate)}) |\n"
        )

        f.write(
            f"| Randomized backpressure | "
            f"{backpressure['first_latency_cycles']} | "
            f"{backpressure['active_cycles']} | "
            f"{backpressure['output_span_cycles']} | "
            f"{backpressure['throughput_active_outputs_per_cycle']:.6f} outputs/cycle "
            f"({format_mops(backpressure_active_rate)}) | "
            f"{backpressure['throughput_output_span_outputs_per_cycle']:.6f} outputs/cycle "
            f"({format_mops(backpressure_span_rate)}) |\n\n"
        )

        f.write("## Interpretation\n\n")
        f.write(
            "In continuous streaming mode, the CORDIC pipeline should approach one "
            "sine/cosine output pair per cycle after the initial pipeline fill. "
            "The active-window throughput includes the initial pipeline latency, "
            "while output-span throughput measures only the output production interval.\n\n"
        )

        f.write(
            "In randomized backpressure mode, throughput decreases because the "
            "valid-ready interface stalls the entire pipeline when the downstream "
            "consumer deasserts `out_ready`. The pass condition is that all outputs "
            "are preserved in order and the RTL output still matches the Python "
            "golden model.\n\n"
        )

        f.write("## Generated Files\n\n")
        f.write("- `sim/metrics_continuous.csv`\n")
        f.write("- `sim/metrics_backpressure.csv`\n")
        f.write("- `sim/rtl_output_continuous.csv`\n")
        f.write("- `sim/rtl_output_backpressure.csv`\n")


def write_text_report(continuous: dict, backpressure: dict):
    continuous_active_rate = outputs_per_second(
        continuous["throughput_active_outputs_per_cycle"],
        continuous["clk_period_ns"],
    )

    continuous_span_rate = outputs_per_second(
        continuous["throughput_output_span_outputs_per_cycle"],
        continuous["clk_period_ns"],
    )

    backpressure_active_rate = outputs_per_second(
        backpressure["throughput_active_outputs_per_cycle"],
        backpressure["clk_period_ns"],
    )

    backpressure_span_rate = outputs_per_second(
        backpressure["throughput_output_span_outputs_per_cycle"],
        backpressure["clk_period_ns"],
    )

    with open(REPORT_TXT, "w", encoding="utf-8") as f:
        f.write("CORDIC Latency and Throughput Benchmark\n")
        f.write("=======================================\n\n")

        f.write("Continuous Streaming\n")
        f.write("--------------------\n")
        f.write(f"First latency cycles: {continuous['first_latency_cycles']}\n")
        f.write(f"Active cycles: {continuous['active_cycles']}\n")
        f.write(f"Output span cycles: {continuous['output_span_cycles']}\n")
        f.write(
            f"Throughput active window: "
            f"{continuous['throughput_active_outputs_per_cycle']:.6f} outputs/cycle, "
            f"{format_mops(continuous_active_rate)}\n"
        )
        f.write(
            f"Throughput output span: "
            f"{continuous['throughput_output_span_outputs_per_cycle']:.6f} outputs/cycle, "
            f"{format_mops(continuous_span_rate)}\n\n"
        )

        f.write("Randomized Backpressure\n")
        f.write("-----------------------\n")
        f.write(f"First latency cycles: {backpressure['first_latency_cycles']}\n")
        f.write(f"Active cycles: {backpressure['active_cycles']}\n")
        f.write(f"Output span cycles: {backpressure['output_span_cycles']}\n")
        f.write(
            f"Throughput active window: "
            f"{backpressure['throughput_active_outputs_per_cycle']:.6f} outputs/cycle, "
            f"{format_mops(backpressure_active_rate)}\n"
        )
        f.write(
            f"Throughput output span: "
            f"{backpressure['throughput_output_span_outputs_per_cycle']:.6f} outputs/cycle, "
            f"{format_mops(backpressure_span_rate)}\n"
        )


def main():
    print("Generating CORDIC benchmark report...")

    continuous = read_single_metrics_csv(METRICS_CONTINUOUS)
    backpressure = read_single_metrics_csv(METRICS_BACKPRESSURE)

    write_markdown_report(continuous, backpressure)
    write_text_report(continuous, backpressure)

    print(f"Wrote: {REPORT_MD}")
    print(f"Wrote: {REPORT_TXT}")


if __name__ == "__main__":
    main()