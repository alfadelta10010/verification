# Chapter 5: Basic Object Oriented Programming
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
	//<variables>    ┐ Members of a class
	//<subroutines>  ┘
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
> Check [Chapter 6: Randomization](chapter6.md) for more

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
- Memory allocation will not happen to the nested handle when create object for the top handle
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
- The `function new()` automatically creates object for A when object for B is created

### Usage of classes
- To use a class:
1. Define class
1. Declare handle
1. Construct object
1. Call object

#### Declaring a handle:
```verilog
Packet pkt;```
- `pkt` is a handle of the type `packet` and `packet` is a class data type
- For a class data type, we declare handles, rest all avalable data types in the language we decalre variables
- When you declare a handle `pkt`, it is initialised to special value null

#### Creating object
```verilog
Packet pkt;  // pkt is a handle
pkt = new(); // pkt is an object
```
- We call the `new()` constructor to construct the Packet object
- It allocates an object of the type `packet`
- `new()` is in-built, it allocates memory to all the members, and are physically present in memory, object created
- The constructor (`new()`) allocates memory for the class `Packet`
- It initialises the variables to their default value (0 for 2-state, X for 4-state)

#### Calling and using object
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
	endfunction: calc_crc
endclass : Transaction
```
- `Transaction tr`: Creating handle
- `initial tr = new;`: Creating an object
- It allocates 40 bytes of memory, and initializes the variables `addr`, `crc`, `data[8]` to `0`
- Calculation
```
addr: 31 bits = 4 bytes
crc: 31 bits = 4 bytes
data: 31 bits = 4 bytes * 8 = 32 bytes
Total: 32 + 4 + 4 = 40 bytes
```
- Functions and tasks are allocated stacks whenever they're called
- Tasks are automatic by default inside the class
- EDA Playground example: [OOPs all examples](https://www.edaplayground.com/x/3QQs)

### Flexible Constructor
```verilog
class Transaction;
	bit [31:0] addr, crc;
	bit [31:0] data[8];
	function new(bit [31:0] a_inp = 10, d_inp = 99); // custom constructor
		addr = a_inp;
		data[0] = d_inp;
		data[1] = d_inp;
	endfunction 
endclass
```
- Starting the object with pre-defined values
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
> What is the output for the following code?
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
Object a1, handleless (ex-a1):	int m = 10
Object a2, a1 & a2 handle:	int m = 20 => 30
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

### Out of block declarations
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

## `this` keyword
- When you use a variable name, SystemVerilog looks in the current scope for it, and then in the parent scopes until the variable is found
```verilog
class packet;
	int y, z;
	
	function void write(int y);
		y = y;
	endfunction
	
	function void my_write(int y);
		this.y = y;
	endfunction
endclass
```
- Used to refer to class properties explicitly

## Copying classes
### Shallow copy
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

### Deep Copy
- A deep copy creates a new object and copies the values of all properties fom the source object, including any nested class properties
- A **copy function** can be written as follows:
```verilog
program file;
	class A;
		bit [7:0] addr, data;
		function void copy (A inp);
			this.addr = inp.addr;
			this.data = inp.data;
		endfunction
	endclass
	
	A a1, a2;
	initial begin
		a1 = new;
		a1.addr = 55;
		a1.data = 66;
		a2 = new;
		a2.copy(a1);
	end
endprogram
```
- During execution, `a1` has `addr = 55` and `data = 66`, and `a2` is created with `data = 0` and `addr = 0`
- When we reach `a2.copy(a1)`, the execution changes to:
```verilog
a2.addr = a1.addr;
a2.data = a1.data;
```
- Due to this, `a2` gets the values `addr = 55` and `data = 66`
- To see this **copy function** for **deep copy**, we see the next program:
```verilog
program file;
	class A;
		bit [7:0] addr, data;
		function void copy (A inp);
			this.addr = inp.addr;
			this.data = inp.data;
		endfunction
	endclass
	class B;
		bit [7:0] p1, p2;
		A a1;
		function new();
			a1 = new;
		endfunction
		function void copy (B inp);
			p1 = inp.p1;
			p2 = inp.p2;
			a1.copy(inp.a1);
		endfunction
	endclass
	B b1, b2;
	initial begin
		b1 = new;
		b1.p1 = 33;
		b1.p2 = 44;
		b1.a1.addr = 11;
		b1.a1.data = 22;
		b2 = new;
		b2.copy(b1);
	end
endprogram
```
- When `b1` and it's values are initialised, an object for `a1` is also created, and it's values are initialised
```
Object 	b1: P1 = 33, P2 = 44, a1
			a1: addr = 11, data = 22
```
- When `b2` is created, `p1` and `p2` are copied with `p1 = inp.p1; p2 = inp.p2;`, a copy of `a1` is also created with `a1.copy(inp.a1)`
```
Object 	b1: P1 = 33, P2 = 44, a1
			a1: addr = 11, data = 22
Object 	b2: P1 = 33, P2 = 44, a1
			a1: addr = 11, data = 22
```

## Passing Objects to Methods
```verilog
class A;
	bit [31:0] k;
endclass

function A create();
	A a1;
	a1 = new;
	a1.k = 55;
	return a1;
endfunction
function void print (A h1);
	$display("h1.k = %0d", h1.k);
endfunction

A p1;
initial begin
	p1 = create(); //function is called
	print(p1);
end
```
- `h1` will point to `p1`
```
Object:
k = 0 => 55
h1 = p1
```

## Static class properties
- Method can be declared as static
- Static method can be called outside the class without instantiation of class
- A static method has no access to non-static members (class properties or methods)
- A static method can directly static class properties or call static methods of the same class
- Access to non-static members or to the special `this` handle within the body of a static method is illegal and results in a compiler error
- Static methods cannot be virtual
```verilog
class Packet;
	static int id;
	bit [7:0] obj_id;
	function new();
		id++;
		obj_id = id;
	endfunction
endclass

Packet pkt1, pkt2, pkt3;
initial begin
	$display("id = %0d\n", Packet::id);
	pkt1 = new;
	$display("pkt1.id = %0d\n", pkt1.id);
	pkt2 = new;
	$display("pkt2.id = %0d\n", pkt2.id);
	pkt3 = new;
	$display("pkt3.id = %0d\n", pkt3.id);
	$display("pkt1.id = %0d\tpkt2.id = %0d\tpkt3.id = %0d\t ", pkt1.id, pkt2.id, pkt3.id);
end
```
- Static variable exists in memory
- We can access that variable always (no object is necessary)
- `function new()` is a custom constructor
- At start, `id = 0`
- When an object is created with handle `pkt1`, `obj_id = 1` as `id` increments to 1, and `pkt1.id = 1` is printed
- When an object is created with handle `pkt2`, `obj_id = 2` as `id` increments to 2, and `pkt2.id = 2` is printed
- When an object is created with handle `pkt3`, `obj_id = 3` as `id` increments to 3, and `pkt3.id = 3` is printed
- When the final display statement is printed, the output is `pkt1.id = 3 pkt2.id = 3 pkt3.id = 3` 
- Output
```
id = 0
pkt1.id = 1
pkt2.id = 2
pkt3.id = 3
pkt1.id = 3 pkt2.id = 3 pkt3.id = 3
```

- We can access static variables/methods through the scope resolution operator
```verilog
class Packet;
	bit [7:0] addr, data;
	
	static int id;
	static bit mode = 1;
	
	function new();
		id++;
	endfunction
	
	static function int get();
		return id;
	endfunction
endclass

Packet pkt1, pkt2;
int ret;

initial begin
	$display("Static variable id: %0d", Packet::id);
	$display("Static method ret: %0d", Packet::get());
	
	pkt1 = new;
	$display("id: %0d\t id: %0d", Packet::id, pkt1.id);
	pkt2 = new;
	$display("Static variable id: %0d", Packet::id);
	ret = Packet::get();
	$display("Static method ret: %0d", ret);
end
```

## Scope
- A scope is a block of code such as a module, program, task, function, class, or begin/end block
- You can only define new variables in a block
- You can declare a variable in an unnamed begin-end block

- For testbenches, you can declare variables in the program or in the initial block. 
- If a variable is only used inside a single initial block, such as a counter, you should declare it there to avoid possible name conflicts with other blocks

- Declare your classes outside of any program or module in a package
- This approach can be shared by all the testbenches, and you can declare temporary variables at the innermost possible level.

- If a block uses an undeclared variable, and another variable with that name happens to be declared in the program block, the class uses it instead, with no warning.

### Rules
- A name can be relative to the current scope or absolute starting with $root
- For a relative name, SystemVerilog looks up the list of scopes until it finds a match.
- If you want to be unambiguous, use $root at the start of a name.
- Variables can not be declared in $root , that is, outside of any module, program or package.

