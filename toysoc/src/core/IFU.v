`include "config.v"

module IFU (
    /*系统信号*/
    input wire i_clk,
    input wire i_rst,
    /*控制信号*/
    input wire i_en,
    output wire o_finish,
    input wire i_jump,
    input wire[31:0] i_jaddr,
    /*输出数据*/
    output reg[`xlen_def] o_iaddr,
    output reg[`ilen_def] o_idata,
    /*RIB总线主机*/
    output wire[31:0] o_ribm_addr,
    output wire o_ribm_wrcs,//读写选择
    output wire[3:0] o_ribm_mask, //写掩码
    output wire[31:0] o_ribm_wdata, //写数据
    input wire[31:0] i_ribm_rdata, //读数据
    output reg o_ribm_req, //主机发出请求
    input wire i_ribm_gnt, //总线授权
    input wire i_ribm_rsp, //从机响应有效
    output wire o_ribm_rdy //主机响应正常
);
    //握手信号
    wire handshake_rdy = o_ribm_req & i_ribm_gnt;
    reg handshake_rdy_last;
    //访问成功
    wire access_rdy = i_ribm_rsp;
    //完成一次数据传输
    wire trans_finish = handshake_rdy_last & i_ribm_rsp;
    always @(posedge i_clk) begin
        if(i_rst)begin
            handshake_rdy_last <= 0;
        end
        else if(i_en) begin
            if(access_rdy | (~handshake_rdy_last))begin
                handshake_rdy_last <= handshake_rdy;
            end
            else begin
                handshake_rdy_last <= 0;
            end
        end
        else begin
            handshake_rdy_last <= 0;
        end
    end



    reg[1:0] state;
    reg[31:0] pc;
    always @(posedge i_clk) begin
        if(i_rst)begin
            state<=0;
            pc<=0;
            o_ribm_req<=0;
        end
        else if(i_en) begin
            //取指开始
            if(state==0)begin
                o_ribm_req<=1;
                state <= 1;
            end
            else if(state==1)begin//取指完成
                if(handshake_rdy)begin
                    o_ribm_req<=0;
                end
                //当指令取出来的时候
                if(trans_finish)begin
                    o_iaddr<=pc;
                    o_idata<=i_ribm_rdata;
                    pc<=pc+4;
                    state<=0;
                end
            end
        end
        else if(i_jump)begin
            pc <= i_jaddr;
        end
    end

    assign o_finish = trans_finish;
    assign o_ribm_addr = pc;
    assign o_ribm_wrcs = 0;
    assign o_ribm_mask = 4'b1111;
    assign o_ribm_wdata = 0;
    assign o_ribm_rdy = i_ribm_rsp;
endmodule