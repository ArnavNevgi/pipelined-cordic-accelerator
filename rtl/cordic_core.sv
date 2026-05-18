`timescale 1ns/1ps

// ============================================================
// cordic_core.sv
//
// 16-stage pipelined CORDIC sine/cosine accelerator.
//
// Phase 3 version:
//   - Rotation-mode CORDIC
//   - Q2.14 fixed-point arithmetic
//   - 16 pipeline stages
//   - Valid-ready style interface
//   - Always-ready input
//   - No output backpressure handling yet
//
// Supported angle range:
//   -pi/2 to +pi/2 radians
//
// Input:
//   angle_in = Q2.14 signed radians
//
// Outputs:
//   cos_out = Q2.14 signed cosine
//   sin_out = Q2.14 signed sine
// ============================================================

import cordic_pkg::*;

module cordic_core (
    input  logic  clk,
    input  logic  rst_n,

    input  logic  in_valid,
    output logic  in_ready,
    input  q2_14_t angle_in,

    output logic  out_valid,
    input  logic  out_ready,
    output q2_14_t cos_out,
    output q2_14_t sin_out
);

  // ------------------------------------------------------------
  // Internal pipeline registers
  // ------------------------------------------------------------

  q2_14_t x_pipe [0:STAGES];
  q2_14_t y_pipe [0:STAGES];
  q2_14_t z_pipe [0:STAGES];

  logic valid_pipe [0:STAGES];

  // ------------------------------------------------------------
  // Phase 3 simplification:
  //
  // The core always accepts input every cycle.
  // out_ready is intentionally unused in this first version.
  // Full stall-aware valid-ready support will be added later.
  // ------------------------------------------------------------

  assign in_ready = 1'b1;

  // ------------------------------------------------------------
  // Output assignments
  // ------------------------------------------------------------

  assign cos_out   = x_pipe[STAGES];
  assign sin_out   = y_pipe[STAGES];
  assign out_valid = valid_pipe[STAGES];

  // ------------------------------------------------------------
  // Pipeline logic
  // ------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin

      for (int i = 0; i <= STAGES; i++) begin
        x_pipe[i]     <= '0;
        y_pipe[i]     <= '0;
        z_pipe[i]     <= '0;
        valid_pipe[i] <= 1'b0;
      end

    end else begin

      // --------------------------------------------------------
      // Load pipeline input stage
      //
      // x starts at CORDIC gain compensation constant.
      // y starts at zero.
      // z starts at input angle.
      // --------------------------------------------------------

      if (in_valid && in_ready) begin
        x_pipe[0]     <= CORDIC_K;
        y_pipe[0]     <= '0;
        z_pipe[0]     <= angle_in;
        valid_pipe[0] <= 1'b1;
      end else begin
        x_pipe[0]     <= '0;
        y_pipe[0]     <= '0;
        z_pipe[0]     <= '0;
        valid_pipe[0] <= 1'b0;
      end

      // --------------------------------------------------------
      // CORDIC iteration stages
      //
      // For each stage i:
      //
      // if z_i >= 0:
      //   x_{i+1} = x_i - (y_i >>> i)
      //   y_{i+1} = y_i + (x_i >>> i)
      //   z_{i+1} = z_i - atan(2^-i)
      //
      // else:
      //   x_{i+1} = x_i + (y_i >>> i)
      //   y_{i+1} = y_i - (x_i >>> i)
      //   z_{i+1} = z_i + atan(2^-i)
      // --------------------------------------------------------

      for (int i = 0; i < STAGES; i++) begin

        valid_pipe[i+1] <= valid_pipe[i];

        if (valid_pipe[i]) begin
          if (z_pipe[i] >= 0) begin
            x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
            y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
            z_pipe[i+1] <= z_pipe[i] - ATAN_TABLE[i];
          end else begin
            x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
            y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
            z_pipe[i+1] <= z_pipe[i] + ATAN_TABLE[i];
          end
        end else begin
          x_pipe[i+1] <= '0;
          y_pipe[i+1] <= '0;
          z_pipe[i+1] <= '0;
        end

      end
    end
  end

  // ------------------------------------------------------------
  // Unused signal note
  // ------------------------------------------------------------
  //
  // out_ready is part of the final interface but is not used in
  // Phase 3. Later phases will add full stall-aware pipeline
  // control.
  // ------------------------------------------------------------

endmodule
