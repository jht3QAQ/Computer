module uControl#(parameter integer WIDTH=16)(clk,P,SWA,SWB,UA,IR,ucode,addr,bus,
															AD1_sel,AD2_sel,AD1_reg,AD2_reg,
															DAT1_sel,DAT2_sel,DAT1_reg,DAT2_reg);
	localparam		P1				= 4'b0001;
	localparam		P2				= 4'b0010;
	localparam		P3				= 4'b0011;
	localparam		P4				= 4'b0100;
	
	localparam		KWE			= 2'b01;
	localparam		KRD			= 2'b10;
	localparam		RP				= 2'b11;
	
	input					clk;
	input[3:0]			P;				//ucode C字段
	input[7:0]			UA;			
	input[15:0]			IR;			//ucode UA字段
	input					SWA,SWB;
	
	input[WIDTH-1:0]	bus;
	input					AD1_sel,AD2_sel;
	output[WIDTH-1:0]	AD1_reg,AD2_reg;
	common_reg#(16)	AD1_reg_inst(.clk(AD1_sel),.in(bus),.out(AD1_reg));
	common_reg#(16)	AD2_reg_inst(.clk(AD2_sel),.in(bus),.out(AD2_reg));
	input					DAT1_sel,DAT2_sel;
	output[WIDTH-1:0]	DAT1_reg,DAT2_reg;
	common_reg#(16)	DAT1_reg_inst(.clk(DAT1_sel),.in(bus),.out(DAT1_reg));
	common_reg#(16)	DAT2_reg_inst(.clk(DAT2_sel),.in(bus),.out(DAT2_reg));
	
	wire[7:0]		IR_UA;		//ucode UA字段
	wire[3:0]		AD1,AD2;
	assign			{IR_UA,AD1,AD2} = IR;
	
	
	output[7:0]		addr;
	output[27:0]	ucode;		//ucode地址
	reg[27:0]		ucode;
	
	wire[1:0] 	SW;
	assign		SW = {SWB,SWA};
	
	//微控制器 处理C字段(即P(1)~P(4))
	always@(posedge clk) begin
		case(P)
			P1:			addr = IR_UA;
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
		ucode = ucode_table(addr,AD1,AD2);
	end
	
	function [27:0] ucode_table;
		//A字段
		parameter	LDR0			= 5'b00001;
		parameter	LDR1			= 5'b00010;
		parameter	LDR2			= 5'b00011;
		parameter	LDDR1			= 5'b00100;
		parameter	LDDR2			= 5'b00101;
		parameter	LDALUCN		= 5'b00110;
		parameter	LDSHEFT		= 5'b00111;
		parameter	LDFLAG		= 5'b01000;
		parameter	LDRAM			= 5'b01001;
		parameter	LDRAMD		= 5'b01010;	//原LDAR
		parameter	LDPC			= 5'b01011;	//原LOAD
		parameter	INCPC			= 5'b01100;	//PC自增单独占一个周期
		parameter	LDLED			= 5'b01101;	//原LED_B
		parameter	LDIR			= 5'b01110;
		parameter	LDAD1			= 5'b01111;
		parameter	LDAD2			= 5'b10000;
		parameter	LDDAT1		= 5'b10001;
		parameter	LDDAT2		= 5'b10010;
		//B字段
		parameter	ELFAG_B		= 5'b00000;
		parameter	INPUT_B		= 5'b00001;
		parameter	R0_B			= 5'b00010;
		parameter	R1_B			= 5'b00011;
		parameter	R2_B			= 5'b00100;
		parameter	ALU_B			= 5'b00101;
		parameter	ALU_FLAG		= 5'b00110;
		parameter	SHEFT_B		= 5'b00111;
		parameter	SHEFT_FLAG	= 5'b01000;
		parameter	FLAG			= 5'b01001;
		parameter	RAM_B			= 5'b01010;
		parameter	PC_B			= 5'b01011;
		parameter	AD1_B			= 5'b01100;
		parameter	AD2_B			= 5'b01101;
		parameter	DAT1_B		= 5'b01110;
		parameter	DAT2_B		= 5'b01111;
		//C字段
		parameter	P1				= 4'b0001;
		parameter	P2				= 4'b0010;
		parameter	P3				= 4'b0011;
		parameter	P4				= 4'b0100;
		
		parameter	RDAR0			= 4'b0001;
		parameter	RDAR1			= 4'b0010;
		parameter	RDAR2			= 4'b0011;
		parameter	DA				= 4'b0100;	//直接寻址
		parameter	IA				= 4'b0101;	//间接寻址
		parameter	AA				= 4'b0110;	//变址寻址 RI寄存器暂定为R2
		parameter	RA				= 4'b0111;	//相对寻址
		parameter	IMMA			= 4'b1000;	//立即数寻址
		parameter	DAR0			= 4'b1001;	//R0直接寻址
		parameter	DAR1			= 4'b1010;	//R1直接寻址
		parameter	DAR2			= 4'b1011;	//R2直接寻址
		
		input[7:0]				addr;
		input[3:0]				AD1,AD2;
		
		case(addr)
			//														目标		源							下一条指令
			//							S			M		WE		A字段		B字段			C字段		UA字段
			//控制台指令
			8'h00:ucode_table = {4'b0,		1'b0,	1'b0,	5'b00,	5'b00,		P4,		8'h00};	//检测SWA SWB 通过P4生成微地址
			//控制台写(KWE)	
			8'h01:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h02};	//PC		-> AR		
			8'h02:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h03};	//PC = PC + 1
			8'h03:ucode_table = {4'b0,		1'b0,	1'b1,	LDRAM,	INPUT_B,		P4,		8'h00};	//INPUT	-> RAM
			//控制台读(KRD)
			8'h04:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h05};	//PC		-> AR		
			8'h05:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h06};	//PC = PC + 1
			8'h06:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h07};	//LDRAM
			8'h07:ucode_table = {4'b0,		1'b0,	1'b0,	LDLED,	RAM_B,		P4,		8'h00};	//RAM		-> LED
			//控制台执行(RP)
			8'h08:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h09};	//PC		-> AR		
			8'h09:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h0A};	//PC = PC + 1
			8'h0A:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h0B};	//LDRAM
			8'h0B:ucode_table = {4'b0,		1'b0,	1'b0,	LDIR,		RAM_B,		4'b0,		8'h0C};	//RAM		-> IR
			//AD1
			8'h0C:
			case(AD1)
				RDAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	R0_B,			4'b0,		8'h33};	//R0		-> DAT1
				RDAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	R1_B,			4'b0,		8'h33};	//R1		-> DAT1
				RDAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	R2_B,			4'b0,		8'h33};	//R2		-> DAT1
				DA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h0D};	//PC		-> AR
				IA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h13};	//PC		-> AR
				AA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h1B};	//PC		-> AR
				RA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h24};	//PC		-> AR
				IMMA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h2D};	//PC		-> AR
				DAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD1,	R0_B,			4'b0,		8'h30};	//R0		-> AD1
				DAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD1,	R1_B,			4'b0,		8'h30};	//R1		-> AD1
				DAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD1,	R2_B,			4'b0,		8'h30};	//R2		-> AD1
				default:
					ucode_table = {4'b0,		1'b0,	1'b0,	5'b00,	5'b00,		4'b0,		8'h33};
			endcase
			//DA
			8'h0D:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h0E};	//PC = PC + 1
			8'h0E:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h0F};	//LDRAM
			8'h0F:ucode_table = {4'b0,		1'b0,	1'b0,	LDAD1,	RAM_B,		4'b0,		8'h10};	//RAM		-> AD1
			8'h10:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h11};	//RAM		-> AR
			8'h11:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h12};	//LDRAM
			8'h12:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//IA
			8'h13:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h14};	//PC = PC + 1
			8'h14:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h15};	//LDRAM
			8'h15:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h16};	//RAM		-> AR
			8'h16:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h17};	//LDRAM
			8'h17:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h18};	//RAM		-> AD1
			8'h18:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h19};	//RAM		-> AR
			8'h19:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h1A};	//LDRAM
			8'h1A:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//AA
			8'h1B:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h1C};	//PC = PC + 1
			8'h1C:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h1D};	//LDRAM
			8'h1D:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	RAM_B,		4'b0,		8'h1E};	//RAM		-> DR1
			8'h1E:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	R2_B,			4'b0,		8'h1F};	//R2		-> DR2
			8'h1F:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,		8'h20};	//EFLAG	-> ALUCN
			8'h20:ucode_table = {4'b1001,	1'b0,	1'b0,	LDAD1,	ALU_B,		4'b0,		8'h21};	//DR1+DR2-> AD1
			8'h21:ucode_table = {4'b1001,	1'b0,	1'b0,	LDRAMD,	AD1_B,		4'b0,		8'h22};	//AD1		-> AR
			8'h22:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h23};	//LDRAM
			8'h23:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//RA
			8'h24:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h25};	//PC = PC + 1
			8'h25:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h26};	//LDRAM
			8'h26:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	RAM_B,		4'b0,		8'h27};	//RAM		-> DR1
			8'h27:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	PC_B,			4'b0,		8'h28};	//PC		-> DR2
			8'h28:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,		8'h29};	//EFLAG	-> ALUCN
			8'h29:ucode_table = {4'b1001,	1'b0,	1'b0,	LDAD1,	ALU_B,		4'b0,		8'h2A};	//DR1+DR2-> AD1
			8'h2A:ucode_table = {4'b1001,	1'b0,	1'b0,	LDRAMD,	AD1_B,		4'b0,		8'h2B};	//AD1		-> AR
			8'h2B:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h2C};	//LDRAM
			8'h2C:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//IMMA
			8'h2D:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h2E};	//PC = PC + 1
			8'h2E:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h2F};	//LDRAM
			8'h2F:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//DARX
			8'h30:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	AD1_B,		4'b0,		8'h31};	//AD1		-> AR
			8'h31:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h32};	//LDRAM
			8'h32:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT1,	RAM_B,		4'b0,		8'h33};	//RAM		-> DAT1
			//AD2
			8'h33:
			case(AD2)
				RDAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	R0_B,			P1,		8'h00};	//R0		-> DAT2
				RDAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	R1_B,			P1,		8'h00};	//R1		-> DAT2
				RDAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	R2_B,			P1,		8'h00};	//R2		-> DAT2
				DA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h34};	//PC		-> AR
				IA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h3A};	//PC		-> AR
				AA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h42};	//PC		-> AR
				RA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h4B};	//PC		-> AR
				IMMA:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	PC_B,			4'b0,		8'h54};	//PC		-> AR
				DAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD2,	R0_B,			4'b0,		8'h57};	//R0		-> AD2
				DAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD2,	R1_B,			4'b0,		8'h57};	//R1		-> AD2
				DAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDAD2,	R2_B,			4'b0,		8'h57};	//R2		-> AD2
				default:
					ucode_table = {4'b0,		1'b0,	1'b0,	5'b00,	5'b00,		P1,		8'h00};
			endcase
			//DA
			8'h34:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h35};	//PC = PC + 1
			8'h35:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h36};	//LDRAM
			8'h36:ucode_table = {4'b0,		1'b0,	1'b0,	LDAD2,	RAM_B,		4'b0,		8'h37};	//RAM		-> AD2
			8'h37:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h38};	//RAM		-> AR
			8'h38:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h39};	//LDRAM
			8'h39:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//IA
			8'h3A:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h3B};	//PC = PC + 1
			8'h3B:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h3C};	//LDRAM
			8'h3C:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h3D};	//RAM		-> AR
			8'h3D:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h3E};	//LDRAM
			8'h3E:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		4'b0,		8'h3F};	//RAM		-> AD2
			8'h3F:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	RAM_B,		4'b0,		8'h40};	//RAM		-> AR
			8'h40:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h41};	//LDRAM
			8'h41:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//AA
			8'h42:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h43};	//PC = PC + 1
			8'h43:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h44};	//LDRAM
			8'h44:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	RAM_B,		4'b0,		8'h45};	//RAM		-> DR1
			8'h45:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	R2_B,			4'b0,		8'h46};	//R2		-> DR2
			8'h46:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,		8'h47};	//EFLAG	-> ALUCN
			8'h47:ucode_table = {4'b1001,	1'b0,	1'b0,	LDAD2,	ALU_B,		4'b0,		8'h48};	//DR1+DR2-> AD2
			8'h48:ucode_table = {4'b1001,	1'b0,	1'b0,	LDRAMD,	AD2_B,		4'b0,		8'h49};	//AD2		-> AR
			8'h49:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h4A};	//LDRAM
			8'h4A:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//RA
			8'h4B:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h4C};	//PC = PC + 1
			8'h4C:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h4D};	//LDRAM
			8'h4D:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	RAM_B,		4'b0,		8'h4E};	//RAM		-> DR1
			8'h4E:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	PC_B,			4'b0,		8'h4F};	//PC		-> DR2
			8'h4F:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,		8'h50};	//EFLAG	-> ALUCN
			8'h50:ucode_table = {4'b1001,	1'b0,	1'b0,	LDAD2,	ALU_B,		4'b0,		8'h51};	//DR1+DR2-> AD2
			8'h51:ucode_table = {4'b1001,	1'b0,	1'b0,	LDRAMD,	AD2_B,		4'b0,		8'h52};	//AD2		-> AR
			8'h52:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h53};	//LDRAM
			8'h53:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//IMMA
			8'h54:ucode_table = {4'b0,		1'b0,	1'b0,	INCPC,	5'b00,		4'b0,		8'h55};	//PC = PC + 1
			8'h55:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h56};	//LDRAM
			8'h56:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//DARX
			8'h57:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	AD2_B,		4'b0,		8'h58};	//AD2		-> AR
			8'h58:ucode_table = {4'b0,		1'b0,	1'b0,	LDRAM,	5'b00,		4'b0,		8'h59};	//LDRAM
			8'h59:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	RAM_B,		P1,		8'h00};	//RAM		-> DAT2
			//WAD1
			8'h5A:
			case(AD1)
				RDAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR0,		DAT1_B,		4'b0,		8'h5C};	//DAT1	-> R0
				RDAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR1,		DAT1_B,		4'b0,		8'h5C};	//DAT1	-> R1
				RDAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR2,		DAT1_B,		4'b0,		8'h5C};	//DAT1	-> R2
				DA,IA,AA,RA,DAR0,DAR1,DAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	AD1_B,		4'b0,		8'h5B};	//AD1		-> IR
				default:
					ucode_table = {4'b0,		1'b0,	1'b0,	5'b00,	5'b00,		4'b0,		8'h5C};
			endcase
			8'h5B:ucode_table = {4'b0,		1'b0,	1'b1,	LDRAM,	DAT1_B,		4'b0,		8'h5C};	//DAT1	-> RAM
			//WAD1
			8'h5C:
			case(AD2)
				RDAR0:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR0,		DAT2_B,		4'b0,		8'h08};	//DAT2	-> R0
				RDAR1:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR1,		DAT2_B,		4'b0,		8'h08};	//DAT2	-> R1
				RDAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDR2,		DAT2_B,		4'b0,		8'h08};	//DAT2	-> R2
				DA,IA,AA,RA,DAR0,DAR1,DAR2:
					ucode_table = {4'b0,		1'b0,	1'b0,	LDRAMD,	AD2_B,		4'b0,		8'h5D};	//AD2		-> IR
				default:
					ucode_table = {4'b0,		1'b0,	1'b0,	5'b00,	5'b00,		4'b0,		8'h08};
			endcase
			8'h5D:ucode_table = {4'b0,		1'b0,	1'b1,	LDRAM,	DAT2_B,		4'b0,		8'h08};	//DAT2	-> RAM
			//WAD2
			//IN	->	DAT2 = INPUT
			8'h5E:ucode_table = {4'b0,		1'b0,	1'b0,	LDDAT2,	INPUT_B,		4'b0,		8'h5A};	//INPUT	-> DAT2
			//ADD	-> DAT2 = DAT1 + DAT2
			8'h5F:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	ELFAG_B,		4'b0,		8'h61};	//EFLAG	-> ALUCN
			//ADC ->	DAT2 = DAT1 + DAT2 + CN
			8'h60:ucode_table = {4'b0,		1'b0,	1'b0,	LDALUCN,	FLAG,			4'b0,		8'h61};	//FLAG	-> ALUCN
			8'h61:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR2,	DAT2_B,		4'b0,		8'h62};	//DAT2	-> DR2
			8'h62:ucode_table = {4'b0,		1'b0,	1'b0,	LDDR1,	DAT1_B,		4'b0,		8'h63};	//DAT1	-> DR1
			8'h63:ucode_table = {4'b1001,	1'b0,	1'b0,	LDDAT2,	ALU_B,		4'b0,		8'h64};	//DR1+DR2-> DAT2
			8'h64:ucode_table = {4'b1001,	1'b0,	1'b0,	LDFLAG,	ALU_FLAG,	4'b0,		8'h5A};	//DR1+DR2-> FLAG
			//STA	->	DAT2 = DAT1
			8'h65:ucode_table = {4'b0,		1'b0,	1'b1,	LDDAT2,	DAT1_B,		4'b0,		8'h5A};	//DAT1	-> DAT2
			//OUT	->	input	= DAT1
			8'h66:ucode_table = {4'b0,		1'b0,	1'b1,	LDLED,	DAT1_B,		4'b0,		8'h5A};	//DAT1	-> LED
			//JMP	->	PC = DAT1
			8'h67:ucode_table = {4'b0,		1'b0,	1'b0,	LDPC,		DAT1_B,		4'b0,		8'h5A};	//DAT1	-> AR
			//RR	->	DAT2 = DAT1 循环右移
			8'h68:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	DAT1_B,		4'b0,		8'h69};	//DAT1	-> SHEFT
			8'h69:ucode_table = {4'b10,	1'b0,	1'b0,	LDSHEFT,	5'b00,		4'b0,		8'h6A};	//循环右移
			8'h6A:ucode_table = {4'b00,	1'b0,	1'b0,	LDDAT2,	SHEFT_B,		4'b0,		8'h6B};	//SHEFT	-> DAT2
			8'h6B:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,		8'h5A};	//SHEFT	-> FLAG
			//RRC	->	DAT2 = DAT1 带进位循环右移
			8'h6C:ucode_table = {4'b11,	1'b0,	1'b0,	LDSHEFT,	FLAG,			4'b0,		8'h6D};	//FLAG	-> SHEFT
			8'h6D:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	DAT1_B,		4'b0,		8'h6E};	//DAT1	-> SHEFT
			8'h6E:ucode_table = {4'b10,	1'b1,	1'b0,	LDSHEFT,	5'b00,		4'b0,		8'h6F};	//带进位循环右移
			8'h6F:ucode_table = {4'b00,	1'b0,	1'b0,	LDDAT2,	SHEFT_B,		4'b0,		8'h70};	//SHEFT	-> DAT2
			8'h70:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,		8'h5A};	//SHEFT	-> FLAG
			//RL	-> DAT2 = DAT1 循环左移
			8'h71:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	DAT1_B,		4'b0,		8'h72};	//DAT1	-> SHEFT
			8'h72:ucode_table = {4'b01,	1'b0,	1'b0,	LDSHEFT,	5'b00,		4'b0,		8'h73};	//循环左移
			8'h73:ucode_table = {4'b00,	1'b0,	1'b0,	LDDAT2,	SHEFT_B,		4'b0,		8'h74};	//SHEFT	-> DAT2
			8'h74:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,		8'h5A};	//SHEFT	-> FLAG
			//RLC	-> DAT2 = DAT1 带进位循环左移
			8'h75:ucode_table = {4'b11,	1'b0,	1'b0,	LDSHEFT,	FLAG,			4'b0,		8'h76};	//FLAG	-> SHEFT
			8'h76:ucode_table = {4'b11,	1'b1,	1'b0,	LDSHEFT,	DAT1_B,		4'b0,		8'h77};	//DAT1	-> SHEFT
			8'h77:ucode_table = {4'b01,	1'b1,	1'b0,	LDSHEFT,	5'b00,		4'b0,		8'h78};	//带进位循环左移
			8'h78:ucode_table = {4'b00,	1'b0,	1'b0,	LDDAT2,	SHEFT_B,		4'b0,		8'h79};	//SHEFT	-> DAT2
			8'h79:ucode_table = {4'b00,	1'b0,	1'b0,	LDFLAG,	SHEFT_FLAG,	4'b0,		8'h5A};	//SHEFT	-> FLAG
			default:	ucode_table = 28'b0;
		endcase
	endfunction
endmodule