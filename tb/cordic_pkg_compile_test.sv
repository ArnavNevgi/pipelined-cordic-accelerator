`timescale 1ns/1ps

module cordic_pkg_compile_test;

  import cordic_pkg::*;

  initial begin
    $display("DATA_WIDTH = %0d", DATA_WIDTH);
    $display("FRAC_BITS  = %0d", FRAC_BITS);
    $display("STAGES     = %0d", STAGES);
    $display("CORDIC_K   = %0d", CORDIC_K);

    for (int i = 0; i < STAGES; i++) begin
      $display("ATAN[%0d]    = %0d", i, ATAN_TABLE[i]);
    end

    $display("Package compile test passed.");
    $finish;
  end

endmodule
