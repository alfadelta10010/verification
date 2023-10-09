# Functions
- Write once run multiple times
- No delays: gets over at time 0, and returns values immediately
- Syntax:
```verilog
function return_type func_name(arguments);
```
- For example:
```verilog
function logic[7:0] add(input logic [7:0] a, b);
	begin
		add = a + b
		// or
		return a + b;
	end
endfunction
```
- `begin` and `end` are not mandatory 
- Return value of a function is set by assigning a value to the name of the function, or using a return function
- How to call a function?
```verilog
module test;
	logic [7:0] out;
	input logic [7:0] inp1, inp2;
	initial
		out = add(inp1, inp2);
	end
endmodule
```
- Functions are **synthesizable**
- Functions cannot contain the following:
	- Time controlled statements like `#` (delay: `#8` = Delay by 8 time scale units) and `##` (cycle delay: `##8` = Delay by 8 clk cycles)
	- Events like `@(posedge clk)` and `@(signal)`
	- `wait` statements
	
## Formal and Actual arguments
- `add(inp1, inp2);`: actual arguments
- `function logic[7:0] add(input logic [7:0] a, b);`: formal arguments
- Once a direction is given, subsequent formals default to the same direction
- If not specified, the arguments are taken to be inputs by default

## Void functions
- Functions can be explicitly declare as a void type, indicating that there is no retun value from the function
- This is used for `$display`  statements
```verilog
function void print_statement(...);
	$display("@%0t: state = %s", time, cur_state.name())
endfunction
```

## Default value of arguments
- In systemverilog you can define a default value  that is used if you leave out an argument in the call
```verilog
function void checksum(input int k, input bit [31:0] low = 0, input int high = -1);
	bit [31:0] checksum = 0;
endfunction
```
- For calling the function:
	- `checksum (a, 1, 30);`: low = 1, high = 30
	- `checksum (a, 1);`    : low = 1, high = -1
	- `checksum (a,  , 2);` : low = 0, high = 2
	- `checksum ();`        : Compile error: k has no default value

## Passing argument by name
- We can specify a subset by specifying the name of the routine argument with a port-like syntax
```verilog
function void many (input int a = 1, b = 2 c = 3, d = 4);
	$display("a = %0d\tb = %0d\tc = %0d\td = %0d", a, b, c, d);
endfunction

initial begin
	many(6, 7, 8, 9); // a = 6, b = 7, c = 8, d = 9
	many(); // a = 1, b = 2, c = 3, d = 4
	many(.c(5)); // a = 1, b = 2, c = 5, d = 3
	many(, 6, , .d(5)); // a = 1, b = 6, c = 3, d = 5
end
```

## Functions with Enum return type
- To create functions with enum:
```verilog
typedef enum {IDLE, WAIT, LOAD, STORE} states_t;
states_t p_state, n_state;

function enum {IDLE, WAIT, LOAD, STORE} states_t get_next(...);
```
- To simplify:
```verilog
typedef enum {IDLE, WAIT, LOAD, STORE} states_t;
states_t p_state, n_state;
function states_t get_next(states_t inp_state);
	case (inp_state)
		WAIT: get_next = LOAD;
		LOAD: get_next = STORE;
		STORE: get_next = WAIT;
		default: get_next = inp_state; // default next state
	endcase
endfunction

initial begin
	p_state = LOAD;
	n_state = get_next(p_state);  // n_state = STORE
end
```
