# Shallow and Deep copy

## `this` keyword
- When you use a variable name, SV looks in the current scope for it, and then in the parent scopes until the variable is found
```verilog
class packet;
	int y, z;
```
- Used to refer to class properties explicitly
:warning: copy from slides

## Deep Copy
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
	p1 = create();
	print(p1);
end
```
- `h1` will point to `p1`

## Static class propertiess
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

[All codes on EDA Playground](https://www.edaplayground.com/x/3QQs)
