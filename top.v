module top(
    input Clk,
    input Rst,
    input data_in,
    input error_add,
    output data_out,
    output error_flag,   
    output Clk_2048,
    output Clk_64K,
    output Clk_8K,
    output reg Clk_8K_delay
);
wire Clk_8192;
wire Clk_4096;
wire locked;
PLL inst_pll(//输入50M，输出8.192M 50%
    .clk_8192(Clk_8192),    
    .reset(!Rst), 
    .locked(locked), 
    .clk_in1(Clk)
); 
divider inst_divider_0(//输入8.192M，输出2.048M 50%
    .clk_in(Clk_8192),      
    .Rst(Rst),      
    .div_ratio(16'd4),  
    .duty_cycle(16'd2),  
    .clk_out(Clk_2048)      
);
divider inst_divider_1(//输入2.048M，输出64K 50%
    .clk_in(Clk_2048),     
    .Rst(Rst),       
    .div_ratio(16'd32),   
    .duty_cycle(16'd16), 
    .clk_out(Clk_64K)      
);
divider inst_divider_2(//输入64K，输出8K 25%
    .clk_in(Clk_64K),      
    .Rst(Rst),       
    .div_ratio(16'd8),   
    .duty_cycle(16'd2),  
    .clk_out(Clk_8K)      
);
divider inst_divider_3(//输入8.192M，输出4.096M 50%
    .clk_in(Clk_8192),      
    .Rst(Rst),      
    .div_ratio(16'd2),  
    .duty_cycle(16'd1),  
    .clk_out(Clk_4096)      
);
wire data_out_coder;
wire enout_coder;
coder coder_inst0(
    .Clk_rec(Clk_2048),//接收时钟
    .Clk_code(Clk_4096),//编码时钟
    .Rst(Rst),
    .data_in(data_in),
    .data_out(data_out_coder),
    .enout(enout_coder),
    .error_add(error_add)
    );
wire [2:0]error_position;
decoder decoder_inst0(
    .Clk(Clk_4096),//译码时钟
    .Clk_out(Clk_2048),//发送时钟
    .Rst(Rst),
    .data_in(data_out_coder),
    .coder_out_valid(enout_coder),
    .dout(data_out),
    .error_flag(error_flag),
    .error_position(error_position)
);
reg [23:0] delay_reg; 

//时序逻辑实现25拍延迟
always @(posedge Clk_2048 or negedge Rst) begin
    if (!Rst) begin
        delay_reg <= 25'd0;
        Clk_8K_delay   <= 1'b0;
    end else begin
        delay_reg <= {delay_reg[22:0], Clk_8K};
        Clk_8K_delay   <= delay_reg[23];
    end
end
endmodule