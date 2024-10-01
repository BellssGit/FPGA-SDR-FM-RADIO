module top (
	input rst,

	input adc_clk,
	input [9:0] adc_data,
	input adc_or,

	output audio_out,
	output lo
);

reg [9:0] adc_data_buf;
wire sys_clk;
wire sys_clk_90;

assign sys_clk = adc_clk;
assign sys_clk_90 = ~adc_clk;

always @ (posedge adc_clk) begin
	adc_data_buf <= adc_data;
end

reg [7:0] t;
reg [3:0] t_cnt = 0;

always @ (posedge sys_clk_90) begin
	if(t_cnt == 0) begin
		t <= 0;
		t_cnt <= t_cnt + 1'b1;
	end
	else if (t_cnt == 1) begin
		t <= 64;
		t_cnt <= t_cnt + 1'b1;
	end
	else if (t_cnt == 2) begin
		t<= 128;
		t_cnt <= t_cnt + 1'b1;
	end
	else if (t_cnt == 3) begin
		t <= 192;
		t_cnt <= 0;
	end
end

wire [9:0] sin;
wire [9:0] cos;

nco nco_inst (.Clock(sys_clk), .ClkEn(1'b1), .Reset(1'b0), .Theta(t), .Sine(sin), .Cosine(cos));

wire signed [19:0] mix_I_FULL;
//wire signed [19:0] mix_I_FULL_debug;
//assign mix_I_FULL_debug = ~mix_I_FULL;
wire signed [19:0] mix_Q_FULL;

wire signed [11:0] mix_I;
wire signed [11:0] mix_Q;

assign mix_I = mix_I_FULL[19:8];
//assign mix_I = mix_I_FULL_debug[19:8];
assign mix_Q = mix_Q_FULL[19:8];

multi multi_inst_I (.Clock(sys_clk_90), .ClkEn(1'b1), .Aclr(1'b0), .DataA(adc_data), .DataB(cos), .Result(mix_I_FULL));
multi multi_inst_Q (.Clock(sys_clk_90), .ClkEn(1'b1), .Aclr(1'b0), .DataA(adc_data), .DataB(sin), .Result(mix_Q_FULL));

wire signed [11:0] cic_out_data_I;
wire cic_out_clk_I;



CIC cic_I (
	.clk(sys_clk),
	.gain(8'd3),
	.d_in(mix_I),
	.d_out(cic_out_data_I),
	.d_clk(cic_out_clk_I)
);

wire signed [11:0] cic_out_data_Q;
wire cic_out_clk_Q;

CIC cic_Q (
	.clk(sys_clk),
	.gain(8'd3),
	.d_in(mix_Q),
	.d_out(cic_out_data_Q),
	.d_clk(cic_out_clk_Q)
);

wire signed [11:0] Dmod_out;

FM_demodule FM_inst (
    .I_in(cic_out_data_I),
    .Q_in(cic_out_data_Q),
    .clk(cic_out_clk_I),

    .Demod_out(Dmod_out)
);


pwm_audio audio
(
    .clk(adc_clk),
	.DataIn(Dmod_out),
    .PWMOut(audio_out)
);

pll ext_mixer_lo (.CLKI(adc_clk), .CLKOP(lo));

endmodule
