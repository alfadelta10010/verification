
## Clocking Block
- A clocking block assembles signals that are synchronous to a particular clock and makes their timing explicit
```verilog
clocking clocking_blk @(edge specifier);
	<items>
endclocking
```
- Chips communicate at cycle level, hence stimulus must be generated at cycle level
- Clocking blocks are not synthesizable
- Taking the memory model example, we need a clocking block to synchronise our signals:
```verilog
interface simple_bus(input clk);
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic wr, rd;
	logic reset;
	
	clocking cb @(posedge clk);
		output addr, wr, rd, wdata; // Directions based on Testbench
		input rdata;
	endclocking
	
	modport dut_ports(input reset, addr, wr, rd, wdata, clk, output rdata);
	modport tb_ports(clocking cb, output reset); // Async reset
endinterface: simple_bus 
```
- The interface block uses the clocking block to specify timing of synchronous signals relative to the clocks
- Any sgnal in a clocking block is driven/sampled synchronously
- Driving clocking block signal from program block (wrt memory model):
```verilog
initial
	vif.cb.wdata <= 32'hffff;
```
- Always use non-blocking assignments
- Sampling of clocking block signal from program block (wrt memory model):
```verilog
initial
	local_data = vif.cb.rdata;
```
- Outputs in testbench can be driven (driving input to RTL) and inputs in testbench can be sampled (reading output from RTL)

### Driving Clocking Blocks
- First, let us take our files:
	- Top Module
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
	
	always @(inp1)
		$display("[DUT Combo] Inp1: %0d @ time %0t",inp1, $time);
	always @(inp2)
		$display("[DUT Combo] Inp2: %0d @ time %0t",inp2, $time);
	always @(posedge clk)
		outp1 <= inp1;
endmodule
```
	- Test bench
	```verilog
program test(dut_if.tb vif);
	initial begin
		$display("Time: %0t", $time);
		@(vif.cb); //@(posedge clk)
		vif.cb.inp1 = 10; 
		//vif.cb.inp1 <= 10;
		$display("Time: %0t", $time);		
		vif.cb.inp2 = 20; 
		//vif.cb.inp2 <= 20;
		repeat (3) @(vif.cb) // Wait for 3 clock edges
	end
endprogram
```
		- Here, we are making the driving statements as blocking assignments on purpose, to see what will happen
	- Interface 
	```verilog
interface dut_if(input bit clk);
	parameter bit [15:0] WIDTH=8;
	logic [WIDTH-1:0] inp1, inp2, outp1;
	/*
	clocking cb @(posedge clk);
		output inp1, inp2;
		input outp1;
	endclocking
	modport tb(clocking cb);
	*/
	modport tb(output inp1, inp2, input outp1);
endinterface
```
#### Without clocking blocks and NBAs
- At first, `inp1` gets updated to 10 in the `test` program block.
- This value is then sent to the `vif` interface, which is instantiated in the `top` module
- The `top` module then sends it to the `dut`, through the interface to `inp1`, which is then sent to `inp1` in the DUT
- All this occurs at the rising edge of clock pulse
- `vif.cb.inp1`: `vif` is the name of the interface, `cb` is the name of the clocking block, and `inp1` is the name of the variable
- At time 0, there are 5 concurrent blocks:
```verilog
always #5 clk = !clk; 											// Top module
always @(inp1) 													// DUT
	$display("[DUT Combo] Inp1: %0d @ time %0t",inp1, $time);
always @(inp2) 													// DUT
	$display("[DUT Combo] Inp2: %0d @ time %0t",inp2, $time);
always @(posedge clk) 											// DUT
	outp1 <= inp1;
$display("Time: %0t", $time); 									// Testbench
```
- The `always #5 clk = !clk;` in the top module is blocked for 5 time units
- The `always` blocks in the DUT are also waiting
- The `$display` statement executes, and as a result, in the active region, the values are `0, x, x, x` for `clk, `inp1`, `inp2`, `outp1`
- In the re-active region, `inp1` gets the value of `10` and then `inp2` gets the value of `20`
- After that, `repeat(3)` statement gets executed, and it needs to wait for 3 cycles
- As both the `inp` singles have changed, both `always` blocks in the DUT are triggered
- Once they are both triggered, the `$display` statements change the values to `10` and `20`, from `x`, in **time period `#0`**
- At time period `#5`, the third `always` statement gets triggered (`always @(posedge clk)`), and `outp1` takes the value of `inp1` i.e. `10`
- The value of `outp1` changes from `x` to `10` at time period `#5`, which is a flaw, the design should sample the old value `x`, not the new value `10`
- This is a cycle level operation

#### Cycle Level Operations
```
	T5		T15		T25		T35
    |───┐   |───┐   ┌───┐   ┌───┐
    |   │   |   │   │   │   │   │ Clk
 ───|   └───|   └───┘   └───┘   └
    |       |
  ┌─|─┐     |
  │ | │     |
──┘ | └─────|──────────────────── Data
    |       |
```
- The testbench executes the following:
```verilog
initial begin
	#2 vif.data=1;
	#6 vif.data=0;
end
```
- `data` = `1` reaches the RTL at time `#2` but in reality the communication takes place in cycle level and not in individual time levels
- We have a block in between the testbench and RTL, giving the previous valye to the RTL, as the data change happens at the rising edge
- At time `#5` the old value `x` is sampled by the RTL

#### Adding the clocking block and NBAs
- When we add the clocking block, we must ask three questions:
	1. At what simulation time are we in?
		- We are at time #0
	1. Is there a clock edge available at the point?
		- No
	1. When is the next posedge of the clock?
		- At time #5
- We go to time `#5`, and the statement `vif.cb.inp1 <= 10` executes, writing the value of `10` in the Re-NBA region
- Next statement, `vif.cb.inp2 <= 20` executes, updating the value of `20` in the Re-NBA region
:warning: Clocking blocks execute in Re-NBA region
- In the active region, `clk` is `1`, however `inp1`, `inp2`, `outp1` are all still `x`, as the updated values of `inp1` and `inp2` are in the Re-NBA region
- As a result, when we sample `outp1`, it will sample the old value of `inp1` which is `x`
- The new values of `inp1` and `inp2` will be sampled in the next rising edge of clock

#### Adding delays in NBA statements
- Test bench
```verilog
program test(dut_if.tb vif);
	initial begin
		$display("Time: %0t", $time);
		#2 vif.cb.inp1 <= 10;
		$display("Time: %0t", $time);		
		#6 vif.cb.inp2 <= 20;
		repeat (3) @(vif.cb) // Wait for 3 clock edges
	end
endprogram
```
- In this case, we ask ourselves the questions again:
	- We're at `#2` time period, there is no clock edge available at that point and the next posedge of the clock is at `#5`
- As a result, we schedule `inp1` to update to `10` in the Re-NBA region of the `#5` time period clock cycle
- When clock edge comes, `outp1` will become `x` from the value that is stored in the Active region already
- We can do the same for the second `inp2` statement

- All of this was for **driving** the data, the same can be applied for **sampling**

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