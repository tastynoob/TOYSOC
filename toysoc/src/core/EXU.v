`include "config.v"
`include "defines.v"


module EXU(
    input wire i_clk,
    input wire i_rst,
    //
    input wire i_en,
    output wire o_finish,
    //译码信息(部分)
    input wire[`xlen_def] i_rs1rdata,//rs1的寄存器数据
    input wire[`xlen_def] i_rs2rdata,//rs2的寄存器数据
    input wire[`xlen_def] i_imm,//指令立即数
    input wire[`xlen_def] i_iaddr,
    input wire i_rdwen,
    input wire[`rfidxlen_def] i_rdidx,
    input wire[`decinfo_grplen_def] i_decinfo_grp,
    input wire[`decinfolen_def] i_decinfo,
    input wire i_rs1topc,
    input wire i_rs2toimm,
    //执行结果
    output wire o_rdwen,
    output wire[`rfidxlen_def] o_rdidx,
    output wire[`xlen_def] o_rdwdata,
    output wire o_jump,
    output wire[`xlen_def] o_jaddr,
    //访存总线
    /*RIB总线主机*/
    output wire[31:0] o_ribm_addr,
    output wire o_ribm_wrcs,//读写选择
    output wire[3:0] o_ribm_mask, //写掩码
    output wire[31:0] o_ribm_wdata, //写数据
    input wire[31:0] i_ribm_rdata, //读数据
    output wire o_ribm_req, //主机发出请求
    input wire i_ribm_gnt, //总线授权
    input wire i_ribm_rsp, //从机响应有效
    output wire o_ribm_rdy //主机响应正常
);
//这里有个小bug
wire[`xlen_def] op1 = i_rs1topc ? i_iaddr : i_rs1rdata;
wire[`xlen_def] op2 = i_rs2toimm ? i_imm : i_rs2rdata;

//单周期执行组件(ALU)
wire[`xlen_def] alu_res;
EXU_ALU u_EXU_ALU(
    .i_clk         ( i_clk         ),
    .i_rst         ( i_rst         ),
    .i_decinfo_grp ( i_decinfo_grp ),
    .i_aluinfo     ( i_decinfo     ),
    .i_op1         ( op1         ),
    .i_op2         ( op2         ),
    .o_result      ( alu_res      )
);

//单周期执行组件(BJU)

wire bju_jump;
EXU_BJU u_EXU_BJU(
    .i_clk         ( i_clk         ),
    .i_rst         ( i_rst         ),

    .i_rs1rdata    ( op1              ),
    .i_op1         ( i_rs1rdata         ),
    .i_op2         ( i_rs2rdata         ),
    .i_offset      ( i_imm      ),
    .i_pc          ( i_iaddr          ),

    .i_decinfo_grp ( i_decinfo_grp ),
    .i_bjuinfo     ( i_decinfo     ),
    .o_jump        ( bju_jump        ),
    .o_jaddr       ( o_jaddr       )
);

assign o_jump = bju_jump & i_en;

//多周期执行组件(LSU)


wire lsu_flush = 0;
wire lsu_working;
wire lsu_finish;
wire lsu_rdwen;
wire[`xlen_def] lsu_rdata;
reg lsu_vld_rdy;
always @(posedge i_clk) begin
    if(i_rst)begin
        lsu_vld_rdy <= 0;
    end
    else if(lsu_vld) begin
        lsu_vld_rdy<=1;
    end
    else if(lsu_finish) begin
        lsu_vld_rdy<=0;
    end
end
wire lsu_vld = i_en & i_decinfo_grp[`decinfo_grp_lsu] & (!lsu_vld_rdy);
EXU_LSU u_EXU_LSU(
    .i_clk          ( i_clk          ),
    .i_rst          ( i_rst         ),

    .i_vld          ( lsu_vld          ),
    .i_flush        ( lsu_flush        ),
    .o_finish       ( lsu_finish ),

    .i_decinfo_grp  ( i_decinfo_grp  ),
    .i_lsuinfo      ( i_decinfo      ),

    .i_lsu_rdwen    ( i_rdwen    ),
    .i_lsu_rdidx    ( i_rdidx    ),
    .i_lsu_rs2rdata ( i_rs2rdata ),
    .i_lsu_addr     ( (i_rs1rdata+i_imm)     ),

    .o_working      ( lsu_working      ),

    .o_will_rdwen   (    ),
    .o_will_rdidx   (    ),
    .o_lsu_rdwen    ( lsu_rdwen    ),
    .o_lsu_rdidx    (     ),
    .o_lsu_rdata    ( lsu_rdata    ),

    .o_ribm_addr    ( o_ribm_addr    ),
    .o_ribm_wrcs    ( o_ribm_wrcs    ),
    .o_ribm_mask    ( o_ribm_mask    ),
    .o_ribm_wdata   ( o_ribm_wdata   ),
    .i_ribm_rdata   ( i_ribm_rdata   ),
    .o_ribm_req     ( o_ribm_req     ),
    .i_ribm_gnt     ( i_ribm_gnt     ),
    .i_ribm_rsp     ( i_ribm_rsp     ),
    .o_ribm_rdy     ( o_ribm_rdy     )
);

//写回
assign o_rdwen =    i_en & (
                    i_decinfo_grp[`decinfo_grp_alu] ? i_rdwen :
                    i_decinfo_grp[`decinfo_grp_bju] ? i_rdwen : 
                    i_decinfo_grp[`decinfo_grp_lsu] ? lsu_rdwen : 0
                    );

assign o_rdidx = i_rdidx;
//写回数据
assign o_rdwdata =  i_decinfo_grp[`decinfo_grp_alu] ? alu_res :
                    i_decinfo_grp[`decinfo_grp_bju] ? (i_iaddr+4) : 
                    i_decinfo_grp[`decinfo_grp_lsu] ? lsu_rdata : 0;

assign o_finish =   i_en & (
                    i_decinfo_grp[`decinfo_grp_alu] ? 1 : 
                    i_decinfo_grp[`decinfo_grp_bju] ? 1 : 
                    i_decinfo_grp[`decinfo_grp_lsu] ? lsu_finish : 0
                    );

endmodule