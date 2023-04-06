module flag_reg(clk,in,out);
	input				clk;
	input[15:0]		in;
	output[15:0]	out;
	common_reg#(16) common_reg_inst(.clk(clk),.in(in),.out(out));
endmodule