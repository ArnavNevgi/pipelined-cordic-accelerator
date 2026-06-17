`timescale 1ns/1ps

module tb_cordic_axi_lite_wrapper;

  localparam int CLK_PERIOD_NS = 10;
  localparam int DATA_WIDTH    = 32;
  localparam int ADDR_WIDTH    = 5;

  localparam logic [ADDR_WIDTH-1:0] REG_CONTROL  = 5'h00;
  localparam logic [ADDR_WIDTH-1:0] REG_STATUS   = 5'h04;
  localparam logic [ADDR_WIDTH-1:0] REG_ANGLE_IN = 5'h08;
  localparam logic [ADDR_WIDTH-1:0] REG_SIN_OUT  = 5'h0C;
  localparam logic [ADDR_WIDTH-1:0] REG_COS_OUT  = 5'h10;

  localparam int RESULT_TOLERANCE_LSB = 8;

  logic                         s_axi_aclk;
  logic                         s_axi_aresetn;

  logic [ADDR_WIDTH-1:0]        s_axi_awaddr;
  logic [2:0]                   s_axi_awprot;
  logic                         s_axi_awvalid;
  logic                         s_axi_awready;

  logic [DATA_WIDTH-1:0]        s_axi_wdata;
  logic [(DATA_WIDTH/8)-1:0]    s_axi_wstrb;
  logic                         s_axi_wvalid;
  logic                         s_axi_wready;

  logic [1:0]                   s_axi_bresp;
  logic                         s_axi_bvalid;
  logic                         s_axi_bready;

  logic [ADDR_WIDTH-1:0]        s_axi_araddr;
  logic [2:0]                   s_axi_arprot;
  logic                         s_axi_arvalid;
  logic                         s_axi_arready;

  logic [DATA_WIDTH-1:0]        s_axi_rdata;
  logic [1:0]                   s_axi_rresp;
  logic                         s_axi_rvalid;
  logic                         s_axi_rready;

  cordic_axi_lite_wrapper dut (
      .s_axi_aclk    (s_axi_aclk),
      .s_axi_aresetn (s_axi_aresetn),

      .s_axi_awaddr  (s_axi_awaddr),
      .s_axi_awprot  (s_axi_awprot),
      .s_axi_awvalid (s_axi_awvalid),
      .s_axi_awready (s_axi_awready),

      .s_axi_wdata   (s_axi_wdata),
      .s_axi_wstrb   (s_axi_wstrb),
      .s_axi_wvalid  (s_axi_wvalid),
      .s_axi_wready  (s_axi_wready),

      .s_axi_bresp   (s_axi_bresp),
      .s_axi_bvalid  (s_axi_bvalid),
      .s_axi_bready  (s_axi_bready),

      .s_axi_araddr  (s_axi_araddr),
      .s_axi_arprot  (s_axi_arprot),
      .s_axi_arvalid (s_axi_arvalid),
      .s_axi_arready (s_axi_arready),

      .s_axi_rdata   (s_axi_rdata),
      .s_axi_rresp   (s_axi_rresp),
      .s_axi_rvalid  (s_axi_rvalid),
      .s_axi_rready  (s_axi_rready)
  );

  initial begin
    s_axi_aclk = 1'b0;
    forever #(CLK_PERIOD_NS/2) s_axi_aclk = ~s_axi_aclk;
  end

  function automatic int signed16(input logic [15:0] value);
    signed16 = $signed(value);
  endfunction

  function automatic int abs_int(input int value);
    if (value < 0) begin
      abs_int = -value;
    end else begin
      abs_int = value;
    end
  endfunction

  task automatic check_close(
      input string name,
      input int actual,
      input int expected,
      input int tolerance
  );
    begin
      if (abs_int(actual - expected) > tolerance) begin
        $display(
            "FAIL: %s actual=%0d expected=%0d tolerance=%0d",
            name,
            actual,
            expected,
            tolerance
        );
        $finish;
      end
    end
  endtask

  task automatic init_axi;
    begin
      s_axi_awaddr  = '0;
      s_axi_awprot  = '0;
      s_axi_awvalid = 1'b0;

      s_axi_wdata   = '0;
      s_axi_wstrb   = '0;
      s_axi_wvalid  = 1'b0;

      s_axi_bready  = 1'b0;

      s_axi_araddr  = '0;
      s_axi_arprot  = '0;
      s_axi_arvalid = 1'b0;

      s_axi_rready  = 1'b0;
    end
  endtask

  task automatic wait_b_response;
    begin
      s_axi_bready = 1'b1;
      while (!s_axi_bvalid) begin
        @(negedge s_axi_aclk);
      end

      if (s_axi_bresp != 2'b00) begin
        $display("FAIL: AXI write response was not OKAY: %b", s_axi_bresp);
        $finish;
      end

      @(posedge s_axi_aclk);
      @(negedge s_axi_aclk);
      s_axi_bready = 1'b0;
    end
  endtask

  task automatic axi_write_aw_then_w(
      input logic [ADDR_WIDTH-1:0]     addr,
      input logic [DATA_WIDTH-1:0]     data,
      input logic [(DATA_WIDTH/8)-1:0] strb
  );
    begin
      @(negedge s_axi_aclk);
      s_axi_awaddr  = addr;
      s_axi_awvalid = 1'b1;

      while (!s_axi_awready) begin
        @(negedge s_axi_aclk);
      end

      s_axi_awvalid = 1'b0;

      repeat (2) @(negedge s_axi_aclk);

      s_axi_wdata  = data;
      s_axi_wstrb  = strb;
      s_axi_wvalid = 1'b1;

      while (!s_axi_wready) begin
        @(negedge s_axi_aclk);
      end

      s_axi_wvalid = 1'b0;
      s_axi_wstrb  = '0;

      wait_b_response();
    end
  endtask

  task automatic axi_write_w_then_aw(
      input logic [ADDR_WIDTH-1:0]     addr,
      input logic [DATA_WIDTH-1:0]     data,
      input logic [(DATA_WIDTH/8)-1:0] strb
  );
    begin
      @(negedge s_axi_aclk);
      s_axi_wdata  = data;
      s_axi_wstrb  = strb;
      s_axi_wvalid = 1'b1;

      while (!s_axi_wready) begin
        @(negedge s_axi_aclk);
      end

      s_axi_wvalid = 1'b0;
      s_axi_wstrb  = '0;

      repeat (2) @(negedge s_axi_aclk);

      s_axi_awaddr  = addr;
      s_axi_awvalid = 1'b1;

      while (!s_axi_awready) begin
        @(negedge s_axi_aclk);
      end

      s_axi_awvalid = 1'b0;

      wait_b_response();
    end
  endtask

  task automatic axi_read(
      input  logic [ADDR_WIDTH-1:0] addr,
      output logic [DATA_WIDTH-1:0] data
  );
    begin
      @(negedge s_axi_aclk);
      s_axi_araddr  = addr;
      s_axi_arvalid = 1'b1;

      while (!s_axi_arready) begin
        @(negedge s_axi_aclk);
      end

      s_axi_arvalid = 1'b0;
      s_axi_rready  = 1'b1;

      while (!s_axi_rvalid) begin
        @(negedge s_axi_aclk);
      end

      if (s_axi_rresp != 2'b00) begin
        $display("FAIL: AXI read response was not OKAY: %b", s_axi_rresp);
        $finish;
      end

      data = s_axi_rdata;

      @(posedge s_axi_aclk);
      @(negedge s_axi_aclk);
      s_axi_rready = 1'b0;
    end
  endtask

  task automatic wait_done(output logic [DATA_WIDTH-1:0] status);
    begin
      status = '0;

      for (int poll = 0; poll < 100; poll++) begin
        axi_read(REG_STATUS, status);

        if (status[1]) begin
          return;
        end
      end

      $display("FAIL: Timed out waiting for STATUS.done");
      $finish;
    end
  endtask

  task automatic run_one_sample(
      input logic [15:0] angle_q214,
      input int expected_sin,
      input int expected_cos
  );
    logic [DATA_WIDTH-1:0] status;
    logic [DATA_WIDTH-1:0] sin_data;
    logic [DATA_WIDTH-1:0] cos_data;
    int sin_value;
    int cos_value;
    begin
      axi_write_aw_then_w(REG_ANGLE_IN, {16'h0000, angle_q214}, 4'h3);
      axi_write_w_then_aw(REG_CONTROL, 32'h0000_0001, 4'hF);
      wait_done(status);

      if (status[0] != 1'b0) begin
        $display("FAIL: STATUS.busy remained set after done: %h", status);
        $finish;
      end

      axi_read(REG_SIN_OUT, sin_data);
      axi_read(REG_COS_OUT, cos_data);

      sin_value = signed16(sin_data[15:0]);
      cos_value = signed16(cos_data[15:0]);

      check_close("sin_out", sin_value, expected_sin, RESULT_TOLERANCE_LSB);
      check_close("cos_out", cos_value, expected_cos, RESULT_TOLERANCE_LSB);

      axi_write_aw_then_w(REG_CONTROL, 32'h0000_0002, 4'hF);
      axi_read(REG_STATUS, status);

      if (status[1] != 1'b0) begin
        $display("FAIL: STATUS.done did not clear: %h", status);
        $finish;
      end
    end
  endtask

  initial begin
    logic [DATA_WIDTH-1:0] status;

    init_axi();
    s_axi_aresetn = 1'b0;

    repeat (5) @(posedge s_axi_aclk);
    @(negedge s_axi_aclk);
    s_axi_aresetn = 1'b1;

    repeat (2) @(posedge s_axi_aclk);

    axi_write_aw_then_w(REG_ANGLE_IN, 32'h0000_0000, 4'h3);
    axi_write_w_then_aw(REG_CONTROL, 32'h0000_0001, 4'h0);
    axi_read(REG_STATUS, status);

    if (status[0] || status[1] || status[4]) begin
      $display("FAIL: CONTROL write with zero WSTRB changed state: %h", status);
      $finish;
    end

    run_one_sample(16'h0000, 0, 16384);
    run_one_sample(16'h3244, 11585, 11585);

    $display("PASS: AXI4-Lite CORDIC wrapper smoke test completed.");
    $finish;
  end

  initial begin
    repeat (1000) @(posedge s_axi_aclk);
    $display("FAIL: Simulation timeout.");
    $finish;
  end

endmodule
