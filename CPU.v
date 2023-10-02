`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    03:44:46 10/15/2019 
// Design Name: 
// Module Name:    CPU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module CPU(
    input reset,
    input clk,
    output [31:0] iaddr,  // address to instruction memory
    input [159:0] idata,   // data from instruction memory
    output [31:0] daddr,  // address to data memory
    input [31:0] drdata,  // data read from data memory
    output [31:0] dwdata, // data to be written to data memory
    output [3:0] we,      // write enable signal for each byte of 32-b word
    //
    output [31:0] daddr1,  // address to data memory
    input [31:0] drdata1,  // data read from data memory
    output [31:0] dwdata1, // data to be written to data memory
    output [3:0] we1,      // write enable signal for each byte of 32-b word
   
    // Additional outputs for debugging
    output [31:0] x31,
    output reg [31:0] PC
);

wire [159:0] idatawire;
wire [31:0] PC_branch;
wire [31:0] PC_plus4;
wire PCsrc;
wire staller;

 reg [2:0] counter,counter_D1,counter_D2 ;
always @(posedge clk) begin
	if(reset || counter == 4) begin
	  counter <= 0;
	end else begin
		counter <=counter + 'h1;
	end
end

always @(posedge clk) begin
 	counter_D1 <= counter;
 	counter_D2 <= counter_D1;

end

assign idatawire = idata;
assign PC_plus4 = PC + 32'd20;

// incrementing PC only if staller is zero and PCsrc decides next instruction
always @(posedge reset or posedge clk) begin
		if (reset )
			PC <= 32'h00000000;
		else begin
			if(PC =='h78 )
					PC <=  'h14;
			if ((~(staller))&&(counter != 'h4))
				PC <=  PC;
			else
			 if (~(staller)) 
				PC <= PCsrc ? PC_branch :PC_plus4;
		end
	end

assign iaddr = PC;

wire [31:0] PC_ID;
wire [159:0] mem_fetch_instr;

// IF_ID interface/Register
IF_ID ifid(
		.clk(clk),
		.staller((staller || PCsrc)),
		.PC_in(PC),
		.idata_in(idatawire),
		.PC_out(PC_ID),
		.idata_out(mem_fetch_instr)
		);

wire [31:0] idata_ID;
// Instruction parser
instr_parser i_instr_parser(
		.clk(clk),
		.rst(reset),
		.icount_inst(counter_D1),
		.idata_instr(mem_fetch_instr),
		.odata_instr(idata_ID));

//Instuction Decode Stage Started
wire [1:0] alusrc;
wire memtoreg;
wire  regwrite;
wire [3:0] memwrite;
wire [2:0] branch;
wire [1:0] aluop;
wire [1:0] regin;
wire [2:0] imm;

wire [2:0] imm_EX;

//Control Unit
control CONTROL(
		.idata(idata_ID),
		.alusrc(alusrc),
		.memtoreg(memtoreg),
		.regwrite(regwrite),
		.memwrite(memwrite),
		.branch(branch),
		.aluop(aluop),
		.regin(regin),
		.imm(imm)
		);

	reg [1:0] alusrc_spr[4:0];
	reg memtoreg_spr[4:0];
	reg regwrite_spr[4:0];
	reg [3:0] memwrite_spr[4:0];
	reg [2:0] branch_spr[4:0];
	reg [1:0] aluop_spr[4:0];
	reg [1:0] regin_spr[4:0];
	reg [2:0] imm_spr[4:0];
	wire [1:0] ALUsrc_EX_spr[4:0];
	wire memtoreg_EX_spr[4:0];
	wire regwrite_EX_spr[4:0];
	wire [3:0] memwrite_EX_spr[4:0];
	wire [2:0] branch_EX_spr[4:0];
	wire [1:0] ALUop_EX_spr[4:0];
	wire [1:0] regin_EX_spr[4:0];
	reg [2:0] imm_EX_spr[4:0];
	always @(*) begin
		alusrc_spr[counter_D1] <= alusrc ;
		memtoreg_spr[counter_D1] <= memtoreg ;
		regwrite_spr[counter_D1] <= regwrite ;
		memwrite_spr[counter_D1] <= memwrite ;
		branch_spr[counter_D1] <= branch ;
		aluop_spr[counter_D1] <= aluop ;
		regin_spr[counter_D1] <= regin ;
		imm_spr[counter_D1] <= imm ;
		imm_EX_spr[counter_D1] <= imm_EX ;
end

wire [31:0]memtoregdata;
wire [31:0] indataforreg;
wire [31:0] regindata;
wire [31:0]datawire1;
wire [31:0]datawire2;
wire [31:0]datawire1_EX[2:0];
wire [31:0]datawire2_EX[2:0];
wire regwrite_WB;
wire [31:0] idata_WB;

// Register File

regfile REGFILE(
		.rs1(idata_ID[19:15]),
		.rs2(idata_ID[24:20]),
		.rd(idata_WB[11:7]),// TODO Writeback
		.indata(regindata), // TODO Writeback
		.we(regwrite_WB),// TODO Writeback
		.clk(clk),
		.rv1(datawire1),
		.rv2(datawire2),
		.x31(x31)
	);

reg [31:0] datawire1_reg[4:0];
reg [31:0] datawire2_reg[4:0];
 always @(*) begin
    datawire1_reg[counter_D1] <= datawire1;
    datawire2_reg[counter_D1] <= datawire2;
 end
wire [31:0] immgen;
wire [31:0] immgen_EX[4:0];
wire [31:0] PC_EX;
wire [31:0] idata_EX_spr[4:0];

wire memread_EX;
assign idata_EX_spr[1] =mem_fetch_instr[63:32];
assign idata_EX_spr[3] =mem_fetch_instr[127:96];

assign memread_EX = (counter_D1 == 1 ) ? (idata_EX_spr[1][6:0]==7'b0000011) : 
										(counter_D1 == 3 ) ? (idata_EX_spr[3][6:0]==7'b0000011) : 0 ;
staller HDU(
		.memread_EX(memread_EX),
		.idata_EX(idata_EX_spr[counter_D2]),  //D1  Should represent last  executed at this moment
		.idata_ID(idata_ID),
		.staller(staller)
		);

immgen IMMGEN(
		.imm(imm_spr[counter_D1]),
		.idata(idata_ID),
		.immgen(immgen)
		);

reg [31:0] immgen_arr[4:0];
 always @(*) begin
    immgen_arr[counter] <= immgen;
 end
reg PCsrc2;


// making control signals zero for bubbling instructions in case of data or control hazards
ID_EX idex(
		.clk(clk),
		.regin_in((staller || PCsrc || PCsrc2) ? 0 : regin_spr[0]), // 0 Represent 1st Instruction Decoded
		.branch_in((staller || PCsrc|| PCsrc2) ? 0 : branch_spr[0]),// 0 Represent 1st Instruction Decoded
		.memtoreg_in((staller || PCsrc|| PCsrc2) ? 0 : memtoreg_spr[0]),// 0 Represent 1st Instruction Decoded
		.ALUop_in((staller || PCsrc|| PCsrc2) ? 0 : aluop_spr[0]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_in((staller || PCsrc|| PCsrc2) ? 0 : alusrc_spr[0]),// 0 Represent 1st Instruction Decoded
		.regwrite_in((staller || PCsrc|| PCsrc2) ? 0 : regwrite_spr[0]),// 0 Represent 1st Instruction Decoded
		.memwrite_in((staller || PCsrc|| PCsrc2) ? 0 : memwrite_spr[0]),// 0 Represent 1st Instruction Decoded
		.rv1_in((staller || PCsrc|| PCsrc2) ? 0 :datawire1_reg[0]),// 0 Represent 1st Instruction Decoded
		.rv2_in((staller || PCsrc|| PCsrc2) ? 0 :datawire2_reg[0]),// 0 Represent 1st Instruction Decoded
		.rv1_out(datawire1_EX[0]), 
		.rv2_out(datawire2_EX[0]), 
		.immgen_in(immgen_arr[0]), // 0 Represent 1st Instruction Decoded
		.immgen_out(immgen_EX[0]),
		.regin_out(regin_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.branch_out(branch_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.memtoreg_out(memtoreg_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.ALUop_out(ALUop_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_out(ALUsrc_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.regwrite_out(regwrite_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.memwrite_out(memwrite_EX_spr[0]),// 0 Represent 1st Instruction Decoded
		.PC_in(PC_ID),//TODO
		.PC_out(PC_EX), //TODO
		.idata_in(mem_fetch_instr[31:0]), // 31:0 Represent 1st Instruction Decoded
		.idata_out(idata_EX_spr[0]) // 0 Represent 1st Instruction Decoded
		);


//Exection Stage
wire [3:0] 	alucon; //As there is only three exection stages
wire [31:0] idata_MEM;
wire  			regwrite_MEM[1:0];

alucontrol ALUCONTROL(
		.aluop(ALUop_EX_spr[0]),
		.funct7(idata_EX_spr[0][31:25]),
		.funct3(idata_EX_spr[0][14:12]),
		.alucon(alucon)
);

wire zero;
wire [31:0] aluoutdata; 
wire [31:0] PC_plus4_EX;

wire [1:0] forwardA, forwardB;

// Forwarding unit
forwarding_unit FU(
		.idata_EX(idata_EX_spr[0]),
		.idata_MEM(idata_MEM),
		.idata_WB(idata_WB),
		.regwrite_MEM(regwrite_MEM[0]),
		.regwrite_WB(regwrite_WB),
		.forwardA(forwardA),
		.forwardB(forwardB)
		);
wire [31:0] rv1forEX, rv2forEX;
wire [31:0] aluoutdata_MEM[1:0]; //Input to MEM stage

assign rv1forEX= (forwardA == 2'b10) ? aluoutdata_MEM[0]:
						(forwardA == 2'b01) ? regindata: datawire1_EX[0];

assign rv2forEX = (forwardB == 2'b10) ? aluoutdata_MEM[0]:
						(forwardB == 2'b01) ? regindata: datawire2_EX[0];
						
// Arithmetic Logic Unit
alu ALU(
		.in1(ALUsrc_EX_spr[0][1] ? PC_EX : rv1forEX),
		.in2(ALUsrc_EX_spr[0][0] ? immgen_EX[0] : rv2forEX),
		.alucon(alucon),
		.out(aluoutdata),
		.zero(zero)
		);

// Program Counter which is also a control hazard detector
PC ProgCoun(
		.PC(PC_EX),
		.immgen(immgen_EX[0]),
		.branch(branch_EX_spr[0]),
		.zero(zero),
		.aluoutdata(aluoutdata),
		.PC_plus4(PC_plus4_EX),
		.PC_next(PC_branch),//TODO
		.PCsrc(PCsrc)//TODO
		);
		


// EX_MEM interface
// If any control hazard takes place, two instructions need to be bubbled. So we need to create a new signal which carries PCsrc for next clk cycle 
// and check if it is 1.
initial PCsrc2 = 0;

always@(posedge clk)begin
PCsrc2<=PCsrc;
end

wire [31:0] PC_plus4_MEM[1:0];
wire [31:0] immgen_MEM;
wire memtoreg_MEM;

wire [3:0]  memwrite_MEM[1:0];
wire [1:0]  regin_MEM[1:0];
wire [31:0] datawire2_MEM[1:0];
wire [31:0] aluoutdata_ma;
assign  aluoutdata_ma = (ALUsrc_EX_spr[0][1] ? PC_ID : datawire1_EX[0]) +
				(ALUsrc_EX_spr[0][0] ? immgen_EX[0]: 32'h0 ) ;
// EX_MEM interface

EX_MEM exmem(
		.clk(clk),
		.memtoreg_in((staller || PCsrc|| PCsrc2) ? 0 : memtoreg_spr[1]),
		.regwrite_in((staller || PCsrc|| PCsrc2) ? 0 : regwrite_spr[1]),
		.memwrite_in((staller || PCsrc|| PCsrc2) ? 0 : memwrite_spr[1]),
		.ALUout_in(aluoutdata_ma),
		.rv2_in(rv2forEX),
		.rv2_out(datawire2_MEM[0]),
		.ALUout_out(aluoutdata_MEM[0]),
		.memwrite_out(memwrite_MEM[0]),
		.regwrite_out(regwrite_MEM[0]),
		.memtoreg_out(memtoreg_MEM),
		.immgen_in(immgen_EX[0]),
		.immgen_out(immgen_MEM),
		.regin_in(regin_EX_spr[0]),
		.regin_out(regin_MEM[0]),
		.PC_plus4_in(PC_plus4_EX),
		.PC_plus4_out(PC_plus4_MEM[0]),
		.idata_in(idata_EX_spr[0]),
		.idata_out(idata_MEM)
		);
// Handling SW, SH, SB

assign we = (memwrite_MEM[0] == 4'b1111 && daddr[1:0]== 2'b00) ? 4'b1111:
				(memwrite_MEM[0] == 4'b0011 && daddr[1:0]== 2'b00) ? 4'b0011:
				(memwrite_MEM[0] == 4'b0011 && daddr[1:0]== 2'b10) ? 4'b1100:
				(memwrite_MEM[0] == 4'b0001 && daddr[1:0]== 2'b00) ? 4'b0001:
				(memwrite_MEM[0] == 4'b0001 && daddr[1:0]== 2'b01) ? 4'b0010:
				(memwrite_MEM[0] == 4'b0001 && daddr[1:0]== 2'b10) ? 4'b0100:
				(memwrite_MEM[0] == 4'b0001 && daddr[1:0]== 2'b11) ? 4'b1000: 4'b0000;


assign dwdata = (memwrite_MEM[0] == 4'b0000) ? datawire2_MEM[0] : (datawire2_MEM[0] << daddr[1:0] * 8) ;
assign daddr = aluoutdata_ma;
 
//  //Exection _stage 2
//  // making control signals zero for bubbling instructions in case of data or control hazards
ID_EX idex1(
		.clk(clk),
		.regin_in((staller || PCsrc || PCsrc2) ? 0 : regin_spr[2]), // 0 Represent 1st Instruction Decoded
		.branch_in((staller || PCsrc|| PCsrc2) ? 0 : branch_spr[2]),// 0 Represent 1st Instruction Decoded
		.memtoreg_in((staller || PCsrc|| PCsrc2) ? 0 : memtoreg_spr[2]),// 0 Represent 1st Instruction Decoded
		.ALUop_in((staller || PCsrc|| PCsrc2) ? 0 : aluop_spr[2]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_in((staller || PCsrc|| PCsrc2) ? 0 : alusrc_spr[2]),// 0 Represent 1st Instruction Decoded
		.regwrite_in((staller || PCsrc|| PCsrc2) ? 0 : regwrite_spr[2]),// 0 Represent 1st Instruction Decoded
		.memwrite_in((staller || PCsrc|| PCsrc2) ? 0 : memwrite_spr[2]),// 0 Represent 1st Instruction Decoded
		.rv1_in((staller || PCsrc|| PCsrc2) ? 0 :datawire1_reg[2]),// 0 Represent 1st Instruction Decoded
		.rv2_in((staller || PCsrc|| PCsrc2) ? 0 :datawire2_reg[2]),// 0 Represent 1st Instruction Decoded
		.rv1_out(datawire1_EX[2]), 
		.rv2_out(datawire2_EX[2]), 
		.immgen_in(immgen_arr[2]), // 0 Represent 1st Instruction Decoded
		.immgen_out(immgen_EX[2]),
		.regin_out(regin_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.branch_out(branch_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.memtoreg_out(memtoreg_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.ALUop_out(ALUop_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_out(ALUsrc_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.regwrite_out(regwrite_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.memwrite_out(memwrite_EX_spr[2]),// 0 Represent 1st Instruction Decoded
		.PC_in(PC_ID),//TODO
		// .PC_out(PC_EX), //TODO
		.idata_in(mem_fetch_instr[95:64]), // 31:0 Represent 1st Instruction Decoded
		.idata_out(idata_EX_spr[2]) // 0 Represent 1st Instruction Decoded
		);


//Exection Stage
wire [3:0] 	alucon_eb; //As there is only three exection stages
wire [31:0] idata_MEM_eb;
alucontrol ALUCONTROL1(
		.aluop(ALUop_EX_spr[2]),
		.funct7(idata_EX_spr[2][31:25]),
		.funct3(idata_EX_spr[2][14:12]),
		.alucon(alucon_eb)
);

wire zero_eb;
wire [31:0] aluoutdata_eb; 
wire [31:0] PC_plus4_EX_eb;

wire [1:0] forwardA_eb, forwardB_eb;

// Forwarding unit
forwarding_unit FU1(
		.idata_EX(idata_EX_spr[2]),
		.idata_MEM(idata_MEM),
		.idata_WB(idata_WB),
		.regwrite_MEM(regwrite_MEM[2]),
		.regwrite_WB(regwrite_WB),
		.forwardA(forwardA_eb),
		.forwardB(forwardB_eb)
		);
wire [31:0] rv1forEX_eb, rv2forEX_eb;
assign rv1forEX_eb= (forwardA_eb == 2'b10) ? aluoutdata_MEM[2]:
						(forwardA_eb == 2'b01) ? regindata: datawire1_EX[2];

assign rv2forEX_eb = (forwardB_eb == 2'b10) ? aluoutdata_MEM[2]:
						(forwardB_eb == 2'b01) ? regindata: datawire2_EX[2];
						
// Arithmetic Logic Unit
alu ALU1(
		.in1(ALUsrc_EX_spr[2][1] ? PC_EX[0] : rv1forEX_eb),
		.in2(ALUsrc_EX_spr[2][0] ? immgen_EX[2] : rv1forEX_eb),
		.alucon(alucon_ab),
		.out(aluoutdata_eb),
		.zero(zero_eb)
		);

// Program Counter which is also a control hazard detector
PC ProgCount1(
		.PC(PC_EX),
		.immgen(immgen_EX[2]),
		.branch(branch_EX_spr[2]),
		.zero(zero_eb),
		.aluoutdata(aluoutdata_eb),
		.PC_plus4(PC_plus4_EX_eb)
		// , 
		// .PC_next(PC_branch), //TODO
		// .PCsrc(PCsrc) //TOD0
		);



wire [31:0] aluoutdata_mb;
assign  aluoutdata_mb = (ALUsrc_EX_spr[2][1] ? PC_ID : datawire1_EX[2]) +
				(ALUsrc_EX_spr[2][0] ? immgen_EX[2]: 32'h0 ) ;
// EX_MEM interface

EX_MEM exmem1(
		.clk(clk),
		.memtoreg_in((staller || PCsrc|| PCsrc2) ? 0 : memtoreg_spr[3]),
		.regwrite_in((staller || PCsrc|| PCsrc2) ? 0 : regwrite_spr[3]),
		.memwrite_in((staller || PCsrc|| PCsrc2) ? 0 : memwrite_spr[3]),
		.ALUout_in(aluoutdata_mb),
		.rv2_in(rv1forEX_eb),
		.rv2_out(datawire2_MEM[1]),
		.ALUout_out(aluoutdata_MEM[1]),
		.memwrite_out(memwrite_MEM[1]),
		.regwrite_out(regwrite_MEM[1]),
		.memtoreg_out(memtoreg_MEM),
		.immgen_in(immgen_EX[1]),
		.immgen_out(immgen_MEM),
		.regin_in(regin_EX_spr[1]),
		.regin_out(regin_MEM[0]),
		.PC_plus4_in(PC_plus4_EX),
		.PC_plus4_out(PC_plus4_MEM[1]),
		.idata_in(idata_EX_spr[1]),
		.idata_out(idata_MEM)
		);
// Handling SW, SH, SB

assign we1 = (memwrite_MEM[1] == 4'b1111 && daddr1[1:0]== 2'b00) ? 4'b1111:
				(memwrite_MEM[1] == 4'b0011 && daddr1[1:0]== 2'b00) ? 4'b0011:
				(memwrite_MEM[1] == 4'b0011 && daddr1[1:0]== 2'b10) ? 4'b1100:
				(memwrite_MEM[1] == 4'b0001 && daddr1[1:0]== 2'b00) ? 4'b0001:
				(memwrite_MEM[1] == 4'b0001 && daddr1[1:0]== 2'b01) ? 4'b0010:
				(memwrite_MEM[1] == 4'b0001 && daddr1[1:0]== 2'b10) ? 4'b0100:
				(memwrite_MEM[1] == 4'b0001 && daddr1[1:0]== 2'b11) ? 4'b1000: 4'b0000;


assign dwdata1 = (memwrite_MEM[1] == 4'b0000) ? datawire2_MEM[1] : (datawire2_MEM[1] << daddr1[1:0] * 8) ;
assign daddr1 = aluoutdata_mb;
 





//  //Exection _stage 2
//  // making control signals zero for bubbling instructions in case of data or control hazards
ID_EX idex2(
		.clk(clk),
		.regin_in((staller || PCsrc || PCsrc2) ? 0 : regin_spr[4]), // 0 Represent 1st Instruction Decoded
		.branch_in((staller || PCsrc|| PCsrc2) ? 0 : branch_spr[4]),// 0 Represent 1st Instruction Decoded
		.memtoreg_in((staller || PCsrc|| PCsrc2) ? 0 : memtoreg_spr[4]),// 0 Represent 1st Instruction Decoded
		.ALUop_in((staller || PCsrc|| PCsrc2) ? 0 : aluop_spr[4]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_in((staller || PCsrc|| PCsrc2) ? 0 : alusrc_spr[4]),// 0 Represent 1st Instruction Decoded
		.regwrite_in((staller || PCsrc|| PCsrc2) ? 0 : regwrite_spr[4]),// 0 Represent 1st Instruction Decoded
		.memwrite_in((staller || PCsrc|| PCsrc2) ? 0 : memwrite_spr[4]),// 0 Represent 1st Instruction Decoded
		.rv1_in((staller || PCsrc|| PCsrc2) ? 0 :datawire1_reg[4]),// 0 Represent 1st Instruction Decoded
		.rv2_in((staller || PCsrc|| PCsrc2) ? 0 :datawire2_reg[4]),// 0 Represent 1st Instruction Decoded
		.rv1_out(datawire1_EX[4]), 
		.rv2_out(datawire2_EX[4]), 
		.immgen_in(immgen_arr[4]), // 0 Represent 1st Instruction Decoded
		.immgen_out(immgen_EX[4]),
		.regin_out(regin_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.branch_out(branch_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.memtoreg_out(memtoreg_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.ALUop_out(ALUop_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.ALUsrc_out(ALUsrc_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.regwrite_out(regwrite_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.memwrite_out(memwrite_EX_spr[4]),// 0 Represent 1st Instruction Decoded
		.PC_in(PC_ID),//TODO
		// .PC_out(PC_EX), //TODO
		.idata_in(mem_fetch_instr[95:64]), // 31:0 Represent 1st Instruction Decoded
		.idata_out(idata_EX_spr[4]) // 0 Represent 1st Instruction Decoded
		);


//Exection Stage
wire [3:0] 	alucon_ec; //As there is only three exection stages
wire [31:0] idata_MEM_ec;
alucontrol ALUCONTROL2(
		.aluop(ALUop_EX_spr[4]),
		.funct7(idata_EX_spr[4][31:25]),
		.funct3(idata_EX_spr[4][14:12]),
		.alucon(alucon_ec)
);

wire zero_ec;
wire [31:0] aluoutdata_ec; 
wire [31:0] PC_plus4_EX_ec;

wire [1:0] forwardA_ec, forwardB_ec;

// Forwarding unit
forwarding_unit FU2(
		.idata_EX(idata_EX_spr[4]),
		.idata_MEM(idata_MEM),
		.idata_WB(idata_WB),
		.regwrite_MEM(regwrite_MEM[4]),
		.regwrite_WB(regwrite_WB),
		.forwardA(forwardA_ec),
		.forwardB(forwardB_ec)
		);
wire [31:0] rv1forEX_ec, rv2forEX_ec;
assign rv1forEX_ec= (forwardA_ec == 2'b10) ? aluoutdata_MEM[4]:
						(forwardA_ec == 2'b01) ? regindata: datawire1_EX[4];

assign rv2forEX_ec = (forwardB_ec == 2'b10) ? aluoutdata_MEM[4]:
						(forwardB_ec == 2'b01) ? regindata: datawire2_EX[4];
						
// Arithmetic Logic Unit
alu ALU2(
		.in1(ALUsrc_EX_spr[4][1] ? PC_EX[0] : rv1forEX),
		.in2(ALUsrc_EX_spr[4][0] ? immgen_EX[4] : rv2forEX),
		.alucon(alucon_ac),
		.out(aluoutdata_ec),
		.zero(zero_ec)
		);

// Program Counter which is also a control hazard detector
PC ProgCount2(
		.PC(PC_EX),
		.immgen(immgen_EX[4]),
		.branch(branch_EX_spr[4]),
		.zero(zero_ec),
		.aluoutdata(aluoutdata_ec),
		.PC_plus4(PC_plus4_EX_ec)
		// , 
		// .PC_next(PC_branch), //TODO
		// .PCsrc(PCsrc) //TOD0
		);

wire [31:0] aluoutdata_WB;
wire [31:0] PC_plus4_WB;
wire [31:0] immgen_WB;
wire [31:0] daddr_WB;
wire memtoreg_WB;
wire [1:0] regin_WB;
wire [31:0]drdata_WB;

// MEM_WB interface

MEM_WB memwb(
		.clk(clk),
		.memtoreg_in(memtoreg_MEM),
		.regwrite_in(regwrite_MEM[0]),
		.ALUout_in(aluoutdata_MEM[0]), //Shouldn't be zero here 
		.drdata_in(drdata),
		.immgen_in(immgen_MEM),
		.PC_plus4_in(PC_plus4_MEM[counter_D2]),
		.regin_in(regin_MEM[0]),
		.idata_in(idata_MEM),
		.daddr_in(daddr),
		.daddr_out(daddr_WB),
		.idata_out(idata_WB),
		.regin_out(regin_WB),
		.PC_plus4_out(PC_plus4_WB),
		.immgen_out(immgen_WB),
		.ALUout_out(aluoutdata_WB),
		.drdata_out(drdata_WB),
		.memtoreg_out(memtoreg_WB),
		.regwrite_out(regwrite_WB)
		);
// Handling LW, LH, LB
assign memtoregdata = memtoreg_WB ? drdata_WB : aluoutdata_WB;
assign indataforreg = (memtoreg_WB && (idata_WB[14:12] == 3'b001 || idata_WB[14:12] == 3'b101)) ? ((memtoregdata >> (daddr_WB[1:0] * 8)) & 32'h0000FFFF) :
							 (memtoreg_WB && (idata_WB[14:12] == 3'b000 || idata_WB[14:12] == 3'b100)) ? ((memtoregdata >> (daddr_WB[1:0] * 8)) & 32'h000000FF) : memtoregdata;
							 
assign regindata = (regin_WB == 2'b00) ? immgen_WB :
						 (regin_WB == 2'b01) ? indataforreg :
						 (regin_WB == 2'b10) ? PC_plus4_WB : indataforreg ;

endmodule
