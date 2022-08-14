

//usart模块,使用rib总线传输数据
//使用方法:
//寄存器:usart_ctrl:0x000 控制寄存器
//寄存器:tx_data:0x004 数据发送寄存器
//寄存器:rx_data:0x008 数据接收寄存器

module USART2RIB (
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
    output reg o_ribs_rsp, 
    input wire i_ribs_rdy
);


reg[7:0] tx_buffer;
reg rx_vld;
wire[7:0] rx_data;
reg rx_err;
wire rx_vld_w;
wire rx_err_w;
wire tx_rdy;
reg tx_en;
//当第一次读取rx标志位时为高
//则需要等待rx标志位重新为低
reg has_rx;

//控制状态寄存器
//低3位分别是:串口读错误,串口读完成,串口发送完成
wire[31:0] usart_ctrl = {29'd0,rx_err_w && (has_rx==0),rx_vld_w&&(has_rx==0),tx_rdy};

///rib握手协议
wire handshake_rdy = i_ribs_req;
always @(posedge i_clk) begin
    if(i_rst)begin
        tx_en <= 0;
        o_ribs_rsp <= 0;
        rx_vld<=0;
        rx_err<=0;
        has_rx<=0;
    end
    else begin
        if(handshake_rdy)begin
            case(i_ribs_addr[15:0])
                16'h0000:begin//读控制寄存器
                    if(i_ribs_wrcs)begin//写无效,退出仿真
                    end
                    else begin//读
                        o_ribs_rdata <= 0;
                        if((rx_vld_w || rx_err_w) && (has_rx == 0))begin
                            has_rx <= 1;
                        end
                        else if(((rx_vld_w || rx_err_w)==0) && (has_rx == 1))begin
                            has_rx <= 0;
                        end
                    end
                end
                16'h0004:begin//读写数据发送寄存器
                    //发送数据
                    if(i_ribs_wrcs)begin//写
                        tx_buffer <= i_ribs_wdata[7:0];
                        tx_en <= 1;
                        $write("%c",i_ribs_wdata[7:0]);
                    end
                    else begin//读
                        o_ribs_rdata <= {24'b0,tx_buffer};
                    end
                end
                16'h0008:begin//读数据接受寄存器(只读)
                    if(i_ribs_wrcs)begin//写无效
                        
                    end
                    else begin
                        o_ribs_rdata <= 0;
                    end
                end
                default:begin
                end
            endcase
            o_ribs_rsp<=1;
        end
        else begin
            tx_en <= 0;
            o_ribs_rsp <= 0;
        end
    end

end
assign o_ribs_gnt = i_ribs_req;

    
endmodule