module FM_demodule (
    input signed [11:0] I_in,
    input signed [11:0] Q_in,
    input clk,

    output signed [11:0] Demod_out
);

reg signed [11:0] I_delay1 = 'b0;
reg signed [11:0] Q_delay1 = 'b0;

reg signed [11:0] I_delay2 = 'b0;
reg signed [11:0] Q_delay2 = 'b0;


always @(posedge clk) begin
    I_delay1 <= I_in;
    Q_delay1 <= Q_in;
    I_delay2 <= I_delay1;
    Q_delay2 <= Q_delay1;
end

wire signed [23:0] I_times_Q_delay_full;
wire signed [23:0] Q_times_I_delay_full;

multi_12bit I_x_Q (.Clock(~clk), .ClkEn('b1), .Aclr('b0), .DataA(I_delay1), .DataB(Q_delay2), 
    .Result(I_times_Q_delay_full));

multi_12bit Q_x_I (.Clock(~clk), .ClkEn('b1), .Aclr('b0), .DataA(Q_delay1), .DataB(I_delay2), 
    .Result(Q_times_I_delay_full));

reg signed [31:0] out = 'b0;
//reg signed [31:0] out_rev = 'b0;

always @(posedge clk) begin
    out <= Q_times_I_delay_full - I_times_Q_delay_full;
	//out_rev <= ~out;
end

assign Demod_out = out[21:10];

endmodule

module AM_demodule (
    input signed [11:0] I_in,
    input signed [11:0] Q_in,
    input clk,

    output reg signed [11:0] Demod_out
);

reg signed [11:0] abs_I = 'b0;
reg signed [11:0] abs_Q = 'b0;

reg signed [12:0] abs_sum = 'b0;

reg signed [12:0] audio_dc = 'b0;

always @(posedge clk) begin
    if(I_in < 0) begin
        abs_I <= -I_in;
    end
    else begin
        abs_I <= I_in;
    end

    if(Q_in < 0) begin
        abs_Q <= -Q_in;
    end
    else begin
        abs_Q <= Q_in;
    end
end

always @(negedge clk) begin
    if (abs_I > abs_Q) begin
        abs_sum <= abs_I + (abs_Q >> 2);
    end
    else begin
        abs_sum <= abs_Q + (abs_I >> 2);
    end
end

always @(posedge clk) begin
    audio_dc <= abs_sum + (audio_dc - audio_dc >>> 5);
    Demod_out <= abs_sum - audio_dc >>> 5;
end

endmodule
