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
| Physical board | Not used |

## Post-Route Timing Summary

| Metric | Value |
|---|---:|
| Timing status | PASS |
| WNS | +3.947 ns |
| TNS | 0.000 ns |
| Failing endpoints | 0 |
| Clock period | 10.000 ns |
| Clock frequency | 100.000 MHz |

Vivado reports positive setup slack and zero failing endpoints for the constrained clock domain.

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

The 16-stage CORDIC accelerator meets the 100 MHz post-route timing target on the Xilinx Artix-7 `xc7a35tcpg236-1` device.

The datapath uses shifts, additions, and subtractions rather than multipliers or lookup RAMs. The post-route utilization reflects that implementation choice:

- 0 DSP blocks
- 0 BRAM tiles
- 1058 LUTs
- 749 registers

The I/O utilization is driven by the simple parallel top-level interface and the selected package size.

## Constraint Note

The project does not include physical package pin constraints because no board target is used. The timing result demonstrates closure for the routed internal registered datapath at 100 MHz.

The Vivado timing checks also report missing input and output delay constraints on top-level I/O ports. For a board-specific implementation, the next step would be to add package pins and external I/O timing constraints based on the actual surrounding system.
