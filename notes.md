# Class 3
- `bit`		unsigned	1 bit	0,1
- `byte`	signed		8 bits	-128 to 127

- `integer` is a Verilog datatype, it's called `int` (32 bit) in systemverilog, `short int` (16 bit) and `long int` (64 bit)

- To use unsigned, mention unsigned
```verilog
int unsigned i2;
```

- `int` = -2147483648 to 2147483647
- `long int` = -9223372036854775808 to 9223372036854775807
- `short int` = -32768 to 32767


### Real data type 
- 64 bit = real
- 32 bit = shortreal

- all sv types (real bit byte int) are 2 state
- all v types (integer reg wire real time) are 4 state
- **logic** is the only 4 state data type in systemverilog


# Styles of designing:
- Dataflow model
- Behavioural model
- Structural model

## Dataflow model:
- Used when boolean expression of the system is given
- Consists of continuous assignment statements
- For example:
```verilog
module andgate(a, b, y);
	input a, b;
	output y;
	assign y = a & b;
endmodule
```

## Behavioural style:
- Used when the behaviour of the system (truth table) is given, but not the boolean expression and the gate level diagram
- Consists of proceudral blocks and blocking and non-blocking assignments
- For example;
```verilog
module andgate(a, b, y);
	input a, b;
	output y;
	always_comb
		y = a & b;
endmodule
```

## Structural style:
- Used when the gate level diagram is present
- Uses built-in primitives (and, not, xor, xnor, or, nand, nor) and user-defined primitives (UDP) (eg: FA module)
- For example:
```verilog
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
- This will not work, as reg data type does not get assigned, only wire (net data types) gets assigned
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
- This is major pain, introducing `logic`
- `logic` automatically assigns as a net or reg data type based on usage
- A logic signal can be used anywhere a net is used:
```verilog
module logic_datatype(input logic rst_h);
	logic q1, q2, q3, q4, inp;
	initial q1 = 0; // Procedural assignment
	assign q2 = inp; // Continuous assignment
	not not_inst (q3, inp); // q3 is being driven by a primitive 
	my_dff d1(q4, inp, clk, rst_h); // q4 is driven by a module
endmodule
```
- However, a logic variable cannot be driven by multiple structual drivers, like follows
```verilog
assign q1 = 0;
initial q1 = 2;
```

# Overview of data types:
- `bit`: 2 state unsigned, 1 bit
- `byte`: 2 state signed, 8 bits
- `int`: 2 state signed, 32 bits
- `shortint`: 2 state signed, 16 bits
- `longint`: 2 state signed, 64 bits
- `shortreal`: 2 state signed single-precision floating point, 32 bits
- `real`: 2 state signed signle-precision floating point, 64 bits
- `string`: array of characters to store string
- `logic`: 4 state unsigned, used in place of reg


# Strings:
- Holds variable-length strings
- An individual character is of `byte` type
- The elements of the string of length N are numbered 0 to N-1
- Memory is dynamically allocated
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
```verilog
module st;
	string a;
	assign a = "vinay";
	initial
		$display(a);
endmodule
```
- The function `getc(N)` returns the byte at location N
```verilog
string s;
initial begin
	s = "IEEE"
	$display(s.getc(0)); // 73
	$display(s.getc(1)); // 69
	$display(s.getc(2)); // 69
	$display(s.getc(3)); // 69
end
```

- The function `toupper()` returns an upper-case copy of the string, and `tolower()` returns a lowercase copy
```verilog
$display(s.tolower());
$display(s.toupper());
```

- The task `putc(M, C)` writes a byte c into a string at location M
