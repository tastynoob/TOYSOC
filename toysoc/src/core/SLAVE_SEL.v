/*
根据地址的高8位选择不同的从机

rib总线,地址与数据都为32位宽
*/
/* verilator lint_off WIDTH */
//从多个从机中选择一个
//默认选择0号从机
//如果slave_mask==0xff,则代表
module SLAVE_SEL #(
    parameter slaves = 3
)(
    input wire i_clk,
    input wire i_rst,
    //从机地址选择,根据地址的高8位选择不同的从机
    input wire [8*slaves-1:0] i_slave_mask,

    //rib主机接口
    input wire[31:0]            i_ribm_addr,
    input wire                  i_ribm_wrcs,//读写选择
    input wire[3:0]             i_ribm_mask, //写掩码
    input wire[31:0]            i_ribm_wdata, //写数据
    output wire[31:0]           o_ribm_rdata, //读数据
    input wire                  i_ribm_req, //主机发出请求
    output wire                 o_ribm_gnt, //总线授权
    output wire                 o_ribm_rsp, //从机响应有效
    input wire                  i_ribm_rdy, //主机响应正常


    //RIB从接口
    output wire[32*slaves-1:0]  o_ribs_addr,//主地址线
    output wire[slaves-1:0]     o_ribs_wrcs,//读写选择
    output wire[4*slaves-1:0]   o_ribs_mask, //掩码
    output wire[32*slaves-1:0]  o_ribs_wdata, //写数据
    input wire[32*slaves-1:0]   i_ribs_rdata,
    output wire[slaves-1:0]     o_ribs_req, 
    input wire[slaves-1:0]      i_ribs_gnt, 
    input wire[slaves-1:0]      i_ribs_rsp, 
    output wire[slaves-1:0]     o_ribs_rdy,

    //RIB从机默认接口
    output wire[31:0]           o_ribd_addr,//主地址线
    output wire                 o_ribd_wrcs,//读写选择
    output wire[3:0]            o_ribd_mask, //掩码
    output wire[31:0]           o_ribd_wdata, //写数据
    input wire[31:0]            i_ribd_rdata,
    output wire                 o_ribd_req, 
    input wire                  i_ribd_gnt, 
    input wire                  i_ribd_rsp, 
    output wire                 o_ribd_rdy

);
    wire[31:0] ribs_rdata[slaves-1:0];
    generate
        genvar j;
        for(j=0;j<slaves;j=j+1)begin
            assign ribs_rdata[j] = i_ribs_rdata[32*j+31:32*j];
        end
    endgenerate


    //哪位bit是1，则输出这个bit所在的位置
    function integer onehot2int;
        input[slaves-1:0] onehot;
        integer j;
        begin
            onehot2int = 0; // prevent latch behavior
            for(j=0;j<slaves;j=j+1)begin
                if(onehot[j])begin
                    onehot2int = j;
                end
            end
        end
    endfunction



    wire[slaves-1:0] sel_tag;
    generate
        genvar i;
        for(i=0;i<slaves;i=i+1) begin:gen_sel_tag
            //从机选择位
            assign sel_tag[i] = (i_ribm_addr[31:24] == i_slave_mask[8*i+7:8*i]);
            //舍去高8位
            assign o_ribs_addr[32*i+31:32*i] = {8'b0,i_ribm_addr[23:0]};
            assign o_ribs_wrcs[i] = i_ribm_wrcs;
            assign o_ribs_mask[4*i+3:4*i] = i_ribm_mask;
            assign o_ribs_wdata[32*i+31:32*i] = i_ribm_wdata;
            //向指定从机发送请求,由于只有一个主机,因此sel_tag有且仅有一位有效
            assign o_ribs_req[i] = i_ribm_req & sel_tag[i];
            
        end
    endgenerate
    //向主机返回授权信号
    assign o_ribm_gnt = (|i_ribs_gnt) | i_ribd_gnt;
    //向主机返回响应信号
    assign o_ribm_rsp = (|i_ribs_rsp) | i_ribd_rsp;

    //对于默认从机,不舍弃高8位
    assign o_ribd_addr = i_ribm_addr;
    assign o_ribd_wrcs = i_ribm_wrcs;
    assign o_ribd_mask = i_ribm_mask;
    assign o_ribd_wdata = i_ribm_wdata;
    //只有当从机都没选择到时才选择默认从机
    assign o_ribd_req = i_ribm_req & (~(|sel_tag));
    
    



    //切换数据总线
    reg default_cs;
    reg[7:0] sel_tag_id;
    wire handshake_rdy = i_ribm_req & o_ribm_gnt;
    //访问成功
    wire access_rdy = o_ribm_rsp;
    reg handshake_rdy_last;//上次传输的握手状态
    //一个总线事务传输完成,上次握手成功&当前传输成功
    wire trans_finish = handshake_rdy_last & access_rdy;
    always @(posedge i_clk) begin
        if(i_rst)begin
            handshake_rdy_last <= 0;
            sel_tag_id <= 0;
            default_cs<=1;
        end
        else begin
            //只有当访问成功或handshake_rdy_last为0时，才允许下一次的传输
            if(access_rdy | (~handshake_rdy_last))begin
                handshake_rdy_last <= handshake_rdy;
                sel_tag_id <= onehot2int(sel_tag);
                default_cs <= ~(|sel_tag);
            end
        end
    end

    //向从机返回rdy信号
    generate
        for(i=0;i<slaves;i=i+1) begin:gen_ribs_rdata
            assign o_ribs_rdy[i] = default_cs ? 0 : (i_ribm_rdy & (sel_tag_id == i));
        end
    endgenerate

    assign o_ribd_rdy = i_ribm_rdy & default_cs;

    //向主机返回数据
    assign o_ribm_rdata = default_cs ? i_ribd_rdata : ribs_rdata[sel_tag_id];

endmodule
