module imem(
    input [31:0] iaddr,
    output [159:0] idata
);
    reg [31:0] m[0:31];
    initial begin $readmemh("imem5_ini.mem",m); end

    assign idata[31:0]    = m[iaddr[31:2]];
	assign idata[63:32]   = m[(iaddr[31:2]+'h1)];
	assign idata[95:64]   = m[(iaddr[31:2]+'h2)];
	assign idata[127:96]  = m[(iaddr[31:2]+'h3)];
	assign idata[159:128] = m[(iaddr[31:2]+'h10)];

	 
endmodule
