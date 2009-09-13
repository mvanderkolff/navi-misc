/*
 * main.v - Top-level module for the RAM Tracer.
 *
 * Copyright (C) 2009 Micah Dowty
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


module main(mclk,
            usb_d, usb_rxf_n, usb_txe_n, usb_rd_n, usb_wr_n, usb_oe_n,
            ram_a, ram_d, ram_oe, ram_we, ram_ce1_in,
            ram_ce1_out, ram_ce2, ram_ub, ram_lb, ram_adv, ram_clk,
            dsi_sysclk);

   input mclk;
   wire  reset = 1'b0;   // Placeholder- no need for reset yet

   inout [7:0] usb_d;
   input       usb_rxf_n, usb_txe_n;
   output      usb_rd_n, usb_wr_n, usb_oe_n;

   input [22:0] ram_a;
   input [15:0] ram_d;
   input        ram_oe, ram_we, ram_ce1_in, ram_ce2;
   input        ram_ub, ram_lb, ram_adv, ram_clk;
   output       ram_ce1_out;

   assign ram_ce1_out = 0;

   output       dsi_sysclk;

   // FIXME: Config options
   wire         trace_enable = 1;
   wire         trace_reads = 1;


   /************************************************
    * USB FIFO
    */

   wire [31:0]   packet_data;
   reg           packet_strobe;
   reg [1:0]     packet_type;
   reg [22:0]    packet_payload;

   wire [15:0]   config_addr;
   wire [15:0]   config_data;
   wire          config_strobe;

   usb_comm usbc(mclk, reset,
                 usb_d, usb_rxf_n, usb_txe_n, usb_rd_n, usb_wr_n, usb_oe_n,
                 packet_data, packet_strobe,
                 config_addr, config_data, config_strobe);

   usb_packet_assemble usbpa(packet_data, packet_type, packet_payload);


   /************************************************
    * Oscillator Simulator
    */

   osc_sim dsosc(mclk, reset, config_addr, config_data, config_strobe, dsi_sysclk);


   /************************************************
    * RAM Bus
    */

   wire [22:0] filter_a;
   wire [15:0] filter_d;
   wire [1:0]  filter_ublb;
   wire        filter_read;
   wire        filter_write;
   wire        filter_addr_latch;
   wire        filter_strobe;

   wire [15:0] nfilter_d;
   wire        nfilter_strobe;

   ram_sampler ramsam(mclk, reset,
                      ram_a, ram_d, ram_oe, ram_we, ram_ce1_in, ram_ce2,
                      ram_ub, ram_lb, ram_adv, ram_clk,
                      filter_a, filter_d, filter_ublb, filter_read,
                      filter_write, filter_addr_latch, filter_strobe,
                      nfilter_d, nfilter_strobe);

   /*
    * Which cycle are we on in this read/write burst?
    *
    * We need this to check for RAM latency later on, plus
    * we use it to report read burst length back to the host.
    */

   reg [7:0]   burst_cycle;

   always @(posedge mclk or posedge reset)
     if (reset)
       burst_cycle <= 0;
     else if (filter_strobe) begin
        if (filter_addr_latch)
          burst_cycle <= 0;
        else if ((filter_write || filter_read) && !(&burst_cycle))
          burst_cycle <= burst_cycle + 1;
     end


   /************************************************
    * Tracing state machine
    */

   parameter READ_LATENCY = 4;
   parameter WRITE_LATENCY = 3;

   reg [22:0] timestamp_counter;

   // Split the timestamp into a piece that we can represent in 5 bits, and the remainder
   wire [4:0] timestamp5 = timestamp_counter > 5'b11111
                           ? 5'b11111 : timestamp_counter[4:0];
   wire [22:0] timestamp5_remainder = timestamp_counter - { 18'b0, timestamp5 };

   always @(posedge mclk or posedge reset)
     if (reset) begin
        timestamp_counter <= 0;
        packet_type <= 0;
        packet_payload <= 0;
        packet_strobe <= 0;
     end
     else if (trace_enable && filter_strobe && filter_addr_latch) begin
        /*
         * Send an address packet
         */

        timestamp_counter <= timestamp_counter + 1;
        packet_type <= 2'b00;
        packet_payload <= filter_a;
        packet_strobe <= 1;
     end
     else if (trace_enable && filter_strobe && filter_write &&
              burst_cycle >= (WRITE_LATENCY - 1)) begin
        /*
         * Send a write word packet
         */

        timestamp_counter <= timestamp5_remainder;
        packet_type <= 2'b10;
        packet_payload <= { timestamp5, filter_ublb, filter_d };
        packet_strobe <= 1;
     end
     else if (trace_enable && trace_reads && nfilter_strobe && filter_read &&
              burst_cycle >= READ_LATENCY) begin
        /*
         * Send a read word packet.
         * Note that data is latched on the negative clock edge,
         * but all control signals are taken from the last positive edge.
         *
         * This also gives us no -1 above, since burst_cycle has
         * already been incremented.
         */

        timestamp_counter <= timestamp5_remainder;
        packet_type <= 2'b01;
        packet_payload <= { timestamp5, filter_ublb, nfilter_d };
        packet_strobe <= 1;
     end
     else if (trace_enable && filter_strobe &&
              burst_cycle == 1 && timestamp5_remainder) begin
        /*
         * Our RAM is otherwise idle, and we have a timestamp remainder-
         * send a timestamp packet to sync up the host with our clock.
         *
         * We only do this during the latency clocks in a read or write,
         * not while the RAM is completely idle. If we did it while totally
         * idle, we'd send a packet every 32 clocks, which would just waste
         * space. But we still want every packet to have an accurate timestamp.
         * By sending it during this latency cycle, we end up with an address
         * packet that may have an outdated timestamp, but the end of the burst
         * (which is what matters) will always have an up-to-date timestamp.
         */

        timestamp_counter <= 0;
        packet_type <= 2'b11;
        packet_payload <= timestamp_counter;
        packet_strobe <= 1;
     end
     else begin
        /*
         * Idle. Just count cycles.
         */

        if (filter_strobe)
          timestamp_counter <= timestamp_counter + 1;

        packet_type <= 2'bXX;
        packet_payload <= 23'hXXXXXX;
        packet_strobe <= 0;
     end

endmodule // main


/*
 * Configurable Oscillator Simulator --
 *
 *   This is a configurable frequency generator. We use a Xilinx DCM to
 *   multiply the incoming clock frequency (to achieve better clock resolution),
 *   then we use an accumulator to divide the clock by a 16-bit fixed-point value.
 *
 *   This oscillator can synthesize frequencies up to 29.9995 MHz, with a
 *   resolution of 457.8 kHz.
 */

module osc_sim(mclk, reset, config_addr, config_data, config_strobe, osc_out);

   input mclk, reset;
   output osc_out;

   input [15:0] config_addr;
   input [15:0] config_data;
   input        config_strobe;

   reg [18:0]  accum;
   reg         accum_out;
   reg         accum_out_buf;
   reg         osc_out;

   reg [15:0]  cfg_rate_buf1;
   reg [15:0]  cfg_rate_buf2;
   wire [15:0] cfg_rate;

   usb_config #(16'h0000) cfg(mclk, reset, config_addr, config_data,
                              config_strobe, cfg_rate);

   wire clk4x;

   DCM #(.CLKDV_DIVIDE(2.0),
         .CLKFX_DIVIDE(1),
         .CLKFX_MULTIPLY(4),
         .CLKIN_DIVIDE_BY_2("FALSE"),
         .CLKOUT_PHASE_SHIFT("NONE"),
         .CLK_FEEDBACK("NONE")
         ) dcm4x (.CLKFX(clk4x),
                  .CLKIN(mclk),
                  .RST(reset));

   /*
    * Performance is critical here, as this adder will be running at 240 MHz!
    * We double-register the input (cfg_rate) and output (osc_out) in order
    * to help isolate this accumulator from the placement of other logic elements.
    *
    * Also, it's a good idea to double-register the input since we're
    * crossing clock domains.
    */

   always @(posedge clk4x or posedge reset)
     if (reset) begin
        accum <= 0;
        accum_out_buf <= 0;
        osc_out <= 0;
        cfg_rate_buf1 <= 0;
        cfg_rate_buf2 <= 0;
     end
     else begin
        accum <= accum + { 3'b000, cfg_rate_buf2 };
        accum_out_buf <= accum[18];
        osc_out <= accum_out_buf;
        cfg_rate_buf1 <= cfg_rate;
        cfg_rate_buf2 <= cfg_rate_buf1;
     end

endmodule
