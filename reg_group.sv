module reg_group	#(parameter integer WIDTH=16,parameter integer COUNT=3)
						(clk,LDR,data,R);
	input									clk;
	input[WIDTH-1:0]					data;
	input[COUNT-1:0]					LDR;
	output[COUNT-1:0][WIDTH-1:0]	R;
	
	reg[COUNT-1:0][WIDTH-1:0]		R;
	
	generate
		genvar i;
		for (i = 0; i < COUNT; i = i + 1)begin: set_reg_i
			always@(posedge clk)begin
				if(LDR[i])
					R[i][WIDTH-1:0] <= data[WIDTH-1:0];
			end
		end
	endgenerate
endmodule