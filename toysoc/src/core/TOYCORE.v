`include "config.v"
`include "defines.v"

module TOYCORE(
    input wire i_clk,
    input wire i_rst,

    //ibus
    output wire[31:0] o_ribm_addr0,
    output wire o_ribm_wrcs0,//读写选择
    output wire[3:0] o_ribm_mask0, //写掩码
    output wire[31:0] o_ribm_wdata0, //写数据
    input wire[31:0] i_ribm_rdata0, //读数据
    output wire o_ribm_req0, //主机发出请求
    input wire i_ribm_gnt0, //总线授权
    input wire i_ribm_rsp0, //从机响应有效
    output wire o_ribm_rdy0, //主机响应正常
    //dbus
    output wire[31:0] o_ribm_addr1,
    output wire o_ribm_wrcs1,//读写选择
    output wire[3:0] o_ribm_mask1, //写掩码
    output wire[31:0] o_ribm_wdata1, //写数据
    input wire[31:0] i_ribm_rdata1, //读数据
    output wire o_ribm_req1, //主机发出请求
    input wire i_ribm_gnt1, //总线授权
    input wire i_ribm_rsp1, //从机响应有效
    output wire o_ribm_rdy1 //主机响应正常
);

wire ctrl2ifu_en;
wire ifu2ctrl_finish;

wire ctrl2idu_en;
wire idu2ctrl_finish=1;

wire ctrl2exu_en;
wire exu2ctrl_finish=1;

wire[1:0] ctrl_state;
CTRL u_CTRL(
    .i_clk                      ( i_clk        ),
    .i_rst                      ( i_rst        ),

    .i_ifu_finish               ( ifu2ctrl_finish ),
    .o_ifu_en                   ( ctrl2ifu_en     ),

    .i_idu_finish               ( idu2ctrl_finish ),
    .o_idu_en                   ( ctrl2idu_en     ),

    .i_exu_finish               ( exu2ctrl_finish ),
    .o_exu_en                   ( ctrl2exu_en     ),
    .o_state                    ( ctrl_state )
);

wire[31:0] ifu_iaddr;
wire[31:0] ifu2idu_idata;

wire exu2ifu_jump;
wire[31:0] exu2ifu_jaddr;

IFU u_IFU(
    .i_clk                     ( i_clk         ),
    .i_rst                     ( i_rst         ),

    .i_en                      ( ctrl2ifu_en   ),
    .o_finish                  ( ifu2ctrl_finish),
    .i_jump                    ( exu2ifu_jump),                
    .i_jaddr                   ( exu2ifu_jaddr),

    .o_iaddr                   ( ifu_iaddr     ),
    .o_idata                   ( ifu2idu_idata ),

    .o_ribm_addr               ( o_ribm_addr0  ),
    .o_ribm_wrcs               ( o_ribm_wrcs0  ),
    .o_ribm_mask               ( o_ribm_mask0  ),
    .o_ribm_wdata              ( o_ribm_wdata0 ),
    .i_ribm_rdata              ( i_ribm_rdata0 ),
    .o_ribm_req                ( o_ribm_req0   ),
    .i_ribm_gnt                ( i_ribm_gnt0   ),
    .i_ribm_rsp                ( i_ribm_rsp0   ),
    .o_ribm_rdy                ( o_ribm_rdy0   )
);


wire exu2idu_rdwen;
wire[`rfidxlen_def] exu2idu_rdidx;
wire[`xlen_def] exu2idu_rdwdata;
  
wire[`xlen_def] idu2exu_rs1rdata;
wire[`xlen_def] idu2exu_rs2rdata;
wire[`xlen_def] idu2exu_imm;
wire idu2exu_rdwen;
wire[`rfidxlen_def] idu2exu_rdidx;
wire[`decinfo_grplen_def] idu2exu_decinfo_grp;
wire[`decinfolen_def] idu2exu_decinfo;
wire idu2exu_rs1topc;
wire idu2exu_rs2toimm;
IDU u_IDU(
    .i_clk         ( i_clk         ),
    .i_rst         ( i_rst         ),

    .i_en          ( ctrl2idu_en          ),
    .o_finish      ( idu2ctrl_finish      ),

    .i_idata       ( ifu2idu_idata       ),

    .i_rdwen       ( exu2idu_rdwen       ),
    .i_rdidx       ( exu2idu_rdidx       ),
    .i_rdwdata     ( exu2idu_rdwdata      ),

    .o_rs1rdata    ( idu2exu_rs1rdata    ),
    .o_rs2rdata    ( idu2exu_rs2rdata    ),
    .o_imm         ( idu2exu_imm         ),
    .o_rdwen       ( idu2exu_rdwen       ),
    .o_rdidx       ( idu2exu_rdidx       ),
    .o_decinfo_grp ( idu2exu_decinfo_grp ),
    .o_decinfo     ( idu2exu_decinfo     ),
    .o_rs1topc    ( idu2exu_rs1topc ),
    .o_rs2toimm    ( idu2exu_rs2toimm    )
);


EXU u_EXU(
    .i_clk         ( i_clk         ),
    .i_rst         ( i_rst         ),

    .i_en          ( ctrl2exu_en          ),
    .o_finish      ( exu2ctrl_finish      ),

    .i_rs1rdata    ( idu2exu_rs1rdata    ),
    .i_rs2rdata    ( idu2exu_rs2rdata    ),
    .i_imm         ( idu2exu_imm         ),
    .i_iaddr       ( ifu_iaddr       ),
    .i_rdwen       ( idu2exu_rdwen       ),
    .i_rdidx       ( idu2exu_rdidx       ),
    .i_decinfo_grp ( idu2exu_decinfo_grp ),
    .i_decinfo     ( idu2exu_decinfo     ),
    .i_rs1topc     ( idu2exu_rs1topc   ),
    .i_rs2toimm    ( idu2exu_rs2toimm    ),

    .o_rdwen       ( exu2idu_rdwen       ),
    .o_rdidx       ( exu2idu_rdidx       ),
    .o_rdwdata     ( exu2idu_rdwdata     ),
    .o_jump        ( exu2ifu_jump        ),
    .o_jaddr       ( exu2ifu_jaddr       ),
    //访存
    .o_ribm_addr               ( o_ribm_addr1  ),
    .o_ribm_wrcs               ( o_ribm_wrcs1  ),
    .o_ribm_mask               ( o_ribm_mask1  ),
    .o_ribm_wdata              ( o_ribm_wdata1 ),
    .i_ribm_rdata              ( i_ribm_rdata1 ),
    .o_ribm_req                ( o_ribm_req1   ),
    .i_ribm_gnt                ( i_ribm_gnt1   ),
    .i_ribm_rsp                ( i_ribm_rsp1   ),
    .o_ribm_rdy                ( o_ribm_rdy1   )
);








endmodule