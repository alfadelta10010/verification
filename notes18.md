# Functional coverage
- `<points>`

## Difference between Code and Functional Coverage
```verilog
module dff(clk, reset, d, q, q_bar);
	input clk, reset, d;
	output q, q_bar;
	reg q, q_bar;
	always @ (posedge clk or posedge reset)
		begin
			q <= d;
			q_bar <= !q;
		end
endmodule
```
- This code has 100% code coverage, but not 100% functional coverage, as this code is not functionally complete, there is no logic for reset
- Code coverage measures how thouroughly the tests have exercised the "implementation" of the design specifications, and not the verification plan
- Code coverage tells you how much lines of code is exerised
- Tells what portion of the code is executed
- To measure code coverage, no extra code is required
- To measure functional coverage, we have to write additional testbench code to extract the functional coverage (cover group)
- It checks if all the possible test vectors are applied on the design under test

## Covergroup
- The cover group construct is a user-defined type
- The type definition is written once, and multiple instances of that type can be created in different contexts
- Syntax:
```verilog
covergroup cov_grp_name([coverage_event]);
	coverpoint_name : coverpoint var_name1;
	coverpoint_name : coverpoint var_name2;
	cross coverpoint_name, coverpoint_name;
endgroup
```
- A coverpoint is the input of the design
- We can make crosses of the coverpoints
- For example:
```verilog
covergroup halfadder();
	tv1: coverpoint a;
	tv2: coverpoint b;
	cross tv1, tv2;
endgroup
```
for the following half adder:
```
a--|    |-- s
   | HA |
b--|    |-- cout
```
### Simple example
- A covergroup is similar to a class data-type, you need to create a handle and create an object
- Similar to a class, once defined, a covergroup instance can be created via the `new()` operator
- A covergroup can be defined in a package, module, program, interface, checker or class
- A bin is a counter, every time the value occurs, the count for the value increases
```verilog
enum {red, green, blue} color;
covergroup my_fcov;
	coverpoint color;
endgroup

my_fcov cov_inst;

initial begin
	cov_inst = new;
	color = red; 
	cov_inst.sample(); // Reading the value of the bin, and incrementing (hitting) the red bin
	color = green; 
	cov_inst.sample(); // Reading the value of the bin, and incrementing (hitting) the green bin
	color = blue; 
	cov_inst.sample(); // Reading the value of the bin, and incrementing (hitting) the blue bin
	color = red; 
	cov_inst.sample(); // Reading the value of the bin, and incrementing (hitting) the red bin
end
```
- In the background, bins are automatically created
```
auto_bin: red (0 -> 1 -> 2)
auto_bin: blue (0 -> 1)
auto_bin: green (0 -> 1)
```
- `instance.sample()` is a built in function, it hits (increments) the bin values of red blue and green
- Usually, there's only one `sample` function call in the code
- For this code, assuming we are only hitting `red` and `green` once, the coverage report is as follows:
```
# Coverage Report by instance with details
# 
# =================================================================================
# === Instance: /top
# === Design Unit: work.top
# =================================================================================
# 
# Covergroup Coverage:
#     Covergroups                      1        na        na    66.66%
#         Coverpoints/Crosses          1        na        na        na
#             Covergroup Bins          3         2         1    66.66%
# ----------------------------------------------------------------------------------------------------------
# Covergroup                                             Metric       Goal       Bins    Status               
#                                                                                                          
# ----------------------------------------------------------------------------------------------------------
#  TYPE /top/my_fcov                                     66.66%        100          -    Uncovered            
#     covered/total bins:                                     2          3          -                      
#     missing/total bins:                                     1          3          -                      
#     % Hit:                                             66.66%        100          -                      
#     Coverpoint color                                   66.66%        100          -    Uncovered            
#         covered/total bins:                                 2          3          -                      
#         missing/total bins:                                 1          3          -                      
#         % Hit:                                         66.66%        100          -                      
#  Covergroup instance \/top/cov_inst                    66.66%        100          -    Uncovered            
#     covered/total bins:                                     2          3          -                      
#     missing/total bins:                                     1          3          -                      
#     % Hit:                                             66.66%        100          -                      
#     Coverpoint color                                   66.66%        100          -    Uncovered            
#         covered/total bins:                                 2          3          -                      
#         missing/total bins:                                 1          3          -                      
#         % Hit:                                         66.66%        100          -                      
#         bin auto[red]                                       1          1          -    Covered              
#         bin auto[green]                                     1          1          -    Covered              
#         bin auto[blue]                                      0          1          -    ZERO                 
# 
# COVERGROUP COVERAGE:
# ----------------------------------------------------------------------------------------------------------
# Covergroup                                             Metric       Goal       Bins    Status               
#                                                                                                          
# ----------------------------------------------------------------------------------------------------------
#  TYPE /top/my_fcov                                     66.66%        100          -    Uncovered            
#     covered/total bins:                                     2          3          -                      
#     missing/total bins:                                     1          3          -                      
#     % Hit:                                             66.66%        100          -                      
#     Coverpoint color                                   66.66%        100          -    Uncovered            
#         covered/total bins:                                 2          3          -                      
#         missing/total bins:                                 1          3          -                      
#         % Hit:                                         66.66%        100          -                      
#  Covergroup instance \/top/cov_inst                    66.66%        100          -    Uncovered            
#     covered/total bins:                                     2          3          -                      
#     missing/total bins:                                     1          3          -                      
#     % Hit:                                             66.66%        100          -                      
#     Coverpoint color                                   66.66%        100          -    Uncovered            
#         covered/total bins:                                 2          3          -                      
#         missing/total bins:                                 1          3          -                      
#         % Hit:                                         66.66%        100          -                      
#         bin auto[red]                                       1          1          -    Covered              
#         bin auto[green]                                     1          1          -    Covered              
#         bin auto[blue]                                      0          1          -    ZERO                 
# 
# TOTAL COVERGROUP COVERAGE: 66.66%  COVERGROUP TYPES: 1
# 
# Total Coverage By Instance (filtered view): 66.66%
```
- Note: By default, the maximum number of autobins generated by the system are 64, we can increase it by using user-defined bins
- We can also restrict the number of bins:
```verilog
program test;
	bit [3:0] addr;
	
	covergroup cov;
		option.auto_bin_max = 4; // Only 4 bins will be generated
		coverpoint addr;
	endgroup
	
	cov cov_inst = new;
endprogram
```
- However, the number of addresses possible are 16 `[3:0]`
- Since the number of bins is lesser than the addresses possible, sharing occurs:
```
16/4 = 4
=> auto_bin1: 0 -> 3
=> auto_bin2: 4 -> 7
=> auto_bin3: 8 -> 11
=> auto_bin4: 12 -> 15
```
- What happens when single bin is allowed for multiple values? 
- Sharing results in the not true functional coverage, all bins can be hit but all possible values aren't provided

- If we take `bit[31:0] a` the possible values for a are 4294967296 (2^32) values, with 64 bins, each bin takes 67108864 different values.
- We use user-defined bins for this reason

- Covergroups are of two types, standalone and embedded
### Standalone covergroup
```verilog
program test;
	bit k;
	class A;
		integer x;
	endclass
	
	A a;
	 covergroup cov;
		 coverpoint k;
		 coverpoint a.x;
		 cross k, a.x;
	 endgroup
	
	cov cov_inst;
	initial begin
		a = new;
		cov_inst = new;
		repeat (5)
			begin
				k = $urandom();
				a.x = $urandom();
				cov_inst.sample(); // Don't forget to sample, otherwise coverage = 0%
			end
	end
endprogram
```
- Here covergroup definition is not a part of class
- We create a handle, create the object and then use it

### Embedded Coverage
```verilog
class Transaction;
	rand bit [31:0] wdata;
	rand bit [3:0] addr;
	
	covergroup covport @(posedge clk); // rising edge of clock is event
		coverpoint addr; // 4 bits, 16 values, 16 bins
		coverpoint wdata; // 32 bits, 2^32 values, 64 bins
	endgroup
	
	function new();
		covport = new(); // We create a custom function for the covergroup in the class
	endfunction
	
endclass

Transaction tr;

initial begin
	tr = new();
	repeat (32) begin // Run a few cycles
		assert (tr.randomize); // Create a transaction
		@(posedge clk); // Gather coverage, no need for fn.sample(), call the coverage event only
	end
end
```
- Covergroup definition is part of the class
- Custom constructor is compulsory
- Taking handle for embedded covergroup is a compile error
- :warning: Important 2/4-marker
- When event is triggered, sampling occurs

> Reminder: `rand` and `randc` is needed only for `class.randomize` function

### Coverage sampling with events
```verilog
event ev;
enum {red, green, blue} color;

covergroup my_fcov @(ev);
	cp: coverpoint color;
endgroup

my_fcov cov_inst;

initial begin
	cov_inst = new;
	color = red;
	-> ev;
	color = blue;
	-> ev;
	color = green;
	-> ev;
end
```

### Sampling with variable change
```verilog
bit [3:0] count;
enum {red, green, blue} color;

covergroup my_fcov @(count);
	cp: coverpoint color;
endgroup

my_fcov cov_inst;

initial begin
	cov_inst = new;
	color = red;
	count++;
	color = blue;
	count++;
	color = green;
	count++;
end
```

# Code Coverage
- What is Coverage?
	- Coverage is a generic term for measuring progress to complete design verification
- How is coverage done?
	- The coverage tools 

> <copy from chapter 9 ppts>	

- Code coverage can measure:
	1. Line coverage: How many lines of code have been executed
	1. Path coverage: Which paths through the code expressions have been executed
	1. Toggle coverage: Which single bit variables have had the values 0 or 1
	1. FSM coverage: Which states and transitions in a state machine have been visted
- In toggle coverage, we test the reset pin of the system, the system is reset in the start **and** at some point during execution

#### Bug rate
- An indirect way to measure coverage is to look at the rate at which fresh bugs are found
- Every time the raye slows down, it is necessary to find different ways to create corner cases

### Assertion Coverage
- Assertions check relationships between design signals, either once or over a period of time 
- Coded using the `assert` property
- `cover property` statement can be used to look for interesting signal values or design states
- How often the assertions are triggered during a test can be measured using assertion coverage

#### Gathering coverage data
```
┌───────────────┐                 ┌────────────┐
│     Design    │                 │Verification│
│ Specification ├─────────────────►    Plan    │
└──────┬────────┘                 └─────┬──────┘
       │                                │
       │                                │
   ┌───▼────┐     ┌──────────┐       ┌──▼──┐
   │ Design ├─────► Coverage ◄───────┤Tests│
   └───▲────┘     │ Database │       └──▲──┘
       │          └────┬─────┘          │
  Debug│               │                │Coverage
       │   No       ┌───▼───┐   Yes     │Analysis
       └────────────┤ Pass? ├───────────┘
                    └───────┘
```
### Functional Coverage Strategies
1. Gather Information, not Data
	- The corner cases for a FIFO are Full and Empty
	- If the transistion from Empty to Full and back to Empty is made, all the levels in between are covered
	- Design signals with a large range should be broken down into smaller ranges, plus corner cases
1. Only measure what you can use
	- Gathering functional coverage data can be expensive, so only measure what is to be analysed and used to improve the tests
1. Measuring Completeness
	- All coverage measurements and the bug rate need to be checked ti see if the goal has been met

### Coverage comparison
```
F     ┌─────────────────────┬─────────────────────┐
u C  H│   Need more FC      │    Good coverage:   │
n o  I│ points, including   │    Check bugrate    │
c v  G│   corner cases      │                     │
t e  H│                     │                     │
i r   ├─────────────────────┼─────────────────────┤
o a  L│      Start of       │ Is design complete? │
n g  O│      Project        │  Perhaps try formal │
a e  W│                     │       tools         │
l     └─────────────────────┴─────────────────────┘
                LOW                  HIGH
                      Code Coverage
```
- The tests are not exercising the full design, perhaps from inadequate verification plan
- The tests are unable to put the testbench in all its interesting states
- The existing strategies have saturated and different approaches like new combinations of design blocks and error generators need to be tried

### Simple functional coverage example
```verilog
program automatic test(busifc.TB ifc);
	class Transaction;
		rand bit [31:0] data;
		rand bit [2:0] dst; // eight dst port numbers
	endclass
	
	Transaction tr; // Transaction to be sampled
	
	covergroup CovDst2;
		coverpoint tr.dst; // Measure coverage
	endgroup
endprogram
```
- Sample 9.2
- To improve your functional coverage, the easiest strategies are to run more simulation cycles, or to try new random seeds

> copy from ppt bro too fast man is going

## Bins
#### User defined bins
```verilog
bit [3:0] addr, data, gvar;
covergroup cov;
	global_addr : coverpoint addr {
		bins zero = {0}; 
		bins low_addr = {[1:4]}; // Covers 1, 2, 3, 4
		bins mid_addr[] = {[5:8]}; // Creates multiple bins, mid_addr_5, mid_addr_6, mid_addr_7, mid_addr_8
		bins fixed[2] = {9, 10}; // Fixed number of bins, share the values uniformly
		bins debug[] = default; // Used for debugging purposes, this is not considered for coverage statistics
	}
	global_data : coverpoint data {
		bins low_range[] = {[$:6]}; // Value is 0 to 6
		bins high_range[] = {[10:$]}; // Value is 10 to 15
		bins trans_4_5 = (4 => 5); // if prev value is 4 and next is 5, then bin gets hit
	}
	trans: coverpoint gvar {
		bins b1 = (3 [*5]); // same as 3 => 3 => 3 => 3 => 3 consecutive repetitions
endgroup
```
- The `bins` keyword is used to define bins, they all need a name
- For example, whenever there is a `0` in the randomization, bin `zero` will be hit
- Totally, 8 bins have been created
- The default bin is not considered for coverage calculation
- All uncovered values comes under default bin
- For example: If address is 11, debug bin increments, whenever there is a hit on the debug bin, it denotes address 11
- Unnecessary address is generated
- Coverage is a log report, the values generated aren't shown

#### Wild card bins
```verilog
bit [1:0] data;
covergroup cov;
	cp1: coverpoint data {
		wildcard bins even = {2'b?0};
		wildcard bins odd = {2'b?1};
		wildcard bins trans = {2'b?0 => 2'b?1};
	}
endgroup
```
- The count of bin even is incremented when the sampled variable is even number: 00, 10
- The count of bin odd is incremented when the sampled variable is even number: 01, 11
- The count of bin trans is incremented for elow shown transistions:
`00 -> 01, 00 -> 11, 10 -> 01, 10 -> 11`

#### Ignore bins and Illegal bins
```verilog
bit [3:0] data;
covergroup cov;
	cp1: coverpoint data {
		bins valid_bin = {1, 7, 8, [10:15]};
		ignore bins ig_bin = {[2:5]};
		illegal bins ileg_bin = {6, 9};
		illegal bins ileg_trans = {}
	}
endgroup
```
- Ignore bins are not considered for coverage calculation
- They are used for documentation/statistical purposes
- For example, we want bins for all values except 2, 3, 4, 5

- Illegal bins are not considered for coverage calculation
- The values 6 and 9 should not occur, if occured, it should not be passed
- If illegal bins have a count of 1 or more, then there are bugs present
- If illegal bins are zero, then its bug free

### Conditions on coverpoint, bins, cross
```verilog
logic [2:0] q;
bit [2:0] port1;
bit d, reset;
covergroup cov_group;
	// Conditions on bins
	coverpoint q { 
		bins dff_reset_q = {0} iff (reset==1);
		// dff_reset_q bin increments if the guard is true, else it won't
		bins dff_all_q[] = {[0:15]} iff (reset==0);
	}
	// Condition on coverpoints
	coverpoint port1 iff (d==1);
	//port1 increments if the guard is true, else it won't
	// Condition on crosses
	cross port1, port1 iff(d==1);
endgroup
```
- It makes verification strict and crisp

## Crosses
```verilog
bit a, b;
covergroup cov_group;
	cp1: coverpoint a; //2 bins
	cp2: coverpoint b; //2 bins
	cr: cross cp1, cp2; //4 bins
	// cross coverpoint a, coverpoint b;
endgroup
```
- We take crosses between coverpoints
- Total, 8 bins are formed
- Combinations are (0, 0), (0, 1), (1, 0), (1, 1) 
- All possible combination bins are created
- If cross wasn't present, we would have achieved 100% coverage with (0, 0) and (1, 1)

```verilog
bit [3:0] data;
bit [1:0] addr;

covergroup cov @(event_var);
	data_cp: coverpoint data {
		bins lo = {[0:7]}; // single bin for 8 values
		bins hi[] = {[8:15]}; // 8 separate bins
	}
	addr_cp : coverpoint addr; //automatically 4 bins created
	cross_data_addr: cross data_cp, addr_cp;
endgroup
```
- Totally for cross (9 x 4) 36 bins will be created

#### User-defined cross bins
```verilog
int i, j;
covergroup ct;
	coverpoint i {bins i0 = {0}; bins i1 = {1};} // 2 bins 
	coverpoint j {bins j0 = {0}; bins j1 = {1};} // 2 bins
	x2: cross i, j {
		bins i_zero = binsof(i) intersect {0}; // Generates bins for <i0, j0> and <i0, j1>
		// bins i_one = binsof(i) intersect {1}; // Generates bins for <i1, j0> and <i1, j1>	
	}
endgroup
```
- Cross `x2` has the following bins:
	- `i_zero` user-defined bin for `<i0, j0>` and `<i0, j1>`
	- `<i1, j0>` is an automatically generated bin that is retained
	- `<i1, j1>` is an automatically generated bin that is retained
	- Totally, 2 + 2 + 1 + 2 = 7 bins
- Note: In cross, whichever case is left out, auto bins are generated for those cases

```verilog
bit [7:0] va, vb;
covergroup cg @(posedge clk);
	a: coverpoint va {
		bins a1 = {[0:63]};
		bins a2 = {[64:127]};
		bins a3 = {[128:191]};
		bins a4 = {[192:255]};
	}
	b: coverpoint vb {
		bins b1 = {0}
		bins b1 = {[1:84]};
		bins b2 = {[85:169]};
		bins b3 = {[170:255]};
	}
	c: cross a, b {
		bins c3 = binsof(a.a1) && binsof(b.b4); // 1 cross product
		bins c1 = !binsof(a) intersect {[100:200]}; // 4 cross products
		bins c2 = binsof(a.a2) || binsof(b.b2); //7 cross products
	}
endgroup
```
- The following bins are created:
```
c3 = (a1, b4)
c1 = (a1, b1) (a1, b2) (a1, b3) (a1, b4)
c2 = (a2, b1) (a2, b2) (a2, b3) (a2, b4) (a1, b2) (a3, b2) (a4, b2)
```
- These are not covered, hence auto bins are created for the following combination of cross
```
(a3, b1) 
(a4, b1) 
(a3, b3) 
(a4, b3) 
(a3, b4) 
(a4, b4) 
```
- Totally, 17 bins are created