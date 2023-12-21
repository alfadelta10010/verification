# Chapter 4: Connecting the Testbench and Design

:warning: This includes Verilog and SystemVerilog Stratified Event Queue, main content starts at the [`program` block](chapter4.md#program-block)

## Verilog Stratified Event Queue
- There are 4 regions in Verilog
	- Active region
	- Inactive region
	- Non Blocking Assignment Region
	- Postponed Region

#### Active Region:
- Consist execution of:
	- Blocking assignments
	- Evaluate RHS of NBA: `y <= a + b`, evaluates a+b
	- `$display` statements
	- Evaluate inputs and updates outputs of primitives
- Active Event Queue

#### Inactive region
- Time 0 (#0) assignments
- All delay statements

#### NBA region
- Updates LHS of NBA
- `y <= a + b`, updates y with value

#### Postponed Region
- `$strobe` and `$monitor` statements
- `<add stuff from notes>`

### Control flow:
```
Active -> Inactive -> NBA -> Postponed
   /\         |        |
   |__________|        |
   |___________________/
```
- After one cycle of these, simulator goes to time 1, and so on so forth   

### Active Event Queue
- What is the final value of `a`
```verilog
module test;
	reg a;
	initial a = 0; //T1
	initial a = 1; //T2
endmodule
```
- Both initial blocks are executed at the same time, they are given the same preference
- At simulation time 0, it will take a look at both the blocking statements
- Both are scheduled at time 0
- It **depends on simulator**
:warning: This is an impt interview question btw

- What is the final value of `a`
```verilog
module test;
	reg a;
	initial a = 0; //Write task
	initial $display("Value of a: %b", a); //Read task
endmodule
```
- Both blocking and display tasks are in active region, again, either initial block can execute first
- The read task can be executed first, or the write task can be executed first
- If Read task is first, the value is x, if write task is first, the value is 0
- If it was a `$monitor` then first write task and then read task, cause `$monitor` comes in postponed region

- Now, adding inactive region:
- What is the final value of `a`
```verilog
module test;
	reg a;
	initial a = 0; //T1
	initial #0 a = 1; //T2
endmodule
```
- The `#0` statement makes a huge difference, first task 1 is executed in active region, then task 2 is executed **after** going to inactive region and then back to active region.

- What is the final value of `a`
```verilog
module test;
	reg a;
	initial a = 0; //Write task
	initial 
		#0 $display("Value of a: %b", a); //Read task
endmodule
```
- Active to Inactive then to active region
- Answer is 0

### NBA and Postponed Regions
```verilog
module test;
	reg a, b, c = 0;
	initial begin
		a = 1;
		b <= c;
		a <= b;
		$display("a = %0d b = %0d", a, b);
	end
endmodule
```
- In active region, a = x, b = x and c = 0
- In the initial block, (while still being in active block) a updates to 1 (provided $display doesn't get executed first)
- Hence, output of $display is `a = 1 b = x`
- Value of c is 0 and b is x for the NBA
- After this, going to the NBA region, values of b and a are updated with the **previously finalised** RHS values, 0 and x respectively
- Therefore, final value of a = x, b = 0, c = 0
- We can see the final values if we had used $monitor instead

> Simulators are smarter now, if they see a $display they give it least priority internally, even though they have equal priority in the stratified event queue

- In this program:
```verilog
module test;
	reg [1:0] a = 0, b = 1, c;
	// Update LHS = Evaluate RHS
	initial begin
		a = b;
		c = a + 1;
		$display("a = %0d c = %0d", a, c);
		$monitor("a = %0d c = %0d", a, c);
	end
endmodule
```
- The first three statements in the initial block are in active region
- **All blocking statements are sequentially executed**, hence `a = b` executes first
- Both the outputs give `a = 1 c = 2`

- Using NBA:
```verilog
module test;
	reg [1:0] a = 0, b = 1, c;
	// Update LHS = Evaluate RHS
	initial begin
		a <= b;
		c <= a + 1;
		$display("a = %0d c = %0d", a, c);
		$monitor("a = %0d c = %0d", a, c);
	end
endmodule
```
- In active region, a = 0, b = 1, c = X, and $display gives `a = 0 c = x`
- Going to NBA region, **both the NBAs are assigned at the same time** and RHS evaluation takes place in Active region, hence `a = 1 and c = 1`

- Using everything:
```verilog
module test;
	reg [2:0] a;
	// Update LHS = Evaluate RHS
	initial begin
		$strobe("Strobe a = %0d", a);
		a = 1;
		a <= 2;
		$display(" Display a = %0d", a);
	end
endmodule
```

> What is the output?
```verilog
module test;
	reg [2:0] a;
	initial begin
		$strobe("Strobe a: %0d", a);
		a = 1;
		a <= 2;
		$display("Display a: %0d", a);
	end
endmodule
```
- Active region: `a = 3'bxxxx`
- Output:
```
Display a: 1
Strobe a: 2
```

> What is the output?
```verilog
module test;
	reg a;
	initial begin
		a <= 0;
		a <= 1;
	end
endmodule
```
- Non-Blocking Assignment: `a = 0` -> `a = 1`
- Final value: `a = 1`

### Verilog coding guidelines
1. When modeling sequential logic, use non-blocking assignments
1. When modeling latches, use non-blocking asignments
1. When modeling combinational logic with an always block, use blocking assignments
1. When modeling both sequential and combinational logic within the same `always` block, use non-blocking assignments
1. Do not mix blocking and non-blocking assignments in the same `always` block
1. Do not make assignments to the same variable from more than one `always` block
1. Use $strobe to display values that have been assigned using non-blocking assignments
1. Do not make assignments using #0 delays
- You will get a wrong output if you don't follow these <3


> What is the significance of a #0 delay?
> #0 is a delay specifier that represents zero time delay. It is processed after all active events at the current simulation time have been processed, and its usage is generally not recommended. Like all delays, it is not synthesizable either in designs.

> What is difference between strobe and display?
> The $display statement is used to display the immediate values of variables or signals. It gets executed in the active region.
> The $monitor statement displays the value of a variable or a signal when ever its value changes. It gets executed in the postponed region. To monitor the value of a variable throughout the simulation, we would have to write the monitor statement only once in our code. 
> The $strobe signal displays the value of a variable or a signal at the end of the current time step i.e the postponed region.

## Races within RTL Code
- Note:
	- Stimulus generation = generating and applying input
	- Sampling = reading output
- Continuation to [Verilog Stratified Event Queue](chapter4.md#verilog-stratified-event-queue)
- Taking a look at a series of flip-flops:
```
    ┌───────┐     ┌───────┐     ┌───────┐
────►DIn   Q├─────►DIn   Q├─────►DIn   Q│
    │       │     │       │     │       │
──┬─►Clk    │  ┌──►Clk    │  ┌──►Clk    │
  │ └───────┘  │  └───────┘  │  └───────┘
  └────────────┴─────────────┘
```
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
			- `q2 = q1` gets executed, `q2 = 0` since `q1 = 0`, even though `d = 1` **in time slot 5**
			- `q1 = 1` since `d = 1`, however `q2 is still 0`, as expected
			- Reading and writing has happened on the same variable `q1` at the same time in the same region
			- Simulation output matches with hardware output
			- No issues here
		- Block 1 gets executed first:
			- `q1 = d` gets executed, `q1 = 1`
			- `q2 = q1` gets executed, AND `q2 = 1` **at time slot 5**
			- Reading and writing has happened on the same variable `q1` at the same time in the same region
			- Simulation output does **not** match the hardware output
			- This is a major issue.
- As a result, we use non-blocking assignments, as thet allow to see the old values of the flip flop inputs while sampling

### What is RTL?
- RTL = Register Transfer Logic/Level
- But in a combinational logic diagram, where is the register?
- The register is at the inputs and outputs ports have register behind them
- The logic levels are transfered through registers
- The inputs and outputs will be sampled at some clock frequency and now this circuit is synchranous
- All programs written are RTL codes, the inputs and outputs are **always** fed through registers
```
        ┌───────┐
Inp─────►       │
        │       ├──┐
      ┌─►─┐     │  │ ┌──────┐     ┌───────┐
      │ └─┴─────┘  └─►      ├─────►       ├───►O/P
      │              │ Logic│     │       │
      │ ┌──────┐  ┌──►      │     │       │
Inp───┼─►      ├──┘  └──────┘     │       │
      │ │      │                ┌─►─┐     │
      ├─►─┐    │                │ └─┴─────┘
      │ └─┴────┘                │
Clk   │                         │
──────┴─────────────────────────┘
```
- Hence while driving the stimulus, we use `@posedge clk` since everything happens in cycle level

### Race between RTL and testbench
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
- At time 1, the `reset` is applied as 1, which triggers the `always` block in the FF, and `dout` gets set as 0.
- At time 3, `reset` is changed to 0, and the program waits until time 5, for the FF to update the value. 
- Putting non-blocking in the testbench will work, but the issue is verification engineer and designer aren't the same
- Hence, it is compulsory to use non-blocking operator while generating stimulus and driving method
- Race between testbench and design module
- In reality, there will be number of blocks waiting on the posedge clk both on the testbench and DUT
- To make the verification engineer's task easy, systemverilog has something called the `program` block
- Simulator can schedule in any order, and mixing design and testbench in the same region introduces race conditions

### How to overcome the races between RTL and TB?
- The root of the probelm is the mixing of design and testbench events duting the same time slot
	- Both are written tems of sepatate modules and both execute concurrently
- The race can be avoided if the **test bench events** are **scheduled seprately** from the **design events**
- For this purspose, SV introduces a separate block named "Program block"

## SystemVerilog Stratified Event Queue
- Assertions can be written for DUT as well, they do not have any synthesizable equivalent hardware, the  ignores it
- In Verilog when both design and TB are at module level
	- In active region, blocking assignment statements & display functions are evaluated
	- In inactive region, #0 delay statements are executed
	- In NBA region, Non Blocking Assignment statements are evaluated
	- In observed region, all concurrent assertion statements that are sampled earlier are evaluated
- In SystemVerilog, testbench is in program block so design module and testbench are not at same level, which lands in reactive region after observed region
	- In Reactive region, blocking assignments and display functions in program block are evaluated
	- In Re-inactive region, #0 delay statements are executed
	- In Re-NBA region, Non-Blocking Assignment statements are evaluated
	- In postponed region, `$monitor`, `$strobe` statements are executed
- As a result, o racing occurs between DUT and Testbench in SystemVerilog

- Simplified Diagram
```
	From Previous
───────────────────┐
	Time slot      │
				   │◄─────────┐
			  ┌────▼─────┐    │ Loop back
			  │  Active  │    │ if more events
			  │ (Design) │    │
			  └────┬─────┘    │
				   ├─────────►│
			  ┌────▼────┐     │
			  │Observed │     │
			  │Assertion│     │
			  └────┬────┘     │
				   ├──────────┘
			  ┌────▼────┐
			  │Re-active│
			  │Testbench│
			  └────┬────┘
				   │        To next
				   └─────────────────────►
							Time slot
```
- Primary SystemVerilog scheduling regions
	- Active: Simulation of design code in modules
	- Observed: Evaluation on SystemVerilog assertions
	- Reactive: Executiong of testbench code in programs
	- Postponed: Sampling design signals for testbench input
	
## Program block
- General layout
```verilog
program test;
	int errors, warnings;
	initial begin
		// Main prgram activity
		// Generate stimulus
	end
	final
	$display("Test done with %0 errors and %0d warnings", errors, warnings);
endprogram
```
- Executes in re-region
- A program block may contain one or more initial or final procedures
- A program block shall not contain:
	- `always` procedures
	- Primitives
	- User-defined primitives
	- Declarations or instances of modules, interfaces, or other programs
- When all initial procedures within a program have reached their end, that program shall immediately terminate the simulation, no need for `$finish`
- Programs can only be instantiated in design scopes

- Type and data declarations within the program are local to the program scope and have static lifetime
- Variables declared within the scope of a program, including variables declared as ports, are called **program variables**
- Similarly, nets decalred within scope of a program are called **program nets**
- Program variables and nets are collectivaely termed **program signals**
- Reference to program signals from outside any program block shall be an error.

- The program block can read and write all signals in modules, and can call routines in modules, but a module has no visibility into a program.
- This is because your testbench needs to see and control the design, but the design should not depend on anything in the testbench.

#### Why no `always` blocks in a `program` block?
- In a design, an always block might trigger on every positive edge of a clock from the start of simulation.
- In contrast, a testbench has the steps of initialization, stimulate and respond to the design, and then wrap up simulation. An always block that runs continuously would not work.
- When the last initial block completes in the program, simulation implicitly ends just as if you had executed $finish .
- If you had an always block, it would run for ever, so you would have to explicitly call $exit to signal that the program completed.

#### Top-level scope
- Variables, routines, data types and parameters that are defined outside of any blocks are in the top-level scope

### What does a proper test bench look like?
- There are three files
	- `HA.sv` - Design file
	- `HA_test.sv` - Testbench file
	- `top.sv` - Top-level module
- The top level module instantiates both the design and testbenc file
- The DUT is also called RTL
- Taking a look at the top module for memory model:
```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│      ┌────────────────┬──┐        ┌──┬─────────────┐      │
│      │   PB           │WR├───────►│WR│    RTL      │      │
│      │                └──┤        ├──┘             │      │
│      │              ┌────┤        ├────┐           │      │
│      │              │ADDR├───────►│ADDR│           │      │
│      │              └────┤        ├────┘           │      │
│      ├─────┐       ┌─────┤        ├─────┐   ┌──────┤      │
└──────┤RDATA│       │WDATA├───────►│WDATA│   │ RDATA├──────┘
       ├─────┘       └─────┤        ├─────┘   └──────┤
       │                ┌──┤        ├──┐             │
       │                │RD├───────►│RD│             │
       │                └──┤        ├──┘             │
       │             ┌─────┤        ├─────┐          │
       │             │Reset├───────►│Reset│          │
       │             └─────┤        ├─────┘          │
       │               ┌───┤        ├───┐            │
       │               │Clk│◄──────►│Clk│            │
       └───────────────┴───┘   ▲    └───┴────────────┘
                               │
      ┌──────────────────┐     │
      │always #5 clk=!clk├─────┘
      └──────────────────┘
```
- Module top generates the `clk` and connects the PB (program block) and RTL
- `clk` is input to PB and RTL
- Instantiating the program block, in the top module:
```verilog
module top;
	bit clk, reset;
	logic [31:0] rdata, wdata;
	logic rd, wr;
	logic [3:0] addr;
	always #5 clk = !clk;
	
	RTL rtl_inst(rdata, wdata, rd, wr, addr, clk, reset);
	TB pgm_blk_inst(rdata, wdata, rd, wr, addr, clk, reset);
endmodule
```

### Memory Model
> Write a Verilog RTL memory model (DUT)
> Write Verilog testbench:
> 	- Write a task to apply reset to DUT
> 	- Write a task to write to all 16 locations
> 	- Write a task to read from all 16 locations 
> 	- Write comparison task to compare write data and read data
> 	- Print Test PASS or FAIL with the compare result
> For example:
> `WRITE`: `wr = 1`, `addr = 3`, `wdata = 50`
> `READ`: `rd = 1`, `addr = 3`, check for `rdata = 50`

#### Third strategy
- DUT, TB and Top module

##### Starting with the RTL block
```verilog
module rtl_memory(rdata, wdata, rd, wr, addr, clk, reset)
	
	parameter ADDR_WIDTH = 4;
	parameter DATA_WIDTH = 32;
	parameter MEM_SIZE = 16;
	
	input bit clk, reset;
	input logic wr, rd;
	input logic [3:0] addr;
	input logic [31:0] wdata;
	output [31:0] rdata;
	
	//wr = 1 => Write
	//rd = 1 => Read
	
	logic [DATA_WIDTH-1:0] mem [MEM_SIZE]; //reg [31:0] mem [16]
	logic [DATA_WIDTH-1:0] data_out;
	
	logic response; // Provides response to master on sucessful write
	logic out_enable; // Controls when to pass read data on rdata pin, additional pin it is, out_enable = rd
	
	// If rd = 0, rdata should be in high impedance state
	// If rd = 1, rdata should be content of memory with given address
	
	assign rdata = out_enable ? data_out : 'bz;
	
	//async reset and sync write
	always @(posedge clk or posedge reset) 
		begin
			if(reset)
				begin
					for(int i = 0, i < MEM_SIZE; i++)
						mem[i] <= 'b0;
				end
			else if (wr)
				begin
					mem[addr] <= wdata;
					response <= 1'b1;
				end
			else
				response <= 1'b0;
		end
	
	//sync read
	always @(posedge clk)
		begin
			if(rd == 1)
				begin
					data_out <= mem[addr];
					out_enable <= 1'b1;
				end
			else
				out_enable <= 1'b0;
		end
endmodule
```
- Synchronous WRITE and Synchronous READ (posedge clk)

- Creating the test bench with program block
```verilog
program testbench(clk, tb_reset, tb_wr, tb_rd, tb_addr, tb_wdata, tb_rdata, response);
	parameter reg[15:0] ADDR_WIDTH = 4;
	parameter reg[15:0] DATA_WIDTH = 32;
	parameter reg[15:0] MEM_SIZE = 16;
	
	input clk;
	output tb_reset;
	output tb_wr; //for write wr = 1
	output tb_rd; //for write wr = 1
	output [ADDR_WIDTH - 1:0] tb_addr;
	output [DATA_WIDTH - 1:0] tb_wdata;
	input [DATA_WIDTH - 1:0] tb_rdata;
	input response;
	
	reg tb_reset;
	reg tb_wr; //for write wr = 1
	reg tb_rd; //for write wr = 1	
	reg [ADDR_WIDTH - 1:0] tb_addr;
	reg [DATA_WIDTH - 1:0] tb_wdata;
	
	reg [DATA_WIDTH - 1:0] ref_arr [MEM_SIZE]; //Expected Data
	reg [DATA_WIDTH - 1:0] got_arr [MEM_SIZE]; //Actual Data
	
	bit [4:0] matched, mis_matched;
	
	initial
		begin
			#1
			$display("[tb] Simulation Started at time: %0t", $time);
			tb_reset = 0;
			reset();
			write();
			repeat(2) @(posedge clk);
			read();
			repeat(2) @(posedge clk);
			compare();
			result();
			#1 $display("[tb] Simulation Ended at time: %0t", $time);
		end
	
	task reset();
		#1
		$display("[tb] Applying reset at time: %0t", $time);
		tb_reset = 1;
		#3
		tb_reset = 0;
		$display("[tb] DUT out of reset at time: %0t", $time);
	endtask
	
	task write();
		reg [31:0] wdata;
		tb_wr <= 1; // Write mode
		for(int i = 0; i < MEM_SIZE; i++)
			begin
				@(posedge clk);
				tb_addr <= i;
				wdata = $urandom_range(10,999);
				tb_wdata <= wdata;
				$display("[tb] Write Addr: %0d\tData: %0d @ Time %0t", i, wdata, $time);
				ref_arr[i] = wdata; // Stores the referene data
			end
		@(posedge clk);
		tb_wr <= 1'b0';
	endtask
	
	task read();
		reg [4:0] i;
		for(i = 0; i < MEM_SIZE; i = i + 1)
			begin
				@(posedge clk);
				tb_rd <= 1;
				tb_addr <= i;
				@(tb_rdata);
				got_arr[tb_addr] = tb_rdata; //Store the received data from DUT
				$display("[tb] Read Addr: %0d\tData: %0d @ Time %0t", tb_addr, tb_rdata, $time);
			end
		tb_rd <= 1'b0;
	endtask
	
	task compare();
		for(int i = 0; i < MEM_SIZE; i++)
			begin
				if(ref_arr[i] == got_arr[i])
					matched++;
				else begin
					mis_matched++;
					$display("[ERROR] Addr: %0d\tExp.Data: %0d\tRecd.Data: %0d", i, ref_arr[i],got_arr[i]);
				end
			end
	endtask
	
	task result();
		$display("\n=================== RESULTS ===================");
		$display("[INFO] Matched: %0d\t Mismatched: %0d", matched, mis_matched);
		if(matched == MEM_SIZE && mis_matched == 0)
			$display("\n[SUCCESS]         Test PASSED");
		else
			$display("\n[FATAL]           Test FAILED");
	endtask
endprogram
```

##### Creating a top module:
```verilog
module top;
	parameter logic [15:0] ADDR_WIDTH = 4;
	parameter logic [15:0] DATA_WIDTH = 32;
	parameter logic [15:0] MEM_SIZE = 16;
	
	logic clk, tb_reset;
	logic tb_wr; // for write wr = 1
	logic tb_rd; // for write wr = 1
	logic [ADDR_WIDTH - 1:0] tb_addr;
	logic [DATA_WIDTH - 1:0] tb_wdata;
	
	logic [DATA_WIDTH - 1:0] tb_rdata;
	logic response;
	
	initial clk = 0;
	always #5 clk = !clk;
	
	memory_rtl DUT(.clk(clk), .reset(tb_reset), .wr(tb_wr), .rd(tb_rd), .addr(tb_addr), .wdata(tb_wdata), .rdata(tb_rdata), .response(response));
	
	testbench TEST(.clk(clk), .tb_reset(tb_reset), .tb_wr(tb_wr), .tb_rd(tb_rd), .tb_addr(tb_addr), .tb_wdata(tb_wdata), .tb_rdata(tb_rdata), .response(response));
	
endmodule
```
- In reality, the number of ports on a system will be huge
- What happens if we mismatch the port connections? Do we get any compile error?
	- We don't get compile error but functionality will be affected, this debugging leads to waste of time and does not add value to the design.
- This debugging leads to waste of time and does not add value to the design.
- To solve this, enter `interface` block
- Instead of using 100s of interconnects, we can group all the signals into a bus using the `interface` block

## Assertions
:warning: Add from photo
### Immediate assertions
- An immediate assertion checks if the expression is true when the statement is executed
- The testbench can check the values of the design signals and testbench vatiables and take action if there is a problem
- Assrertions result in actions, and there are four functions to print messages:
	- `$info`: Assertion failure carries no specific severity
	- `$warning`: Run-time warnings, can be supressed in tool-specific manner
	- `$error`: Run-time errors
	- `$fatal`: Run-time fatal error

### Concurrent assertions
- It is a small model that runs continuously, checking the values of signals for the entire simulation.
-  These are instantiated similarly to other design blocks and are active for the entire simulation.
- These check the sequence of events spread over multiple clock cycles
- It is evaluated on clock ticks, hence sampling clock required
- The test expression is evaluated at clock edges 
- Can be placed in a procedural block, module, interface or program
- For example:
```verilog
c_assert: assert property (@(posedge clk) not (a && b))
```
- The keyword is `property`

#### Concurrent assertion to check for `x`/`z`
```verilog
interface arb_if(input bit clk);
	logic [1:0] grant, request;
	bit rst;
	
	property request_2state;
		@(posedge clk) disable iff (rst)
		$isunknown(request) == 0; // Make sure no z or x
	endproperty
	assert_request_2state: assert property(request_2state);
endinterface
```
- Here, we don't want to procede with the check if some condition (`rst`) is true, which is why we use `disable iff()`
- `$isunknown(expression)`: If any bit of the expression is `x` or `z` then it returns `true`

## Interface
- Interface represents a bundle of nets or variables, with intelligence such as synchronization, and functional code.
- An interface can be instantiated like a module but also connected to ports like a signal.
- Syntax:
```verilog
interface interface_name (arguments);
	<interface_items>
endinterface
```
- The interface straddles two modules
```
┌──────────────────────────────────────────────┐
│    Top Module                                │
│  ┌─────────────┐           ┌──────────────┐  │
│  │           ┌─┼───────────┼─┐            │  │
│  │ Testbench │ │ Interface │ │  Arbiter   │  │
│  │           └─┼───────────┼─┘            │  │
│  └─────────────┘           └──────────────┘  │
└──────────────────────────────────────────────┘
```
- It contains the connectivity, synchronisation and functionality of the communction between two+ blocks (optional) and error checking (optional)
- Used to connect design blocks and/or testbenches
- Arbiter: The arbiter is a mediator between different system components and system resources.
- All the nets in the interface, by default, bidirectional (`inout`)
- All variables in the interface, by default, are `ref` type
- Interface blocks are to be decalred **outside** modules and program blocks
- Some compilers may not support defining an interface inside a module, if allowed, the interface is a local interface which is not visible to the rest of the design

- Taking a basic example for using interface as a port:
```verilog
interface simple_bus;
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic wr, rd;
endinterface

module RTL (simple_bus intf, input logic clk);
	logic [31:0] mem [16];
	always @(posedge clk)
		if(intf.wr == READ) //pseudo code
			intf.rdata <= mem[intf.addr];
endmodule
```
- **Note:** The RTL and TB is pseudo-code btw
```
       ┌──┬─────────────┐      
 ──────│WR│    RTL      │      
       ├──┘             │      
       ├────┐           │      
 ──────│ADDR│           │      
       ├────┘           │      
       ├─────┐   ┌──────┤      
 ──────│WDATA│   │ RDATA│
       ├─────┘   └──────┤
       ├──┐             │
 ──────│RD│             │
       ├──┘             │
       ├─────┐          │
 ──────│Reset│          │
       ├─────┘          │
       ├───┐            │
 ──────│Clk│            │
       └───┴────────────┘
```
- Taking a look at the testbench:
```verilog
program TB(simple_bus tbif, input clk);
	initial begin
		tbif.wr = 1;
		tbif.wdata = $urandom;
		tbif.addr = 5;
	end
endprogram
```
- In the `top` module:
```verilog
module top;
	logic clk = 0
	always #5 clk = !clk;
	simple_bus intf_inst();
	RTL dut_inst(intf_inst clk); // positional mapping
	TB test_inst(.tbif(intf_inst), .clk(clk)); // nominal mapping
endmodule
```
- Interface block can be written in `top` module or `rtl` module
- Interface can be used for both testbench & design, or "interface for testbench and direct mapping in design", or vice versa.
```verilog
interface simple_bus;
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic rd, wr;
endinterface: simple_bus

module top;
	bit clk;
	simple_bus intf();
	mem_rtl dut(.clk(clk), .rdata(intf.rdata), .wdata(intf.wdata), .wr(intf.wr), .addr(intf.addr), .rd(intf.rd));
endmodule
```
- Referring `2.TB Using simple interface`'s `top.sv`
```verilog
module top;
	bit clk;
	always #50 clk = ~clk;
	
	arb_if arbif(clk);
	arb_with_ifc a1(arbif);
	test_with_ifc t1(arbif);
endmodule : top
```
#### Logic v/s Wire in an interface
- If the testbench drives an async signal in an interface with procedural assignments, the signal must be of logic data type
- A wrire can be driven by a continuous assignment statement **only**
- Signals in a clocking block are synchronous and can be declared as logic or wire
- The compiler can give an error if we unintentionally use multiple structural drivers, hence we use logic

- We see that the structure is as follows:
```
┌──────────────────────────────────────────────────────┐
│    Top Module                                        │
│  ┌──────────────┐                  ┌──────────────┐  │
│  │              ├─────┐     ┌──────┤              │  │
│  │              │   ┌─▼─────▼─┐    │              │  │
│  │  Testbench   ├──►│Interface│◄───┤   Design     │  │
│  │              │   └─▲─────▲─┘    │  (Arbiter)   │  │
│  │              ├─────┘     └──────┤              │  │
│  └──────────────┘                  └──────────────┘  │
└──────────────────────────────────────────────────────┘
```
- However, one issue: how does designer know which is input and which are output?
- Enter, Modports

## Modports
- A modport defines the port direction that the module sees for the signas in the interface
```verilog
interface simple_bus(input clk); // Define the interface
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic rd, wr;
	
	modport dut_ports (input addr, wr, rd, wdata, clk, output rdata);
	modport tb_ports (output addr, wr, rd, wdata input rdata, clk);
endinterface
```
- The modport definitions do not contain vector sizes of types
- The modport declaration only defines that the connected module sees input or output, bidirectional inout or ref port
```
       ┌──┬─────────────┐      
 ─────►│WR│     RTL     │      
       ├──┴─┐           │      
 ─────►│ADDR│           │      
       ├────┴┐   ┌──────┤      
 ─────►│WDATA│   │ RDATA├───►
       ├──┬──┘   └──────┤
 ─────►│RD│             │
       ├──┴──┐          │
 ─────►│Reset│          │
       ├───┬─┘          │
 ─────►│Clk│            │
       └───┴────────────┘
```
- A modport can be declared in two manners:
	- As part of the interface connection to the module instance
	- As part of the module port declaration in the module definition
	
### As part of connection to module:
- Top Module:
```verilog
module top;
	logic clk = 0;
	RTL dut_inst(intf_inst.dut_ports, clk);
	TB test_int(intf_inst.tb_ports, .clk(clk));
endmodule
```

- Testbench:
```verilog
program TB(simple_bus tbif, input clk);
	initial begin
		@(negedge clk);
		tbif.wr = WRITE;
		tbif.wdata = $urandom;
		tbif.addr = 5;
	end
endprogram
```

- Interface:
```verilog
interface simple_bus;
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic rd, wr;
	modport dut_ports(input addr, wr, rd, wdata, clk, output rdata);
	modport tb_ports(output addr, wr, rd, wdata, input clk, rdata);
endinterface
```

- Module:
```verilog
module RTL(simple_bus intf, inout logic clk);
	logic [31:0] mem [16];
	always @(posedge clk)
		if(intf.wr == READ)
			intf.rdata <= mem[intf.addr];
	...........
endmodule
```

### As part of module port declaration
- Top Module:
```verilog
module top;
	logic clk = 0;
	simple_bus intf_inst();
	RTL dut_inst(intf_inst, clk);
	TB test_int(intf_inst, .clk(clk));
endmodule
```

- Testbench:
```verilog
program TB(simple_bus.tb_ports tbif, input clk);
	initial begin
		@(negedge clk);
		tbif.wr = WRITE;
		tbif.wdata = $urandom;
		tbif.addr = 5;
	end
endprogram
```

- Interface:
```verilog
interface simple_bus;
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic rd, wr;
	modport dut_ports(input addr, wr, rd, wdata, clk, output rdata);
	modport tb_ports(output addr, wr, rd, wdata, input clk, rdata);
endinterface
```
- Module:
```verilog
module RTL(simple_bus.dut_ports intf, inout logic clk);
	logic [31:0] mem [16];
	always @(posedge clk)
		if(intf.wr == READ)
			intf.rdata <= mem[intf.addr];
	...........
endmodule
```

### Parameterized interfaces
- Interfaces can be defined with parameters for port sizes
```verilog
interface simple_bus #(parameter DWIDTH = 32, AWIDTH = 4)(input clk);
	logic [DWIDTH-1:0] rdata, wdata;
	logic [AWIDTH-1:0] addr;
	enum_type wr;
endinterface: simple_bus
```
- In the top module, we can call the interface in the following manners:
```verilog
module top;
	simple_bus sb_intf1(); //DWIDTH = 32, AWIDTH = 4
	simple_bus #(64,8) sb_intf2(); //DWIDTH = 64, AWIDTH = 8
	simple_bus #(.DWIDTH(16), .AWIDTH(3)) sb_intf3(); //DWIDTH = 16, AWIDTH = 3
endmodule
```

### Arbiter Communication Model

- Truth table

|`rst`|`req[0]`|`req[1]`|`grnt[0]`|`grnt[1]`|
|:-:|:-:|:-:|:-:|:-:|
|1|X|X|0|0|
|0|0|1|0|1|
|0|1|0|1|0|
|0|1|1|P|P|

- Last case is based on priority

#### Case 1: Using Ports
- Design code:
```verilog
module arb_with_port (output logic [1:0] grant,
					  input logic [1:0] request,
					  input bit rst, clk);
	always @(posedge clk or posedge rst)
		begin
			if (rst)
				grant <= 2'b00;
			else if (request[0])  // High priority
				grant <= 2'b01;
			else if (request[1])  // Low priority
				grant <= 2'b10;
			else
				grant <= '0;
		end
endmodule
```
- Testbench code:
```verilog
module test_with_port (input logic [1:0] grant,
					   output logic [1:0] request,
					   output bit rst,
					   input bit clk);
	initial begin
		@(posedge clk);
		request <= 2'b01;
		$display("@%0t: Drove req = 01", $time);
		repeat (2) @(posedge clk);
		if (grant == 2'b01)
			$display("@%0t: Success: grant == 2'b01", $time);
		else
			$display("@%0t: Error: grant != 2'b01", $time);
		$finish;
	end
endmodule
```
- Top module:
```verilog
module top;
	logic [1:0] grant, request;
	bit clk;
	always #50 clk = ~clk;
	
	arb_with_port a1 (grant, request, rst, clk);
	test_with_port t1 (grant, request, rst, clk);
endmodule
```
- The RTL Diagram looks like follows:
```
┌──────────────────────────────────────────────┐
│                   Testbench                  │
│    ┌────────────────────────────────────┐    │
│    │                                    │    │
│    │ request[1:0]┌─────────┐ grant[1:0] │    │
│    ├─────────────►         ├───────────►│    │
│    │             │ Arbiter │            │    │
│    │   rst       │         │    clk     │    │
│    ├─────────────►         ◄─────▲──────►    │
└────┘             └─────────┘     │      └────┘
```

#### Case 2: Using interface
- RTL:
```
┌──────────────────────────────────────────────────────┐
│    Top Module                                        │
│  ┌──────────────┐                  ┌──────────────┐  │
│  │              ├─────┐     ┌──────┤              │  │
│  │              │   ┌─▼─────▼─┐    │              │  │
│  │  Testbench   ├──►│Interface│◄───┤   Design     │  │
│  │              │   └─▲─────▲─┘    │  (Arbiter)   │  │
│  │              ├─────┘     └──────┤              │  │
│  └──────────────┘                  └──────────────┘  │
└──────────────────────────────────────────────────────┘
```
- Design code:
```verilog
module arb_with_ifc (arb_if arbif);
	always @(posedge arbif.clk or posedge arbif.rst)
		begin
			if (arbif.rst)
				arbif.grant <= 2'b00;
			else if (arbif.request[0])  // High priority
				arbif.grant <= 2'b01;
			else if (arbif.request[1])  // Low priority
				arbif.grant <= 2'b10;
			else
				arbif.grant <= '0;
		end
endmodule
```
- Testbench code
```verilog
module test_with_ifc (arb_if arbif);
	initial begin
		@(posedge arbif.clk);
		arbif.request <= 2'b01;
		$display("@%0t: Drove req = 01", $time);
		repeat (2) @(posedge arbif.clk);
		if (arbif.grant == 2'b01)
			$display("@%0t: Success: grant == 2'b01", $time);
		else
			$display("@%0t: Error: grant != 2'b01", $time);
		$finish;
	end
endmodule
```
- Interface code:
```verilog
interface arb_if(input bit clk);
	logic [1:0] grant, request;
	bit rst;
endinterface
```
- Top module
```verilog
module top;
	bit clk;
	always #50 clk = ~clk;
	
	arb_if arbif(clk);
	arb_with_ifc a1(arbif);
	test_with_ifc t1(arbif);
endmodule : top
```

#### Case 3: Using modport in module port declaration
- RTL
```
┌──────────────────────────────────────────────────────┐
│    Top Module                                        │
│  ┌──────────────┐                  ┌──────────────┐  │
│  │              ├─────┐     ┌──────┤              │  │
│  │              │   ┌─▼─────▼─┐    │              │  │
│  │  Testbench   ├──►│ Modport │◄───┤   Design     │  │
│  │              │   └─▲─────▲─┘    │  (Arbiter)   │  │
│  │              ├─────┘     └──────┤              │  │
│  └──────────────┘                  └──────────────┘  │
└──────────────────────────────────────────────────────┘
```
- Design:
```verilog
module arb_with_mp (arb_if.DUT arbif);
	always @(posedge arbif.clk or posedge arbif.rst)
		begin
			if (arbif.rst)
				arbif.grant <= 2'b00;
			else if (arbif.request[0])  // High priority
				arbif.grant <= 2'b01;
			else if (arbif.request[1])  // Low priority
				arbif.grant <= 2'b10;
			else
				arbif.grant <= '0;
		end
endmodule
```
- Testbench
```verilog
module test_with_mp (arb_if.TEST arbif);
	initial begin
		@(posedge arbif.clk);
		arbif.request <= 2'b01;
		$display("@%0t: Drove req = 01", $time);
		repeat (2) @(posedge arbif.clk);
		if (arbif.grant == 2'b01)
			$display("@%0t: Success: grant == 2'b01", $time);
		else
			$display("@%0t: Error: grant != 2'b01", $time);
		$finish;
	end
endmodule
```

- Interface
```verilog
interface arb_if(input bit clk);
	logic [1:0] grant, request;
	bit rst;
	modport TEST (output request, rst, input grant, clk);
	modport DUT (input request, rst, clk, input grant);
endinterface
```

- Top Module
```verilog
module top;
	bit clk;
	always #50 clk = ~clk;
	
	arb_if arbif(clk);
	arb_with_mp a1(arbif);
	test_with_mp t1(arbif);
endmodule : top
```

#### Case 4: Using modport in connection to module
- RTL
```
┌──────────────────────────────────────────────────────┐
│    Top Module                                        │
│  ┌──────────────┐                  ┌──────────────┐  │
│  │              ├─────┐     ┌──────┤              │  │
│  │              │   ┌─▼─────▼─┐    │              │  │
│  │  Testbench   ├──►│ Modport │◄───┤   Design     │  │
│  │              │   └─▲─────▲─┘    │  (Arbiter)   │  │
│  │              ├─────┘     └──────┤              │  │
│  └──────────────┘                  └──────────────┘  │
└──────────────────────────────────────────────────────┘
```
- Design:
```verilog
module arb_with_mp (arb_if arbif);
	always @(posedge arbif.clk or posedge arbif.rst)
		begin
			if (arbif.rst)
				arbif.grant <= 2'b00;
			else if (arbif.request[0])  // High priority
				arbif.grant <= 2'b01;
			else if (arbif.request[1])  // Low priority
				arbif.grant <= 2'b10;
			else
				arbif.grant <= '0;
		end
endmodule
```
- Testbench
```verilog
module test_with_mp (arb_if arbif);
	initial begin
		@(posedge arbif.clk);
		arbif.request <= 2'b01;
		$display("@%0t: Drove req = 01", $time);
		repeat (2) @(posedge arbif.clk);
		if (arbif.grant == 2'b01)
			$display("@%0t: Success: grant == 2'b01", $time);
		else
			$display("@%0t: Error: grant != 2'b01", $time);
		$finish;
	end
endmodule
```

- Interface
```verilog
interface arb_if(input bit clk);
	logic [1:0] grant, request;
	bit rst;
	modport TEST (output request, rst, input grant, clk);
	modport DUT (input request, rst, clk, input grant);
endinterface
```

- Top Module
```verilog
module top;
	bit clk;
	always #50 clk = ~clk;
	
	arb_if arbif(clk);
	arb_with_mp a1(arbif.DUT);
	test_with_mp t1(arbif.TEST);
endmodule : top
```

### Advantages of Interfaces
- An interface is ideal for design reuse. When two blocks communicate with a specified protocol using more than two signals, consider using an interface. If groups of signals are repeated over and over, as in a networking switch, you should additionally use virtual interfaces
- The interface takes the jumble of signals that you declare over and over in every module or program and puts it in a central location, reducing the possibility of misconnecting signals.
- To add a new signal, you just have to declare it once in the interface, not in higher-level modules, once again reducing errors.
- Modports allow a module to easily tap a subset of signals from an interface. You can specify signal direction for additional checking.

### Disadvantages of Interfaces
- For point-to-point connections, interfaces with modports are almost as verbose as using ports with lists of signals. Interfaces have the advantage that all the declarations are still in one central location, reducing the chance for making an error.
- You must now use the interface name in addition to the signal name, possibly making the modules more verbose, but more readable for debugging.
- If you are connecting two design blocks with a unique protocol that will not be reused, interfaces may be more work than just wiring together the ports.
- It is difficult to connect two different interfaces. A new interface (bus_if) may contain all the signals of an existing one (arb_if), plus new signals (address, data, etc.). You may have to break out the individual signals and drive them appropriately.


## Clocking Block
- A clocking block assembles signals that are synchronous to a particular clock and makes their timing explicit
```verilog
clocking clocking_blk @(edge specifier);
	<items>
endclocking
```
- Signals in a clocking block are driven or sampled synchronously, ensuring that your testbench interacts with the signals at the right time.

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
	T5      T15     T25     T35
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
- Checking time `#5` slot, `outp1` is initially `x`
- When `outp1 <= count` executes, the updated value of `0` is stored during the Non-Blocking region
- When we check `sig1` it is present in the Re-active region, and as a result, we must ask ourselves the questions again: We're in `#5` time, there is a clock edge available, and the next posedge is at `#15`
- Whatever value was present in `#1` before current time slot in `outp1` right before execution of `sig1 = vif.cb.outp1`, that value will be stored in `sig1` i.e., from the Postponed region.
	- See: [Skews](chapter4.md#skews) 
- As a result, `sig1` is `x`
- When it comes to sampling, it doesn't matter whether old or new data is collected, but we can use `#0` to collect the new value

### Default Clocking Blocks
- Clocking blocks can be specified as the default for all cycle delay operations
```verilog
program test(simple_bus.tb intf);
	default clocking bus @(posedge intf.clk);
	endclocking
	
	initial begin
		##5; // Wait for 5 clock cycles
		// repeat(5) @(posedge intf.clk)
		if(intf.cb.data == 10)
			##1; // Wait for one clock cycle
		// @(posedge intf.clk);
	end
endprogram
```
- `#X`: Regular delay
- `##X`: Clock cycle delay
- If our clocking block is as follows:
```verilog
default clocking bus @(posedge clk);
	output data;
endclocking
```
### Synchronous Drives
- We can write to `data` in the following ways:
	- `bus.data[3:0] <= 4'h5`: Drive data to `0005` in Re-NBA region of current cycle 
	- `##1; bus.data <= 8'hz`: Wait a clock cycle and then drive data to `zzzz_zzzz`
	- `##2; bus.data <= 2`: Wait 2 clock cycles and then drive data to `0000_0010`
	- `bus.data <= ##2 r`: Remember the value of `r` and then drive data to the value of `r` 2 clock cycles later (`##2 r` is called an intra-assignment delay)
	- `bus.data <= #2 r`: Illegal, regular intra-assignment delays are not allowed

### Skews
```
     Rising Edge
       |
       |
    |  |──|─┐
    |  |  | │
   ─|──|  | └──
    |     |
    |     |
    |     Signal
 Signal   Driven
Sampled
```
- If input skew is specified, signal is sampled at **skew time units** before the clock event
- If output skew is specified, signal is driven at **skew time units** after the clock event
- Default input skew: `#1`
- Default output skew: `#0`
- For example:
```verilog
clocking cb_mem @(posedge clk);
	input #1ns rdata;
	output #2ns wdata, addr, wr;
endclocking
``` 
- **or**
```verilog
clocking cb_mem @(posedge clk);
	default input #1ns output #2ns
	input rdata;
	output wdata, addr, wr;
endclocking
``` 
- In both cases, there is `#1` input skew and `#2` output skew
