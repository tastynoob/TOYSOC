

/* verilator lint_off WIDTH */
//从多个主机中选择一个
//时序逻辑，从0号主机开始优先级依次递减
//0号主机优先级最低,默认选择为0号主机
module MASTER_SEL #(
    parameter masters = 3
)(
    input wire i_clk,
    input wire i_rst,
    //rib主机接口
    input wire[32*masters-1:0]  i_ribm_addr,
    input wire[masters-1:0]     i_ribm_wrcs,//读写选择
    input wire[4*masters-1:0]   i_ribm_mask, //写掩码
    input wire[32*masters-1:0]  i_ribm_wdata, //写数据
    output wire[32*masters-1:0] o_ribm_rdata, //读数据
    input wire[masters-1:0]     i_ribm_req, //主机发出请求
    output wire[masters-1:0]    o_ribm_gnt, //总线授权
    output wire[masters-1:0]    o_ribm_rsp, //从机响应有效
    input wire[masters-1:0]     i_ribm_rdy, //主机响应正常


    //RIB从接口
    output wire[31:0]           o_ribs_addr,//主地址线
    output wire                 o_ribs_wrcs,//读写选择
    output wire[3:0]            o_ribs_mask, //掩码
    output wire[31:0]           o_ribs_wdata, //写数据
    input wire[31:0]            i_ribs_rdata,
    output wire                 o_ribs_req, 
    input wire                  i_ribs_gnt, 
    input wire                  i_ribs_rsp, 
    output wire                 o_ribs_rdy
);


    //哪位bit是1，则输出这个bit所在的位置
    function integer onehot2int;
        input[masters-1:0] onehot;
        integer j;
        begin
            onehot2int = 0; // prevent latch behavior
            for(j=0;j<masters;j=j+1)begin
                if(onehot[j])begin
                    onehot2int = j;
                end
            end
        end
    endfunction
    



    wire[31:0] ribm_addr[masters-1:0];
    wire[3:0] ribm_mask[masters-1:0];
    wire[31:0] ribm_wdata[masters-1:0];
    generate
        genvar i0;
        for(i0=0;i0<masters;i0=i0+1)begin:gen_ribm_addr
            assign ribm_addr[i0] = i_ribm_addr[32*i0+31:32*i0];
            assign ribm_mask[i0] = i_ribm_mask[4*i0+3:4*i0];
            assign ribm_wdata[i0] = i_ribm_wdata[32*i0+31:32*i0];
        end
    endgenerate

    //移交地址总线
    //masters位选择位
    wire[masters-1:0] sel_tag;
    generate
        genvar i;
        for(i=0;i<masters;i=i+1)begin:addr_sel
            if(i==0)begin//0号主机选择的条件:其他主机都没有请求信号
                assign sel_tag[0] = ~(|i_ribm_req[masters-1:1]);
            end
            else if(i == masters-1)begin
                assign sel_tag[i] = i_ribm_req[i];
            end
            else begin
                assign sel_tag[i] = i_ribm_req[i] & ~(|i_ribm_req[masters-1:i+1]);
            end

            //向主机发送授权信号
            assign o_ribm_gnt[i] = sel_tag[i] & i_ribs_gnt;
            //返回读数据,由于数据有效由rsp信号决定,所以干脆直连读数据
            assign o_ribm_rdata[32*i+31:32*i] = i_ribs_rdata;
        end
    endgenerate

    //向从机发送选择读写地址
    assign o_ribs_addr = ribm_addr[onehot2int(sel_tag)];
    //向从机发送选择读写方式
    assign o_ribs_wrcs = i_ribm_wrcs[onehot2int(sel_tag)];
    //向从机发送选择掩码
    assign o_ribs_mask = ribm_mask[onehot2int(sel_tag)];
    //向从机发送写数据
    assign o_ribs_wdata = ribm_wdata[onehot2int(sel_tag)];
    //向从机发出请求
    assign o_ribs_req = |i_ribm_req;




    //移交数据总线
    reg[$clog2(masters):0] sel_tag_id;
    wire handshake_rdy = o_ribs_req & i_ribs_gnt;
    //访问成功
    wire access_rdy = i_ribs_rsp;
    reg handshake_rdy_last;//上次传输的握手状态
    //一个总线事务传输完成,上次握手成功&当前传输成功
    wire trans_finish = handshake_rdy_last & access_rdy;
    always @(posedge i_clk) begin
        if(i_rst)begin
            handshake_rdy_last <= 0;
        end
        else begin
            //只有当访问成功或handshake_rdy_last为0时，才允许下一次的传输
            if(access_rdy | (~handshake_rdy_last))begin
                handshake_rdy_last <= handshake_rdy;
                sel_tag_id <= onehot2int(sel_tag);
            end
        end
    end

    //向主机返回响应
    generate
        genvar j;
        for(j=0;j<masters;j=j+1)begin:data_sel
            assign o_ribm_rsp[j] = (j==sel_tag_id) & i_ribs_rsp;
        end
    endgenerate


    assign o_ribs_rdy = i_ribm_rdy[sel_tag_id];
    
endmodule