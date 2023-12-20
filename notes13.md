# Randomization
- There are some in-built directives that help us generate random values
	- `$random`
	- `$urandom`
	- `$urandom_range(min, max)
	- `$randomize`

### Types of randomization
- Pseudo-randomization
	- Generates values with time as a seed
	- If you do on two days, same time, you will get same values (?)
```verilog
module test;
	int a;
	initial begin
		repeat(10) begin
			a = $random();
			$display("Value is %d", a);
		end
	end
endmodule
```

- Randomization with seed
	- Uses a seed given by user
```verilog
module test;
	int a;
	initial begin
		a = $random(130);
		$display("Value is %d", a);
		repeat(9) begin
			a = $random();
			$display("Value is %d", a);
		end
	end
endmodule
```

- Randomization with constraints
```verilog
module top;
	int a;
	int b;
	int c;
	initial begin
		randomize(a, b, c) with {
			a > 10;
			b inside (3,4,9);
			c > a + b;
			// no assignments allowed
		}
	end
	$display("Value is %d, %d, %d", a, b, c);
endmodule
```
- The constraints ad random variables are moved into a class

### Constraints
- The values of random variables are determined using constraint expressions that are declared using constraint blocks
```verilog
class class_name;
	<class_properties>;
	rand <sv_data_type>;
	randc <sv_data_type>;
	
	constraint cons_name{
		<constraints_expression_n_items>;
	}
	<class_methods>;
endclass
```
- You cannot randomise public or standard variables, only random variables
- Hence we have `rand` and `randc` variable type
- `rand`: Standard Random {0, 5, 2, 1, 5, 8, 9, 8}
- `randc`: Cyclic Random {0, 5, 2, 1, 8, 9} - No repetition allowed

- `rand` and `randc` are not data types, so:
	- `rand bit[3:0] a;` - Gives a standard distribution, values are uniformly distributed over their range
	- `randc bit[3:0] a;` - Cycle through all the values in a random permutation of their declared range
- The values of random variables are determined using constraint expressions that are declared using constraint blocks

#### `randc` variables
- `randc bit [1:0] y`
- The variable y can take on the values 0, 1, 2, 3 (range of 0 to 3)
- The basic idea is that `randc` randomly iterates over all the values in the range and that no value is repeated within an iteration

```verilog
class A;
	randc bit [1:0] y;
endclass

program test;
	A a;
	initial begin
		a = new;
		repeat(12) begin
			a.randomize();
			$display("a.y = %0d", a.y);
		end
	end
endprogram
```
- Initial permutation: `0 -> 2 -> 1 -> 3`
- Next permutation: `3 -> 1 -> 0 -> 2`
- Next permutation: `2 -> 1 -> 0 -> 3`
- The `randomize()` goes to the class to check all random and cyclic random variables, if there are any constraints
- Here there are no constraints, so it assgins random generated value and returns 1 on successful randomization

#### Simple constraints
```verilog
class A;
	rand bit [7:0] len, addr, src, sel;
	rand bit [31:0] data;
	rand bit wr, sel;
	constraint my_cstr 
	{
		addr > 0;
		addr < 15;
		wr == 1;
		data > 100 && data < 500;
		len <= src;
		if (sel == 10) 
		{
			src inside {10, [30:40], [66:88], 100};
		}
		else 
		{
			src inside{[199:255]};
		}
	}
endclass
```
### EDA Playground example
- [Link](https://www.edaplayground.com/x/nFrb)
```verilog
program test;
	Packet pkt;
	initial begin
		pkt=new;
		repeat(100) begin
			$display("******************************");
			pkt.k = 4;
			pkt.randomize;
			pkt.print();
			$display("******************************");
		end
	end
endprogram
```

- Main class
```verilog
class Packet;
	bit [3:0] k;
	rand bit [7:0] sa,da;
	rand bit [31:0] payload[];
	
	constraint valid {
		sa inside {[1:8]};
		k < 5;//checker
	}
	
	constraint kkk {
		da > 1 && da < 9;
	}
	
	constraint con_arr {
		foreach(payload[i]) 
			payload[i] inside {[1:255]};
	}
  
	constraint gen_arr {
	  payload.size inside {[1:9]};
	}
	
	function void print();
		$display("[Packet] OLD k=%0d sa=%0d da=%0d payload.size=%0d payload=%0p",k,sa,da,payload.size(),payload);
	endfunction
endclass
```
- Output:
```
# ******************************
# [Packet] OLD k=4 sa=8 da=7 payload.size=3 payload=69 168 23
# ******************************
# ******************************
# [Packet] OLD k=4 sa=2 da=7 payload.size=4 payload=84 223 164 205
# ******************************
# ******************************
# [Packet] OLD k=4 sa=3 da=8 payload.size=4 payload=163 23 5 98
# ******************************
# ******************************
# [Packet] OLD k=4 sa=2 da=3 payload.size=1 payload=250
# ******************************
# ******************************
# [Packet] OLD k=4 sa=4 da=7 payload.size=9 payload=250 252 99 196 245 85 34 170 14
# ******************************
```
- Payload is an array of 32 bits, the values in each spot are limited by `con_arr` constraint, and the size of the array is limited by the `gen_arr` constraint
- Value of `sa` is regulated to be between 1 and 8 by the `valid` constraint, and value of `da` is controlled by the `kkk` constraint
- If we change the value of k in the testbench to 6, we get the following output:
```
******************************
# testbench.sv(11): randomize() failed due to conflicts between the following constraints:
# 	design.sv(11): valid { 1'h0; }
# ** Note: (vsim-7130) Enabling enhanced debug (-solvefaildebug=2) may generate a more descriptive constraint contradiction report and -solvefaildebug testcase.
# ** Note: (vsim-7106) Use vsim option '-solvefailtestcase[=filename]' to generate a simplified testcase that will reproduce the failure.
# ** Warning: (vsim-7084) No solutions exist which satisfy the specified constraints; randomize() failed.
# 
#    Time: 0 ns  Iteration: 0  Process: /test/#INITIAL#6 File: testbench.sv Line: 11
# [Packet] OLD k=6 sa=0 da=0 payload.size=0 payload=
# ******************************
```
- This happens because the constraint `valid` is violated.

### What to Randomize
- Verification involves the verification of:
	- Device configuration
		- Most common reason why bugs are missed during testing of the RTL design is not enough different configurations have been tried! 
		- Most tests just use the design as it comes out of reset, or apply a fixed set of initialization vectors to put it into a known state.
	- Environment configuration
		- The device that you are designing operates in an environment containing other devices.
		- When you are verifying the DUT, it is connected to a testbench that mimics this environment.
		- You should randomize the entire environment, including the number of objects and how they are configured.
	- Primary Input data
		- This is what you probably thought of first when you read about random stimulus
	- Encapsulated Input data (internal signals)
		- Many devices process multiple layers of stimulus.
		- Each level has its own control fields that can be randomized to try new combinations. 
		- So you are randomizing the data and the layers that surround it.
	- Protocol Exceptions, Errors, and Violations
		- When two devices communicate, what happens if the transfer stops partway through? Can your testbench simulate these breaks?
		- If there are error detection and correction fields, you must make sure all combinations are tried.
	- Delays
		- Many communication protocols specify ranges of delays. 
		- Your testbench should always use random, legal delays during every test to try to find that (hopefully) one combination that exposes a design bug.
	
- You should never randomize an object in the class constructor
	- Your test may need to turn constraints on or off, change weights, or even add new constraints before randomization.
- The constructor is for initializing the object’s variables, and if you called randomize at this early stage, you might end up throwing away the results.
	- Variables in your classes should be random and public. This gives your test the most control over the DUT’s stimulus and control.