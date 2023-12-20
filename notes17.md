# Interprocess communication
## Disable particcular thread
- Take the following example
```verilog
fork
	begin: t1
		@ev1; //Event mention
		//->ev1; Event triggering
		#100 task1();
	end
	
	begin :t2
		@reset;
		disable t1;
	end
join
```
- The program has two threads, `t1` and `t2`
- `t1` and `t2` are waiting on their events, `ev1` and `reset`
- When `reset` occurs, `t1` gets killed
- In order to kill a particular thread, we use `disable <thread name>`
- Taking another example
```verilog
event event_done;
fork
	begin: t1
		drive_stimulus();
	end
	
	begin: t2
		@event_done;
		disable t1;
	end
join
```
- At fork, both `t1` and `t2` start execution
- In thread 1, `drive_stimulus()` starts execution
- In thread 2, when `event_done` occurs, the next statement executes, killing thread 1

> We use fork and join to create concurrent processes

## Mailbox
- A mailbox is a communcation mechanism that allows messages to be exchanged between proceses. 
- Data can be sent to a mailbox by one process and retrived by another
- Mailbox helps us communicate between two threads without any loss of data
- It is used for interprocess communcation
- Mailbox is a built-in class data type
	- Hence we must create a handle and construct it with some size
	- Uses FIFO principle
- `put` method places the argument values into the mailbox
- `put` is a blocking method, places the data into the mailbox if it is empty, else it will block and wait till the mailbox becomes empty
- `put` **copies the data** to the mailbox
- `get` method retrives the data out of the mailbox and assign it to the argument supplied
- `get` is a blocking method, if no data is available it blocks until the data is available
- `get` **removes the data** from the mailbox
- If the type of the message variable is not equivalent to the type of the message in the mailbox, a run-time error is generated
- **Note:** If we create the handle as follows:
```verilog
mbx = new;
```
- Then we create an **unbounded mailbox**, can accomodate unlimited values
- ***Used in industry***
- Take a look at the following code:
```verilog
mailbox mbx;
int j;
initial begin
	mbx = new(1); //Mailbox size 1
	fork
		for (int i = 1; i <= 3; i++) //Thread 1
			begin
				$display("Producer: before put(%0d)", i);
				mbx.put(i);
				$display("Producer: after put(%0d)", i);
			end
		
		repeat(3) //Thread 2
			begin
				mbx.get(j);
				$display("Consumer: after get(%0d)", j);
			end
	join
end
```
- We must use the **same data type** that we are saving and retriving from the mailbox, `int i` and `int j`
- These **7 functions** (`get`, `put`, `try_get`, `try_put`, `peek`, `try_peek` and `num`) are in-built
- The output is as follows
```
Producer: before put(1)
Producer: after put(1)
Producer: before put(2)
Consumer: after get(1)
Producer: after put(2)
Producer: before put(3)
Consumer: after get(2)
Producer: after put(3)
Consumer: after get(3)
```
- The size of the mailbox is important, if it was size 3, then thread 1 would not be blocked, and it would copy all the values, 1 2 3 into the mailbox, and thread 2 would copy all the data out of the mailbox
```
Producer: before put(1)
Producer: after put(1)
Producer: before put(2)
Producer: after put(2)
Producer: before put(3)
Producer: after put(3)
Consumer: after get(1)
Consumer: after get(2)
Consumer: after get(3)
```
- `put` is blocking method, which may become a hinderance
- Enter `try_put()`, which tries to place a message in a mailbox witout blocking
- If the mailbox is not full, then the specified message is placed in the mailbox, and the function returns a positive integer
- If the mailbox is full, then the message is not placed, and the function returns 0
- `get` is blocking method, which may become a hinderance
- Enter `try_get()` which tries to retrieve a message from the mailbox without blocking
- If the mailbox is empty, the function returns 0
#### Additional functions
- `peek()`: The `peek` method copies a message from a mailbox without removing the message from the queue

- If the mailbox is empty, the current process blocks until a message is placed in the mailbox
- `try_peek()`: The `try_peek` method tries to copy a message from a mailbox without removing the message from the queue
- If the mailbox is empty, then the method returns 0 without copying the message
- `num()`: The `num` method returns the number of messages currently in the mailbox

### Parameterised Mailbox
- Normal mailbox
```verilog
mailbox mbx;
mbx = new(10);
```
- It accepts any kind of data
- On the other hand, a parameterised mailbox:
```verilog
mailbox #(int) mbox;
mbox = new(10);
```
- Accepts only values of integer type
- All type mismatches are caught by the compiler and not at run-time
- Can give all data types as parameter

## Semaphore
- SystemVerilog provides a powerful and easy-to-use set of synchronization mechanism that can be created and reclaimed dynamically
- This set comprises of a `semaphore` built-in class, which can be used for synchronization and **mutual exclusion to shared resources**
- For example, let there be 3 threads, requiring a shared resource
- To decide which thread receieves the shared resource, we use semaphores 
- The steps are as follows:
```verilog
semaphore sem; //Creating handle
sem = new(1);  //Creating object with 1 key
sem.get(1);    //Retrieving the key
sem.put(1);    //Returning the key
```
- Here, the semaphore has 1 key
- `get()`: If the specified number of keys is available, the method returns and execution continues. If the specified number of keys is not available, the process blocks until the keys become available
- When the `put()` function is called, the specified number of keys is returned to the semaphore
- The semaphore try_get() method is used to procure a specified number of keys from a semaphore but without blocking
- Get key, use resource, return key, repeat
- Taking the following code snipped:
```verilog
class Driver;
	semaphore sem;
	task run();
		sem = new(1);
		mbx.get(tr)
		fork
			device1_drive(tr);
			device2_drive(tr);
		join
	endtask
	
	task device2_drive(packet tr);
		sem.get(1);
		@(bus.cb); //waits for bus to be available
		bus.cb.addr <= tr.addr;
		bus.cb.data <= tr.data;
		...
		sem.put(1);
	endtask
	
	task device1_drive(packet tr);
		sem.get(1);
		@(bus.cb); //waits for bus to be available
		bus.cb.addr <= tr.addr;
		bus.cb.data <= tr.data;
		...
		sem.put(1);
	endtask
endclass
```
- Assuming `device1_drive()` gets the key first, `device2_drive()` will be blocked until `device1_drive()` returns the key, cause only 1 key exists
- This is known as mutual exclusion of shared resources

> 1/2 markers from semaphore

# Events
- There is always the possibility of a race condition in verilog where one thread blocks on an event at the same time another triggers it
- If the triggering thread executes before the blocking thread, the trigger is missed
```verilog
event e1;
initial begin
	$display("@%0t: 1: before trigger", $time);
	-> e1;
end
initial begin
	@e1;
	$display("@%0t: 2: after trigger", $time);
end
```
- Output is as follows:
```
@0: 1: before -<ended>
```
- or
```
@0: 1: before trigger
@0: 2: after trigger
```
- To ensure the race doesn't occur, we use persistent triggered property
## Persistent triggered property
- SystemVerilog introduces the `triggered()` method that lets you check whether an event has been triggered including the during the given time slot
- The triggered event property helps eliminate a common race condition which occurs when both the trigger and wait happen at the same time
```verilog
event e1;
initial begin
	$display("@%0t: 1: before trigger", $time);
	-> e1;
end
initial begin
	wait(e1.triggered());
	$display("@%0t: 2: after trigger", $time);
end
```

## Event Sequencing: `wait_order()`
- The wait_order construct suspends the calling process until all the specified events are triggered in the given order, left to right.
```verilog
event a, b, c;
bit success;
wait_order(a, b, c);
success = 1
else
	success = 0;
```
- Suspends the current process until events a, b and c trigger in the order a -> b -> c
- If the events trigger out of order then `else` part is executed

> Interview question
- What is the output?
```verilog
program test;
	initial begin
		for(int j = 0; j < 3; j++)
			fork
				$display(j);
			join_none
		#0
		$display("\n");
	end
endprogram
```
- Nothing gets displayed at the `$display(j)` during execution, since `join_none` schedules all for after simulation, but the value of `j` gets incremented each time
- Due to the false condition of `j < 3` (`j = 3`), the `for` loop breaks, and the simulation ends
- All the statements that were scheduled for after simulation get executed
- Hence, the output is:
```



333
```
- To solve the problem, we can modify as:
```verilog
program test;
	initial begin
		for(int j = 0; j < 3; j++)
			fork
				automatic int k = j
				$display(k);
			join_none
		#0
		$display("\n");
	end
endprogram
```
- The value of `j` gets copied to k, and the output becomes:
- Hence, the output is:
```



012
```