module dmem(
    input clk,
    input [31:0] daddr,
    input [31:0] dwdata,
    input [3:0] we,
    output [31:0] drdata,

    input [31:0] daddr1,
    input [31:0] dwdata1,
    input [3:0] we1,
    output [31:0] drdata1

);
    reg [7:0] m[0:127];
    initial $readmemh("dmem_ini.mem",m);

    wire [31:0] add0,add1,add2,add3;
    wire [31:0] add10,add11,add12,add13;
     
	 assign add0 = (daddr & 32'hfffffffc) + 32'h00000000;
	 assign add1 = (daddr & 32'hfffffffc) + 32'h00000001;
	 assign add2 = (daddr & 32'hfffffffc) + 32'h00000002;
	 assign add3 = (daddr & 32'hfffffffc) + 32'h00000003;
	
     assign add10 = (daddr1 & 32'hfffffffc) + 32'h00000000;
     assign add11 = (daddr1 & 32'hfffffffc) + 32'h00000001;
     assign add12 = (daddr1 & 32'hfffffffc) + 32'h00000002;
     assign add13 = (daddr1 & 32'hfffffffc) + 32'h00000003;
     
	 assign drdata = {m[add3],m[add2],m[add1],m[add0]};
     assign drdata1 = {m[add13],m[add12],m[add11],m[add10]};
	 
    always @(posedge clk) begin
        if (we[0]==1)
            m[add0]= dwdata[7:0];
        if (we[1]==1)
            m[add1]= dwdata[15:8];
        if (we[2]==1)
            m[add2]= dwdata[23:16];
        if (we[3]==1)
            m[add3]= dwdata[31:24];
    end
	  
    always @(posedge clk) begin
        if (we1[0]==1)
            m[add10]= dwdata1[7:0];
        if (we1[1]==1)
            m[add11]= dwdata1[15:8];
        if (we1[2]==1)
            m[add12]= dwdata1[23:16];
        if (we1[3]==1)
            m[add13]= dwdata1[31:24];
    end  
endmodule
