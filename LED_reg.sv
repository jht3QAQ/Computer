module LED_reg#(parameter integer WIDTH=16)(clk,in,out);
	input				clk;
	input[WIDTH-1:0]		in;
	output[WIDTH-1:0]	out;
	common_reg#(WIDTH) common_reg_inst(.clk(clk),.in(in),.out(out));
endmodule