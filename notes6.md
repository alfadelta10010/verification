# SystemVerilog Tasks
- Syntax: `task task_name(arguments);`
- `task`: Keyword
- `arguments`: inputs/outputs
- Example:
```verilog
task my_task (output logic x, input logic y);
	----------
	statements
	----------
endtask
```
- The same rules of functions apply for the arguments in the task

## Task with Timing control
```verilog
task mem(input [31:0] addr, expected_data, output success);
	logic [31:0] data;
	@(posedge clk);
	data = mem[addr];
	success = (data == expected_data);
endtask
```
- `@(posedge clk)`: waits only for the first positive edge only
- `always @(posedge clk)`: Triggers at ever positive edge, all statements get executed

## Calling a task
```verilog
program test;
	bit result;
	mem(30, 50, result);
	if (result == 1)
		$display("Pass: Data Match");
	else
		$display("Fail: Data Mismatch");
	end
endprogram
```
- A stack will be allocated when task is called, for all the variables which are in the task
- After computation and result, the stack is deallocated

## Automatic tasks
- Let's analyse the following code, where a task is called twice
```verilog
module top;
	logic [4:0] m, k;
	task test(input [3:0] n, output [4:0] out);
		$display("%0d %0t", n, time);
		#2
		out = n + 5;
		$display("%0d %0t", n, time);
	endtask
	initial
		test(5, k); //c1
	initial
		#1
		test(10, m); //c2
endmodule
```
- Here, the task is called in 2 procedural (inital) blocks
- At simulation time 0, the compiler has indentified there are two variables, a task and allocated a stack for it, and execution of the procedural blocks begins: `c1` is executed, `c2` is blocked with `#1` delay.
- `c1: n = 5 @ time = 0`: `n = 5, out = x`
- From 0 to 1, `c1` is blocked by the `#2` delay in the task
- At simulation time 1, `c2` starts execution, and since `c1` is blocked, the value is updated
- `c2: n = 10 @ time = 1`: `n = 10, out = x`
- From 1 to 2, `c2` is blocked by the `#2` delay in the task
- At simulation time 2, `c1` resumes execution, and `out = n + 5` statement is executed. While one would expect `c1: out = 10, n = 5`, *this is not what happens* ***as the stack is shared***. In the stack, `n = 10` so `out = 15`
- `c1: out = 15 @ time = 2`: `n = 10, out = 15`
- At simulation time 3, when `c2` resumes execution, the same result will be generated again.
- `c2: out = 15 @ time = 2`: `n = 10, out = 15`
- This output is clearly not desired, we use `automatic` keyword to declare tasks with **automatic storage** - Different stack is allocated for each call, resulting in no stack sharing
```verilog
task automatic test(input [3:0] n, output [4:0] out);
```
- By using automatic storage we are able to overcome the problem caused due to stack sharinf when the same stack is called multiple times while one of them is waiting
- At the start of simulation time 3, `c1` stack gets deallocated, and only `c2` stack remains, after finishing that is also deallocated

### Concise notes
- When a task is created, a stack is allocated
- Whenever a task is called multiple times, it will use the same stack as allocated before, a new stack will not be assigned to the task
- The output of the first call is corrupted by the second call when the tasks are waiting simultaneously
- The problem is stack is shared
- Solution: each caller should have its own stack
- By using automatic storage, we overcome this problem

# ref direction
- Physical connection
- `initial`: Starts executing @ simulation time 0
- `always`: Starts executing when there is a change in the sensitivity lst
- If we want physically connected, then change directions to `ref`

> :warning: Refer slides for code, procedure
- Ref works both directions (inout), both as input and as output
- Advantage: When we want to pass large sized arrays to methods, we usually use ref direction
- Disadvantage: Since ref is visible, a write (change) on the vale of ref will trigger the blocks waiting on it
- To overcome this, we can set it as `const ref`, to be used for read-only operations in methods