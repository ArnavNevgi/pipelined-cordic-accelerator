# Quartus Implementation Flow

This folder contains the Intel Quartus Prime implementation flow for the 16-stage SystemVerilog CORDIC accelerator. It targets Intel Cyclone V device `5CSEMA5F31C6` and has been executed successfully as a cross-vendor FPGA implementation check without changing RTL behavior.

The flow does not include physical board pin assignments. Non-clock top-level ports are marked as virtual pins, and the SDC constrains only the 100 MHz design clock plus the asynchronous reset exception. Do not use this flow as a board-level timing claim until real pin and external I/O timing constraints are added.

If the installed Quartus version does not support `5CSEMA5F31C6`, `create_project.tcl` attempts to print the available Cyclone V device list. Select a supported Cyclone V part from that list and update `DEVICE_NAME` in `create_project.tcl`.

## Measured Results

| Metric | Result |
|---|---:|
| Tool version | Intel Quartus Prime Lite 25.1std.0 Build 1129 10/21/2025 SC Lite Edition |
| Target device | 5CSEMA5F31C6 |
| Top-level entity | cordic_top |
| Timing status | PASS at 100 MHz |
| Worst-case slack / WNS equivalent | +6.230 ns |
| Fitter status | Successful |
| ALM usage | 405 / 32,070 = 1% |
| Register count | 772 |
| DSP usage | 0 / 87 = 0% |
| Memory usage | 0 / 4,065,280 block memory bits = 0% |

These results are from a no-board FPGA implementation compile. They do not include board execution or physical pin constraints.

## Files

| File | Purpose |
|---|---|
| `create_project.tcl` | Creates `cordic_quartus` under `quartus/build/` |
| `run_quartus.tcl` | Creates the project, runs full compile, and extracts reports |
| `cordic_quartus.sdc` | TimeQuest 100 MHz clock constraint |
| `extract_quartus_reports.py` | Copies/extracts text summaries into `reports/quartus/` |

## Windows PowerShell

Run the wrapper from the repository root:

```powershell
cd quartus
quartus_sh -t run_quartus.tcl
```

Equivalent manual flow:

```powershell
cd quartus
quartus_sh -t create_project.tcl
cd build
quartus_sh --flow compile cordic_quartus
cd ..
python .\extract_quartus_reports.py
```

## Linux Shell

Run the wrapper from the repository root:

```sh
cd quartus
quartus_sh -t run_quartus.tcl
```

Equivalent manual flow:

```sh
cd quartus
quartus_sh -t create_project.tcl
cd build
quartus_sh --flow compile cordic_quartus
cd ..
python3 ./extract_quartus_reports.py
```

## Reports

Curated report files are written to:

```text
reports/quartus/timing_summary.txt
reports/quartus/utilization_summary.txt
reports/quartus/fit_summary.txt
reports/quartus/quartus_compile.log
reports/quartus/README_or_STATUS.txt
```

The raw Quartus project and generated reports remain under `quartus/build/` and are ignored by Git.

## Timing Interpretation

The 100 MHz target corresponds to a 10.000 ns clock period on port `clk`. Treat the Quartus implementation as passing only if `reports/quartus/timing_summary.txt` reports a non-negative worst-case slack/WNS equivalent. If slack is negative or unavailable, do not claim Cyclone V timing closure.

Fmax is reported when TimeQuest emits an Fmax summary. If it is not present in the curated text file, inspect the raw `.sta.rpt` and `.sta.summary` files under `quartus/build/output_files/`.

## Cleaning Generated Files

PowerShell:

```powershell
cd quartus
Remove-Item -Recurse -Force .\build
```

Linux shell:

```sh
cd quartus
rm -rf ./build
```

The curated `reports/quartus/` files are not removed by these commands.
