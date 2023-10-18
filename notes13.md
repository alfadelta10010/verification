# Randomization
- There are some in-built directives that help us generate random values
	- `$random`
	- `$urandom`
	- `$urandom_range(min, max)
	- `$randomize`
- 

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

### Constraints
// 
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
	- `rand bit[3:0] a;` - Gives a standard distribution (? copy from slides, again `-_-`)
	- `randc bit[3:0] a;`
- The values of random variables are determined using constraint expressions that are declared using constraint blocks

#### `randc` variables
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
- `randc bit [1:0] y`
- The variable y can take on the values 0, 1, 2, 3 (range of 0 to 3)
- The basic idea is that `randc` randomly iterates over all the values in the range and that no value is repeated within an iteration
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
```verilog
program
```
:warning: copy from slides, `Chapter 6 PPTs`




- Verification involves the verification of:
	- Device configuration
	- Environment configuration
	- Primary Input data
	- Encapsulated Input data (internal signals)
	- Protocols
	- Delays
	
- You should never randomize an object in the class constructor
	- Your