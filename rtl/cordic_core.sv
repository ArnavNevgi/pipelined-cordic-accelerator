`timescale 1ns/1ps

// ============================================================
// cordic_core.sv
//
// 16-stage pipelined CORDIC sine/cosine accelerator.
//
// Phase 6 version:
//   - Rotation-mode CORDIC
//   - Q2.14 fixed-point arithmetic
//   - 16 pipeline stages
//   - Valid-ready streaming interface
//   - Global stall support for output backpressure
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
  // Pipeline control
  // ------------------------------------------------------------
  //
  // The pipeline advances when:
  //
  //   1. The output stage is empty, or
  //   2. The output stage contains valid data and the downstream
  //      interface is ready to accept it.
  //
  // If out_valid is high and out_ready is low, the full pipeline
  // stalls and all registers hold their values.
  // ------------------------------------------------------------

  logic pipe_advance;

  assign pipe_advance = out_ready || !valid_pipe[STAGES];

  assign in_ready = pipe_advance;

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

      if (pipe_advance) begin

        // ------------------------------------------------------
        // Load pipeline input stage
        // ------------------------------------------------------

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

        // ------------------------------------------------------
        // CORDIC iteration stages
        // ------------------------------------------------------

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

      // If pipe_advance is low, all pipeline registers hold.
      // This preserves output data and all in-flight transactions
      // during downstream backpressure.

    end
  end

endmodule