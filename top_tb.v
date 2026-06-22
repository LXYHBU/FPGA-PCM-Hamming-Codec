`timescale 1ns / 1ps
module top_tb();
reg Clk;
reg Rst;
reg data_in;
reg error_add;
wire data_out;
wire Clk_2048;
wire Clk_64K;
wire Clk_8K;
wire error_flag;
initial begin
    Clk=0;
    Rst=1;
    data_in=0;
    error_add=1;
    #20 Rst=0;
    #20 Rst=1;
    #448
    #250000
    #9272
    #244
    #488 data_in=1;
    #488 data_in=0;
    #488 data_in=1;
    #488 data_in=1;

    #488 data_in=1;
    #488 data_in=0;
    #488 data_in=1;
    #488 data_in=1;

    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=1;
    #488 data_in=1;
    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=1;
    #488 data_in=1;
    #488 data_in=1;
    #488 data_in=1;
    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=0;
    #488 data_in=0;


end
always #10 Clk<=~Clk;
top inst_top(
    .Clk(Clk),
    .Rst(Rst),
    .data_in(data_in),
    .error_flag(error_flag),
    .data_out(data_out),
    .error_add(error_add), 
    .Clk_2048(Clk_2048),
    .Clk_64K(Clk_64K),
    .Clk_8K(Clk_8K)
);
endmodule