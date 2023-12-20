## `constraint_mode`
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
## Disabling random variables
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

## In-line constraints
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

## Uniqueness constraints
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

## `std::randomize()`
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

## Hierarchial randomization
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

## External constraint block
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

## Solution probabilities
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

## Valid constraints
- A good randomization technique is to create several constraints to ensure the correctness of your random stimulus, known as "valid constraints"

```verilog
class Transaction;
	typedef enum {BYTE, WORD, LWRD, QWRD} 
```
:warning: take from slide 86, Chapter 6 - PPTs

## `pre_randomize()` and `post_randomize()`
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

## Random number functions
- `$random` - Flat distribution, returning signed 32-bit random
- `$urandom` - Flat distribution, returning signed 32-bit random
- `$urandom_range` - Flat distribution over a range
- `$dist_exponential` - Exponential decay
- `$dist_normal` - Bell-shaped distribution
- `$dist_poisson` - Bell-shaped distribution
- `$dist_uniform` - Flat distribution

## Using non-random variable
- Turning off randomness of a variable using `rand_mode()` and using it like a normal variable
:warning: slide 98

## Checking values using constraints
Slide 99
## Randomizing Individual Variables
Slide 100

