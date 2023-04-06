module RAM#(parameter integer WIDTH=16)(clk,we,data,q,LDRAM,LDRAMD,qd,ram_clk,ramd_clk);
	input					clk,we,LDRAM,LDRAMD;
	input[WIDTH-1:0]	data;
	output[WIDTH-1:0]	q;
	output[WIDTH-1:0]	qd;
	
	reg[WIDTH-1:0]		addr;
	
	output				ram_clk;
	assign				ram_clk = clk && LDRAM;
	wire					ramd_clk;
	output				ramd_clk = clk && LDRAMD;
	assign				qd = addr;
	
	LPM_RAM_DQ #(.LPM_WIDTH(WIDTH),.LPM_WIDTHAD(WIDTH), .LPM_OUTDATA("UNREGISTERED")) 
				ram_inst(.inclock(ram_clk),.we(we),.address(addr),.data(data),.q(q));
	
	always@(posedge ramd_clk) begin
		addr <= data;
	end
	
endmodule