module Flag_helper#(parameter integer WIDTH=16)(data,CN,flag);
	input[WIDTH-1:0]	data;
	input					CN;
	output[15:0]		flag;

	wire					OF,DF,IF,TF,SF,ZF,AF,PF,CF;
	assign	flag[15:0] = {1'b0,1'b0,1'b0,1'b0,OF,DF,IF,TF,SF,ZF,1'b0,AF,1'b0,PF,1'b0,CF};
	assign	OF	= 1'bz;
	assign	SF = 1'bz;				//符号位
	assign	ZF = ~(|data);			//0检验
	assign	PF = ~(^data);			//奇偶校验
	assign	CF = CN;					//无符号进位
	assign	DF = 1'bZ;				//字符串方向
	assign	IF = 1'bZ;				//中断允许
	assign	TF = 1'bZ;				//单步调试
	assign	AF = 1'bZ;				//4bit辅助进位
endmodule