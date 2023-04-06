module ALU#(parameter integer WIDTH=16) (S,M,data,F,clk,LDDR1,LDDR2,LDCN,flag,A,B,CN);
	input[3:0]			S;
	input					M,LDCN;
	input[WIDTH-1:0]	data;
	output[WIDTH-1:0]	F;
	
	input					clk,LDDR1,LDDR2;
	output[15:0]		flag;
	output[15:0]		A,B;
	output				CN;
	
	reg[WIDTH-1:0]	A,B;
	reg				CN;
	wire				CN4;
	wire				ALU_74181_warp_inst_CN,ALU_74181_warp_inst_CN4;
	ALU_74181_warp ALU_74181_warp_inst(	.S(S),.M(M),.CN(ALU_74181_warp_inst_CN),
													.A(A),.B(B),.CN4(ALU_74181_warp_inst_CN4),.F(F));
	assign			ALU_74181_warp_inst_CN = ~CN;
	assign			CN4 = ~ALU_74181_warp_inst_CN4;
	
	Flag_helper#(WIDTH) Flag_helper_inst(.data(F),.CN(CN4),.flag(flag));
	
	wire	reg_A_clk,reg_B_clk,reg_CN_clk;
	assign reg_A_clk = LDDR1 && clk;
	assign reg_B_clk = LDDR2 && clk;
	assign reg_CN_clk = LDCN && clk;
	
	always@(posedge reg_A_clk) begin:set_reg_A
		A[WIDTH-1:0] <= data[WIDTH-1:0];
	end
	always@(posedge reg_B_clk) begin:set_reg_B
		B[WIDTH-1:0] <= data[WIDTH-1:0];
	end
	always@(posedge reg_CN_clk) begin:set_reg_CN
		CN <= data[0];
	end
	
endmodule

module ALU_74181_warp#(	parameter integer WIDTH=16,
								parameter integer ALU_74181_COUNT = (WIDTH + 4 - 1) / 4) 
							(S,M,CN,A,B,CN4,F);
	
	input[3:0]			S;
	input					M,CN;
	input[WIDTH-1:0]	A,B;
	output				CN4;
	output[WIDTH-1:0]	F;
	
	wire[ALU_74181_COUNT-1:0]	insts_B3N,insts_B2N,insts_B1N,insts_B0N;
	wire[ALU_74181_COUNT-1:0]	insts_A3N,insts_A2N,insts_A1N,insts_A0N;
	wire[ALU_74181_COUNT-1:0]	insts_F3N,insts_F2N,insts_F1N,insts_F0N;
	wire[ALU_74181_COUNT:0]		insts_CN;
	wire[ALU_74181_COUNT*4-1:0]	insts_A,insts_B,insts_F;
	ALU_74181 ALU_74181_insts[ALU_74181_COUNT-1:0](.M(M),
										.S3(S[3]),.S2(S[2]),.S1(S[1]),.S0(S[0]),
										.B3N(insts_B3N),.B2N(insts_B2N),.B1N(insts_B1N),.B0N(insts_B0N),
										.A3N(insts_A3N),.A2N(insts_A2N),.A1N(insts_A1N),.A0N(insts_A0N),
										.F3N(insts_F3N),.F2N(insts_F2N),.F1N(insts_F1N),.F0N(insts_F0N),
										.CN(insts_CN[ALU_74181_COUNT-1:0]),.CN4(insts_CN[ALU_74181_COUNT:1])
										);
	
	assign CN4 						= insts_CN[ALU_74181_COUNT];
	assign insts_CN[0]			= CN;
	
	assign insts_A[WIDTH-1:0]	= A[WIDTH-1:0];
	assign insts_B[WIDTH-1:0]	= B[WIDTH-1:0];
	assign F[WIDTH-1:0]			= insts_F[WIDTH-1:0];
	
	generate
		genvar i;
		for(i = 0;i<ALU_74181_COUNT;i=i+1) begin : ALU_74181_insts_PIN_init
			assign insts_B3N[i] 		= insts_B[i*4+3];
			assign insts_B2N[i] 		= insts_B[i*4+2];
			assign insts_B1N[i] 		= insts_B[i*4+1];
			assign insts_B0N[i] 		= insts_B[i*4+0];
			assign insts_A3N[i] 		= insts_A[i*4+3];
			assign insts_A2N[i] 		= insts_A[i*4+2];
			assign insts_A1N[i] 		= insts_A[i*4+1];
			assign insts_A0N[i]		= insts_A[i*4+0];
			assign insts_F[i*4+3]	= insts_F3N[i];
			assign insts_F[i*4+2]	= insts_F2N[i];
			assign insts_F[i*4+1]	= insts_F1N[i];
			assign insts_F[i*4+0]	= insts_F0N[i];
		end
	endgenerate
endmodule