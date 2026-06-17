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

The `.xsa` is exported with the bitstream included when the full build completes.

## Register Map

The Zynq PS accesses the CORDIC peripheral at base address `0x43C00000` unless overridden with `-tclargs -base_addr <addr>`.

| Offset | Register | Description |
|---:|---|---|
| `0x00` | `CONTROL` | bit 0: start, bit 1: done_ack |
| `0x04` | `STATUS` | bit 0: busy, bit 1: done, bit 2: input ready, bit 3: output valid, bit 4: start pending |
| `0x08` | `ANGLE_IN` | bits `[15:0]`: signed Q2.14 input angle |
| `0x0C` | `SIN_OUT` | bits `[15:0]`: signed Q2.14 sine output |
| `0x10` | `COS_OUT` | bits `[15:0]`: signed Q2.14 cosine output |

## Next Step

Create a Vitis C application using the exported `cordic_zedboard.xsa`. The app should use PS UART for console I/O, write a Q2.14 angle to `ANGLE_IN`, write `CONTROL.start`, poll `STATUS.done`, then read and print `SIN_OUT` and `COS_OUT`.

For example, angle `0x0000` should produce approximately:

```text
sin = 0x0000
cos = 0x4000
```

Hardware Validation Result

Board: ZedBoard Zynq-7020 xc7z020clg484-1
Interface: Zynq PS to CORDIC PL accelerator through AXI4-Lite
Software: Vitis standalone bare-metal C application
UART: ZedBoard onboard PS UART, 115200 baud

Result:
5/5 hardware tests passed.

Tested angles:
0 rad
+pi/4
-pi/4
+pi/2
-pi/2

CORDIC AXI base address:
0x43C00000
