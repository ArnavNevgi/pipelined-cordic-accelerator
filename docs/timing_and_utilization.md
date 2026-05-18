# Timing and Utilization

## Target Device

The design was synthesized, implemented, routed, and reported in Vivado for a Xilinx Artix-7 target.

| Item | Value |
|---|---:|
| FPGA family | Xilinx Artix-7 |
| Part | xc7a35tcpg236-1 |
| Speed grade | -1 |
| Top module | cordic_top |
| Clock target | 100 MHz |
| Clock period | 10.000 ns |
| Physical board | Not used |

## Vivado Flow

Synthesis:

```text
vivado -mode batch -source scripts/vivado_synth.tcl
```

Implementation:

```text
vivado -mode batch -source scripts/vivado_impl.tcl
```

Report regeneration:

```text
vivado -mode batch -source scripts/vivado_reports.tcl
```

The raw post-route reports are stored in `reports/`.

## Post-Route Timing

| Metric | Value |
|---|---:|
| Timing status | PASS |
| Clock target | 100 MHz |
| Clock period | 10.000 ns |
| WNS | +3.947 ns |
| TNS | 0.000 ns |
| Failing endpoints | 0 |

The routed design meets the 100 MHz target with positive setup slack and no failing endpoints.

## Post-Route Utilization

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| Slice LUTs | 1058 | 20800 | 5.09% |
| Slice Registers | 749 | 41600 | 1.80% |
| Block RAM Tiles | 0 | 50 | 0.00% |
| DSPs | 0 | 90 | 0.00% |
| Bonded IOBs | 54 | 106 | 50.94% |
| BUFGCTRL | 1 | 32 | 3.13% |

The zero DSP and zero BRAM usage reflect the multiplier-free shift-add CORDIC datapath. The higher I/O percentage comes from the simple parallel top-level interface on a small Artix-7 package, not from the internal datapath.

## Constraint Note

The project does not target a physical board and does not include package pin constraints. The timing result demonstrates post-route timing closure for the routed internal registered datapath at 100 MHz.

The post-route timing checks also flag missing top-level input and output delay constraints. This is a board-level constraint limitation: real hardware integration would need package pins and external timing constraints for the surrounding system. It is not a failure of the internal registered CORDIC pipeline timing result.
