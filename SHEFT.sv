module SHEFT #(parameter integer WIDTH=16) (clk,m,s,d,q,flag);
	input					clk,m;
	input[1:0]			s;
	input[WIDTH-1:0]	d;
	output[WIDTH-1:0]	q;
	output[15:0]		flag;
	
	wire					cn;
	wire[2:0]			ctrl;
	reg[WIDTH:0]		data = {WIDTH{1'b0}};
	reg					c0 = 1'b0;
	
	assign	ctrl 				=	{s,m};
	assign	q[WIDTH-1:0]	=	data[WIDTH-1:0];
	assign	cn					=	data[WIDTH];
	
	Flag_helper#(WIDTH) Flag_helper_inst(.data(q),.CN(cn),.flag(flag));
	
	always@(posedge clk) begin : sheft
		reg	cy;
		casex(ctrl)
			3'b010: begin	//循环左移
				cy 					=	data[WIDTH-1];
				data[WIDTH:1]		=	data[WIDTH-1:0];
				data[0]				=	cy;
			end 
			3'b011: begin	//带进位循环左移
				data[WIDTH:1]		=	data[WIDTH-1:0];
				data[0]				=	c0;
			end
			3'b100: begin	//循环右移
				cy						=	data[0];
				data[WIDTH-2:0]	=	data[WIDTH-1:1];
				data[WIDTH-1]		=	cy;
				data[WIDTH]			=	cy;
			end
			3'b101: begin	//带进位循环右移
				cy						=	data[0];
				data[WIDTH-2:0]	=	data[WIDTH-1:1];
				data[WIDTH-1]		=	c0;
				data[WIDTH]			=	cy;
			end
			3'b110: begin	//装c0
				c0						=	d[0];
			end
			3'b111: begin	//装数
				data[WIDTH-1:0]	=	d[WIDTH-1:0];
			end
		endcase
	end
endmodule