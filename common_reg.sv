module common_reg#(parameter integer WIDTH=16)(clk,in,out);
	input				clk;
	input[WIDTH-1:0]		in;
	output[WIDTH-1:0]	out;
	reg[WIDTH-1:0]		flag;
	assign			out = flag;
	always@(posedge clk) begin
		flag <= in;
	end
endmodule