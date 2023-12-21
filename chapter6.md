# Chapter 6: Randomization
- As designs grow larger, it becomes more difficult to create a complete set of stimuli needed to check their functionality
- The solution is to create test cases automatically using constrained- random tests (CRT). A directed test finds the bugs you think are there, but a CRT finds bugs you never thought about, by using random stimulus.
- You restrict the test scenarios to those that are both valid and of interest by using constraints.

- When you think of randomizing the stimulus to a design, the first thing you may think of are the data fields.
- The challenging bugs are in the control logic. As a result, you need to randomize all decision points in your DUT.

- There are some in-built directives that help us generate random values
	- `$random`
	- `$urandom`
	- `$urandom_range(min, max)
	- `$randomize`
- We can randomize the following:
	- Variables that contain a simple set of bits.
		- 2-state types
		- 4-state types (only 2-state values)
		- integers
		- bit vectors
- You cannot have a random
	- string
	- refer to a handle in a constraint.
	- real variables

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
	
- We create a class to hold a group of related random variables, then have the random solver fill them with random values
- Then we create constraints to limit the random values to legal values or to test specific features


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

## Constraints
- A constraint is just a set of relational expressions that must be true for the chosen value of the variables.
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
	- `rand bit[3:0] a` - Gives a standard distribution, values are uniformly distributed over their range
	- `randc bit[3:0] a` - Cycle through all the values in a random permutation of their declared range
- The values of random variables are determined using constraint expressions that are declared using constraint blocks

- The randomize function returns 0 if a problem is found with the constraints
- The code checks the result and stops simulation with $finish if there is a problem

- You should never randomize an object in the class constructor
	- Your test may need to turn constraints on or off, change weights, or even add new constraints before randomization
- The constructor is for initializing the object’s variables, and if you called randomize at this early stage, you might end up throwing away the results
	- Variables in your classes should be random and public
	- This gives your test the most control over the DUT’s stimulus and control

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

#### Some other examples
- [Randomization of arrays](https://www.edaplayground.com/x/DP5V)
- [Constraints outside the class](https://www.edaplayground.com/x/JrD6)
- [Constraints](https://www.edaplayground.com/x/fua9)
- [Assertions and Constraints](https://www.edaplayground.com/x/j5sU)
- [Using `rand` and `randc`](https://www.edaplayground.com/x/XCiz)
- [Using `randc`](https://www.edaplayground.com/x/tiKe)
- [Using `rand`](https://www.edaplayground.com/x/DP3D)

### Set Membership and `inside` operator
- The solver chooses between the values in the set with equal probability, unless there are other constraints on the variable
```verilog
class A;
	rand integer a, b, c;
	constraint c2 {
		a inside {b, c};
	}
endclass

int arr[4] ='{5, 10, 15, 20};
rand int v1, v2;
constraint c3 {!(v1 inside {arr};)}  // v1 != 5, v1 != 10, v1 != 15, v1 != 20, any value except
constraint c4 {(v1 inside {arr};)}   // v2 = 5, v2 = 10, v2 = 15, v2 = 20

rand bit [6:0] b; // 0 to 127
rand bit [5:0] e;
constraint c_range {
	b inside {[$:4], [20:$]};
	e inside {[$:4], [20:$]};
}
```
- `a inside {b, c}`
- Gives `a == b || a == c`
- Another example:
```verilog
class Ranges;
	rand bit [31:0] c; // Random variable
	bit [31:0] lo, hi; // Non-random variables, used as limits
	constraint c_range {
		c inside {[lo:hi]}; // lo <= c && c <= hi
		!(c inside {[lo:hi]}); // c < lo || c > hi
	}
endclass
```


###  Weighted distributions using `dist` operator
```verilog
class A;
	rand int src, dst;
	constraint c_dist {
		src dist {0 := 40, [1:3] := 60};
		// src = 0, weight = 40/100
		// src = 1, weight = 60/100
		// src = 2, weight = 60/100
		// src = 3, weight = 60/100
		dst dist {0 :/ 40, [1:3] :/ 60};
		// dst = 0, weight = 40/100
		// dst = 1, weight = 20/100
		// dst = 2, weight = 20/100
		// dst = 3, weight = 20/100
	}
endclass

program test;
	A a1;
	bit ret;
	
	initial begin
		a1 = new;
		repeat (220)
			void'(a1.randomize();) //Converts to a void type
	end
endprogram
```
- Weighted distributions
- `:=` Equivalence distribution
- `:/` Divided distribution
- The dist operator allows you to create weighted distributions so that some values are chosen more often than others.
- The `:=` operator specifies that the weight is the same for every specified value in the range
- The `:/` operator specifies that the weight is to be equally divided between all the values.

- Values and weights can be constants or variables
- We can use variable weights to change distributions on the fly or even to eliminate choices by setting the weight to zero
```verilog
// Bus operation, byte word or long word
class BusOp;
	// Operand length
	typedef enum {BYTE, WORD, LWRD} length_e;
	rand length_r len;
	
	// Weights for dist constraint
	bit [31:0] w_byte = 1, w_word = 3, w_lwrd = 5;
	
	constraint c_len {
		len dist {
			BYTE := w_byte, // Choose a random
			WORD := w_word, // length using
			LWRD := w_lwrd  // variable weights
		};
	}
endclass
```

> `'` is used for type casting

### Conditional Constraints
```verilog
typedef enum {S, M, JUMBO_FRAMES} pkt_type_e;
class A;
	rand pkt_type_e pkt_size;
	rand int len;
	
	constraint c_len_frames {
		if (pkt_size == JUMBO_FRAMES)
			len inside {[2000:5000]};
		else
			len inside {[64:1024]};
	}
endclass

program test;
	A a1;
	bit ret;
	
	initial begin
		a1 = new;
		ret = a1.randomize();
	end
endprogram
```
- The value gets generated based on output frame size, if it's 0 or 1 (small or medium) the number is in between 64 and 1024, if it's 2 (jumbo) the number is inbetween 2000 and 5000
- [On EDA playground](https://www.edaplayground.com/x/d44z)

### Implication constraints
```verilog
class A;
	rand bit x; // 0 or 1
	rand bit [1:0] y; // 0 1 2 3
	
	constraint c_xy {
		(x == 0) -> y == 0;
	}
endclass

program test;
	A a1;
	bit ret;
	
	initial begin
		repeat (5) begin
			a1 = new;
			ret = a1.randomize();
			$display(a1.x, " ", a1.y);
		end
	end
endprogram
```
- Program output:
```
1 1
1 2
1 0
0 0
0 0
```
- Implication operator `->` says that when x = 0, y is forced to 0
- When y = 0, there is no constraint on x
- However, implication is bidirectional; if y were forced to a non-zero value, x would have to be 1

```verilog
class BusOp;
	rand bit [31:0] addr;
	rand bit io_space_mode;
	constraint c_io {
		io_space_mode -> addr[31] == 1'b1;
	}
	// same as
	constraint c_io {
		if (io_space_mode)
			addr[31] == 1'b1;
	}
endclass
```
- The expression A -> B, when the implication operator appears in a constraint, the solver picks values for A and B so that expression is true
- When A is true, B must be true, but when A is false, B can be true/false
- Note that this is a partly bidirectional constraint, but that A -> B does not imply B -> A
- The two expressions produce different results

| A -> B | B = false | B = true |
|:---------:|:----:|:----:|
| A = False | True | True |
| A = True | False | True |

- When A is true, B is also true
- When A is false, B is true or false

### `solve ... before ...` statement
```verilog
class A;
	rand bit x; // 0 or 1
	rand bit [1:0] y; // 0 1 2 3
	
	constraint c_xy {
		(x == 0) -> y == 0;
		solve x before y;
	}
endclass

program test;
	A a1;
	bit ret;
	
	initial begin
		repeat (5) begin
			a1 = new;
			ret = a1.randomize();
			$display(a1.x, " ", a1.y);
		end
	end
endprogram
```
- Sometimes, it is desirable to force certain combinations to occur more frequently
- This mechanism helps in ordering the variables so that x can be chosen independent of y
- `solve-before` randomises with equal probability
- Program output:
```
1 3
1 1
1 2
1 2
1 2
0 0
1 0
1 0
0 0
0 0
```

### Constraining individual array elements
```verilog
class A;
	rand bit [31:0] len[]; //dynamic array
	constraint c_len {
		foreach (len[i])
			len[i] inside {[1:255]}; // Each element must be in between 1 and 255
		len.size() inside {[1:8]};
		len.sum < 1024;
	}
endclass
```
- As a result, the following is generated:
```
len[] = {56, 250, 120, 177}
len.size = 4
len.sum = 603
```


### Bidirectional Constraints
- Adding or removing a constraint on any one variable affects the value chosen for all variables that are related directly or indirectly
- All are solved concurrently
```verilog
class Bidir;
	rand bit [15:0] r, s, t;
	constraint c_bidir {
		r < t;
		s == r;
		t < 10;
		s > 5;
	}
endclass
```
- All are solved in parallel
- The SystemVerilog solver looks at all four constraints simultaneously.
- The variable r has to be less than t , which has to be less than 10.
- However, r is also constrained to be equal to s, which is greater than 5.
- Even though there is no direct constraint on the lower value of t , the constraint on s restricts the choices.

|Solution|`r`|`s`|`t`|
|:------:|:-:|:-:|:-:|
| A | 6 | 6 | 7 |
| B | 6 | 6 | 7 |
| C | 6 | 6 | 7 |
| D | 6 | 6 | 7 |
| E | 6 | 6 | 7 |
| F | 6 | 6 | 7 |

### Equivalence Operator
- The equivalence operator `<->` is bidirectional
- AB is defined as `((A->B) && (B -> A))`

| A <-> B | B = false | B = true |
|:-------:|:----:|:----:|
| A = False | True | False |
| A = True | False | True |

- For example
```verilog
rand bit d, e;
constraint c {(d == 1) <-> (e == 1);}
```
- When `d` is true, `e` must also be true
- When `d` is false, `e` must also be false
- This operator is compared to a logical XNOR

### Solution probabilities
- Whenever we deal with random values, we need to understand the probability of the outcome
- SystemVerilog does not guarantee the exact solution found by the random constraint solver, but we can influence the distribution
```verilog
class Unconstrained;
	rand bit x;
	rand bit [1:0] y;
endclass
```
- Adding implication constraint
```verilog
class Imp1;
	rand bit x;
	rand bit [1:0] y;
	constraint c_xy {
		(x == 0) -> (y == 0);
	}
endclass
```
- Adding additional constraint with implication constraint
```verilog
class Imp2;
	rand bit x; // 0 or 1
	rand bit [1:0] y; // 0, 1, 2, 3
	constraint c_xy {
		y > 0; // Force y = 1, 2, 3
		(x == 0) -> (y == 0);
	}
endclass
```

- Solutions:

|Solution|`x`|`y`| P(1) | P(2) | P(3) |
|:------:|:-:|:-:|:---:|:---:|:---:|
|A|0|0|1/8|1/2|0|
|B|0|1|1/8|0|0|
|C|0|2|1/8|0|0|
|D|0|3|1/8|0|0|
|E|1|0|1/8|1/8|0|
|F|1|1|1/8|1/8|1/3|
|G|1|2|1/8|1/8|1/3|
|H|1|3|1/8|1/8|1/3|


- Guiding distribution with `solve-before`
```verilog
class SolveXBeforeY;
	rand bit x;
	rand bit [1:0] y;
	constraint c_xy {
		(x == 0) -> (y == 0);
		solve x before y;
		solve y before x;
	}
endclass
```
- Solution

|Solution|`x`|`y`| P(1) | P(2) |
|:------:|:-:|:-:|:---:|:---:|
|A|0|0|1/8|1/2|1/8|
|B|0|1|1/8|0|0|
|C|0|2|1/8|0|0|
|D|0|3|1/8|0|0|
|E|1|0|1/8|1/8|1/8|
|F|1|1|1/8|1/8|1/4|
|G|1|2|1/8|1/8|1/4|
|H|1|3|1/8|1/8|1/4|

### `constraint_mode`
- A class can contain multiple constraint blocks
- At run time, you can use the built-in constraint_mode() routine to turn constraint on and off
```verilog
class Packet;
	rand int length;
	constraint c_short {length inside {[1:32]};}
	constraint c_long {length inside {[1000:1023]};}
endclass

Packet pkt;
initial begin
	pkt = new;
	pkt.c_long.constraint_mode(0); // Disables constraint c_long, generates length in range 1 - 32
	pkt.randomize();
end
```
[Randomization Example](https://www.edaplayground.com/x/4Pp3)

### Disabling random variables
- Using rand_mode(), we can control whether a random variable is active or inactive
```verilog
class A;
	rand int x, y, z;
endclass

A a1;
initial begin
	a1 = new;
	a1.rand_mode(0); // Turn off all variables in object
	a1.x.rand_mode(1); // Turn on rand mode for variable x
	a1.randomize();
end
```
- Other functions include `randc_mode()`

### In-line constraints
- Giving extra constraints to the existing constraints
```verilog
class Transaction;
	rand bit [31:0] addr, data;
	constraint c1 {addr inside {[0:100], [1000:2000]};}
endclass

Transaction t;
initial begin
	t = new();
	// addr is 50-100, 1000-1500, data < 10
	t.randomize() with {addr >= 50; addr <= 1500; data < 10;};
	// force addr to a specific value, data > 10
	t.randomize() with {addr == 2000; data > 10;};
end
```
- Equivalent to adding an extra constraint to any existing ones in effect

### Uniqueness constraints
- A group of variables can be constrained using the `unique` constraint so that no two members of the group have the same value after randomization
```verilog
class A;
	rand byte a[5];
	rand byte addr;
	rand byte data;
	constraint u {unique {addr, a[2:3], data};}
endclass
```
- Variables `a[2]`, `a[3]`, `addr` and `data` will contain all different values after randomization
- Note: This code will fail when the datatype is `bit`, as 0 and 1 have only two states, and four variables are required

### `std::randomize()`
- The scope randomize function, `std::randomize()`, enables users to randomize data in the current scope without the need to define a class or instantiate a class object
```verilog
rand bit [15:0] addr;
rand bit [31:0] data;
rand bit success, rd, wr;

initial begin
	success = std::randomize(addr, data, wr);
end
```
- Used when class concepts are not used, can add constraints
```verilog
rand bit [15:0] addr;
rand bit [31:0] data;
rand int a, b, c;

initial begin
	success = std::randomize(a, b) with {a < b;};
	success = std::randomize(a, b, c) with {(b - a) > c;};
end
```

### Hierarchial randomization
```verilog
class A;
	rand bit [3:0] addr;
endclass

class B;
	rand bit [7:0] data;
	A a1;
	
	function new();
		a1 = new;
	endfunction
endclass

B b1;
initial begin
	b1 = new;
	void'(b1.randomize()); // Only data gets randomized
	void'(b1.a1.randomize()); // data and addr gets randomized
end
```
- This is not very conveinent
```verilog
class A;
	rand bit [3:0] addr;
endclass

class B;
	rand bit [7:0] data;
	rand A a1; // Creating handle with rand keyword
	
	function new();
		a1 = new;
	endfunction
endclass

B b1;
initial begin
	b1 = new;
	void'(b1.randomize()); // Both addr and data gets randomized
end
```
- This ensures all members are randomized

### External constraint block
```verilog
class packet;
	rand bit [7:0] addr;
	rand bit [31:0] data;
	
	extern constraint valid_c;
endclass

constraint packet::valid_c {
	addr inside {[0:15]};
	data inside {[100:500]};
}
```
- We move the constraint outside the class to make the class look clean, just like functions and tasks

### Valid constraints
- A good randomization technique is to create several constraints to ensure the correctness of your random stimulus, known as "valid constraints"

```verilog
class Transaction;
	typedef enum {BYTE, WORD, LWRD, QWRD} length_e;
	typedef enum {READ, WRITE RMW, INTR} access_e;
	rand length_e length;
	rand access_e access;
	
	constrain valid_RMW_LWRD {
		(access == RMW) -> (length == LWRD);
	}
endclass
```
- The bus transaction obeys the rule, if we want the system to violate the rules, we can use `constraint_mode` to turn it off to generate errors

### `pre_randomize()` and `post_randomize()`
- The `randomize()` method generates random values for all the active random variables of an object, subject to the active constraints.
- Variables declared with the rand keyword will get random values on the `object.randomize()` method call.
- The `randomize()` method returns 1 if the randomization is successful i.e on randomization it’s able to assign random values to all the random variables, otherwise, it returns 0.
- On calling `randomize()`, `pre_randomize()` and `post_randomize()` functions will get called before and after the randomize call respectively
- These functions are written inside a class
- Need not be explicitly called, when calling `randomize()`, will call `pre_randomize()`, `randomize()` and `post_randomize()` if present
- `randomize()` method is associated with two callbacks:
	- `pre_randomize()`
	- `post_randomize()`
- `pre_randomize()`
	- Used to set the pre-conditions before the object randomizations
	- Turning on and off random variables, writing randomization control logic, etc
	
- `post_randomize()`
	- Used to check and perform post-conditions after the object randomizations
	- Override randomized values, print randomized values, etc
- These are **built-in methods, and are **callbacks** associated with `randomize()` function
```verilog
class packet;
	rand bit [7:0] addr;
	randc bit [7:0] wr_rd;
	bit tmp_wr_rd;
	
	function void pre_randomize();
		$display("Inside pre_randomize");
		if (tmp_wr_rd == 1)
			addr.rand_mode(0);
		else
			addr.rand_mode(1);
	endfunction
	
	function void post_randomize();
		$display("Inside post_randomize");
		tmp_wr_rd = wr_rd;
		$display("Addr = %0d, WR_RD = %0d", addr, wr_rd);
	endfunction
endclass

module rand_method;
	initial begin
		packet pkt;
		pkt = new();
		repeat(4)
			pkt.randomize();
	end
endmodule
```
[Pre-Post Randomization](https://www.edaplayground.com/x/6JNh)

#### Bathtub and pre-randomize
- We build a bathtub distribution as follows:

![Bathtub distribution](https://upload.wikimedia.org/wikipedia/commons/7/78/Bathtub_curve.svg)

- High on both ends, low in the middle
- This can be made using `$dist_exponential` and `pre_randomize()`
```verilog
class bathtub;
	int value; // Random variable with bathtub dist
	int WIDTH = 50, DEPTH = 6, seed = 1;
	
	function void pre_randomize();
		// Calculate an exponential curve
		value = $dist_exponential(seed, DEPTH);
		if (value > WIDTH)
			value = WIDTH;
		
		// Randomly put this point on the left or right curve
		if ($urandom_range(1)) // Random 0/1
			value = WIDTH - value;
	endfunction
endclass
```

### Random number functions
- `$random` - Flat distribution, returning signed 32-bit random
- `$urandom` - Flat distribution, returning signed 32-bit random
- `$urandom_range` - Flat distribution over a range
- `$dist_exponential` - Exponential decay
- `$dist_normal` - Bell-shaped distribution
- `$dist_poisson` - Bell-shaped distribution
- `$dist_uniform` - Flat distribution

- `$urandom_range(3, 10) = $urandom_range(10, 3)`

### Using non-random variable
- Turning off randomness of a variable using `rand_mode()` and using it like a normal variable
```verilog
// Packet with variable length payload
class Packet;
	rand bit [7:0] length, payload[];
	constraint c_valid {
		length > 0;
		payload.size() == length;
	}

	function void display(input string msg);
		$display("\n%s:", msg);
		$write("\tPacket length: %0d, bytes = ", length);
		for(int i = 0; (i < 4 && i < payload.size()); i++)
			$write(" %0d", payload[i]);
		$display;
	endfunction
	
endclass

Packet p;
initial begin
	p = new();
	`SV_RAND_CHECK(p.randomize()); // Randomize all variables
	p.display("Simple randomize");
	p.length.rand_mode(0); // Disable random-ness of length,
	p.length = 42;         // and set it to a constant value
	`SV_RAND_CHECK(p.randomize()); // and randomize the payload
	p.display("Randomize with rand_mode");
end
```
- Packet size is stored in the random variable length
- First half of the test randomizes both the `length` variable and the contents of the `payload` dynamic array 
- Second half calls rand_mode to make length a non-random variable, sets it to 42, then calls `randomize`
- The constraint sets the pay-load size at the constant `42`, but the array is still filled with random values

### Checking values using constraints
- If you randomize an object and then modify some variables, you can check that the object is still valid by checking if all constraints are still obeyed

- Call `handle.randomize(null)` and SystemVerilog treats all variables as non-random (state variables) and just ensures that all constraints are satisfied, i.e all expressions are true. If any constraints are not satisfied, the randomize function returns 0.

### Randomizing Individual Variables
```verilog
class Rising;
	bit [7:0] low; // Not random
	rand bit [7:0] med, hi; // random variables
	constraint up {
		low < med; 
		med < hi;
	}
endclass

initial begin
	Rising r;
	r = new();
	r.randomize(); // Randomize med, hi, low is unaltered
	r.randomize(med); // Only med is randomized
	r.randomize(low); // Randomize only low
end
```
- We can pass a non-random variable, and `low` is given a random value, as long as it obeys the constraint
