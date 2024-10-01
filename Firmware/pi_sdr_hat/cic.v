// https://www.embedded.com/design/configurable-systems/4006446/Understanding-cascaded-integrator-comb-filters
// https://github.com/ericgineer/CIC/blob/master/CIC.v
// https://westcoastdsp.wordpress.com/tag/cic-filter/
// https://www.dsprelated.com/thread/907/cic-filter
// http://home.mit.bme.hu/~kollar/papers/cic.pdf

/*
or a Q-stage CIC decimation-by-D filter (diff delay = 1) overflow errors are avoided if the number of integrator and comb register bit widths is at least

    register bit widths = number of bits in x(n) + {Qlog2(D)}

where x(n) is the input to the CIC filter, and {k} means that if k is not an integer, round it up to the next larger integer. For example, if a Q = 3-stage CIC decimation filter accepts one-bit binary input words from a sigma-delta A/D converter and the decimation factor is D = 64, binary overflow errors are avoided if the three integrator and three comb registers\92 bit widths are no less than

    register bit widths = 1 + {3 log2(D)} = 1 + 3 6 = 19 bits.
	5 stadi, decimation 16384 (14 bit) 1 + 5 * 14 = 71 

*/

//Thanks to 1bitSDR and the guy who write the CIC code

module CIC 
  (input wire               clk,
   input wire [7:0]		gain,
   input wire signed [11:0]  d_in,
   output reg signed [11:0]  d_out,
   output reg 				 d_clk);

  parameter width = 48;
  parameter decimation_ratio = 100;

  reg signed [width-1:0] d_tmp = 'b0, d_d_tmp = 'b0;


  // Integrator stage registers

  reg signed [width-1:0] d1 = 'b0;
  reg signed [width-1:0] d2 = 'b0;
  reg signed [width-1:0] d3 = 'b0;
  reg signed [width-1:0] d4 = 'b0;

  // Comb stage registers

  reg signed [width-1:0] d6 = 'b0, d_d6 = 'b0;
  reg signed [width-1:0] d7 = 'b0, d_d7 = 'b0;
  reg signed [width-1:0] d8 = 'b0, d_d8 = 'b0;
  reg signed [width-1:0] d9 = 'b0, d_d9 = 'b0;
  reg signed [width-1:0] d_scale = 'b0;

  reg [15:0] count = 'b0;

  reg v_comb = 'b0;  // Valid signal for comb section running at output rate

  reg d_clk_tmp = 'b0;


  always @(posedge clk)
    begin


      // Integrator section
      d1 <= d_in + d1;

      d2 <= d1 + d2;

      d3 <= d2 + d3;

      d4 <= d3 + d4;


      // Decimation

      if (count == decimation_ratio - 1)
        begin
          count <= 16'b0;
          d_tmp <= d4;
          d_clk_tmp <= 1'b1;
          v_comb <= 1'b1;
        end else if (count == decimation_ratio >> 1)
          begin
            d_clk_tmp <= 1'b0;
            count <= count + 16'd1;
            v_comb <= 1'b0;
          end else
            begin
              count <= count + 16'd1;
              v_comb <= 1'b0;
            end

    end

  always @(posedge clk)  // Comb section running at output rate
    begin
      d_clk <= d_clk_tmp;


      if (v_comb)
        begin
          // Comb section
          d_d_tmp <= d_tmp;

          d6 <= d_tmp - d_d_tmp;
          d_d6 <= d6;

          d7 <= d6 - d_d6;
          d_d7 <= d7;

          d8 <= d7 - d_d7;
          d_d8 <= d8;

          d9 <= d8 - d_d8;
			d_scale <= d9;
		  d_out <= d9[35:24];	
        end
    end		
endmodule

