`include "config.v"
`include "defines.v"

module EXU_ALU(
    input wire i_clk,
    input wire i_rst,

    input wire[`decinfo_grplen_def] i_decinfo_grp,
    input wire[`decinfolen_def] i_aluinfo,
    
    input wire[`xlen_def] i_op1,
    input wire[`xlen_def] i_op2,


    output wire[`xlen_def] o_result
);

wire[`xlen_def] alu_add = i_decinfo_grp[`decinfo_grp_add] ? (i_op1 + i_op2) : 0;
wire[`xlen_def] alu_sub = i_aluinfo[`aluinfo_sub] ? (i_op1 - i_op2) : 0;
wire[`xlen_def] alu_sll = i_aluinfo[`aluinfo_sll] ? (i_op1 << i_op2) : 0;
wire[`xlen_def] alu_srl = i_aluinfo[`aluinfo_srl] ? (i_op1 >> i_op2) : 0;
wire[`xlen_def] alu_sra = i_aluinfo[`aluinfo_sra] ? (({32{i_op1[31]}} << (6'd32 - {1'b0, i_op2[4:0]})) | (i_op1 >> i_op2[4:0])) : 0;
wire[`xlen_def] alu_xor = i_aluinfo[`aluinfo_xor] ? (i_op1 ^ i_op2) : 0;
wire[`xlen_def] alu_and = i_aluinfo[`aluinfo_and] ? (i_op1 & i_op2) : 0;
wire[`xlen_def] alu_or =  i_aluinfo[`aluinfo_or]   ?  (i_op1 | i_op2) : 0;
wire[`xlen_def] alu_slt = i_aluinfo[`aluinfo_slt] ? {31'h0,(($signed(i_op1)) < ($signed(i_op2)))} : 0;
wire[`xlen_def] alu_sltu = i_aluinfo[`aluinfo_sltu] ? {31'h0,(i_op1 < i_op2)} : 0;


assign o_result =  alu_add |
                        alu_sub |
                        alu_sll |
                        alu_srl |
                        alu_sra |
                        alu_xor |
                        alu_and |
                        alu_or  |
                        alu_slt |
                        alu_sltu;
endmodule