#!/usr/bin/env python3
"""Extract GitHub-friendly summaries from a Quartus compile."""

from __future__ import annotations

import re
import shutil
from datetime import datetime
from pathlib import Path


PROJECT_NAME = "cordic_quartus"
TOP_NAME = "cordic_top"
TARGET_DEVICE = "5CSEMA5F31C6"


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except FileNotFoundError:
        return ""


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def first_existing(paths: list[Path]) -> Path | None:
    for path in paths:
        if path.exists():
            return path
    return None


def find_line(text: str, patterns: list[str]) -> str | None:
    for line in text.splitlines():
        clean = line.strip()
        for pattern in patterns:
            if re.search(pattern, clean, re.IGNORECASE):
                return clean
    return None


def find_lines(text: str, patterns: list[str], limit: int = 20) -> list[str]:
    matches: list[str] = []
    for line in text.splitlines():
        clean = line.strip()
        if any(re.search(pattern, clean, re.IGNORECASE) for pattern in patterns):
            matches.append(clean)
            if len(matches) >= limit:
                break
    return matches


def semicolon_value(line: str | None) -> str | None:
    if not line:
        return None
    parts = [part.strip() for part in line.strip(";").split(";")]
    return parts[1] if len(parts) >= 2 and parts[1] else line.strip()


def parse_slack(text: str) -> float | None:
    slack_patterns = [
        r"\b(?:worst-case\s+slack|wns|slack)\b[^-\d+]*([-+]?\d+(?:\.\d+)?)",
        r";\s*Slack\s*;\s*([-+]?\d+(?:\.\d+)?)",
    ]
    for pattern in slack_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                return float(match.group(1))
            except ValueError:
                return None
    return None


def parse_timing_status(text: str, slack: float | None) -> str:
    if slack is not None:
        return "PASS" if slack >= 0.0 else "FAIL"
    lowered = text.lower()
    if "timing requirements were met" in lowered or "no failing paths" in lowered:
        return "PASS"
    if "timing requirements were not met" in lowered or "failing paths" in lowered:
        return "FAIL - inspect raw TimeQuest report"
    return "UNKNOWN - inspect raw TimeQuest report"


def extract_version(texts: list[str]) -> str:
    patterns = [
        r"(Quartus(?:\(R\))?\s+Prime[^\n\r]+Version[^\n\r]+)",
        r"(Version\s+\d+[^\n\r]+Build[^\n\r]+)",
    ]
    for text in texts:
        for pattern in patterns:
            match = re.search(pattern, text, re.IGNORECASE)
            if match:
                return match.group(1).strip()
    return "Not found"


def status_block(version: str) -> str:
    generated = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return (
        f"Generated: {generated}\n"
        f"Project: {PROJECT_NAME}\n"
        f"Top-level entity: {TOP_NAME}\n"
        f"Target device: {TARGET_DEVICE}\n"
        f"Quartus version: {version}\n"
    )


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    build_dir = script_dir / "build"
    output_dir = build_dir / "output_files"
    report_dir = repo_root / "reports" / "quartus"

    flow_report = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.flow.rpt",
            build_dir / f"{PROJECT_NAME}.flow.rpt",
        ]
    )
    sta_summary = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.sta.summary",
            build_dir / f"{PROJECT_NAME}.sta.summary",
        ]
    )
    sta_report = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.sta.rpt",
            build_dir / f"{PROJECT_NAME}.sta.rpt",
        ]
    )
    fit_summary = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.fit.summary",
            build_dir / f"{PROJECT_NAME}.fit.summary",
        ]
    )
    fit_report = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.fit.rpt",
            build_dir / f"{PROJECT_NAME}.fit.rpt",
        ]
    )
    map_summary = first_existing(
        [
            output_dir / f"{PROJECT_NAME}.map.summary",
            build_dir / f"{PROJECT_NAME}.map.summary",
        ]
    )
    quartus_logs = [
        build_dir / "quartus_sh_compile.log",
        build_dir / "quartus_sh.log",
        script_dir / "quartus_sh_compile.log",
        script_dir / "quartus_sh.log",
    ]

    raw_texts = [read_text(path) for path in [flow_report, sta_summary, sta_report, fit_summary, fit_report, map_summary] if path]
    raw_texts.extend(read_text(path) for path in quartus_logs if path.exists())
    version = extract_version(raw_texts)
    quartus_available = shutil.which("quartus_sh") is not None
    not_run_reason = (
        "quartus_sh was not found in PATH in this environment."
        if not quartus_available
        else "No Quartus output reports were found under quartus/build."
    )

    if not any([flow_report, sta_summary, sta_report, fit_summary, fit_report, map_summary]):
        common = status_block(version)
        write_text(
            report_dir / "README_or_STATUS.txt",
            common
            + "\n"
            + "Status: PREPARED, NOT EXECUTED\n"
            + f"Reason: {not_run_reason}\n"
            + "No timing, Fmax, or utilization result is claimed.\n",
        )
        write_text(
            report_dir / "timing_summary.txt",
            common
            + "\n"
            + "Timing status at 100 MHz: NOT GENERATED\n"
            + "Worst-case slack / WNS equivalent: NOT AVAILABLE\n"
            + "Fmax: NOT AVAILABLE\n"
            + "Quartus must be run before making a Cyclone V timing claim.\n",
        )
        write_text(
            report_dir / "utilization_summary.txt",
            common
            + "\n"
            + "ALM / logic element usage: NOT AVAILABLE\n"
            + "Register count: NOT AVAILABLE\n"
            + "DSP block usage: NOT AVAILABLE\n"
            + "Memory block usage: NOT AVAILABLE\n"
            + "Quartus must be run before making a Cyclone V utilization claim.\n",
        )
        write_text(
            report_dir / "fit_summary.txt",
            common
            + "\n"
            + "Fitter status: NOT GENERATED\n"
            + "Raw fitter report: NOT AVAILABLE\n",
        )
        write_text(
            report_dir / "quartus_compile.log",
            common
            + "\n"
            + "Quartus compile log: NOT GENERATED\n"
            + f"Reason: {not_run_reason}\n"
            + "Run quartus_sh -t run_quartus.tcl from the quartus directory on a machine with Intel Quartus Prime installed.\n",
        )
        print(f"No Quartus output reports found. Wrote status files to {report_dir}.")
        return 0

    sta_text = "\n".join(read_text(path) for path in [sta_summary, sta_report] if path)
    fit_text = "\n".join(read_text(path) for path in [fit_summary, fit_report, map_summary] if path)
    flow_text = read_text(flow_report) if flow_report else ""

    slack = parse_slack(sta_text)
    timing_status = parse_timing_status(sta_text + "\n" + flow_text, slack)
    fmax_lines = find_lines(sta_text, [r"\bfmax\b", r"restricted fmax"], limit=12)

    alm_line = find_line(fit_text, [r"logic utilization.*alm", r"total alm", r"combinational alu"])
    le_line = find_line(fit_text, [r"logic elements", r"les\s*;"])
    reg_line = find_line(fit_text, [r"total registers", r"dedicated logic registers", r"register count"])
    dsp_line = find_line(fit_text, [r"dsp", r"embedded multiplier"])
    mem_line = find_line(fit_text, [r"m10k", r"block memory", r"memory bits"])
    fitter_status_line = find_line(fit_text + "\n" + flow_text, [r"fitter status", r"fit successful", r"successful"])

    common = status_block(version)
    write_text(
        report_dir / "README_or_STATUS.txt",
        common
        + "\n"
        + "Status: EXECUTED - extracted from Quartus output reports\n"
        + "Inspect timing_summary.txt, utilization_summary.txt, and fit_summary.txt for curated results.\n",
    )

    timing_summary = [
        common,
        "",
        f"Timing status at 100 MHz: {timing_status}",
        f"Worst-case slack / WNS equivalent: {'{:.3f} ns'.format(slack) if slack is not None else 'Not found'}",
        "Fmax:",
    ]
    timing_summary.extend(f"  {line}" for line in fmax_lines) if fmax_lines else timing_summary.append("  Not found in extracted TimeQuest summary")
    timing_summary.append("")
    timing_summary.append(f"Raw TimeQuest summary: {sta_summary if sta_summary else 'Not found'}")
    timing_summary.append(f"Raw TimeQuest report: {sta_report if sta_report else 'Not found'}")
    write_text(report_dir / "timing_summary.txt", "\n".join(timing_summary) + "\n")

    utilization_summary = [
        common,
        "",
        f"ALM / logic usage: {semicolon_value(alm_line) or 'Not found'}",
        f"Logic element usage: {semicolon_value(le_line) or 'Not found'}",
        f"Register count: {semicolon_value(reg_line) or 'Not found'}",
        f"DSP block usage: {semicolon_value(dsp_line) or 'Not found'}",
        f"Memory block usage: {semicolon_value(mem_line) or 'Not found'}",
        "",
        f"Raw fitter summary: {fit_summary if fit_summary else 'Not found'}",
        f"Raw fitter report: {fit_report if fit_report else 'Not found'}",
        f"Raw map summary: {map_summary if map_summary else 'Not found'}",
    ]
    write_text(report_dir / "utilization_summary.txt", "\n".join(utilization_summary) + "\n")

    fit_summary_out = [
        common,
        "",
        f"Fitter status: {semicolon_value(fitter_status_line) or fitter_status_line or 'Not found'}",
        f"Raw flow report: {flow_report if flow_report else 'Not found'}",
        f"Raw fitter summary: {fit_summary if fit_summary else 'Not found'}",
        "",
        "Selected fitter/utilization lines:",
    ]
    selected_fit_lines = [line for line in [fitter_status_line, alm_line, le_line, reg_line, dsp_line, mem_line] if line]
    for line in selected_fit_lines:
        fit_summary_out.append(f"  {line}")
    if not selected_fit_lines:
        fit_summary_out.append("  Not found")
    write_text(report_dir / "fit_summary.txt", "\n".join(fit_summary_out) + "\n")

    copied_log = None
    for log_path in quartus_logs:
        if log_path.exists():
            copied_log = log_path
            break
    if copied_log:
        log_text = read_text(copied_log)
        write_text(
            report_dir / "quartus_compile.log",
            common
            + "\n"
            + f"Copied/extracted from: {copied_log}\n\n"
            + log_text,
        )
    else:
        write_text(
            report_dir / "quartus_compile.log",
            common
            + "\n"
            + "Quartus compile log file was not found, but Quartus reports were extracted.\n",
        )

    print(f"Quartus summaries written to {report_dir}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
