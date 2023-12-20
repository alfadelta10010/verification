### Sampling Clocking Blocks
- First, let us take our files:

	- :warning: Top Module
	```verilog
module top;
	bit clk;
	always #5 clk = !clk;
	dut_if ifc(clk);
	test test_inst(ifc);
	dut dut_inst(
		.clk(ifc.clk),
		.inp1(ifc.inp1),
		.inp2(ifc.inp2),
		.outp1(ifc.outp1)
	);
endmodule
```
	- RTL Module
	```verilog
module dut(clk, inp1, inp2, outp1);
	input clk;
	parameter bit [15:0] WIDTH = 8;
	input [WIDTH-1:0] inp1, inp2;
	output [WIDTH-1:0] outp1;
	reg [WIDTH-1:0] outp1;
	bit [7:0] count;
	always @(posedge clk)
		begin
			outp1 <= count;
			count++;
			$strobe("[Postponed] outp1: %0d @ time %0t", outp1, $time);
		end
endmodule
```
	- Test bench
	```verilog
program test(dut_if.tb vif);
	initial begin
		@(vif.cb); 
		sig1 = vif.cb.outp1;
		$display("[Re-active] Sampled outp1: %0d @ time %0t", sig1, $time);		
	end
endprogram
```
	- Interface 
	```verilog
interface dut_if(input bit clk);
	parameter bit [15:0] WIDTH=8;
	logic [WIDTH-1:0] inp1, inp2, outp1;
	clocking cb @(posedge clk);
		output inp1, inp2;
		input outp1;
	endclocking
	modport tb(clocking cb);
endinterface
```
[17:53] 13 Clocking Blocks.mp4