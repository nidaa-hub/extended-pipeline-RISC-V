module instr_parser (
	input clk,    // Clock
	input rst,    // Reset 
	input [159:0] idata_instr, // 5 instruction from Instruction memory
	input [3:0]   icount_inst,
	output reg [31:0] odata_instr
);
 
always @(*) begin
 case (icount_inst)
 	3'd0 : odata_instr [31:0] <= idata_instr[31:0]   ;
 	3'd1 : odata_instr [31:0] <=idata_instr[63:32]  ; 
 	3'd2 : odata_instr [31:0] <=idata_instr[95:64]  ; 
 	3'd3 : odata_instr [31:0] <=idata_instr[127:96] ; 
 	3'd4 : odata_instr [31:0] <=idata_instr[159:128]; 
 	default : odata_instr [31:0] <=idata_instr[31:0];
 endcase
end
endmodule