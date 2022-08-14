/* verilator lint_off WIDTH */
module ITCM_CTRL (
    input wire i_clk,
    input wire i_rst,

    //RIB接口
    input wire[31:0] i_ribs_addr,//主地址线
    input wire i_ribs_wrcs,//读写选择
    input wire[3:0] i_ribs_mask, //掩码
    input wire[31:0] i_ribs_wdata, //写数据
    output wire[31:0] o_ribs_rdata,

    input wire i_ribs_req, 
    output wire o_ribs_gnt, 
    output wire o_ribs_rsp, 
    input wire i_ribs_rdy
);

ITCM_SIM u_ITCM_SIM(
    .i_clk        ( i_clk        ),
    .i_rst       ( i_rst       ),
    .i_ribs_addr  ( i_ribs_addr  ),
    .i_ribs_wrcs  ( i_ribs_wrcs  ),
    .i_ribs_mask  ( i_ribs_mask  ),
    .i_ribs_wdata ( i_ribs_wdata ),
    .o_ribs_rdata ( o_ribs_rdata ),
    .i_ribs_req   ( i_ribs_req   ),
    .o_ribs_gnt   ( o_ribs_gnt   ),
    .o_ribs_rsp   ( o_ribs_rsp   ),
    .i_ribs_rdy   ( i_ribs_rdy   )
);

endmodule



module ITCM_SIM (
    input wire i_clk,
    input wire i_rst,

    //RIB接口
    input wire[31:0] i_ribs_addr,//主地址线
    input wire i_ribs_wrcs,//读写选择
    input wire[3:0] i_ribs_mask, //掩码
    input wire[31:0] i_ribs_wdata, //写数据
    output reg[31:0] o_ribs_rdata,

    input wire i_ribs_req, 
    output wire o_ribs_gnt, 
    output wire o_ribs_rsp, 
    input wire i_ribs_rdy
    
);

    reg[31:0] sram[100*1024-1:0]; //39k
    integer i;
    initial begin
        $readmemh("..\\mem.list", sram);
    end

    reg handshake_rdy;
    always @(posedge i_clk) begin
        if(i_rst) begin
            handshake_rdy<=0;
        end 
        else begin
            if(i_ribs_req) begin//当接受到请求时
                handshake_rdy<=1;
                if(i_ribs_wrcs == 1)begin//写请求
                    sram[i_ribs_addr[31:2]] <= 
                    {i_ribs_mask[3] ? i_ribs_wdata[31:24] : sram[i_ribs_addr[31:2]][31:24], 
                    i_ribs_mask[2] ? i_ribs_wdata[23:16] : sram[i_ribs_addr[31:2]][23:16], 
                    i_ribs_mask[1] ? i_ribs_wdata[15:8] : sram[i_ribs_addr[31:2]][15:8], 
                    i_ribs_mask[0] ? i_ribs_wdata[7:0] : sram[i_ribs_addr[31:2]][7:0]};
                end
                else begin//读请求
                    o_ribs_rdata <= sram[i_ribs_addr[31:2]];
                end
            end
            else begin
                handshake_rdy<=0;
            end
        end
    end

    assign o_ribs_gnt = i_ribs_req;
    assign o_ribs_rsp = handshake_rdy;//过一个周期之后返回响应
    
endmodule
