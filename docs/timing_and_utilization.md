# Timing and Utilization

## Target FPGA

| Item | Value |
|---|---:|
| FPGA family | Xilinx Artix-7 |
| Part | xc7a35tcpg236-1 |
| Speed grade | -1 |
| Top module | cordic_top |
| Clock target | 100 MHz |
| Clock period | 10 ns |
| Physical board | Not used |

## Vivado Flow

The design was synthesized and implemented using Vivado batch scripts.

### Synthesis

vivado -mode batch -source scripts/vivado_synth.tcl

Implementation

vivado -mode batch -source scripts/vivado_impl.tcl

Post-Route Timing Results

| Metric               |       Value |
| -------------------- | ----------: |
| Timing status        |        PASS |
| Worst Negative Slack |   +3.947 ns |
| Total Negative Slack |    0.000 ns |
| Failing endpoints    |           0 |
| Clock period         |   10.000 ns |
| Clock frequency      | 100.000 MHz |

The design meets the 100 MHz post-route timing target.

Post-Route Utilization Results

| Resource        | Used | Available | Utilization |
| --------------- | ---: | --------: | ----------: |
| Slice LUTs      | 1058 |     20800 |       5.09% |
| Slice Registers |  749 |     41600 |       1.80% |
| Block RAM Tiles |    0 |        50 |       0.00% |
| DSPs            |    0 |        90 |       0.00% |
| Bonded IOBs     |   54 |       106 |      50.94% |
| BUFGCTRL        |    1 |        32 |       3.13% |
