# Interprocess communication
## Threads
- The power of parallel threads
- How to create threads
- How to control the threads
- Communication between threads

### Creating threads
- `fork`/`join` blocks provide the primary mechanism for creating concurrent processes
- `fork`/`join` | `join_none` | `join_any` create threads
- SystemVerilog introduces two new ways to create threads, within the fork we can use:
	- `join_none` statements
	- `join_any` statements
- `join-<option>` will decide when code after the fork-join should execute

#### `join`
- Taking the following example:
```verilog
task display1();
	$display("From task 1\n");
endtask

task display2();
	$display("From task 2\n");
endtask

task display3();
	$display("From task 3\n");
endtask

program test;
	initial begin
		$display("Started\n");
		fork
			display1();
			display2();
			display3();
		join
		$display("Ended");
	end
endprogram
```
- The different tasks have equal priority, hence output can be like:
```
Started
From task 3
From task 1
From task 2
Ended
```
- Once all the statements between `fork` and `join` are completed, the statement after `join` is executed
- This is equivalent to `join_all`
```
    ┌────────┐
    │  Fork  │
    └───┬────┘
  ┌─────┼─────┐
┌─▼─┐ ┌─▼─┐ ┌─▼─┐
│   │ │   │ │   │
└─┬─┘ └─┬─┘ └─┬─┘
  └─────┼─────┘
      ┌─▼─┐
      │AND│
      └─┬─┘
  ┌─────▼─────┐
  │ join_all  │
  └───────────┘
```
- All the tasks will start at the same time, and have the same priority
- The concurrent threads can execute at the same time

#### `join_any`
- Taking the following example:
```verilog
task display1();
	$display("From task 1\n");
endtask

task display2();
	$display("From task 2\n");
endtask

task display3();
	$display("From task 3\n");
endtask

program test;
	initial begin
		$display("Started\n");
		fork
			display1();
			display2();
			display3();
		join_any
		$display("Ended");
	end
endprogram
```
- All the different tasks need not complete, hence (incomplete) output can be like:
```
Started
From task 2
Ended
```
- Only one task needs to complete for the fork to join again
- If any one of the statement is completed after execution, the `fork` and `join_any` will execute the statement after `join_any`
- **However**, the simulator checks if there were any tasks that were scheduled, and **completes any pending tasks**
- Once you reach the end of the simulation, the scheduled statements will get executed
```
Started
From task 2
Ended
From task 1
From task 3
```
- The logic is as follows:
```
     ┌─────────┐
     │  Fork   │
     └────┬────┘
  ┌───────┼──────┐
┌─▼──┐ ┌──▼─┐ ┌──▼─┐
│----│ │----│ │----│
│----│ │----│ │----│
└─┬──┘ └──┬─┘ └──┬─┘
  └───────┼──────┘
        ┌─▼─┐
        │Or │
        │   │
        └─┬─┘
    ┌─────▼─────┐
    │ join_all  │
    └───────────┘
```
- We don't use functions because, we can't have delays in functions, and functions return the values immediately

#### `join_none`
- Taking the following example:
```verilog
task display1();
	$display("From task 1\n");
endtask

task display2();
	$display("From task 2\n");
endtask

task display3();
	$display("From task 3\n");
endtask

program test;
	initial begin
		$display("Started\n");
		fork
			display1();
			display2();
			display3();
		join_none
		$display("Ended");
	end
endprogram
```
- If we want tasks to get executed at program termination, then we use `join_none`
- Output becomes like:
```
Started
Ended
From Task 2
From Task 1
From Task 3
```
- In the case of fork and join_none, the statements are scheduled but not executed
```
         ┌─────────┐
         │  Fork   │
         └────┬────┘
              │
┌─────┬───────┼──────┐
│     │       │      │
│   ┌─▼──┐ ┌──▼─┐ ┌──▼─┐
│   │    │ │    │ │    │
│   │    │ │    │ │    │
│   └─┬──┘ └──┬─┘ └──┬─┘
│     │       │      │
└─────────────┐
              │
              │
        ┌─────▼─────┐
        │ join_none │
        └───────────┘
```

### Controlling threads
- `wait fork`
- `wait (expression)`
- `wait_order (statements)`
- `disable`
- `disable fork`
- `events`

#### `wait_fork`
- Taking the following example:
```verilog
task display1();
	#2;
	$display("From task 1\n");
endtask

task display2();
	$display("From task 2\n");
endtask

task display3();
	$display("From task 3\n");
endtask

program test;
	initial begin
		$display("Started\n");
		fork
			display1();
			display2();
			display3();
		join_any
		$display("Ended");
		wait fork
	end
endprogram
```
- Without `wait_fork`, the program executes as follows:
```
Started
From task 2
Ended
From task 3
```
- After this, the program ends with `endprogram`
- We insert `wait_fork` to ensure task 1 gets executed
- This is not useful for `join_all`, it's used for `join_any`
- With `wait_fork`, the program executes as follows:
```
Started
From task 2
Ended
From task 3
From task 1
```
- The `wait fork` statement blocks process execution flows until all immediate child subprocesses (processes created by the current process, excluding their descendants) have completed their execution
- The `wait fork` statements allows the program block to wait for the completion of all concurrent threads before exiting
- The `wait fork` statement shall block the execution flow of the task until all spawned processes complete before returning to its caller
- When all the `initial blocks in the program are done, the simulator exits
- Use the `wait fork` statement to wait for all child threads

#### `disable fork`
- Taking the following example:
```verilog
initial begin
	$display("Start of simulation \n");
	fork
		$display("Thread 1\n");
		$display("Thread 2\n");
		$display("Thread 3\n");
	join_any
	disable fork;
	$display("End of simulation\n");
end
```
- Output is as follows:
```
Started
From task 2
Ended
```