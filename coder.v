module coder(
    input Clk_rec,
    input Clk_code,
    input error_add,
    input Rst,
    input data_in,
    output reg enout,
    output reg data_out
    );
    reg [3:0]r_data_in;
    reg [6:0] data_coded;
    ////////////串转并编码逻辑/////////////
    reg [1:0]rx_cnt;
    reg rx_done;
    always @(posedge Clk_rec or negedge Rst) begin//接收计数器
        if(!Rst)
            rx_cnt<=2'd0;
        else rx_cnt<=rx_cnt+2'd1;
    end

    always@(posedge Clk_rec or negedge Rst)begin
        if(!Rst)begin
            r_data_in<=4'b0;
            rx_done<=1'b0;
        end
        else begin
            case(rx_cnt)
                2'd0:begin r_data_in[0]<=data_in;rx_done<=1'b0;end
                2'd1:begin r_data_in[1]<=data_in;rx_done<=1'b0;end
                2'd2:begin r_data_in[2]<=data_in;rx_done<=1'b1;end
                2'd3:begin r_data_in[3]<=data_in;rx_done<=1'b0;end
            endcase
            end
    end
    reg wr_en,rd_en;
    wire rd_vaild;
    wire fifo_full,fifo_empty;
    wire [3:0]fifo_out;
    wire wr_rst_busy,rd_rst_busy;
    always @(posedge Clk_rec or negedge Rst) begin
        if(!Rst)
            wr_en<=1'b0;
        else if(rx_done&&(!fifo_full))
            wr_en<=1'b1;
        else 
            wr_en<=1'b0;
    end
    always @(posedge Clk_code or negedge Rst) begin
        if(!Rst)
            rd_en<=1'b0;
        else if(!fifo_empty)
            rd_en<=1'b1;
        else 
            rd_en<=1'b0;
    end
    FIFO_0 inst_fifo (                 
        .rst(!Rst),                  // input wire rst
        .wr_clk(Clk_rec),            // input wire wr_clk
        .rd_clk(Clk_code),            // input wire rd_clk
        .din(r_data_in),                  // input wire [3 : 0] din
        .wr_en(wr_en),              // input wire wr_en
        .rd_en(rd_en),              // input wire rd_en
        .dout(fifo_out),                // output wire [3 : 0] dout
        .full(fifo_full),                // output wire full
        .valid(rd_valid),              // output wire valid
        .empty(fifo_empty),              // output wire empty
        .wr_rst_busy(wr_rst_busy),  // output wire wr_rst_busy
        .rd_rst_busy(rd_rst_busy)  // output wire rd_rst_busy
        );

    wire check_1,check_2,check_3;
    assign check_1=~(fifo_out[3]^fifo_out[1]^fifo_out[0]);
    assign check_2=~(fifo_out[3]^fifo_out[2]^fifo_out[0]);
    assign check_3=~(fifo_out[3]^fifo_out[2]^fifo_out[1]);

    always @(posedge Clk_code or negedge Rst) begin
        if(!Rst)
            data_coded<=7'b0;
        else if (rd_valid)begin
            data_coded[0]<=check_1;
            data_coded[1]<=check_2;
            data_coded[2]<=fifo_out[0];
            data_coded[3]<=check_3;
            data_coded[4]<=fifo_out[1];
            data_coded[5]<=fifo_out[2];
            data_coded[6]<=fifo_out[3];
        end
    end
    ////////////并转串发送逻辑/////////////
    //reg enout;
    reg [2:0]tx_cnt;
    always @(posedge Clk_code or negedge Rst) begin
        if(!Rst)
            enout<=1'b0;
        else if(rd_valid)//读取有效
            enout<=1'b1;
        else if(tx_cnt == 3'd6)//发送完毕
            enout<=1'b0;
    end

    always @(posedge Clk_code or negedge Rst) begin
        if(!Rst)
            tx_cnt<=3'd0;
        else if((tx_cnt==3'd6)||(!enout))
            tx_cnt<=3'd0;
        else 
            tx_cnt<=tx_cnt+1'd1;
    end
    always @(posedge Clk_code or negedge Rst) begin
        if(!Rst)begin
            data_out<=1'b0;
        end
        else if(enout&&(!error_add))begin
            case (tx_cnt)
                3'd0: data_out <= data_coded[0];
                3'd1: data_out <= data_coded[1];
                3'd2: data_out <= data_coded[2];
                3'd3: data_out <= data_coded[3];
                3'd4: data_out <= data_coded[4];
                3'd5: data_out <= data_coded[5];
                3'd6: data_out <= data_coded[6];
            endcase
        end
        else if(enout&&error_add)begin//加错
                case (tx_cnt)
                3'd0: data_out <= data_coded[0];
                3'd1: data_out <= data_coded[1];
                3'd2: data_out <= data_coded[2];
                3'd3: data_out <= data_coded[3];
                3'd4: data_out <= data_coded[4];
                3'd5: data_out <= ~data_coded[5];
                3'd6: data_out <= data_coded[6];
            endcase
        end
        else data_out<=1'b0;
            
    end
endmodule