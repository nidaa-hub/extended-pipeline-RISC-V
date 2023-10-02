/*module inst_sprdr (
	input [2:0] i_counter,
	input [1:0] alusrc,
	input memtoreg,
	input  regwrite,
	input [3:0] memwrite,
	input [2:0] branch,
	input [1:0] aluop,
	input [1:0] regin,
	input [2:0] imm,
	input [1:0] ALUsrc_EX,
	input memtoreg_EX,
	input  regwrite_EX,
	input [3:0] memwrite_EX,
	input [2:0] branch_EX,
	input [1:0] ALUop_EX,
	input [1:0] regin_EX,
	input [2:0] imm_EX,
	
	output reg [1:0] alusrc_spr[4:0],
	output reg memtoreg_spr[4:0],
	output reg  regwrite_spr[4:0],
	output reg [3:0] memwrite_spr[4:0],
	output reg [2:0] branch_spr[4:0],
	output reg [1:0] aluop_spr[4:0],
	output reg [1:0] regin_spr[4:0],
	output reg [2:0] imm_spr[4:0],
	output reg [1:0] ALUsrc_EX_spr[4:0],
	output reg memtoreg_EX_spr[4:0],
	output reg  regwrite_EX_spr[4:0],
	output reg [3:0] memwrite_EX_spr[4:0],
	output reg [2:0] branch_EX_spr[4:0],
	output reg [1:0] ALUop_EX_spr[4:0],
	output reg [1:0] regin_EX_spr[4:0],
	output reg [2:0] imm_EX_spr[4:0],
	);

always @(*) begin
		alusrc_spr[i_counter] <= alusrc ;
		memtoreg_spr[i_counter] <= memtoreg ;
		regwrite_spr[i_counter] <= regwrite ;
		memwrite_spr[i_counter] <= memwrite ;
		branch_spr[i_counter] <= branch ;
		aluop_spr[i_counter] <= aluop ;
		regin_spr[i_counter] <= regin ;
		imm_spr[i_counter] <= imm ;
		ALUsrc_EX_spr[i_counter] <= ALUsrc_EX ;
		memtoreg_EX_spr[i_counter] <= memtoreg_EX ;
		regwrite_EX_spr[i_counter] <= regwrite_EX ;
		memwrite_EX_spr[i_counter] <= memwrite_EX ;
		branch_EX_spr[i_counter] <= branch_EX ;
		ALUop_EX_spr[i_counter] <= ALUop_EX ;
		regin_EX_spr[i_counter] <= regin_EX ;
		imm_EX_spr[i_counter] <= imm_EX ;
end
endmodule*/