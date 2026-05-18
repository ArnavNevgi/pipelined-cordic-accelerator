# Timing and Utilization

## Target FPGA

- Family: Xilinx Artix-7
- Part: xc7a35tcpg236-1
- Clock target: 100 MHz
- Clock period: 10 ns
- Physical board: not used

## Vivado Flow

The project uses Vivado batch scripts in non-project mode.

### Synthesis

```text
vivado -mode batch -source scripts/vivado_synth.tcl

Implementation
vivado -mode batch -source scripts/vivado_impl.tcl
Generated Reports

Synthesis reports:

reports/synth_timing_summary.rpt
reports/synth_utilization.rpt
reports/synth_power.rpt
reports/synth_clock_utilization.rpt
reports/synth_check_timing.rpt

Post-route implementation reports:

reports/post_route_timing_summary.rpt
reports/post_route_utilization.rpt
reports/post_route_power.rpt
reports/route_status.rpt
reports/post_route_clock_utilization.rpt
reports/post_route_check_timing.rpt
Status

Vivado synthesis and implementation reports are generated in Phase 8.

The numerical timing and utilization summary is extracted in Phase 9.