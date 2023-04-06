module IR_reg(clk,in,out);
	input				clk;
	input[7:0]		in;
	output[7:0]	out;
	common_reg#(8) common_reg_inst(.clk(clk),.in(in),.out(out));
endmodule