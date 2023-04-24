module Computer#(parameter integer DATA_WIDTH=16)(clk,timing_clr,input_data,pc_clr,led_out,SWA,SWB,
					d_timing,
					d_uaddr,d_ucode_S,d_ucode_M,d_ucode_WE,d_ucode_A,d_ucode_B,d_ucode_C,d_ucode_UA,
					d_bus,
					d_RAM_out,d_RAM_addr,
					d_R0,
					d_PC_out,
					d_ALU_out,d_ALU_flag_out,
					d_FLAG,
					d_SHEFT_clk,d_SHEFT_out,d_SHEFT_flag
					);
	input							clk,timing_clr,pc_clr;
	input[DATA_WIDTH-1:0]	input_data;
	input							SWA,SWB;
	output[DATA_WIDTH-1:0]	led_out;
	
	//debug输出
	output[1:0]					d_timing;
	output[7:0]					d_uaddr;
	output[DATA_WIDTH-1:0]	d_bus;
	output[DATA_WIDTH-1:0]	d_RAM_out,d_RAM_addr;
	output[DATA_WIDTH-1:0]	d_R0;
	output[DATA_WIDTH-1:0]	d_PC_out;
	output[DATA_WIDTH-1:0]	d_ALU_out,d_ALU_flag_out;
	output[DATA_WIDTH-1:0]	d_FLAG;
	output[3:0]					d_ucode_S;
	output						d_ucode_M,d_ucode_WE;
	output[4:0]					d_ucode_A,d_ucode_B;
	output[3:0]					d_ucode_C;
	output[7:0]					d_ucode_UA;
	output						d_SHEFT_clk;
	output[DATA_WIDTH-1:0]	d_SHEFT_out,d_SHEFT_flag;
	
	
	//双周期的时钟发生器
	wire						ucode_gen_clk,ucode_exec_clk;
	wire[1:0]				clk_cycle;
	assign					clk_cycle[1:0]	= {ucode_gen_clk,ucode_exec_clk};
	Timing#(2)				Timing_inst(.clk(clk),.clr(timing_clr),.T(clk_cycle));
	assign					d_timing = clk_cycle;
	
	wire[DATA_WIDTH-1:0]	data_bus;
	wire[27:0]				ucode_bus;
	
	//ucode
	wire[3:0]				ucode_S;
	wire						ucode_M,ucode_WE;
	wire[4:0]				ucode_A,ucode_B;
	wire[3:0]				ucode_C;
	wire[7:0]				ucode_UA;
	assign					{ucode_S,ucode_M,ucode_WE,ucode_A,ucode_B,ucode_C,ucode_UA}=ucode_bus;
	
	//微控制器
	wire[15:0]				last_code;						//IR寄存器内容
	
	//A字段译码器 负责指明调用的器件
	wire						LDR0,LDR1,LDR2;				//REG:载入寄存器R0,载入寄存器R1,载入寄存器R2
	wire						LDDR1,LDDR2,LDALUCN;			//ALU:载入操作数A,载入操作数B,载入进位CN
	wire						LDSHEFT;							//LDSHEFT:载入位移器(配合ucode_S功能位选择载入进位CN或数据)
	wire						LDFLAG;							//LDFLAG:载入flag寄存器
	wire						LDRAM,LDRAMD;					//LDRAM:RAM进行读取/写入 LDRAMD:写入RAM地址
	wire						LDPC,INCPC;						//LDPC:写入PC计数器 INCPC:PC计数器自增
	wire						LDLED;							//LDLED:输出到LED
	wire						LDIR;								//LDIR:输出到IR寄存器
	wire						LDAD1,LDAD2;					//LDAD:ucontrol内部寻址寄存器
	wire						LDDAT1,LDDAT2;					//LDDAT:ucontrol内部寻址数据寄存器
	
	//总线以及MUX选择器输入
	wire[DATA_WIDTH-1:0]	EFLAG = {DATA_WIDTH{1'b0}};
	wire[DATA_WIDTH-1:0]	R0,R1,R2;
	wire[DATA_WIDTH-1:0]	ALU_out,ALU_flag_out;
	wire[DATA_WIDTH-1:0]	SHEFT_out,SHEFT_flag_out;
	wire[DATA_WIDTH-1:0]	flag;
	wire[DATA_WIDTH-1:0]	RAM_out;
	wire[DATA_WIDTH-1:0]	PC_out;
	wire[DATA_WIDTH-1:0]	AD1_out,AD2_out;
	wire[DATA_WIDTH-1:0]	DAT1_out,DAT2_out;
	
	wire						AD1_clk,AD2_clk;
	assign					AD1_clk	= LDAD1 && ucode_exec_clk;
	assign					AD2_clk	= LDAD2 && ucode_exec_clk;
	wire						DAT1_clk,DAT2_clk;
	assign					DAT1_clk	= LDDAT1 && ucode_exec_clk;
	assign					DAT2_clk	= LDDAT2 && ucode_exec_clk;
	uControl#(DATA_WIDTH)uControl_inst(	.clk(ucode_gen_clk),.P(ucode_C),.SWA(SWA),.SWB(SWB),.UA(ucode_UA),.IR(last_code),
													.ucode(ucode_bus),.addr(d_uaddr),
													.bus(data_bus),.AD1_sel(AD1_clk),.AD2_sel(AD2_clk),.AD1_reg(AD1_out),.AD2_reg(AD2_out),
													.DAT1_sel(DAT1_clk),.DAT2_sel(DAT2_clk),.DAT1_reg(DAT1_out),.DAT2_reg(DAT2_out));
	assign					d_ucode_S	= ucode_S,
								d_ucode_M	= ucode_M,
								d_ucode_WE	= ucode_WE,
								d_ucode_A	= ucode_A,
								d_ucode_B	= ucode_B,
								d_ucode_C	= ucode_C,
								d_ucode_UA	= ucode_UA;
	
	decode5_32				ucode_A_decoder(	.data(ucode_A),
														.eq1(LDR0),.eq2(LDR1),.eq3(LDR2),
														.eq4(LDDR1),.eq5(LDDR2),.eq6(LDALUCN),
														.eq7(LDSHEFT),
														.eq8(LDFLAG),
														.eq9(LDRAM),.eq10(LDRAMD),
														.eq11(LDPC),.eq12(INCPC),
														.eq13(LDLED),
														.eq14(LDIR),
														.eq15(LDAD1),.eq16(LDAD2),
														.eq17(LDDAT1),.eq18(LDDAT2),
														);

	lpm_mux5					data_bus_mux(	.sel(ucode_B),.result(data_bus),
													.data0x(EFLAG),
													.data1x(input_data),
													.data2x(R0),.data3x(R1),.data4x(R2),
													.data5x(ALU_out),.data6x(ALU_flag_out),
													.data7x(SHEFT_out),.data8x(SHEFT_flag_out),
													.data9x(flag),
													.data10x(RAM_out),
													.data11x(PC_out),
													.data12x(AD1_out),.data13x(AD2_out),
													.data14x(DAT1_out),.data15x(DAT2_out));
	assign					d_bus = data_bus;
	
	//执行元器件实例
	//ALU
	ALU#(DATA_WIDTH)				ALU_inst(.S(ucode_S),.M(ucode_M),.data(data_bus),.F(ALU_out),.flag(ALU_flag_out),
													.clk(ucode_exec_clk),.LDDR1(LDDR1),.LDDR2(LDDR2),.LDCN(LDALUCN));
	assign							d_ALU_out = ALU_out;
	assign							d_ALU_flag_out = ALU_flag_out;

	//位移器
	wire								SHEFT_clk;
	assign							SHEFT_clk = ucode_exec_clk && LDSHEFT;
	SHEFT#(DATA_WIDTH)			SHEFT_inst(	.clk(SHEFT_clk),.m(ucode_M),.s(ucode_S[1:0]),.d(data_bus),
														.q(SHEFT_out),.flag(SHEFT_flag_out));
	assign							d_SHEFT_clk = SHEFT_clk;
	assign							d_SHEFT_out = SHEFT_out, d_SHEFT_flag = SHEFT_flag_out;
	
	//寄存器组
	wire[2:0][DATA_WIDTH-1:0]	reg_group_out;
	assign							{R2,R1,R0} = reg_group_out;
	wire[2:0]						reg_group_ldr;
	assign							reg_group_ldr = {LDR2,LDR1,LDR0};
	reg_group#(DATA_WIDTH,3)	reg_group_inst(.clk(ucode_exec_clk),.LDR(reg_group_ldr),.data(data_bus),.R(reg_group_out));
	assign							d_R0 = reg_group_out[0];
	
	//flag寄存器
	wire								flag_reg_clk;
	assign							flag_reg_clk = ucode_exec_clk && LDFLAG;
	flag_reg							flag_reg_inst(.clk(flag_reg_clk),.in(data_bus),.out(flag));
	assign							d_FLAG = flag;
	
	//RAM
	RAM								ram_inst(.clk(ucode_exec_clk),.we(ucode_WE),.data(data_bus),.q(RAM_out),.LDRAM(LDRAM),.LDRAMD(LDRAMD),.qd(d_RAM_addr));
	assign							d_RAM_out = RAM_out;
	
	//PC计数器
	wire								PC_counter_clk;
	assign							PC_counter_clk = ucode_exec_clk&& (pc_clr || LDPC || INCPC);
	assign							d_PC_out = PC_out;
	PC_counter						PC_counter_inst(.clock(PC_counter_clk),.data(data_bus),.sclr(pc_clr),.sload(LDPC),.q(PC_out));
	
	//LED输出
	wire								LED_reg_clk;
	assign							LED_reg_clk = ucode_exec_clk && LDLED;
	LED_reg#(DATA_WIDTH)			LED_reg_inst(.clk(LED_reg_clk),.in(data_bus),.out(led_out));
	
	//IR寄存器
	wire								IR_reg_clk;
	assign							IR_reg_clk = ucode_exec_clk && LDIR;
	IR_reg							IR_reg_inst(.clk(IR_reg_clk),.in(data_bus),.out(last_code));
	
endmodule