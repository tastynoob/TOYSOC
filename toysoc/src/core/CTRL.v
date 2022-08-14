module CTRL(
    input wire i_clk,
    input wire i_rst,

    /*IFU状态控制*/
    input wire i_ifu_finish,
    output reg o_ifu_en,
    /*IDU状态控制*/
    input wire i_idu_finish,
    output reg o_idu_en,
    /*EXU状态控制*/
    input wire i_exu_finish,
    output reg o_exu_en,
    output wire[1:0] o_state
);

reg[1:0] state;

always @(posedge i_clk) begin
    if(i_rst) begin
        state <= 0;
        o_ifu_en<=0;
        o_idu_en<=0;
        o_exu_en<=0;
    end 
    else begin
        if(state==0)begin//刚上电启动
            state <= 1;
            o_ifu_en<=1;
            o_idu_en<=0;
            o_exu_en<=0;
        end
        else if(state==1)begin//取指
            if(i_ifu_finish)begin
                state <= 2;
                o_ifu_en <= 0;
                o_idu_en <= 1;
                o_exu_en <= 0;
            end
        end
        else if(state==2)begin//译码
            if(i_idu_finish)begin
                state <=3;
                o_ifu_en <= 0;
                o_idu_en <= 0;
                o_exu_en <= 1;
            end
        end
        else if(state==3)begin//执行
            if(i_exu_finish)begin
                state <= 1;
                o_ifu_en <= 1;
                o_idu_en <= 0;
                o_exu_en <= 0;
            end
        end
    end
end
assign o_state = state;
endmodule