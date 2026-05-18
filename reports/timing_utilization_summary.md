# CORDIC Timing and Utilization Summary

## Target Device

| Item | Value |
|---|---:|
| FPGA family | Xilinx Artix-7 |
| Part | xc7a35tcpg236-1 |
| Design top | cordic_top |
| Design state | Routed |
| Clock target | 100 MHz |
| Clock period | 10.000 ns |

## Post-Route Timing Summary

| Metric | Value |
|---|---:|
| Timing status | PASS |
| Worst Negative Slack | +3.947 ns |
| Total Negative Slack | 0.000 ns |
| Failing endpoints | 0 |
| Clock period | 10.000 ns |
| Clock frequency | 100.000 MHz |

Vivado reports that all user-specified timing constraints are met.

## Post-Route Utilization Summary

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 1058 | 20800 | 5.09% |
| Slice Registers | 749 | 41600 | 1.80% |
| Block RAM Tiles | 0 | 50 | 0.00% |
| DSPs | 0 | 90 | 0.00% |
| Bonded IOBs | 54 | 106 | 50.94% |
| BUFGCTRL | 1 | 32 | 3.13% |

## Interpretation

The 16-stage CORDIC accelerator meets the 100 MHz post-route timing target on the Xilinx Artix-7 xc7a35tcpg236-1 device.

The design uses a multiplier-free shift-add datapath, which is reflected in the post-route utilization results:

- 0 DSP blocks
- 0 BRAM tiles
- 1058 LUTs
- 749 flip-flops

The relatively higher I/O utilization is caused by the simple top-level parallel interface, not by the internal datapath itself.

## Constraint Note

The current timing report shows that the main clock is constrained and internal timing is met. The report also flags missing input and output delay constraints for top-level I/O ports. Since this project is completed without a physical board, no package pin or board-level timing constraints are applied.

For a board-specific implementation, the next step would be to add board-level pin constraints and real external I/O timing constraints.