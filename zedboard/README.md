# ZedBoard Vivado Integration

This directory contains the first physical ZedBoard validation path for the existing pipelined CORDIC accelerator. The flow packages the verified AXI4-Lite wrapper as custom Vivado IP, connects it to the Zynq-7020 Processing System, and prepares hardware export for a Vitis UART test application.

## Target

| Item | Value |
|---|---:|
| Board | ZedBoard |
| Device | `xc7z020clg484-1` |
| PL clock | 100 MHz from PS `FCLK_CLK0` |
| CORDIC AXI base address | `0x43C00000` |
| CORDIC AXI range | `0x00010000` |

## Run The Vivado Flow

From the repository root:

```text
vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl
```

For a faster project and block-design generation pass without implementation:

```text
vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl -tclargs -no_bitstream
```

If Vivado cannot find the ZedBoard board files, install the ZedBoard board definition files or pass the board part explicitly:

```text
vivado -mode batch -source zedboard/vivado/create_zedboard_project.tcl -tclargs -board_part <board_part_vlnv>
```

Common ZedBoard board-part names vary by Vivado/board-file source. Examples you may see are similar to:

```text
em.avnet.com:zed:part0:<version>
digilentinc.com:zedboard:part0:<version>
```

The board preset is required for the physical validation flow because it configures the Zynq PS DDR, fixed I/O, and PS UART MIO for the board.

## Generated Outputs

The scripts create generated files under:

```text
zedboard/vivado/build/
zedboard/vivado/ip_repo/
zedboard/hw/
```

The full flow exports the hardware platform here:

```text
zedboard/hw/cordic_zedboard.xsa
```

The `.xsa` is exported with the bitstream included when the full build completes. Generated Vivado build outputs and hardware export files are not intended to be committed.

## Register Map

The Zynq PS accesses the CORDIC peripheral at base address `0x43C00000` unless overridden with `-tclargs -base_addr <addr>`.

| Offset | Register | Description |
|---:|---|---|
| `0x00` | `CONTROL` | bit 0: start, bit 1: done_ack |
| `0x04` | `STATUS` | bit 0: busy, bit 1: done, bit 2: input ready, bit 3: output valid, bit 4: start pending |
| `0x08` | `ANGLE_IN` | bits `[15:0]`: signed Q2.14 input angle |
| `0x0C` | `SIN_OUT` | bits `[15:0]`: signed Q2.14 sine output |
| `0x10` | `COS_OUT` | bits `[15:0]`: signed Q2.14 cosine output |

## Hardware Validation

The CORDIC accelerator has been physically validated on ZedBoard through the Zynq PS-to-PL AXI4-Lite path. A standalone Vitis application writes Q2.14 angles, starts the accelerator, polls `STATUS.done`, reads `SIN_OUT` and `COS_OUT`, and prints the results over the ZedBoard PS UART at 115200 baud.

| Angle | Input Q2.14 | SIN_OUT | COS_OUT | Max Error | Result |
|---|---:|---:|---:|---:|---|
| `0` | `0x0000` | `0x0004` | `0x3FFF` | 4 LSB | PASS |
| `+pi/4` | `0x3244` | `0x2D41` | `0x2D42` | 1 LSB | PASS |
| `-pi/4` | `0xCDBC` | `0xD2BE` | `0x2D42` | 1 LSB | PASS |
| `+pi/2` | `0x6488` | `0x3FFF` | `0x0002` | 2 LSB | PASS |
| `-pi/2` | `0x9B78` | `0xC000` | `0xFFFE` | 2 LSB | PASS |

5/5 ZedBoard hardware tests passed within +/-16 LSB tolerance.

The accelerator was also validated without UART using XSCT direct JTAG memory access to the AXI4-Lite registers:

| Angle | STATUS | SIN_OUT | COS_OUT |
|---|---:|---:|---:|
| `0x0000` | `0x00000006` | `0x00000004` | `0x00003FFF` |
| `0x3244` | `0x00000006` | `0x00002D41` | `0x00002D42` |

This confirms the hardware AXI register path independently of the UART print code.

## Run The Vitis Demo

Use the exported `zedboard/hw/cordic_zedboard.xsa` to create a standalone platform for `ps7_cortexa9_0`. Build the app source at:

```text
zedboard/vitis/cordic_uart_demo/main.c
```

Program the FPGA, run the ELF, and open the ZedBoard PS UART at 115200 baud. The expected final line is:

```text
CORDIC ZedBoard hardware validation PASSED
```

## Evidence Files

- `zedboard/evidence/zedboard_cordic_uart_pass.txt`
- `zedboard/evidence/zedboard_cordic_jtag_axi_pass.txt`
- `zedboard/evidence/zedboard_cordic_uart_pass.png`
- `zedboard/vitis/cordic_uart_demo/main.c`
- `zedboard/vivado/package_cordic_ip.tcl`
- `zedboard/vivado/create_block_design.tcl`
- `zedboard/vivado/create_zedboard_project.tcl`
