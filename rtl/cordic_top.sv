`timescale 1ns/1ps

// ============================================================
// cordic_top.sv
//
// Top-level wrapper for Vivado synthesis.
// ============================================================

import cordic_pkg::*;

module cordic_top (
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

  cordic_core u_cordic_core (
      .clk       (clk),
      .rst_n     (rst_n),

      .in_valid  (in_valid),
      .in_ready  (in_ready),
      .angle_in  (angle_in),

      .out_valid (out_valid),
      .out_ready (out_ready),
      .cos_out   (cos_out),
      .sin_out   (sin_out)
  );

endmodule
