# SystemVerilog Procedural Blocks
- SystemVerilog has two types of procedural blocks
	- `always` block (and it's sub-types)
	- `initial` block
	- `final` block
	- `tasks` block
	- `functions` block

## `always` block
- Synthesizable
- Used in designs, to generate purpose modeling **in verilog**
- Executes multiple times, based on sensitivity list
- Triggered based on sensitivity list
- At RTL level, the `always` procedural block **in verilog** is used to model:
	- combinational logic
	```verilog
		always @(a, b)
			begin
				sum = a + b;
				diff = a - b;
				prod = a * b;
			end
	```
	- latched logic
	```verilog
		always @(a, b)
			begin
				sum = a + b;
				diff = a - b;
				prod = a * b;
			end
	```
	- flip flop logic
	```verilog
		always @(a, b)
			begin
				sum = a + b;
				diff = a - b;
				prod = a * b;
			end
	```
- Take the following example:
```verilog
always@(a, en)
	if(en) y = a;
```
- Here, the latch would be required to realise the procedural block's functionality
- SystemVerilog gets rid of the ambiguity
```verilog
always_comb
	if(en) y = a;
``` 
- The tool warns that a latch is required here, even though the designer's intent was combinational logic

> When sensitivity list and designer intent are not matching, it is an incomplete sensitivty list

### Advantages of `always_comb`:
- It is used to indicate inent to model combinational logic, and it infers sensitivity list automatically:
```verilog
always_comb // (mode, a, b)
	if(!mode)
		y = a + b;
	else
		y = a - b;
end
```
- All variables on the left (`y` above) cannot be written to by any other procedural block:
```verilog
always @(sel or inp1 or inp2)
	begin
		if(sel)
			out = inp1;
		else
			out = inp2;
	end
always @(sel)
	out = !inp3;
```
- The above code is bad, but it won't give an error, `out` gives random values as both `always` blocks are run simultaneously
```verilog
always_comb 
	begin
		if(sel)
			out = inp1;
		else
			out = inp2;
	end
always @(sel)
	out = !inp3;
```
	- This gives a compiler error
- Time-0 Initialization problem:
**write from slides idk bro**
	- `always_comb` executes once at time 0

### Always_latch
- The always_latch procedural block us used ti unducate that the intent of the procedural block is to model latch-based logic
- `always_comb` infers its sensitivity list, like `always_comb`

### `always_ff`
- The always_ff specialisied procedral block indicates that the designers intent is to model synthesizable sequential lofic behaviour
```verilog
always_ff @(posedge clock, negedge reset)
	if (!reset) 
		q <= 0;
	else 
		q <= d;
```
- A sensitivity list must be specified with an `always_ff` procedural block 
- This allows the engineer to model either synchronous or asynchronous set and/or logic based on the contents of the sensitivity list


# Advanced Data structures
## Creating new data types with `typedef` in SystemVerilog
> Throwback: Check FSMs in CADD, unit 4
- Verilog does not allow users to define new data types, SystemVerilog does this through `typedef`
```verilog
typedef int unsigned uint;
uint a, b;  // Variables a & b are user defined uint data type
typedef bit [31:0] bit32;
bit32 a, b; // Variables a & b are user defined bit32 data type
```
- Using parameters is possible too:
```verilog
parameter OPSIZE = 8;
typedef logic [OPSIZE-1:0] opreg_t;

opreg_t op_a, op_b;
```
- User-defined associative array index
```verilog
typedef bit[63:0] bit64_t;
bit64_t assoc[bit64_t], idx = 1;
```

Q] Create a user-defined type "nibble" of 4 bits
```verilog
typedef bit[3:0] nibble;
```
Q] Create a real variable r and initalise is to 4.33
Q] Create a short int variable, i_pack
Q] Create an unpacked array k containing 4 elements of your user defined data type 

## Structures
- Structures allow multiple variales to be grouped together under a common name
```verilog
struct {
	logic [31:0] data;
	bit [7:0] addr;
} packet;

initial 
	begin
		packet.data = 32'hffff;
		packet.addr = 8'd9;
	end
endmodule
```
## Enumerated data-type
- Gives internal numbers to text-based operations
```verilog
typedef enum {NOP, ADD, SUB, MUL, DIV} opcode_t;
struct{
	logic [31:0] in1;
	logic [31:0] in2;
	opcode_t op_code;
} packet;

module test;
	initial begin
		packet.in1 = 10;
		packet.in2 = 20;
		packet.op_code = ADD;
		$display("in1 = %0d \nin2 = %0d\n Op Code = %0s", packet.in1, packet.in2, packet.op_code.name());
		// in1 = 10, in2 = 20, Op Code = ADD
	end
endmodule
```
- Unpacked structures
```verilog
typedef struct{
	logic [7:0] sa; //MSB
	logic [7:0] da;
	logic [7:0] crc;
	logic [7:0] payload; //LSB
} unpacked_st;

module test;
	unpacked_st pkt;
	initial begin
		pkt.sa = 1;
		pkt.da = 4;
		pkt.payload = 8'hff;
		//pkt[7:0] = 40 - This is not possible, pkt has sub parts individual, not combined together.
		// We shoyld access only elements of struct, not individual fields as a whole
	end
endmodule
```

- Packed structures
```verilog
typedef struct packed{
	logic [7:0] sa; //MSB
	logic [7:0] da;
	logic [7:0] crc;
	logic [7:0] payload; //LSB
} packed_st;

module test;
	packed_st pkt;
	initial begin
		pkt.sa = 1;
		pkt.da = 4;
		pkt.payload = 8'hff;
		pkt[7:0] = 40 // When packed, it works
		$display("pkt.payload = %0d", pkt.payload); //pkt.payload = 40
		din = pkt;
	end
endmodule
```
## Union
- A union is a data type that represents a single piece of storage that can be accessed using one of the named member data types
- Only one of the data types in the union can be used at a time
```verilog
module test;
	union {
		int i;
		real f;
	} un_var;
	
	initial un_var.f = 12.345; //set value in floating point format
endmodule
```
- Unions are useful when you frequently need to read and write a register in several different formats

## `initial` block
- Non-synthesizable
- Used in testbenches
- Executes only once
- Executes at run time 0