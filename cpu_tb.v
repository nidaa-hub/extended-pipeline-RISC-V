module cpu_tb();
    reg clk, reset;
    wire [31:0] iaddr ;
    wire [159:0] idata;
    wire [31:0] daddr, drdata, dwdata;
    wire [31:0] daddr1, drdata1, dwdata1;
    wire [3:0] we;
    wire [3:0] we1;
    wire [31:0] x31, PC;

    CPU dut (
        .clk(clk),
        .reset(reset),
        .iaddr(iaddr),
        .idata(idata),
        .daddr(daddr),
        .drdata(drdata),
        .dwdata(dwdata),
        .we(we),
        .daddr1(daddr1),
        .drdata1(drdata1),
        .dwdata1(dwdata1),
        .we1(we1),
        .x31(x31),
        .PC(PC)
    );
	 
	 dmem dmem(
		.clk(clk),
		.daddr(daddr),
		.dwdata(dwdata),
		.drdata(drdata),
		.we(we),
        .daddr1(daddr1),
        .dwdata1(dwdata1),
        .drdata1(drdata1),
        .we1(we1)
		);
	 imem imem(
		.iaddr(iaddr), 
		.idata(idata)
	);
	
    always #5 clk = ~clk;
    initial begin
        clk = 0;
        reset = 1;
        #103
        reset = 0;
    end

endmodule
