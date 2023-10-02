# Verilog Stratified Event Queue
- There are 4 regions in Verilog
	- Active region
	- Inactive region
	- Non Blocking Assignment Region
	- Postponed Region

#### Active Region:
- Consists of:
	- Blocking assignments
	- Evaluate RHS of NBA: `y <= a + b`, evaluates a+b
	- `$display` statements
	- Evaluate inputs and updates outputs of primitives
- Active Event Queue

#### Inactive region
- Time 0 (#0) assignments

#### NBA region
- Updates LHS of NBA
- `y <= a + b`, updates y with value

#### Postponed Region
- $strobe and monitor statements
- `<add stuff from notes>`

## Control flow:
Active -> Inactive -> NBA -> Postponed
   /\         |        |
   |__________|        |
   |___________________/
- After one cycle of these, simulator goes to time 1, and so on so forth   

## Active Event Queue
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
> This is an impt interview question btw

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
- If it was a `$monitor` then first write task and then read task, cause monitor comes in postponed region

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

## NBA and Postponed Regions
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

> Practice the examples from slides as well, `1. Chapter 4 PPTs.pdf`, page 23

## Verilog coding guidelines
1. When modeling sequential logic, use non-blocking assignments
1. When modeling latches, use non-blocking asignments
1. When modeling combinational logic with an always block, use blocking assignments
1. When modeling both sequential and combinational logic within the same `always` blovk, use non-blocking assignments
1. Do not mix blocking and non-blocking assignments in the same `always` block
1. Do not make assignments to the same varable from more than one `always` block
1. Use $strobe to display values that have been assigned using non-blocking assignments
1. Do not make assignments using #0 delays
- You will get a wrong output if you don't follow these <3


> What is the significance of a #0 delay?
> #0 is a delay specifier that represents zero time delay. It is processed after all active events at the current simulation time have been processed, and its usage is generally not recommended. Like all delays, it is not synthesizable either in designs.

> What is difference between strobe and display?
> The $display statement is used to display the immediate values of variables or signals. It gets executed in the active region.
> The $monitor statement displays the value of a variable or a signal when ever its value changes. It gets executed in the postponed region. To monitor the value of a variable throughout the simulation, we would have to write the monitor statement only once in our code. 
> The $strobe signal displays the value of a variable or a signal at the end of the current time step i.e the postponed region.