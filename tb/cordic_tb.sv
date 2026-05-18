`timescale 1ns/1ps

// ============================================================
// cordic_tb.sv
//
// Phase 6 testbench for the 16-stage pipelined CORDIC
// accelerator.
//
// This testbench:
//   - Reads Q2.14 angle vectors from tb/cordic_test_vectors.hex
//   - Applies randomized input valid gaps
//   - Applies randomized output backpressure
//   - Captures sine/cosine outputs
//   - Writes RTL output CSV to sim/rtl_output.csv
//   - Measures latency and throughput
//   - Checks output count
//
// Python comparison is performed separately using:
//   python scripts/compare_results.py
// ============================================================

import cordic_pkg::*;

module cordic_tb;

  // ------------------------------------------------------------
  // Test configuration
  // ------------------------------------------------------------

  localparam int CLK_PERIOD_NS = 10;
  localparam int NUM_VECTORS   = 1011;
  localparam int MAX_CYCLES    = 20000;

  localparam int RANDOM_SEED   = 123;

  // Set to 1 for randomized valid and ready behavior.
  // Set to 0 for continuous streaming.
  localparam bit ENABLE_RANDOM_STALLS = 1'b1;

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
  int last_input_cycle;
  int last_output_cycle;

  int measured_first_latency;
  int active_cycles;
  real measured_throughput;

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
  // Output ready generation
  // ------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_ready <= 1'b1;
    end else begin
      if (ENABLE_RANDOM_STALLS) begin
        // Around 80 percent ready, 20 percent stalled.
        out_ready <= ($urandom_range(0, 9) >= 2);
      end else begin
        out_ready <= 1'b1;
      end
    end
  end

  // ------------------------------------------------------------
  // Output monitor
  // ------------------------------------------------------------

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      recv_count         <= 0;
      first_output_cycle <= -1;
      last_output_cycle  <= -1;
    end else begin
      if (out_valid && out_ready) begin

        if (recv_count == 0) begin
          first_output_cycle <= cycle_count;
        end

        last_output_cycle <= cycle_count;

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
    rst_n                 = 1'b0;
    in_valid             = 1'b0;
    angle_in             = '0;

    sent_count            = 0;
    first_input_cycle     = -1;
    last_input_cycle      = -1;
    measured_first_latency = -1;
    active_cycles         = 0;
    measured_throughput   = 0.0;

    void'($urandom(RANDOM_SEED));

    // Load test vectors
    $display("------------------------------------------------------------");
    $display("CORDIC Phase 6 Backpressure Testbench Started");
    $display("Loading test vectors from tb/cordic_test_vectors.hex");
    $display("Random stalls enabled: %0d", ENABLE_RANDOM_STALLS);
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
    // This driver only advances to the next vector when the DUT
    // accepts the current vector using in_valid && in_ready.
    // --------------------------------------------------------

    while (sent_count < NUM_VECTORS) begin
      @(negedge clk);

      if (ENABLE_RANDOM_STALLS) begin
        // Around 85 percent valid, 15 percent idle.
        in_valid = ($urandom_range(0, 99) >= 15);
      end else begin
        in_valid = 1'b1;
      end

      angle_in = angle_mem[sent_count];

      @(posedge clk);

      if (in_valid && in_ready) begin
        if (sent_count == 0) begin
          first_input_cycle = cycle_count;
        end

        last_input_cycle = cycle_count;
        sent_count++;
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

    // Final metrics
    measured_first_latency = first_output_cycle - first_input_cycle;
    active_cycles = last_output_cycle - first_input_cycle + 1;

    if (active_cycles > 0) begin
      measured_throughput = real'(recv_count) / real'(active_cycles);
    end

    // Final checks
    $display("------------------------------------------------------------");
    $display("CORDIC Phase 6 Testbench Summary");
    $display("------------------------------------------------------------");
    $display("Sent inputs            : %0d", sent_count);
    $display("Received outputs       : %0d", recv_count);
    $display("First input cycle      : %0d", first_input_cycle);
    $display("First output cycle     : %0d", first_output_cycle);
    $display("Last input cycle       : %0d", last_input_cycle);
    $display("Last output cycle      : %0d", last_output_cycle);
    $display("Measured first latency : %0d cycles", measured_first_latency);
    $display("Active cycles          : %0d", active_cycles);
    $display("Measured throughput    : %f outputs/cycle", measured_throughput);

    if (sent_count != NUM_VECTORS) begin
      $display("FAIL: Sent count mismatch.");
      $finish;
    end

    if (recv_count != NUM_VECTORS) begin
      $display("FAIL: Output count mismatch.");
      $finish;
    end

    if (measured_first_latency < STAGES) begin
      $display("FAIL: Latency shorter than expected pipeline depth.");
      $finish;
    end

    $display("PASS: Phase 6 valid-ready backpressure simulation completed.");
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