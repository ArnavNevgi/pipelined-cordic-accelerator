`timescale 1ns/1ps

// ============================================================
// cordic_tb.sv
//
// Phase 7 benchmark-capable testbench for the 16-stage
// pipelined CORDIC accelerator.
//
// Features:
//   - Reads Q2.14 angle vectors from tb/cordic_test_vectors.hex
//   - Supports continuous streaming mode
//   - Supports randomized valid-ready backpressure mode
//   - Captures RTL output CSV
//   - Captures latency and throughput metrics CSV
//
// Plusargs:
//   +RANDOM_STALLS=0 or 1
//   +SEED=<integer>
//   +RTL_CSV=<path>
//   +METRICS_CSV=<path>
//
// Example:
//   vsim -c work.cordic_tb +RANDOM_STALLS=1 +SEED=123 \
//        +RTL_CSV=sim/rtl_output_backpressure.csv \
//        +METRICS_CSV=sim/metrics_backpressure.csv \
//        -do "run -all; quit"
// ============================================================

import cordic_pkg::*;

module cordic_tb;

  // ------------------------------------------------------------
  // Test configuration
  // ------------------------------------------------------------

  localparam int CLK_PERIOD_NS = 10;
  localparam int NUM_VECTORS   = 1011;
  localparam int MAX_CYCLES    = 30000;

  // ------------------------------------------------------------
  // Runtime configuration through plusargs
  // ------------------------------------------------------------

  int random_stalls;
  int random_seed;

  string rtl_csv_path;
  string metrics_csv_path;

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
  int total_output_span_cycles;
  int active_cycles;

  real measured_throughput_active;
  real measured_throughput_output_span;

  int rtl_csv_fd;
  int metrics_csv_fd;

  bit drive_valid_next;
  bit input_accepted;

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
      if (random_stalls != 0) begin
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

    // ----------------------------------------------------------
    // Default runtime configuration
    // ----------------------------------------------------------

    random_stalls    = 0;
    random_seed      = 123;
    rtl_csv_path     = "sim/rtl_output.csv";
    metrics_csv_path = "sim/metrics.csv";

    void'($value$plusargs("RANDOM_STALLS=%d", random_stalls));
    void'($value$plusargs("SEED=%d", random_seed));
    void'($value$plusargs("RTL_CSV=%s", rtl_csv_path));
    void'($value$plusargs("METRICS_CSV=%s", metrics_csv_path));

    void'($urandom(random_seed));

    // ----------------------------------------------------------
    // Initial values
    // ----------------------------------------------------------

    rst_n                    = 1'b0;
    in_valid                = 1'b0;
    angle_in                = '0;

    sent_count              = 0;
    first_input_cycle       = -1;
    last_input_cycle        = -1;

    measured_first_latency  = -1;
    total_output_span_cycles = 0;
    active_cycles           = 0;

    measured_throughput_active      = 0.0;
    measured_throughput_output_span = 0.0;
    drive_valid_next                = 1'b0;
    input_accepted                  = 1'b0;

    // ----------------------------------------------------------
    // Load vectors and open files
    // ----------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("CORDIC Phase 7 Benchmark Testbench Started");
    $display("Loading test vectors from tb/cordic_test_vectors.hex");
    $display("RANDOM_STALLS = %0d", random_stalls);
    $display("SEED          = %0d", random_seed);
    $display("RTL CSV       = %s", rtl_csv_path);
    $display("METRICS CSV   = %s", metrics_csv_path);
    $display("------------------------------------------------------------");

    $readmemh("tb/cordic_test_vectors.hex", angle_mem);

    rtl_csv_fd = $fopen(rtl_csv_path, "w");

    if (rtl_csv_fd == 0) begin
      $display("ERROR: Could not open RTL CSV file: %s", rtl_csv_path);
      $finish;
    end

    $fdisplay(rtl_csv_fd, "index,angle_q214_signed,sin_q214_signed,cos_q214_signed,cycle");

    metrics_csv_fd = $fopen(metrics_csv_path, "w");

    if (metrics_csv_fd == 0) begin
      $display("ERROR: Could not open metrics CSV file: %s", metrics_csv_path);
      $finish;
    end

    $fdisplay(
      metrics_csv_fd,
      "random_stalls,seed,num_vectors,clk_period_ns,first_input_cycle,first_output_cycle,last_input_cycle,last_output_cycle,first_latency_cycles,active_cycles,output_span_cycles,throughput_active_outputs_per_cycle,throughput_output_span_outputs_per_cycle"
    );

    // ----------------------------------------------------------
    // Reset sequence
    // ----------------------------------------------------------

    repeat (5) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    $display("Reset released at cycle %0d", cycle_count);

    repeat (2) @(posedge clk);

    // ----------------------------------------------------------
    // Drive all input vectors.
    // Driver advances only on in_valid && in_ready.
    // ----------------------------------------------------------

    while (sent_count < NUM_VECTORS) begin
      @(negedge clk);

      if (input_accepted) begin
        in_valid      = 1'b0;
        input_accepted = 1'b0;
      end

      if (!in_valid) begin
        if (random_stalls != 0) begin
          // Around 85 percent valid, 15 percent idle.
          drive_valid_next = ($urandom_range(0, 99) >= 15);
        end else begin
          drive_valid_next = 1'b1;
        end

        in_valid = drive_valid_next;
        angle_in = angle_mem[sent_count];
      end

      @(posedge clk);

      if (in_valid && in_ready) begin
        if (sent_count == 0) begin
          first_input_cycle = cycle_count;
        end

        last_input_cycle = cycle_count;
        sent_count++;
        input_accepted = 1'b1;
      end
    end

    // Stop driving
    @(negedge clk);
    in_valid = 1'b0;
    angle_in = '0;

    $display("Finished sending %0d input vectors at cycle %0d", sent_count, cycle_count);

    // ----------------------------------------------------------
    // Wait for all outputs
    // ----------------------------------------------------------

    while (recv_count < NUM_VECTORS && cycle_count < MAX_CYCLES) begin
      @(posedge clk);
    end

    // ----------------------------------------------------------
    // Compute metrics
    // ----------------------------------------------------------

    measured_first_latency = first_output_cycle - first_input_cycle;
    active_cycles = last_output_cycle - first_input_cycle + 1;
    total_output_span_cycles = last_output_cycle - first_output_cycle + 1;

    if (active_cycles > 0) begin
      measured_throughput_active = real'(recv_count) / real'(active_cycles);
    end

    if (total_output_span_cycles > 0) begin
      measured_throughput_output_span = real'(recv_count) / real'(total_output_span_cycles);
    end

    // ----------------------------------------------------------
    // Write metrics
    // ----------------------------------------------------------

    $fdisplay(
      metrics_csv_fd,
      "%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%f,%f",
      random_stalls,
      random_seed,
      NUM_VECTORS,
      CLK_PERIOD_NS,
      first_input_cycle,
      first_output_cycle,
      last_input_cycle,
      last_output_cycle,
      measured_first_latency,
      active_cycles,
      total_output_span_cycles,
      measured_throughput_active,
      measured_throughput_output_span
    );

    $fclose(rtl_csv_fd);
    $fclose(metrics_csv_fd);

    // ----------------------------------------------------------
    // Final checks
    // ----------------------------------------------------------

    $display("------------------------------------------------------------");
    $display("CORDIC Phase 7 Benchmark Summary");
    $display("------------------------------------------------------------");
    $display("Sent inputs                         : %0d", sent_count);
    $display("Received outputs                    : %0d", recv_count);
    $display("First input cycle                   : %0d", first_input_cycle);
    $display("First output cycle                  : %0d", first_output_cycle);
    $display("Last input cycle                    : %0d", last_input_cycle);
    $display("Last output cycle                   : %0d", last_output_cycle);
    $display("Measured first latency              : %0d cycles", measured_first_latency);
    $display("Active cycles                       : %0d", active_cycles);
    $display("Output span cycles                  : %0d", total_output_span_cycles);
    $display("Throughput active window            : %f outputs/cycle", measured_throughput_active);
    $display("Throughput output span              : %f outputs/cycle", measured_throughput_output_span);

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

    $display("PASS: Phase 7 benchmark simulation completed.");
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
