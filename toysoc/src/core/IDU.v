`include "config.v"
`include "defines.v"

/* verilator lint_off PINMISSING */

module IDU (
    //
    input wire i_clk,
    input wire i_rst,
    //
    input wire i_en,
    output wire o_finish,
    //
    input wire[`ilen_def] i_idata,
    //写回
    input wire i_rdwen,
    input wire[`rfidxlen_def] i_rdidx,
    input wire[`xlen_def] i_rdwdata,
    //译码信息(部分)
    output reg[`xlen_def] o_rs1rdata,
    output reg[`xlen_def] o_rs2rdata,
    output reg[`xlen_def] o_imm,
    output reg o_rdwen,
    output reg[`rfidxlen_def] o_rdidx,
    output reg[`decinfo_grplen_def] o_decinfo_grp,
    output reg[`decinfolen_def] o_decinfo,
    output reg o_rs1topc,
    output reg o_rs2toimm
);



wire reg_rs1ren;
wire[`rfidxlen_def] reg_rs1idx;
wire[`xlen_def] reg_rs1rdata;
wire reg_rs2ren;
wire[`rfidxlen_def] reg_rs2idx;
wire[`xlen_def] reg_rs2rdata;

REGFILE u_REGFILE(
    .i_clk          ( i_clk          ),
    .i_rst          ( i_rst         ),

    .i_rdwen        ( i_rdwen        ),
    .i_rdidx        ( i_rdidx        ),
    .i_rd_wdata     ( i_rdwdata     ),
    //
    .i_rs1ren       ( reg_rs1ren       ),
    .i_rs1idx       ( reg_rs1idx       ),
    .o_rs1_rdata    ( reg_rs1rdata    ),
    //
    .i_rs2ren       ( reg_rs2ren       ),
    .i_rs2idx       ( reg_rs2idx       ),
    .o_rs2_rdata    ( reg_rs2rdata    ),
    //不用旁路
    .i_bypass_rdwen ( 0 ),
    .i_bypass_rdidx ( 0 ),
    .i_bypass_rd_wdata  ( 0  )
);



wire dec_rdwen;
wire[`rfidxlen_def] dec_rdidx;
wire[`xlen_def] dec_imm;
wire[`decinfo_grplen_def] dec_decinfo_grp;
wire[`decinfolen_def] dec_decinfo;
wire dec_rs1topc;
wire dec_rs2toimm;
DECODE u_DECODE(
    .i_clk         ( i_clk         ),
    .i_rst        ( i_rst        ),

    .i_inst_vld    ( i_en    ),
    .i_inst        ( i_idata        ),

    .o_rdwen       ( dec_rdwen       ),
    .o_rdidx       ( dec_rdidx       ),

    .o_rs1ren      ( reg_rs1ren      ),
    .o_rs1idx      ( reg_rs1idx      ),
    .o_rs2ren      ( reg_rs2ren      ),
    .o_rs2idx      ( reg_rs2idx      ),
    .o_imm         ( dec_imm         ),

    .o_decinfo_grp ( dec_decinfo_grp ),
    .o_decinfo     ( dec_decinfo     ),
    .o_rs1topc     ( dec_rs1topc     ),
    .o_rs2toimm    ( dec_rs2toimm    )
);


always @(posedge i_clk) begin
    if(i_rst)begin
        o_decinfo_grp<=0;
    end
    else if(i_en) begin
        o_rs1rdata<=reg_rs1rdata;
        o_rs2rdata<=reg_rs2rdata;

        o_imm<=dec_imm;
        o_rdwen<=dec_rdwen;
        o_rdidx<=dec_rdidx;
        o_decinfo_grp<=dec_decinfo_grp;
        o_decinfo<=dec_decinfo;
        o_rs1topc<=dec_rs1topc;
        o_rs2toimm<=dec_rs2toimm;
    end
end


assign o_finish = i_en;
endmodule


module REGFILE (
    input wire i_clk,
    input wire i_rst,
    input wire i_rdwen,
    input wire[`rfidxlen_def] i_rdidx,
    input wire[`xlen_def] i_rd_wdata,

    input wire i_rs1ren,
    input wire[`rfidxlen_def] i_rs1idx,
    output wire[`xlen_def] o_rs1_rdata,

    input wire i_rs2ren,
    input wire[`rfidxlen_def] i_rs2idx,
    output wire[`xlen_def] o_rs2_rdata,
    //旁路
    input wire i_bypass_rdwen,
    input wire[`rfidxlen_def] i_bypass_rdidx,
    input wire[`xlen_def] i_bypass_rd_wdata

);

    reg[`xlen_def] rfxs[31:0];//32个寄存器,x0是不用的
    generate
        genvar i;
        for(i=0;i<32;i=i+1)begin:gen_regfile_rd
            if(i==0)begin
                //0号寄存器不做任何写操作
            end
            else begin
                always @(posedge i_clk) begin
                    if(i_rdwen & (i_rdidx == i))begin
                        rfxs[i] <= i_rd_wdata;
                    end
                end
            end
        end
    endgenerate

    assign o_rs1_rdata =    i_rs1ren ? 
                            (
                            ((i_rs1idx == i_bypass_rdidx) & i_bypass_rdwen)  ?
                            i_bypass_rd_wdata :
                                (
                                ((i_rs1idx == i_rdidx) & i_rdwen) ? i_rd_wdata 
                                : rfxs[i_rs1idx]
                                )
                            ) 
                            : 0;

    assign o_rs2_rdata =    i_rs2ren ? 
                            (
                            ((i_rs2idx == i_bypass_rdidx) & i_bypass_rdwen)  ?
                            i_bypass_rd_wdata :
                                (
                                ((i_rs2idx == i_rdidx) & i_rdwen) ? i_rd_wdata 
                                : rfxs[i_rs2idx]
                                )
                            ) 
                            : 0;

    wire[31:0] x1_ra = rfxs[1];
    wire[31:0] x2_sp = rfxs[2];
    wire[31:0] x3_gp = rfxs[3];
    wire[31:0] x4_tp = rfxs[4];
    wire[31:0] x5_t0 = rfxs[5];
    wire[31:0] x6_t1 = rfxs[6];
    wire[31:0] x7_t2 = rfxs[7];
    wire[31:0] x8_s0 = rfxs[8];
    wire[31:0] x9_s1 = rfxs[9];
    wire[31:0] x10_a0 = rfxs[10];
    wire[31:0] x11_a1 = rfxs[11];
    wire[31:0] x12_a2 = rfxs[12];
    wire[31:0] x13_a3 = rfxs[13];
    wire[31:0] x14_a4 = rfxs[14];
    wire[31:0] x15_a5 = rfxs[15];
    wire[31:0] x16_a6 = rfxs[16];
    wire[31:0] x17_a7 = rfxs[17];
    wire[31:0] x18_s2 = rfxs[18];
    wire[31:0] x19_s3 = rfxs[19];
    wire[31:0] x20_s4 = rfxs[20];
    wire[31:0] x21_s5 = rfxs[21];
    wire[31:0] x22_s6 = rfxs[22];
    wire[31:0] x23_s7 = rfxs[23];
    wire[31:0] x24_s8 = rfxs[24];
    wire[31:0] x25_s9 = rfxs[25];
    wire[31:0] x26_s10 = rfxs[26];
    wire[31:0] x27_s11 = rfxs[27];
    wire[31:0] x28_t3 = rfxs[28];
    wire[31:0] x29_t4 = rfxs[29];
    wire[31:0] x30_t5 = rfxs[30];
    wire[31:0] x31_t6 = rfxs[31];
endmodule

module DECODE (
    input wire i_clk,
    input wire i_rst,

    //指令
    input wire i_inst_vld,
    input wire[`ilen_def] i_inst,

    output wire o_rdwen,
    output wire[`rfidxlen_def] o_rdidx,
    output wire o_rs1ren,
    output wire[`rfidxlen_def] o_rs1idx,
    output wire o_rs2ren,
    output wire[`rfidxlen_def] o_rs2idx,
    output wire o_csr_ren,//csr读使能
    output wire[`csridxlen_def] o_csridx,
    output wire[`xlen_def] o_imm,//立即数
    output wire[`xlen_def] o_zimm,//csr zimm
    //译码信息
    output wire[`decinfo_grplen_def] o_decinfo_grp,
    output wire[`decinfolen_def] o_decinfo,
    output wire o_rs1topc,//是否将rs1替换成pc值
    output wire o_rs2toimm//是否将rs2替换成立即数
);


    wire opc_rv32 = i_inst[1] & i_inst[0];
    // 32位取出指令中的每一个域
    wire[4:0] opc = i_inst[6:2];
    wire[4:0] rd = i_inst[11:7];
    wire[2:0] func = i_inst[14:12];
    wire[6:0] func7 = i_inst[31:25];
    wire[4:0] rs1 = i_inst[19:15];
    wire[4:0] rs2 = i_inst[24:20];
    wire[11:0] type_i_imm_11_0 = i_inst[31:20];
    wire[6:0] type_s_imm_11_5 = i_inst[31:25];
    wire[4:0] type_s_imm_4_0 = i_inst[11:7];
    wire[6:0] type_b_imm_12_10_5 = i_inst[31:25];
    wire[4:0] type_b_imm_4_1_11 = i_inst[11:7];
    wire[19:0] type_u_imm_31_12 = i_inst[31:12];
    wire[19:0] type_j_imm_31_12 = i_inst[31:12];

    // 指令opc域的取值
    wire opc_lui = (opc == `opc_lui);
    wire opc_auipc = (opc == `opc_auipc);
    wire opc_jal = (opc == `opc_jal);
    wire opc_jalr = (opc == `opc_jalr);
    wire opc_branch = (opc == `opc_branch);
    wire opc_load = (opc == `opc_load);
    wire opc_store = (opc == `opc_store);
    wire opc_opimm = (opc == `opc_opimm);
    wire opc_op = (opc == `opc_op);
    wire opc_fence = (opc == `opc_fence);
    wire opc_system = (opc == `opc_system);

    // 指令func域的取值
    wire func_000 = (func == 3'b000);
    wire func_001 = (func == 3'b001);
    wire func_010 = (func == 3'b010);
    wire func_011 = (func == 3'b011);
    wire func_100 = (func == 3'b100);
    wire func_101 = (func == 3'b101);
    wire func_110 = (func == 3'b110);
    wire func_111 = (func == 3'b111);

    // 指令func7域的取值
    wire func7_0000000 = (func7 == 7'b0000000);
    wire func7_0100000 = (func7 == 7'b0100000);
    wire func7_0000001 = (func7 == 7'b0000001);

    // I类型指令imm域的取值
    wire type_i_imm_000000000000 = (type_i_imm_11_0 == 12'b000000000000);
    wire type_i_imm_000000000001 = (type_i_imm_11_0 == 12'b000000000001);

/*********************************************************/
    // 译码出具体指令
    /*j*/
    wire inst_lui = opc_lui;
    wire inst_auipc = opc_auipc;
    wire inst_jal = opc_jal;
    wire inst_jalr = opc_jalr & func_000;
    /*branch*/
    wire inst_beq = opc_branch & func_000;
    wire inst_bne = opc_branch & func_001;
    wire inst_blt = opc_branch & func_100;
    wire inst_bge = opc_branch & func_101;
    wire inst_bltu = opc_branch & func_110;
    wire inst_bgeu = opc_branch & func_111;
    /*load*/
    wire inst_lb = opc_load & func_000;
    wire inst_lh = opc_load & func_001;
    wire inst_lw = opc_load & func_010;
    wire inst_lbu = opc_load & func_100;
    wire inst_lhu = opc_load & func_101;
    /*store*/
    wire inst_sb = opc_store & func_000;
    wire inst_sh = opc_store & func_001;
    wire inst_sw = opc_store & func_010;
    /*opimm*/
    wire inst_addi = opc_opimm & func_000;
    wire inst_slti = opc_opimm & func_010;
    wire inst_sltiu = opc_opimm & func_011;
    wire inst_xori = opc_opimm & func_100;
    wire inst_ori = opc_opimm & func_110;
    wire inst_andi = opc_opimm & func_111;
    wire inst_slli = opc_opimm & func_001 & func7_0000000;
    wire inst_srli = opc_opimm & func_101 & func7_0000000;
    wire inst_srai = opc_opimm & func_101 & func7_0100000;
    /*op*/
    wire inst_add = opc_op & func_000 & func7_0000000;
    wire inst_sub = opc_op & func_000 & func7_0100000;
    wire inst_sll = opc_op & func_001 & func7_0000000;
    wire inst_slt = opc_op & func_010 & func7_0000000;
    wire inst_sltu = opc_op & func_011 & func7_0000000;
    wire inst_xor = opc_op & func_100 & func7_0000000;
    wire inst_srl = opc_op & func_101 & func7_0000000;
    wire inst_sra = opc_op & func_101 & func7_0100000;
    wire inst_or = opc_op & func_110 & func7_0000000;
    wire inst_and = opc_op & func_111 & func7_0000000;
    /*fence*/
    wire inst_fence = opc_fence & func_000;
    wire inst_fencei = opc_fence & func_001;
    /*system*/
    wire inst_ecall = opc_system & func_000 & type_i_imm_000000000000;
    wire inst_ebreak = opc_system & func_000 & type_i_imm_000000000001;
    wire inst_csrrw = opc_system & func_001;
    wire inst_csrrs = opc_system & func_010;
    wire inst_csrrc = opc_system & func_011;
    wire inst_csrrwi = opc_system & func_101;
    wire inst_csrrsi = opc_system & func_110;
    wire inst_csrrci = opc_system & func_111;

    /*M拓展*/
    wire inst_mul = opc_op & func_000 & func7_0000001;
    wire inst_mulh = opc_op & func_001 & func7_0000001;
    wire inst_mulhsu = opc_op & func_010 & func7_0000001;
    wire inst_mulhu = opc_op & func_011 & func7_0000001;
    wire inst_div = opc_op & func_100 & func7_0000001;
    wire inst_divu = opc_op & func_101 & func7_0000001;
    wire inst_rem = opc_op & func_110 & func7_0000001;
    wire inst_remu = opc_op & func_111 & func7_0000001;

    wire inst_expand_M = opc_op & func7_0000001;

/*********************************************************/

    // 指令中的立即数
    //lui、auipc
    wire[31:0] inst_u_type_imm = {i_inst[31:12], 12'b0};
    //jal
    wire[31:0] inst_j_type_imm = {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0};
    //branch
    wire[31:0] inst_b_type_imm = {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
    //store
    wire[31:0] inst_s_type_imm = {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};
    //jalr、load、opimm
    wire[31:0] inst_i_type_imm = {{20{i_inst[31]}}, i_inst[31:20]};
    //csr zimm
    wire[31:0] inst_csr_type_imm = {27'h0, i_inst[19:15]};
    wire[31:0] inst_shift_type_imm = {27'h0, i_inst[24:20]};

    wire[31:0] inst_opimm_imm = (inst_slli | inst_srli | inst_srai) ? 
                                inst_shift_type_imm : inst_i_type_imm;
    //对于移位指令，由于移位只需要立即数低5位，高位省略，所以为了方便，直接将inst_i_type_imm当作shamt
    assign o_imm =  ({`xlen{opc_lui|opc_auipc}} & inst_u_type_imm) |
                    ({`xlen{opc_branch}} & inst_b_type_imm) |
                    ({`xlen{opc_store}} & inst_s_type_imm) |
                    ({`xlen{opc_load}} & inst_i_type_imm) |
                    ({`xlen{opc_opimm}} & inst_opimm_imm) |
                    ({`xlen{opc_jal}} & inst_j_type_imm) |
                    ({`xlen{opc_jalr}} & inst_i_type_imm);



/********************************************************/
    //寄存器写使能
    assign o_rdwen =    (rd!=0) &
                        (opc_lui    |
                        opc_auipc   |
                        opc_jal     |
                        opc_jalr    |
                        opc_opimm   |
                        opc_op      |
                        opc_system  |
                        opc_load);
    assign o_rdidx = rd;

    //寄存器读使能1
    assign o_rs1ren =   (rs1!=0)&
                        (opc_jalr   |
                        opc_branch  |
                        opc_load    |
                        opc_store   |
                        opc_opimm   |
                        opc_op      |
                        inst_csrrw  |
                        inst_csrrs  |
                        inst_csrrc);
    assign  o_rs1idx =  rs1;

    //寄存器读使能2
    assign o_rs2ren  =  (rs2!=0) &
                        (opc_branch  |
                        opc_store   |
                        opc_op);
    assign  o_rs2idx =  rs2;


    


    //公共部分
    wire[`decinfo_grplen_def] decinfo_grp;//注意:m拓展也属于op类指令
    assign decinfo_grp[`decinfo_grp_alu] = opc_lui | opc_auipc | opc_opimm | (opc_op & (~inst_expand_M)) ;
    assign decinfo_grp[`decinfo_grp_lsu] = opc_load | opc_store;
    assign decinfo_grp[`decinfo_grp_bju] = opc_jal | opc_jalr | opc_branch;
    assign decinfo_grp[`decinfo_grp_mdu] = inst_expand_M;
    assign decinfo_grp[`decinfo_grp_scu] = opc_system;
    assign decinfo_grp[`decinfo_grp_add] = opc_lui | opc_auipc | inst_add | inst_addi | opc_load | opc_store;

    //ALU
    wire[`decinfolen_def] aluinfo;
    assign aluinfo[`aluinfo_sub] = inst_sub;
    assign aluinfo[`aluinfo_sll] = inst_sll | inst_slli;
    assign aluinfo[`aluinfo_srl] = inst_srl |  inst_srli;
    assign aluinfo[`aluinfo_sra] = inst_sra | inst_srai;
    assign aluinfo[`aluinfo_xor] = inst_xor | inst_xori;
    assign aluinfo[`aluinfo_and] = inst_and | inst_andi;
    assign aluinfo[`aluinfo_or] = inst_or |  inst_ori;
    assign aluinfo[`aluinfo_slt] = inst_slt | inst_slti;
    assign aluinfo[`aluinfo_sltu] = inst_sltu | inst_sltiu;

    //将rs1输出替换为pc
    assign o_rs1topc = opc_auipc | opc_jal | opc_branch;
    //将rs2输出替换成立即数,lui,auipc,opc,_imm
    assign o_rs2toimm = opc_lui | opc_auipc | opc_opimm | opc_load | opc_store; 

    //LSU
    wire[`decinfolen_def] lsuinfo;
    assign lsuinfo[`lsuinfo_wrcs] = opc_store;//读为0,写为1
    //3种掩码
    assign lsuinfo[`lsuinfo_opb] = func_000 |  func_100;//字节
    assign lsuinfo[`lsuinfo_oph] = func_001 |  func_101;//半字
    assign lsuinfo[`lsuinfo_opw] = func_010;//全字
    assign lsuinfo[`lsuinfo_lu] = func_100 | func_101;//无符号拓展

    //BJU
    wire[`decinfolen_def] bjuinfo;
    assign bjuinfo[`bjuinfo_jal]=opc_jal | opc_jalr;
    assign bjuinfo[`bjuinfo_beq]=inst_beq;
    assign bjuinfo[`bjuinfo_bne]=inst_bne;
    assign bjuinfo[`bjuinfo_blt]=inst_blt;
    assign bjuinfo[`bjuinfo_bge]=inst_bge;
    assign bjuinfo[`bjuinfo_bltu]=inst_bltu;
    assign bjuinfo[`bjuinfo_bgeu]=inst_bgeu;
    assign bjuinfo[`bjuinfo_bpu_bflag]=0;//分支预测跳转标志

    //MDU
    wire[`decinfolen_def] mduinfo;
    assign mduinfo[`mduinfo_mul]    =inst_mul;
    assign mduinfo[`mduinfo_mulh]   =inst_mulh;
    assign mduinfo[`mduinfo_mulhsu] =inst_mulhsu;
    assign mduinfo[`mduinfo_mulhu]  =inst_mulhu;
    assign mduinfo[`mduinfo_div]    =inst_div;
    assign mduinfo[`mduinfo_divu]   =inst_divu;
    assign mduinfo[`mduinfo_rem]    =inst_rem;
    assign mduinfo[`mduinfo_remu]   =inst_remu;


    

    //读csr寄存器的条件：sys指令、func不为0
    //当前是csrrw或csrrwi指令时,rdidx不为0
    assign o_csr_ren = opc_system & (|func) & ((inst_csrrw & inst_csrrwi) ? (rd!=0) : 1);
    //csr索引
    assign o_csridx = {`csridxlen{o_csr_ren}} & i_inst[31:20];
    //func[2]==1说明是立即数
    assign o_zimm = {`xlen{o_csr_ren & func[2]}} & inst_csr_type_imm;

    //SCU
    wire[`decinfolen_def] scuinfo;
    assign scuinfo[`scuinfo_ecall]  =inst_ecall;
    assign scuinfo[`scuinfo_ebreak] =inst_ebreak;
    assign scuinfo[`scuinfo_csrrw]  =inst_csrrw | inst_csrrwi;
    assign scuinfo[`scuinfo_csrrs]  =inst_csrrs | inst_csrrsi;
    assign scuinfo[`scuinfo_csrrc]  =inst_csrrc | inst_csrrci;
    assign scuinfo[`scuinfo_csrimm] =func[2];
    //写csr寄存器的条件:
    //当前是csrrs或csrrc指令,rs1idx不为0
    //当前是csrrsi或csrrci,zimm不为0
    assign scuinfo[`scuinfo_csrwen] = (inst_csrrs | inst_csrrsi | inst_csrrc | inst_csrrci) ? (rs1!=0) : |func;//只有rs1idx!=0才能写





    assign o_decinfo_grp = decinfo_grp;
    assign o_decinfo =  ({`decinfolen{decinfo_grp[`decinfo_grp_alu]}}   & aluinfo) |
                        ({`decinfolen{decinfo_grp[`decinfo_grp_lsu]}}   & lsuinfo) |
                        ({`decinfolen{decinfo_grp[`decinfo_grp_bju]}}   & bjuinfo) |
                        ({`decinfolen{decinfo_grp[`decinfo_grp_mdu]}}   & mduinfo) |
                        ({`decinfolen{decinfo_grp[`decinfo_grp_scu]}}   & scuinfo) ;




endmodule