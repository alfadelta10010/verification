# Class 3
bit - unsigned - 1 bit - 0,1
byte - signed - 8 bits - -128 - 127

integer is a verilog datatype, it's called int (32 bit) in systemverilog, short int (16 bit) and long int (64 bit)

to use unsigned, mention unsigned
```systemverilog
int unsigned i2;
```

int = -2147483648 to 2147483647
long int = -9223372036854775808 to 9223372036854775807
shirtint = -32768 


real data type 
- 64 bit = real
- 32 bit = shortreal

all sv types (real bit byte int) are 2 state
all v types (integer reg wire real time) are 4 state
**logic** is the only 4 state data type in systemverilog


Styles of designing:
- Dataflow model
- Behavioural model
- Structural model

Dataflow model:
- Used when boolean expression of the system is given
- Consists of continuous assignment statements
- For example:
```systemverilog
module andgate(a, b, y);
input a, b;
output y;
assign y = a & b;
endmodule
```

Behavioural style:
- Used when the behaviour of the system (truth table) is given, but not the boolean expression and the gate level diagram
- Consists of proceudral blocks and blocking and non-blocking assignments
- For example;
```systemverilog
module andgate(a, b, y);
input a, b;
output y;
always_comb
	y = a & b;
endmodule
```

Structural style:
- Used when the gate level diagram is present
- Uses built-in primitives (and, not, xor, xnor, or, nand, nor) and user-defined primitives (UDP) (eg: FA module)
- For example:
```systemverilog
module andgate(a, b, y);
input a, b;
output y;
and I1 (y, a, b);
endmodule
```
- `and (a, b, y)`: Positional port mapping
- `and (.y(y), .b(b), .a(a))`: Nominal port mapping


# The Logic datatype
- Take a look at this example:
```verilog
module test;
	reg a;
	assign a = 1;
	initial
		begin
			$display(a);
		end
	endmodule
```
- this will not work, as reg data type does not get assigned, only wire (net data types) gets assigned
- Lets take a look at another example:
```verilog
module test;
	wire a;
	initial
		begin
			$display(a);
		end
	endmodule
```
- This also does not work, as wire (a net datatype) cannot be used inside a procedural block
- Designers need to mix different datatypes introducing ambiguity
- This is major pain, introducing ``logic``
- ``logic`` automatically assigns as a net or reg data type based on usage
- A logic signal can be used anywhere a net is used:
```sysverilog
module logic_datatype(input logic rst_h);
	logic q1, q2, q3, q4, inp;
	initial q1 = 0; // Procedural assignment
	assign q2 = inp; // Continuous assignment
	not not_inst (q3, inp); // Q3 is being driven by a primitive 
	my_dff d1(q4, inp, clk, rst_h); // q4 is driven by a module
endmodule
```
- However, a logic variable cannot be driven by multiple structual drivers
```sysverilog
assign q1 = 0;
initial q1 = 2;
```

Overview of data types:
- bit: 2 state unsigned, 1 bit
- byte: 2 state signed, 8 bits
- int: 2 state signed, 32 bits
- shortint: 2 state signed, 16 bits
- longint: 2 state signed, 64 bits
- shortreal: 2 state signed single-precision floating point, 32 bits
- real: 2 state signed signle-precision floating point, 64 bits
- string: array of characters to stre string
- logic: 4 state signed, 1 bit (?)


Strings:
- If we want to save a name "vinay" for example
- There's no defined verilog data type to save
- For one letter, you need 8 bits, so for 5 letters you need 8 * 5 = 40 bits
```verilog
module st;
	wire [39:0] a;
	assign a = "vinay";
	initial
		$display(a);
endmodule
```
- In SystemVerilog, the string data type does the calculation for you:
```systemverilog
module st;
	string a;
	assign a = "vinay";
	initial
		$display(a);
endmodule
```

# Directed and Random testing
## Directed testing
- Look at the hardware specicication and write a verification plan with a list of tests, each of which concentrated on a set of related features
- (+) Produces almost immediate results
- (+) Given ample time and staffing, directed testing is sufficient to verify nany designs
- (-) When the design complexity doubles, it takes twice as a long to complite or requires twice as many people to implement
- `<Insert graph: Directed test progress over time>`

## Random testing
- RTG: Random TestVector generation
- `<Insert graph: Directed Test vs Random test progress over time>
- We call it constrained random testing, as we give a constrianed set of values
- Smiley = Feature, Ladybug = Bug, Rectangle = test
- Random tests often cover a wider space than a directed test
- This wider coverage leads to illegal areas and overalling tests
- Illegal areas are avoided with stronger constraints on the random test generation
- Overlapping tests are used to find bugs that were missed earlier
- Writing directed tests for features not covered by the random test are required

## Paths to achieve complete coverage
- Write a constrained-random test with test vectors
- Run with many different seeds, look at the coverage
- Check for functionalility that was not covered, and write constraints that weren't covered
- Repeat until coverage improves and reaches 100%
- If coverage stagnates, write directed tests for the test

# Principles of Verification
- Constrained-random stimulus:
	- Random stimulus is crucial for exercising complex designs instead of applying directed test stimulus
- Functional coverage
	- When using random stimuli, we need functional coverage metric to measure verification progress
- Layered testbench using transactors
	- We need automated way to predict the results: A reference model or scoreboard
	- Building the testbench infrastructure includuing self-prediction
	- A layered testbench helps you control the complexity by breaking the problem down 
- Common testbench for all tests
	- We can build a testbench infrastructure that can be shared by all tests and does not have to be continually modified	
- Test case-specific code kept separate from the test bench
	- Code specific to a a single test must be kept separate  
		
# Summary [till 18/8]:
- Different levels of testing
	- Block level testing
	- Integration level
	- System level
	- Error handling
- Basic Testbench functionality
- Directed v/s Constrined-Random testing
- Basic principles of verification (5 principles)
- Paths to achieve complete coverage
- SystemVerilog 2 state data types
- SystemVerilog Logic data type
- String data type
