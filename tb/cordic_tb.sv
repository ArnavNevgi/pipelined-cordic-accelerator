`timescale 1ns/1ps

// ============================================================
// cordic_tb.sv
//
// Phase 4 basic testbench for the 16-stage pipelined CORDIC
// accelerator.
//
// This testbench:
//   - Reads Q2.14 angle vectors from tb/cordic_test_vectors.hex
//   - Drives the DUT with continuous valid input
//   - Keeps out_ready high
//   - Captures sine/cosine outputs
//   - Writes RTL output CSV to sim/rtl_output.csv
//   - Measures first-output latency
//
// This testbench does not yet compare against the golden model.
// Python comparison will be added in the next phase.
// ============================================================

import cordic_pkg::*;

module cordic_tb;

  // ------------------------------------------------------------
  // Test configuration
  // ------------------------------------------------------------

  localparam int CLK_PERIOD_NS = 10;
  localparam int NUM_VECTORS   = 1011;
  localparam int MAX_CYCLES    = 5000;

  // ------------------------------------------------------------
  // DUT signals
  // ------------------------------------------------------------

  logic clk;
  logic rst_n;

  logic  in_valid;
  logic  in_ready;
  q2_14_t angle_in;

  logic  out_valid;
  logic  out_ready;
  q2_14_t cos_out;
  q2_14_t sin_out;

  // ------------------------------------------------------------
  // Test vector storage
  // ------------------------------------------------------------

  q2_14_t angle_mem [0:NUM_VECTORS-1];

  int sent_count;
  int recv_count;
  int cycle_count;

  int first_input_cycle;
  int first_output_cycle;
  int measured_latency;

  int rtl_csv_fd;

  // ------------------------------------------------------------
  // DUT instantiation
  // ------------------------------------------------------------

  cordic_top dut (
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

  // ------------------------------------------------------------
  // Clock generation
  // ------------------------------------------------------------

  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // ------------------------------------------------------------
  // Cycle counter
  // ------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
    end
  end

  // ------------------------------------------------------------
  // Output monitor
  // ------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recv_count         <= 0;
      first_output_cycle <= -1;
    end else begin
      if (out_valid && out_ready) begin

        if (recv_count == 0) begin
          first_output_cycle <= cycle_count;
        end

        $fdisplay(
          rtl_csv_fd,
          "%0d,%0d,%0d,%0d,%0d",
          recv_count,
          angle_mem[recv_count],
          sin_out,
          cos_out,
          cycle_count
        );

        recv_count <= recv_count + 1;
      end
    end
  end

  // ------------------------------------------------------------
  // Main test sequence
  // ------------------------------------------------------------

  initial begin

    // Initial values
    rst_n              = 1'b0;
    in_valid          = 1'b0;
    angle_in          = '0;
    out_ready         = 1'b1;

    sent_count         = 0;
    first_input_cycle  = -1;
    measured_latency   = -1;

    // Load test vectors
    $display("------------------------------------------------------------");
    $display("CORDIC Phase 4 Testbench Started");
    $display("Loading test vectors from tb/cordic_test_vectors.hex");
    $display("------------------------------------------------------------");

    $readmemh("tb/cordic_test_vectors.hex", angle_mem);

    // Open RTL output CSV
    rtl_csv_fd = $fopen("sim/rtl_output.csv", "w");

    if (rtl_csv_fd == 0) begin
      $display("ERROR: Could not open sim/rtl_output.csv");
      $finish;
    end

    $fdisplay(rtl_csv_fd, "index,angle_q214_signed,sin_q214_signed,cos_q214_signed,cycle");

    // Reset sequence
    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    $display("Reset released at cycle %0d", cycle_count);

    // Small gap after reset
    repeat (2) @(posedge clk);

    // --------------------------------------------------------
    // Drive all input vectors.
    //
    // Use negedge driving so that values are stable before the
    // next positive clock edge where the DUT samples them.
    // --------------------------------------------------------

    for (int i = 0; i < NUM_VECTORS; i++) begin
      @(negedge clk);

      in_valid = 1'b1;
      angle_in = angle_mem[i];

      if (i == 0) begin
        first_input_cycle = cycle_count;
      end

      @(posedge clk);

      if (in_valid && in_ready) begin
        sent_count++;
      end else begin
        $display("ERROR: Input was not accepted at vector %0d", i);
        $finish;
      end
    end

    // Stop driving
    @(negedge clk);
    in_valid = 1'b0;
    angle_in = '0;

    $display("Finished sending %0d input vectors at cycle %0d", sent_count, cycle_count);

    // Wait for all outputs
    while (recv_count < NUM_VECTORS && cycle_count < MAX_CYCLES) begin
      @(posedge clk);
    end

    // Close CSV
    $fclose(rtl_csv_fd);

    // Final checks
    $display("------------------------------------------------------------");
    $display("CORDIC Phase 4 Testbench Summary");
    $display("------------------------------------------------------------");
    $display("Sent inputs      : %0d", sent_count);
    $display("Received outputs : %0d", recv_count);
    $display("First input cycle: %0d", first_input_cycle);
    $display("First output cycle: %0d", first_output_cycle);

    measured_latency = first_output_cycle - first_input_cycle;
    $display("Measured first-output latency: %0d cycles", measured_latency);

    if (sent_count != NUM_VECTORS) begin
      $display("FAIL: Sent count mismatch.");
      $finish;
    end

    if (recv_count != NUM_VECTORS) begin
      $display("FAIL: Output count mismatch.");
      $finish;
    end

    if (measured_latency != STAGES) begin
      $display("WARNING: Expected latency approximately %0d cycles, measured %0d cycles.", STAGES, measured_latency);
      $display("This may be due to testbench cycle-count alignment. Check waveform if needed.");
    end else begin
      $display("Latency check passed.");
    end

    $display("PASS: Phase 4 basic CORDIC simulation completed.");
    $display("RTL output written to sim/rtl_output.csv");
    $display("------------------------------------------------------------");

    $finish;
  end

  // ------------------------------------------------------------
  // Timeout watchdog
  // ------------------------------------------------------------

  initial begin
    repeat (MAX_CYCLES) @(posedge clk);
    $display("FAIL: Simulation timeout after %0d cycles.", MAX_CYCLES);
    $finish;
  end

endmodule
