## Set Membership
- `inside` operator
```verilog
class A;
	rand integer a, b, c;
	constraint c2 {
		a inside {b, c};
	}
endclass

int arr[4] ='{5, 10, 15, 20};
rand int v1, v2;
constraint c3 {!(v1 inside {arr};)}  // v1 != 5, v1 != 10, v1 != 15, v1 != 20
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

## Distributions using `dist` operator
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

> `'` is used for type casting

## Conditional Constraints
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

## Implication
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
- Implication operator says that when x = 0, y is forced to 0
- When y = 0, there is no constraint on x
- However, implication is bidirectional; if y were forced to a non-zero value, x would have to be 1

```verilog
class BusOp;
	rand bit [31:0] addr;
	rand bit io_space_mode;
	constraint c_io {
		io_space_mode -> addr[31] == 1'b1;
	}
endclass
```
- The expression A -> B, when the implication operator appears in a constraint, the solver picks values for A and B so that expression is true
- When A is true, B must be true, but when A is false, B can be true/false.
- Note that this is a partly bidirectional constraint, but that A -> B does not imply B -> A
- The two expressions produce different results

| A -> B | B = false | B = true |
|:-------:|:----:|:----:|
| A = False | True | True |
| A = True | False | True |

- When A is true, B is also true
- When A is false, B is true or false

## `solve ... before ...` statement
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

## Constraining individual array elements
```verilog
class A;
	rand bit [31:0] len[]; //dynamic array
	constraint c_len {
		foreach (len[i])
			len[i] inside {[1:255]}; // Each element must be in between 1 and 255
		len.size() inside 
		```
		
:warning: copy from slides T_T
> examples 6.8, 6.9, 6.10

## Bidirectional Constraints
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
|Solution|`r`|`s`|`t`|
|:------:|:-:|:-:|:-:|
| A | 6 | 6 | 7 |
| B | 6 | 6 | 7 |
| C | 6 | 6 | 7 |
| D | 6 | 6 | 7 |
| E | 6 | 6 | 7 |
| F | 6 | 6 | 7 |

## Equivalence Operator
- The equivalence operator `<->` is bidirectional
- AB is defined as `((A->B) && (B -> A))`

| A <-> B | B = false | B = true |
|:-------:|:----:|:----:|
| A = False | True | False |
| A = True | False | True |
