module decoder(
    input Clk,
    input Clk_out,
    input Rst,
    input data_in,
    input coder_out_valid,
    output reg dout,
    output reg error_flag,
    output reg [2:0]error_position
);
/////////////////译码器接收数据/////////////////////
reg [2:0]rx_cnt;
reg [6:0]r_data_in;
reg rx_done;
reg en_in;
reg [3:0]data_out;
always @(posedge Clk or negedge Rst) begin
    if(!Rst)
        en_in<=1'b0;
    else begin
        if(coder_out_valid)
            en_in<=1'b1;
        else if(rx_cnt==3'd6)
            en_in<=1'b0;
    end
end
always @(posedge Clk or negedge Rst) begin
    if(!Rst)
        rx_cnt<=3'd0;
    else if(en_in)begin
        if(rx_cnt==3'd6)
            rx_cnt<=3'd0;
        else 
            rx_cnt<=rx_cnt+1;
    end
end

always @(posedge Clk or negedge Rst) begin
    if(!Rst)begin
        rx_done<=1'b0;
        r_data_in<=7'b0;
    end
    else begin
        case (rx_cnt)
            0: begin r_data_in[0]<=data_in;rx_done<=1'b0;end
            1: begin r_data_in[1]<=data_in;rx_done<=1'b0;end
            2: begin r_data_in[2]<=data_in;rx_done<=1'b0;end
            3: begin r_data_in[3]<=data_in;rx_done<=1'b0;end
            4: begin r_data_in[4]<=data_in;rx_done<=1'b0;end
            5: begin r_data_in[5]<=data_in;rx_done<=1'b0;end
            6: begin r_data_in[6]<=data_in;rx_done<=1'b1;end
        endcase
    end
end
    reg [6:0] rr_data_in;
    always @(posedge Clk or negedge Rst) begin
        if(!Rst)
            rr_data_in<=7'b0;
        else if(rx_done)
            rr_data_in<=r_data_in;
    end
/////////////纠错状态机逻辑(独热码)///////////////
parameter IDLE = 4'b0001;//空状态
parameter CALC_SYNDROME = 4'b0010;// 计算校验子状态
parameter CHECK_ERROR = 4'b0100;// 检查错误状态
parameter OUTPUT_DATA = 4'b1000;// 输出数据状态
reg [3:0]state;
reg [2:0] syndrome;// 校验子计算
reg [6:0] corrected_data;//改正后的数据
reg wr_en;
always @(posedge Clk or negedge Rst) begin
    if(!Rst)begin
        state<=IDLE;
        data_out<=4'b0;
        corrected_data <= 7'b0;
        error_flag<=1'b0;
        error_position<=3'b0;
        wr_en<=1'b0;
    end
    else begin
        case(state)
        IDLE:begin
            wr_en<=1'b0;
            if(rx_done)
                state<=CALC_SYNDROME;
        end
        CALC_SYNDROME:begin
            wr_en<=1'b0;
            syndrome[0]<=~(rr_data_in[6]^rr_data_in[4]^rr_data_in[2]^rr_data_in[0]);//低位
            syndrome[1]<=~(rr_data_in[6]^rr_data_in[5]^rr_data_in[2]^rr_data_in[1]);
            syndrome[2]<=~(rr_data_in[6]^rr_data_in[5]^rr_data_in[4]^rr_data_in[3]);//高位
            state<=CHECK_ERROR;
        end
        CHECK_ERROR:begin
            wr_en<=1'b0;
            corrected_data <= rr_data_in; // 默认无错误
            case (syndrome)
                3'b001: begin corrected_data[0] <= ~rr_data_in[0];error_flag <=1'b1;error_position<=syndrome;end//索引1错误
                3'b010: begin corrected_data[1] <= ~rr_data_in[1];error_flag <=1'b1;error_position<=syndrome;end//索引2错误
                3'b011: begin corrected_data[2] <= ~rr_data_in[2];error_flag <=1'b1;error_position<=syndrome;end//索引3错误
                3'b100: begin corrected_data[3] <= ~rr_data_in[3];error_flag <=1'b1;error_position<=syndrome;end//索引4错误
                3'b101: begin corrected_data[4] <= ~rr_data_in[4];error_flag <=1'b1;error_position<=syndrome;end//索引5错误
                3'b110: begin corrected_data[5] <= ~rr_data_in[5];error_flag <=1'b1;error_position<=syndrome;end//索引6错误
                3'b111: begin corrected_data[6] <= ~rr_data_in[6];error_flag <=1'b1;error_position<=syndrome;end//索引7错误
                default: begin corrected_data <= rr_data_in;error_flag <=1'b0;error_position<=3'b0;end//无错误
            endcase
            state<=OUTPUT_DATA;
        end
        OUTPUT_DATA:begin
            data_out <= {corrected_data[6], corrected_data[5], corrected_data[4], corrected_data[2]};
            wr_en<=1'b1;
            state<=IDLE;
        end
        endcase
    end
end
wire wr_rst_busy,rd_rst_busy;
wire full,empty;
wire [3:0]data_out_fifo;
wire rd_valid;
FIFO_1 inst_fifo_1 (
  .rst(!Rst),                  // input wire rst
  .wr_clk(Clk),            // input wire wr_clk
  .rd_clk(Clk_out),            // input wire rd_clk
  .din(data_out),                  // input wire [3 : 0] din
  .wr_en(wr_en&(!full)),              // input wire wr_en
  .rd_en(!empty),              // input wire rd_en
  .dout(data_out_fifo),                // output wire [3 : 0] dout
  .full(full),                // output wire full
  .valid(rd_valid),
  .empty(empty),              // output wire empty
  .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
  .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
);
reg [1:0]tx_cnt;
reg enout;
reg [3:0]r_data_out_fifo;
always @(posedge Clk_out or negedge Rst) begin
        if(!Rst)
            enout<=1'b0;
        else if(rd_valid)//读取有效
        begin
            enout<=1'b1;
            r_data_out_fifo<=data_out_fifo;
        end
        else if(tx_cnt == 2'd3)//发送完毕
            enout<=1'b0;
end
always @(posedge Clk_out or negedge Rst) begin
    if(!Rst)
        tx_cnt<=2'b0;
    else if((tx_cnt==2'd3)||(!enout))
        tx_cnt<=2'b0;
    else tx_cnt<=tx_cnt+1'b1;
end
reg r_dout;
reg rr_dout;
always @(posedge Clk_out or negedge Rst) begin
        if(!Rst)begin
            r_dout<=1'b0;
        end
        else if(enout)begin
            case (tx_cnt)
                2'd0: r_dout <= r_data_out_fifo[0];
                2'd1: r_dout <= r_data_out_fifo[1];
                2'd2: r_dout <= r_data_out_fifo[2];
                2'd3: r_dout <= r_data_out_fifo[3];
            endcase
        end
end
always @(posedge Clk_out) begin//延时打一拍
    rr_dout<=r_dout;
    dout<=rr_dout;
end
endmodule
