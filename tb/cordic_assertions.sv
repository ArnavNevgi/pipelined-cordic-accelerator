`timescale 1ns/1ps

// ============================================================
// cordic_assertions.sv
//
// Lightweight SystemVerilog assertions for the pipelined CORDIC
// accelerator testbench.
//
// These assertions check valid-ready protocol behavior, reset
// behavior, output stability under backpressure and basic
// transaction accounting.
//
// This file is intended for simulation-time checking in QuestaSim.
// ============================================================

import cordic_pkg::*;

module cordic_assertions (
    input logic clk,
    input logic rst_n,

    input logic in_valid,
    input logic in_ready,
    input q2_14_t angle_in,

    input logic out_valid,
    input logic out_ready,
    input q2_14_t sin_out,
    input q2_14_t cos_out
);

  // ------------------------------------------------------------
  // Transaction counters
  // ------------------------------------------------------------

  int accepted_input_count;
  int accepted_output_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accepted_input_count  <= 0;
      accepted_output_count <= 0;
    end else begin
      if (in_valid && in_ready) begin
        accepted_input_count <= accepted_input_count + 1;
      end

      if (out_valid && out_ready) begin
        accepted_output_count <= accepted_output_count + 1;
      end
    end
  end

  // ------------------------------------------------------------
  // Assertion 1:
  // Reset should clear visible output valid.
  // ------------------------------------------------------------

  property p_reset_clears_out_valid;
    @(posedge clk)
      !rst_n |-> !out_valid;
  endproperty

  a_reset_clears_out_valid:
    assert property (p_reset_clears_out_valid)
    else $error("ASSERTION FAILED: out_valid is high during reset.");

  // ------------------------------------------------------------
  // Assertion 2:
  // Input angle must not be unknown when input handshake occurs.
  // ------------------------------------------------------------

  property p_no_unknown_input_on_handshake;
    @(posedge clk) disable iff (!rst_n)
      (in_valid && in_ready) |-> !$isunknown(angle_in);
  endproperty

  a_no_unknown_input_on_handshake:
    assert property (p_no_unknown_input_on_handshake)
    else $error("ASSERTION FAILED: angle_in has X/Z during input handshake.");

  // ------------------------------------------------------------
  // Assertion 3:
  // Output values must not be unknown when output is valid.
  // ------------------------------------------------------------

  property p_no_unknown_output_when_valid;
    @(posedge clk) disable iff (!rst_n)
      out_valid |-> (!$isunknown(sin_out) && !$isunknown(cos_out));
  endproperty

  a_no_unknown_output_when_valid:
    assert property (p_no_unknown_output_when_valid)
    else $error("ASSERTION FAILED: sin_out or cos_out has X/Z while out_valid is high.");

  // ------------------------------------------------------------
  // Assertion 4:
  // If input is valid but not accepted, input data must remain stable.
  //
  // This checks the source-side valid-ready contract.
  // ------------------------------------------------------------

  property p_input_stable_when_blocked;
    @(posedge clk) disable iff (!rst_n)
      (in_valid && !in_ready) |=> (in_valid && $stable(angle_in));
  endproperty

  a_input_stable_when_blocked:
    assert property (p_input_stable_when_blocked)
    else $error("ASSERTION FAILED: input changed while in_valid was high and in_ready was low.");

  // ------------------------------------------------------------
  // Assertion 5:
  // If output is valid but not accepted, output data must remain stable.
  //
  // This checks the sink-side backpressure contract.
  // ------------------------------------------------------------

  property p_output_stable_when_blocked;
    @(posedge clk) disable iff (!rst_n)
      (out_valid && !out_ready) |=> (out_valid && $stable(sin_out) && $stable(cos_out));
  endproperty

  a_output_stable_when_blocked:
    assert property (p_output_stable_when_blocked)
    else $error("ASSERTION FAILED: output changed while out_valid was high and out_ready was low.");

  // ------------------------------------------------------------
  // Assertion 6:
  // The design must never produce more accepted outputs than
  // accepted inputs.
  // ------------------------------------------------------------

  property p_output_count_never_exceeds_input_count;
    @(posedge clk) disable iff (!rst_n)
      accepted_output_count <= accepted_input_count;
  endproperty

  a_output_count_never_exceeds_input_count:
    assert property (p_output_count_never_exceeds_input_count)
    else $error("ASSERTION FAILED: output count exceeded input count.");

  // ------------------------------------------------------------
  // Assertion 7:
  // out_valid must not be asserted before enough input
  // transactions have entered the pipeline.
  //
  // This is a conservative check based on transaction count.
  // ------------------------------------------------------------

  property p_no_output_without_prior_input;
    @(posedge clk) disable iff (!rst_n)
      out_valid |-> (accepted_input_count > accepted_output_count);
  endproperty

  a_no_output_without_prior_input:
    assert property (p_no_output_without_prior_input)
    else $error("ASSERTION FAILED: out_valid asserted without a prior unconsumed input.");

endmodule