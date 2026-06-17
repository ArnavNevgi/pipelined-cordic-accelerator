// cordic_axi_lite_wrapper.sv
//
// AXI4-Lite register wrapper for a one-sample-at-a-time CORDIC hardware demo.
//
// Register map:
//   0x00 CONTROL  [0] start, [1] done_ack
//   0x04 STATUS   [0] busy, [1] done, [2] cordic_in_ready,
//                 [3] cordic_out_valid, [4] start_pending
//   0x08 ANGLE_IN [15:0] signed Q2.14 input angle
//   0x0C SIN_OUT  [15:0] signed Q2.14 sine result
//   0x10 COS_OUT  [15:0] signed Q2.14 cosine result
//
// Software flow:
//   1. Write ANGLE_IN
//   2. Write CONTROL[0] = 1 to start
//   3. Poll STATUS[1] until done = 1
//   4. Read SIN_OUT and COS_OUT
//   5. Write CONTROL[1] = 1 to clear done, if desired
//
// Assumption:
//   The existing cordic_top module has this interface:
//     clk, rst_n,
//     in_valid, in_ready, angle_in,
//     out_valid, out_ready, sin_out, cos_out

`timescale 1ns/1ps

module cordic_axi_lite_wrapper #(
    parameter int C_S_AXI_DATA_WIDTH = 32,
    parameter int C_S_AXI_ADDR_WIDTH = 5
) (
    input  logic                                  s_axi_aclk,
    input  logic                                  s_axi_aresetn,

    // AXI4-Lite write address channel
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]         s_axi_awaddr,
    input  logic [2:0]                            s_axi_awprot,
    input  logic                                  s_axi_awvalid,
    output logic                                  s_axi_awready,

    // AXI4-Lite write data channel
    input  logic [C_S_AXI_DATA_WIDTH-1:0]         s_axi_wdata,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0]     s_axi_wstrb,
    input  logic                                  s_axi_wvalid,
    output logic                                  s_axi_wready,

    // AXI4-Lite write response channel
    output logic [1:0]                            s_axi_bresp,
    output logic                                  s_axi_bvalid,
    input  logic                                  s_axi_bready,

    // AXI4-Lite read address channel
    input  logic [C_S_AXI_ADDR_WIDTH-1:0]         s_axi_araddr,
    input  logic [2:0]                            s_axi_arprot,
    input  logic                                  s_axi_arvalid,
    output logic                                  s_axi_arready,

    // AXI4-Lite read data channel
    output logic [C_S_AXI_DATA_WIDTH-1:0]         s_axi_rdata,
    output logic [1:0]                            s_axi_rresp,
    output logic                                  s_axi_rvalid,
    input  logic                                  s_axi_rready
);

    // ------------------------------------------------------------------------
    // Register addresses
    // ------------------------------------------------------------------------
    localparam logic [C_S_AXI_ADDR_WIDTH-1:0] REG_CONTROL  = 5'h00;
    localparam logic [C_S_AXI_ADDR_WIDTH-1:0] REG_STATUS   = 5'h04;
    localparam logic [C_S_AXI_ADDR_WIDTH-1:0] REG_ANGLE_IN = 5'h08;
    localparam logic [C_S_AXI_ADDR_WIDTH-1:0] REG_SIN_OUT  = 5'h0C;
    localparam logic [C_S_AXI_ADDR_WIDTH-1:0] REG_COS_OUT  = 5'h10;

    // ------------------------------------------------------------------------
    // AXI write capture
    // ------------------------------------------------------------------------
    logic [C_S_AXI_ADDR_WIDTH-1:0]     awaddr_reg;
    logic                             awaddr_valid;

    logic [C_S_AXI_DATA_WIDTH-1:0]     wdata_reg;
    logic [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_reg;
    logic                             wdata_valid;

    wire write_fire = awaddr_valid && wdata_valid && !s_axi_bvalid;

    // ------------------------------------------------------------------------
    // User-visible registers
    // ------------------------------------------------------------------------
    logic signed [15:0] angle_reg;
    logic signed [15:0] active_angle_reg;
    logic signed [15:0] sin_reg;
    logic signed [15:0] cos_reg;

    logic busy_reg;
    logic done_reg;
    logic start_pending_reg;

    // ------------------------------------------------------------------------
    // CORDIC core wires
    // ------------------------------------------------------------------------
    logic        cordic_in_valid;
    logic        cordic_in_ready;
    logic signed [15:0] cordic_angle_in;

    logic        cordic_out_valid;
    logic        cordic_out_ready;
    logic signed [15:0] cordic_sin_out;
    logic signed [15:0] cordic_cos_out;

    assign cordic_angle_in  = active_angle_reg;
    assign cordic_out_ready = 1'b1;   // This wrapper always consumes the result.

    // One-cycle input valid pulse generated when a pending start is accepted.
    logic cordic_in_valid_reg;
    assign cordic_in_valid = cordic_in_valid_reg;

    // ------------------------------------------------------------------------
    // CORDIC DUT instance
    // ------------------------------------------------------------------------
    cordic_top u_cordic_top (
        .clk       (s_axi_aclk),
        .rst_n     (s_axi_aresetn),

        .in_valid  (cordic_in_valid),
        .in_ready  (cordic_in_ready),
        .angle_in  (cordic_angle_in),

        .out_valid (cordic_out_valid),
        .out_ready (cordic_out_ready),
        .sin_out   (cordic_sin_out),
        .cos_out   (cordic_cos_out)
    );

    // ------------------------------------------------------------------------
    // AXI constant responses
    // ------------------------------------------------------------------------
    assign s_axi_bresp = 2'b00; // OKAY
    assign s_axi_rresp = 2'b00; // OKAY

    // ------------------------------------------------------------------------
    // Register read mux
    // ------------------------------------------------------------------------
    function automatic logic [C_S_AXI_DATA_WIDTH-1:0] read_reg(
        input logic [C_S_AXI_ADDR_WIDTH-1:0] addr
    );
        logic [C_S_AXI_DATA_WIDTH-1:0] data;
        begin
            data = '0;

            unique case (addr)
                REG_CONTROL: begin
                    data[0] = 1'b0; // start is write-only/self-clearing
                    data[1] = 1'b0; // done_ack is write-only/self-clearing
                end

                REG_STATUS: begin
                    data[0] = busy_reg;
                    data[1] = done_reg;
                    data[2] = cordic_in_ready;
                    data[3] = cordic_out_valid;
                    data[4] = start_pending_reg;
                end

                REG_ANGLE_IN: begin
                    data[15:0] = angle_reg;
                end

                REG_SIN_OUT: begin
                    data[15:0] = sin_reg;
                end

                REG_COS_OUT: begin
                    data[15:0] = cos_reg;
                end

                default: begin
                    data = '0;
                end
            endcase

            return data;
        end
    endfunction

    // ------------------------------------------------------------------------
    // AXI write channel
    // ------------------------------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            awaddr_reg    <= '0;
            awaddr_valid  <= 1'b0;
        end else begin
            s_axi_awready <= 1'b0;

            if (!awaddr_valid && s_axi_awvalid) begin
                awaddr_reg    <= s_axi_awaddr;
                awaddr_valid  <= 1'b1;
                s_axi_awready <= 1'b1;
            end

            if (write_fire) begin
                awaddr_valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            wdata_reg    <= '0;
            wstrb_reg    <= '0;
            wdata_valid  <= 1'b0;
        end else begin
            s_axi_wready <= 1'b0;

            if (!wdata_valid && s_axi_wvalid) begin
                wdata_reg    <= s_axi_wdata;
                wstrb_reg    <= s_axi_wstrb;
                wdata_valid  <= 1'b1;
                s_axi_wready <= 1'b1;
            end

            if (write_fire) begin
                wdata_valid <= 1'b0;
            end
        end
    end

    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
        end else begin
            if (write_fire) begin
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // AXI read channel
    // ------------------------------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= '0;
        end else begin
            s_axi_arready <= 1'b0;

            if (!s_axi_rvalid && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rdata   <= read_reg(s_axi_araddr);
                s_axi_rvalid  <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // CORDIC control/status logic
    // ------------------------------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            angle_reg           <= '0;
            active_angle_reg    <= '0;
            sin_reg             <= '0;
            cos_reg             <= '0;
            busy_reg            <= 1'b0;
            done_reg            <= 1'b0;
            start_pending_reg   <= 1'b0;
            cordic_in_valid_reg <= 1'b0;
        end else begin
            // Default: no input pulse unless generated below.
            cordic_in_valid_reg <= 1'b0;

            // Software writes
            if (write_fire) begin
                unique case (awaddr_reg)
                    REG_CONTROL: begin
                        if (wstrb_reg[0]) begin
                            // CONTROL[1]: clear done
                            if (wdata_reg[1]) begin
                                done_reg <= 1'b0;
                            end

                            // CONTROL[0]: start one CORDIC transaction
                            // Ignore start if a transaction is already running.
                            if (wdata_reg[0] && !busy_reg && !start_pending_reg) begin
                                active_angle_reg  <= angle_reg;
                                busy_reg          <= 1'b1;
                                done_reg          <= 1'b0;
                                start_pending_reg <= 1'b1;
                            end
                        end
                    end

                    REG_ANGLE_IN: begin
                        // Low 16 bits hold signed Q2.14 angle.
                        // Byte strobes are honored for the low halfword.
                        if (wstrb_reg[0]) begin
                            angle_reg[7:0] <= wdata_reg[7:0];
                        end
                        if (wstrb_reg[1]) begin
                            angle_reg[15:8] <= wdata_reg[15:8];
                        end
                    end

                    default: begin
                        // Other registers are read-only or reserved.
                    end
                endcase
            end

            // Convert pending start into one valid pulse when the CORDIC input
            // side is ready.
            if (start_pending_reg && cordic_in_ready) begin
                cordic_in_valid_reg <= 1'b1;
                start_pending_reg   <= 1'b0;
            end

            // Capture result.
            // Since cordic_out_ready is tied high, any out_valid cycle is consumed.
            if (cordic_out_valid && busy_reg && !start_pending_reg) begin
                sin_reg  <= cordic_sin_out;
                cos_reg  <= cordic_cos_out;
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Suppress unused AXI protection-signal warnings in lint flows
    // ------------------------------------------------------------------------
    wire unused_axi_prot = &{1'b0, s_axi_awprot, s_axi_arprot};

endmodule
