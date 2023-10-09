# Races within RTL Code
## What races?
- Note:
	- Stimulus generation = generating and applying input
	- Sampling = reading output
- Continuation to [Verilog Stratified Event Queue]()
- Taking a look at a series of flip-flops:
`<insert 3 flip flops conncected synchranously to a clock>`
- When the clock and data are changing at the same time, the flip flop is supposed to sample the old value at clk
- Creating this circuit in behavioural style:
```verilog
module dut();
	always
		#5 clk = ~clk;
	always @(posedge clk)
		q1 = d;  //q1 <= d
	always @(posedge clk)
		q2 = q1; //q2 <= q1
	always @(posedge clk)
		q3 = q2; //q3 <= q2
endmodule
```
- At time slot 5, the first positive edge of clock occurs:
	- the `always` blocks get blocked concurrently, the simulator can enter into either block
	- In active region, `q1 = 0, q2 = 0, q3 = 0, d = 1, clk 5`
	- Now, there can be two (multiple) cases:
		- Block 2 gets executed first:
			- 
		- Block 1 gets executed first:
			- `q1 = d` gets executed, `q1 = 1`
			- `q2 = q1` gets executed, AND `q2 = 1` **at time slot 5**
			- This is an issue
> :warning: `1. Chapter 4 PPTs-2.pdf` must be referred to complete this on 4/10/23
- As a result, we use non-blocking assignments, as thet allow to see the old values of the flip flop inputs while sampling 

## What is RTL?
- RTL = Register Transfer Logic/Level
- But in a combinational logic diagram, where is the register?
- The register is at the inputs and outputs ports have register behind them
- The logic levels are transfered through registers
- The inputs and outputs will be sampled at some clock frequency and now this circuit is synchranous
- All programs written are RTL codes, the inputs and outputs are **always** fed through registers
```
        ┌───────┐
Inp─────►      │
        │       ├──┐
      ┌─►─┐    │  │ ┌──────┐     ┌───────┐
      │ └──┴────┘  └─►     ├─────►      ├───►O/P
      │              │ Logic│     │       │
      │ ┌──────┐  ┌──►     │     │       │
Inp───┼─►     ├──┘  └──────┘     │       │
      │ │      │                ┌─►─┐    │
      ├─►─┐   │                │ └──┴────┘
      │ └──┴───┘                │
Clk   │                         │
──────┴─────────────────────────┘
```

## Race between RTL and testbench
- Take a look at D Flip Flop code:
```verilog
module dff (clk, reset, din, dout);
	input clk, reset;
	input [3:0] din;
	output [3:0] dout;
	//reg [3:0] dout;
	
	always @(posedge clk or posedge reset)
		begin
			if (reset == 1'b1)
				dout <= 4'b0000;
			else begin
				dout <= din;
			end
		end
endmodule
```
- :warning: In a sensitivity list, both should be edge triggered or level triggered, cannot be a mix of both
- Now, taking a look at the testbench
```verilog
module testbench;
	reg clk, reset;
	reg [3:0] tb_din;
	wire [3:0] tb_dout;
	
	dff dff_inst(clk, reset, tb_din, tb_dout);
	always #5 clk = !clk;
	initial 
		begin
			clk = 0;
			reset = 0;
			tb_din = 0;
			#1 reset = 1;
			#3 reset = 0;
			@(posedge clk);
			tb_din = 2;
			@(posedge clk);
			#50 $finish
		end
endmodule
```
- Let's start analysing this code
- Starting at time 0, all `always` block are blocked, the clock one by the delay, and the FF one by the sensitivity list
- We enter the initial block, and the starting assignments occur, and one unit delay is encountered
- At time 1, the reset is applied as 1, which triggers the always block in the FF, and `dout` gets set as 
`<get explanation from akshay>`
- Putting non-blocking in the testbench will work, but the issue is verification engineer and designer aren't the same
- Hence, it is compulsory to use non-blocking operator while generating stimulus and driving method
- Race between testbench and design module
- In reality, there will be number of blocks waiting on the posedge clk both on the testbench and DUT
- To make the verification engineer's task easy, systemverilog has something called the `program` block
- Simulator can schedule in any order, and mixing design and testbench in the same region introduces race conditions

## How to overcome the races between RTL and TB?
- The root of the probelm is the mixing of design and testbench events duting the same time slot
	- Both are written tems of sepatate modules and both execute concurrently
- The race can be avoided if the **test bench events** are **scheduled seprately** from the **design events**
- For this purspose, SV introduces a separate block named "Program block"

## SystemVerilog Stratified Event Queue

# SystemVerilog Stratified Event Queue
- Assertions can be written for DUT as well, they do not have any synthesizable equivalent hardware, the <> ignores it
- In Verilog hen both design and TB are at module level
	- In active region, blocking assignment statements & display functions are evaluated
	- In inactive region, #0 delay statements are executed
	- In NBA region, Non Blocking Assignment statements are evaluated
	- In observed region, all concurrent assertion statements that are sampled earlier are evaluated
- In SystemVerilog, testbench is in program block so design module and testbench are not at same level, which lands in reactive region after observed region
	- In Reactive region, blocking assignments and display functions in program block are evaluated
	- In Re-inactive region, #0 `<copy>`
- Simplified Diagram
```
				From Previous
───────────────────────────────┐
				Time slot      │
							   │◄─────────┐
						  ┌────▼────┐     │ Loop back
						  │  Active  │     │ if more events
						  │ (Design) │     │
						  └────┬─────┘     │
							   ├─────────►│
						  ┌────▼────┐     │
						  │ Observed │     │
						  │Assertion │     │
						  └────┬─────┘     │
							   ├───────────┘
						  ┌────▼────┐
						  │ Reactive │
						  │Testbench │
						  └────┬─────┘
							   │        To next
							   └─────────────────────►
										Time slot
```
- Primary SystemVerilog scheduling regions
	- Active: Simulation of design code in modules
	- Observed: Evaluation on SystemVerilog assertions
	- Reactive: Executiong of testbench code in programs
	- Postponed: Sampling design signals for testbench input