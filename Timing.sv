module Timing_DFF(CLK,D,Q,CLRN);
	input	CLK,D,CLRN;
	output	Q;
	reg		Q = 1'b0;

	always@(posedge CLK) begin : dff_clk
		if(CLRN)	Q <= 1'b0;
		else		Q <= D;
	end
endmodule
module Timing#(parameter integer WIDTH=2)(clk,clr,T);
	input					clk,clr;
	output[WIDTH-1:0]	T;
	
	wire[WIDTH-1:0]	D,Q;
		
	Timing_DFF dff_insts[WIDTH-1:0](.CLK(clk),.CLRN(clr),.D(D),.Q(Q));
	
	assign T[WIDTH-1:0]	= Q[WIDTH-1:0];
	
	assign D[WIDTH-1:1]	= Q[WIDTH-2:0];
	assign D[0]				= ~(|Q[WIDTH-2:0]);
	
endmodule