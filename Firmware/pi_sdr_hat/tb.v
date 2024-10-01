`timescale 1ns/1ps
module tb;

GSR GSR_INST(.GSR(1'b1));
PUR PUR_INST(.PUR(1'b1));

reg clk;
initial clk = 0 ;
always #25 clk = ~clk;

reg rst;
initial begin
	rst = 1;
	#200000 rst = 0;
end

reg [9:0] Xin;
reg [63:0] count;
reg [63:0] stimulus[1:200000*2];   

initial begin
	$readmemb("/home/pnb/sinewave.txt",stimulus);
	//文件路径必须在simulation/modelsim中
	count = 0;
	repeat(20000000)begin
		count = count +1;
		Xin   = stimulus[count];
		#50;       //每隔1个时钟周期读入一个数据，相当于抽样频率20MHz
	end
end

wire audio;

top inst (
	.adc_clk(clk),
	.adc_data(Xin),
	.adc_or(),
	.rst(rst),
	.audio_out(audio)
);

endmodule