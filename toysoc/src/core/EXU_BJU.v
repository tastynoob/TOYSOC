`include "config.v"
`include "defines.v"

module EXU_BJU(
    input wire i_clk,
    input wire i_rst,

    input wire[`xlen_def] i_rs1rdata,
    input wire[`xlen_def] i_op1,
    input wire[`xlen_def] i_op2,
    input wire[`xlen_def] i_offset,
    input wire[`xlen_def] i_pc,

    input wire[`decinfo_grplen_def] i_decinfo_grp,
    input wire[`decinfolen_def] i_bjuinfo,

    output wire o_jump,
    output wire[`xlen_def] o_jaddr
);

wire bxx_beq  = (i_op1 == i_op2);
wire bxx_bne  = (i_op1!=i_op2);
wire bxx_blt  = (($signed(i_op1))<($signed(i_op2)));
wire bxx_bge  = (($signed(i_op1))>=($signed(i_op2)));
wire bxx_bltu = (i_op1<i_op2);
wire bxx_bgeu = (i_op1>=i_op2);

assign o_jump = i_decinfo_grp[`decinfo_grp_bju] & 
                ((i_bjuinfo[`bjuinfo_beq] ? bxx_beq :
                i_bjuinfo[`bjuinfo_bne] ? bxx_bne :
                i_bjuinfo[`bjuinfo_blt] ? bxx_blt :
                i_bjuinfo[`bjuinfo_bge] ? bxx_bge :
                i_bjuinfo[`bjuinfo_bltu] ? bxx_bltu :
                i_bjuinfo[`bjuinfo_bgeu] ? bxx_bgeu :
                0) | i_bjuinfo[`bjuinfo_jal]);

assign o_jaddr = i_rs1rdata + i_offset;
endmodule