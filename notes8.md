# The breakdown of portions:
[*] Ch1. Introduction
[*] Ch2. Data types
[*] Ch3. Routines -  Tasks and Functions
[*] Ch4. Stratified Event Queue
[*] Ch5. Classes (OOP)

- All this is ISA-1 portions

# Object Oriented Programming
- Object Oriented Programming involves the development of applications with modular, reusable components
- It consists of the following:
	- Encapsulation
	- Inheritance
	- Polymorphism
- **Encapsulation:** Principle of grouping together common functionality and features into a code "object"
- **Inheritance:** The principle of transferring the functionality of a parent to a child
- **Polymorphism:** Allows redefining methods for derived classes while enforcning a common interface
- These principles allow ease of code development, debugging, maintenance, reusable and code expansion

## Classes
- Class is a data type containing properties (variables) of various types, and methods (tasks and functions) for manipulating the data members
```verilog
class class_name;
	//<variables>    -| Members of a class
	//<subroutines>  _|
endclass
```
- Both properties and methods are referred to as "members" of a class
#### Structures v/s Classes
- Classes are dynamic data type, structures are static
- Classes contains both properties and methods, structures have only properties

### Simple class
- Lets take a look at the following example:
```verilog
class Packet;
	bit [7:0] addr;   // Properties
	bit [31:0] wdata; // Properties 
	logic rd, wr;     // Properties 
	
	function void print();  // Members of class named packet
		$display("[Packet] addr = %0d; wdata = %0d; wr = %b; rd = %b;", addr, wdata, rd, wr);
	endfunction
	
	task gen_write_stimulus();   // Methods of class named packet
		wr = 1;
		addr = $urandom_range(1, 30);
		wdata = $urandom_range(20, 200);
	endtask
endclass
```
- Grouping all the members into a class named packet, is called **Encapsulation**
- All tasks written inside a class are automatic

> Compiler directives to generate random numbers
> `$random`: Range depends on bit size of the data type
> `$urandom`: Range depends on bit size of the data type
> `$urandom_range`: Range defined by user
> `$random_range`: Range defined by user

### Nested Class
```verilog
program test;
	class A;
		int j;
	endclass

	class B;
		int k;
		A a1;
	endclass
	B b1;
	initial begin
		b1 = new();
		b1.a1 = new()
		b1.k = 20;
		b1.a1.j = 30;
	end
endprogram
```
- `a1` handle belonging to class `A` inside class `B`
- In memory:
```verilog
Object b1:  k = 0; => 20
			A a1;

Object a1:	j = 0 => 30
```
- Memory allocation wl not happen to the nested handle when create object for the top handle
- This is a two-step process, which becomes a maintenence issue (in case we forget)
- To rectify this:
```verilog
program test;
	class A;
		int j;
	endclass

	class B;
		int k;
		A a1;
		function new();
			a1 = new();
		endfunction
	endclass
	B b1;
	initial begin
		b1 = new();
		b1.k = 20;
		b1.a1.j = 30;
	end
endprogram
```
- The `function new()` automatically creates object for A when obhject for B is created

### Usage of classes
- To usage a class:
1. Create class
1. Create handle
1. Create object
1. Call object

**Declaring a handle:**
```verilog
Packet pkt;```
- `pkt` is a handle of the type `packet` and `packet` is a class data type
- For a class cdata type, we declare handles, rest all avalable data types in the language we decalre variables
- When you declare a handle `pkt`, it is initialised to special value null

**Creating object**
```verilog
Packet pkt;  // pkt is a handle
pkt = new(); // pkt is an object
```
- We call the `new()` constructor to construct the Packet object
- It allocates an object of the type `packet`
- `new()` is in-built, it allocates memory to all the members, and are physically present in memory, object created
- The constructor {`new()`} allocates memory for the class `Packet`
- It initialises the variables to their default value (0 for 2-state, X for 4-state)

**Calling and using object**
```verilog
program test;
	class Packet;
		bit [7:0] addr;   // Properties
		bit [31:0] wdata; // Properties 
		logic rd, wr;     // Properties 
	
		function void print();  // Members of class named packet
			$display("[Packet] addr = %0d; wdata = %0d; wr = %b; rd = %b;", addr, wdata, rd, wr);
		endfunction
	
		task gen_write_stimulus();   // Methods of class named packet
			wr = 1;
			addr = $urandom_range(1, 30);
			wdata = $urandom_range(20, 200);
		endtask
	endclass
	Packet pkt;
	initial begin
		pkt = new(); //pkt = new also works
		pkt.rd = 0;
		pkt.get_write_stimulus();
		pkt.print();
	end
endprogram
```
- Object values:
```verilog
addr = 0
data = 0
wr = x
rd = x  //=> 0
```
## What is a constructor?
```verilog
class Transaction;
	bit [31:0] addr, crc;
	bit [31:0] data[8];
	
	function void display;
		$display("addr = %0d", addr);
	endfunction: display
	
	function void calc_crc;
		crc = addr ^ data.xor;
	endfunction
endclass
```
:warning: copy from slides, page 16 of OOPs slides

### Flexible Constructor
```verilog
class Transaction;
	bit [31:0] addr, crc;
	bit [31:0] data[8];
	function new(bit [31:0] a_inp = 10, d_inp = 99);
		addr = a_inp;
		data[0] = d_inp;
		data[1] = d_inp;
	endfunction 
endclass
```
- Starting the obhect with pre-defined values
- This custom constructor/flexible constructor gives the values at object-creation time
- In main program:
```verilog
Transaction tr1, tr2;
initial begin
	tr1 = new(22, 33);
	tr2 = new;
end
```
- The values in memory are as follows:
```verilog
tr2.addr = 10;
tr2.data[0] = 99;
tr2.data[1] = 99;
tr2.crc = 0;
tr1.addr = 22;
tr1.data[0] = 33;
tr1.data[1] = 33;
tr1.crc = 0;
```

### Handle Assignments
- ***What is the output for the following code?***
```verilog
class A;
	int m;
endclass

A a1, a2;
initial begin
	a1 = new; a1.m = 10;
	a2 = new; a2.m = 20;
	a1 = a2; 
	a1.m = 30;
end
```
- The handle `a1` points to object `a2`, object `a1` becomes garbage and is discarded
- Object description:
```
Object a1, handleless (ex a1):	int m = 10
Object a2, a1 & a2 handle:	int m = 20
```
- In order to have handle assignment, both objects should be of same class

### Variable assignment
- Taking a look at the following code:
```verilog
class A;
	int k1, k2;
endclass

A a1, a2;
initial begin
	a1 = new; 
	a1.k1 = 10;
	a1.k2 = 20;
	a2 = new; 
	a2.k1 = a1.k1;
	a2.k2 = a1.k2;
end
```
- Only the variables are swapped

## Out of block declarations
- Class has properties and methods
- To make the class look more neat and readable we cab write the methods out of the class block
```verilog
class packet;
	bit [31:0] addr, data;
	extern function void print();
	extern task run(input [31:0] m, output [31:0] y);
endclass
		
function void packet::print();
	$display("[Packet] addr = %0d; data = %0d\n", addr, data)
endfunction
task packet::run(input [31:0] m, output [31:0] y);
	y = m + 1;
endtask
```
- `::` is called scope resolution operator
- Only purpose is to make the class look clean

## Shallow copy
```verilog
program test;
	class A;
		int m, k;
	endclass
	
	A a1, a2;
	initial begin
		a1 = new;
		a1.m = 40;
		a1.k = 50;
		a2 = new a1;
	end
endprogram
```
- A shallow copy creates a new object and copies the values of all properties fom the source object
- An object is created for a2 and contents of a1 are copied to a2
```verilog
a2 = new a1;
=>
a2 = new;
a2.m = a1.m;
a2.k = a1.k;
```
- It is like taking a photocopy of a document, if a document has references to some other page, those are not copied
- Similarly, if we have a nested class, the values of the nested class are not duplicated
- It is a shallow copy becuase it does not make a copy of any nested objects

- Taking example of a nested class:
```verilog
class B;
	int j;
endclass

class A;
	int k;
	B b1;
	function new();
		b1 = new();
	endfunction
endclass

A a1, a2;
initial begin
	a1 = new;
	a1.j = 10;
	a1.b1.k = 30;
	$display("a1.j = %0d; a1.b1.k = %0d", a1.j, a1.b1.k);
	a2 = new a1;
	$display("a2.j = %0d; a2.b1.k = %0d", a2.j, a2.b1.k);
	a1.j = 20;
	$display("a1.j = %0d; a2.j = %0d", a1.j, a2.j);
	a1.b1.k = 44;
	$display("a1.b1.k = %0d; a2.b1.k = %0d", a1.b1.k, a2.b1.k);
	a2.j = 30;
	$display("a1.j = %0d; a2.j = %0d", a1.j, a2.j);
end
```
- Object a1.b1 will not be copied to a2.b1, instead handle b1 will be assigned
```verilog
a2 = new a1;
a2 = new;
a2.j = a1.j; // Variable j value copy
a2.b1 = a1.b1; // Handle assignment
```
