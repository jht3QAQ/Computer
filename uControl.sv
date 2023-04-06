module uControl(clk,P,SWA,SWB,UA,IR,ucode,addr);
	parameter		P1				= 4'b0001;
	parameter		P2				= 4'b0010;
	parameter		P3				= 4'b0011;
	parameter		P4				= 4'b0100;
	parameter		PLDPC			= 4'b0110;
	
	parameter		KWE			= 2'b01;
	parameter		KRD			= 2'b10;
	parameter		RP				= 2'b11;
	
	input				clk;
	input[3:0]		P;				//ucode C字段
	input[7:0]		UA;			//ucode UA字段
	input[7:0]		IR;			//ucode UA字段
	input				SWA,SWB;
	
	
	output[7:0]		addr;
	output[25:0]	ucode;		//ucode地址
	reg[25:0]		ucode;
	
	wire[1:0] 	SW;
	assign		SW = {SWB,SWA};
	
	//微控制器 处理C字段(即P(1)~P(4))
	always@(posedge clk) begin
		case(P)
			P1:			addr = IR;
			P4:begin
				case(SW)
					KWE:	addr = 8'h01;
					KRD:	addr = 8'h04;
					RP:	addr = 8'h08;
					default:	addr = 8'h00;
				endcase
			end
			default:		addr = UA;
		endcase
		ucode = ucode_table(addr);
	end
	
	function [25:0] ucode_table;
		//A字段
		parameter	LDR0			= 4'b0001;
		parameter	LDR1			= 4'b0010;
		parameter	LDR2			= 4'b0011;
		parameter	LDDR1			= 4'b0100;
		parameter	LDDR2			= 4'b0101;
		parameter	LDALUCN		= 4'b0110;
		parameter	LDSHEFT		= 4'b0111;
		parameter	LDFLAG		= 4'b1000;
		parameter	LDRAM			= 4'b1001;
		parameter	LDRAMD		= 4'b1010;	//原LDAR
		parameter	LDPC			= 4'b1011;	//原LOAD
		parameter	INCPC			= 4'b1100;	//PC自增单独占一个周期
		parameter	LDLED			= 4'b1101;	//原LED_B
		parameter	LDIR			= 4'b1110;
		//B字段
		parameter	ELFAG_B		= 4'b0000;
		parameter	INPUT_B		= 4'b0001;
		parameter	R0_B			= 4'b0010;
		parameter	R1_B			= 4'b0011;
		parameter	R2_B			= 4'b0100;
		parameter	ALU_B			= 4'b0101;
		parameter	ALU_FLAG		= 4'b0110;
		parameter	SHEFT_B		= 4'b0111;
		parameter	SHEFT_FLAG	= 4'b1000;
		parameter	FLAG			= 4'b1001;
		parameter	RAM_B			= 4'b1010;
		parameter	PC_B			= 4'b1011;
		//C字段
		parameter	P1				= 4'b0001;
		parameter	P2				= 4'b0010;
		parameter	P3				= 4'b0011;
		parameter	P4				= 4'b0100;
		
		input[7:0]				addr;
		
		case(addr)
			//														目标		源					下一条指令
			//							S			M		WE		A字段		B字段			C字段	UA字段
			//控制台指令
			8'h00:ucode_table = {4'b0,		1'b0,	1'b0,	4'b00,	4'b00,		P4,	8'h00};	//检测SWA SWB 通过P4生成微地址
			//控制台写(KWE)	
			8'h01:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h02};	//PC		-> AR		
			8'h02:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h03};	//PC = PC + 1
			8'h03:ucode_table = {4'b0,		1'b0,	1'b1,	LDRAM,	INPUT_B,		P4,	8'h00};	//INPUT	-> RAM
			//控制台读(KRD)
			8'h04:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h05};	//PC		-> AR		
			8'h05:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h06};	//PC = PC + 1
			8'h06:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h07};	//LDRAM
			8'h07:ucode_table = {4'b0,		1'b0,	1'b0,	LDLED,	RAM_B,		P4,	8'h00};	//RAM		-> LED
			//控制台执行(RP)
			8'h08:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h09};	//PC		-> AR		
			8'h09:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h0A};	//PC = PC + 1
			8'h0A:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h0B};	//LDRAM
			8'h0B:ucode_table = {4'b0,		1'b0,	1'b0,	LDIR,		RAM_B,		P1,	8'h00};	//RAM		-> IR
			//IN
			8'h0C:ucode_table = {4'b0,		1'b0,	1'b0,	LDR0,		INPUT_B,		4'b0,	8'h08};	//INPUT	-> R0
			//ADD[addr]	-> R0 = R0 + [addr]
			8'h0D:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,	8'h0F};	//EFLAG	-> ALUCN
			//ADC[addr]	->	R0 = R0 + [addr] + CN
			8'h0E:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	FLAG,			4'b0,	8'h0F};	//FLAG	-> ALUCN
			8'h0F:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h10};	//PC		-> AR		
			8'h10:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h11};	//PC = PC + 1
			8'h11:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h12};	//LDRAM
			8'h12:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,	8'h13};	//RAM		-> AR
			8'h13:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h14};	//LDRAM
			8'h14:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	RAM_B,		4'b0,	8'h15};	//RAM		-> DR2
			8'h15:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	R0_B,			4'b0,	8'h16};	//R0		-> DR1
			8'h16:ucode_table = {4'b1001,	1'b0,	1'b0,	LDR0,		ALU_B,		4'b0,	8'h17};	//DR1+DR2-> R0
			8'h17:ucode_table = {4'b1001,	1'b0,	1'b0,	LDFLAG,	ALU_FLAG,	4'b0,	8'h08};	//DR1+DR2-> FLAG
			//STA[addr]	->	[addr] = R0
			8'h18:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h19};	//PC		-> AR		
			8'h19:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h1A};	//PC = PC + 1
			8'h1A:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h1B};	//LDRAM
			8'h1B:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,	8'h1C};	//RAM		-> AR
			8'h1C:ucode_table = {4'b0,		1'b0,	1'b1,	LDRAM,	R0_B,			4'b0,	8'h08};	//R0		-> RAM
			//OUT[addr]	->	input	= [addr]
			8'h1D:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h1E};	//PC		-> AR		
			8'h1E:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h1F};	//PC = PC + 1
			8'h1F:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h20};	//LDRAM
			8'h20:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,	8'h21};	//RAM		-> AR
			8'h21:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h22};	//LDRAM
			8'h22:ucode_table = {4'b0,		1'b0,	1'b1,	LDLED,	RAM_B,		4'b0,	8'h08};	//RAM		-> LED
			//JMP[addr]	->	PC = addr
			8'h23:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,	8'h24};	//PC		-> AR		
			8'h24:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	4'b00,		4'b0,	8'h25};	//PC = PC + 1
			8'h25:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	4'b00,		4'b0,	8'h26};	//LDRAM
			8'h26:ucode_table = {4'b0,		1'b0,	1'b0,	LDPC,		RAM_B,		4'b0,	8'h08};	//RAM		-> AR
			//RR			->	R0 循环右移
			8'h27:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	R0_B,			4'b0,	8'h28};	//R0		-> SHEFT
			8'h28:ucode_table = {4'b10,	1'b0,	1'b0,	LDSHEFT,	4'b00,		4'b0,	8'h29};	//R0 循环右移
			8'h29:ucode_table = {4'b00,	1'b0,	1'b0,	LDR0,		SHEFT_B,		4'b0,	8'h2A};	//SHEFT	-> R0
			8'h2A:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,	8'h08};	//SHEFT	-> FLAG
			//RRC			->	R0 带进位循环右移
			8'h2B:ucode_table = {4'b11,	1'b0,	1'b0,	LDSHEFT,	FLAG,			4'b0,	8'h2C};	//FLAG	-> SHEFT
			8'h2C:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	R0_B,			4'b0,	8'h2D};	//R0		-> SHEFT
			8'h2D:ucode_table = {4'b10,	1'b1,	1'b0,	LDSHEFT,	4'b00,		4'b0,	8'h2E};	//R0 带进位循环右移
			8'h2E:ucode_table = {4'b00,	1'b0,	1'b0,	LDR0,		SHEFT_B,		4'b0,	8'h2F};	//SHEFT	-> R0
			8'h2F:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,	8'h08};	//SHEFT	-> FLAG
			//RL			-> R0 循环左移
			8'h30:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	R0_B,			4'b0,	8'h31};	//R0		-> SHEFT
			8'h31:ucode_table = {4'b01,	1'b0,	1'b0,	LDSHEFT,	4'b00,		4'b0,	8'h32};	//R0 循环左移
			8'h32:ucode_table = {4'b00,	1'b0,	1'b0,	LDR0,		SHEFT_B,		4'b0,	8'h33};	//SHEFT	-> R0
			8'h33:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,	8'h08};	//SHEFT	-> FLAG
			//RLC			-> R0 带进位循环左移
			8'h34:ucode_table = {4'b11,	1'b0,	1'b0,	LDSHEFT,	FLAG,			4'b0,	8'h35};	//FLAG	-> SHEFT
			8'h35:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	R0_B,			4'b0,	8'h36};	//R0		-> SHEFT
			8'h36:ucode_table = {4'b01,	1'b1,	1'b0,	LDSHEFT,	4'b00,		4'b0,	8'h37};	//R0 带进位循环左移
			8'h37:ucode_table = {4'b00,	1'b0,	1'b0,	LDR0,		SHEFT_B,		4'b0,	8'h38};	//SHEFT	-> R0
			8'h38:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,	8'h08};	//SHEFT	-> FLAG
			default:	ucode_table = 26'b0;
		endcase
	endfunction
endmodule