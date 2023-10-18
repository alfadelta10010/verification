# Program block
- General layout
```verilog
program test;
	int errors, warnings;
	initial begin
		// Main prgram activity
		// Generate stimulus
	end
	final
	$display("Test done with %0 errors and %0d warnings", errors, warnings);
endprogram
```
- Executes in re-region
- A program block may contain one or more initial or final procedures
- A program block shall not contain:
	- `always` procedures
	- Primitives
	- User-defined primitives
	- Declarations or instances of modules, interfaces, or other programs
- When all initial procedures within a program have reached their end, that program shall immediately terminate the simulation, no need for `$finish`
- Programs can only be instantiated in design scopes
:warning: page 86 of `1. Chapter 4 PPTs-2.pdf`

## What does a proper test bench look like?
- There are three files
	- `HA.sv` - Design file
	- `HA_test.sv` - Testbench file
	- `top.sv` - Top-level module
- The top level module instantiates both the design and testbenc file
- The DUT is also called RTL
- Taking a look at the top module for memory model:
```
┌───────────────────────────────────────────────────────────┐
│                                                           │
│      ┌────────────────┬──┐        ┌──┬─────────────┐      │
│      │   PB           │WR├──────►│WR│    RTL      │      │
│      │                └──┤        ├──┘             │      │
│      │              ┌────┤        ├────┐           │      │
│      │              │ADDR├──────►│ADDR│           │      │
│      │              └────┤        ├────┘           │      │
│      ├─────┐       ┌─────┤        ├─────┐   ┌──────┤      │
└──────┤RDATA│       │WDATA├──────►│WDATA│   │ RDATA├──────┘
       ├─────┘       └─────┤        ├─────┘   └──────┤
       │                ┌──┤        ├──┐             │
       │                │RD├──────►│RD│             │
       │                └──┤        ├──┘             │
       │             ┌─────┤        ├─────┐          │
       │             │Reset├──────►│Reset│          │
       │             └─────┤        ├─────┘          │
       │               ┌───┤        ├───┐            │
       │               │Clk│◄────►│Clk│            │
       └───────────────┴───┘   ▲   └───┴────────────┘
                               │
                               │
      ┌──────────────────┐     │
      │always #5 clk=!clk├─────┘
      └──────────────────┘
```
- Module top generates the `clk` and connects the PB (program block) and RTL
- `clk` is input to PB and RTL
- Writing a test bench for this:
```verilog
program test();
	input clk;
	output [31:0] wdata;
	output rd, wr, reset;
	input [31:0] rdata;
	initial begin
		wr = 1;
		for(int i = 0; i <= 15; i++)
			
			```
:warning: Copy from `1. Chapter 4 PPTs-2.pdf`

- Instantiating the program block
```verilog
module top;
	bit clk, reset;
	logic [31:0] rdata, wdata;
	logic rd, wr;
	logic [3:0] addr;
	always #5 clk = !clk;
	
	RTL rtl_inst(rdata, wdata, rd, wr, addr, clk, reset);
	TB pgm_blk_inst(rdata, wdata, rd, wr, addr, clk, reset);
endmodule
```

## Memory Model
> Write a Verilog RTL memory model (DUT)
> Write Verilog testbench:
> 	- Write a task to apply reset to DUT
> 	- Write a task to write to all 16 locations
> 	- Write a task to read from all 16 locations 
> 	- Write comparison task to compare write data and read data
> 	- Print Test PASS or FAIL with the compare result
> For example:
> `WRITE`: `wr = 1`, `addr = 3`, `wdata = 50`
> `READ`: `rd = 1`, `addr = 3`, check for `rdata = 50`

### Third strategy
- DUT, TB and Top module

#### Starting with the RTL block
```verilog
module rtl_memory(rdata, wdata, rd, wr, addr, clk, reset)
	
	parameter ADDR_WIDTH = 4;
	parameter DATA_WIDTH = 32;
	parameter MEM_SIZE = 16;
	
	input bit clk, reset;
	input logic wr, rd;
	input logic [3:0] addr;
	input logic [31:0] wdata;
	output [31:0] rdata;
	
	//wr = 1 => Write
	//rd = 1 => Read
	
	logic [DATA_WIDTH-1:0] mem [MEM_SIZE]; //reg [31:0] mem [16]
	logic [DATA_WIDTH-1:0] data_out;
	
	logic response; // Provides response to master on sucessful write
	logic out_enable; // Controls when to pass read data on rdata pin, additional pin it is, out_enable = rd
	
	// If rd = 0, rdata should be in high impedance state
	// If rd = 1, rdata should be content of memory with given address
	
	assign rdata = out_enable ? data_out : 'bz;
	
	//async reset and sync write
	always @(posedge clk or posedge reset) 
		begin
			if(reset)
				begin
					for(int i = 0, i < MEM_SIZE; i++)
						mem[i] <= 'b0;
				end
			else if (wr)
				begin
					mem[addr] <= wdata;
					response <= 1'b1;
				end
			else
				response <= 1'b0;
		end
	
	//sync read
	always @(posedge clk)
		begin
			if(rd == 1)
				begin
					data_out
```
:warning: copy from slides: `1. Chapter 4 PPTs-2.pdf`
- Synchronous WRITE and Synchronous READ (posedge clk)
- Creating the test bench with 

#### Creating a top module:
```verilog
module top;
	parameter logic [15:0] ADDR_WIDTH = 4;
	parameter logic [15:0] DATA_WIDTH = 32;
	parameter logic [15:0] MEM_SIZE = 16;
	
	logic clk, tb_reset;
	logic tb_wr; // for write wr = 1
	logic tb_rd; // for write wr = 1
	logic [ADDR_WIDTH - 1:0] tb_addr;
	logic [DATA_WIDTH - 1:0] tb_wdata;
	
	logic [DATA_WIDTH - 1:0] tb_rdata;
	logic response;
	
	initial clk = 0;
	always #5 clk = !clk;
	
	memory_rtl DUT(.clk(clk), .reset(tb_reset), .wr(tb_wr), .rd(tb_rd), .addr(tb_addr), .wdata(tb_wdata), .rdata(tb_rdata), .response(response));
	
	testbench TEST(.clk(clk), .tb_reset(tb_reset), .tb_wr(tb_wr), .tb_rd(tb_rd), .tb_addr(tb_addr), .tb_wdata(tb_wdata), .tb_rdata(tb_rdata), .response(response));
	
endmodule
```
- In reality, the number of ports on a system will be huge
- What happens if we mismatch the port connections? Do we get any compile error?
	- We don't get compile error but functionality will be affected, this debugging leads to waste of time and does not add value to the design.
- To solve this, enter `interface` block
- Instead of using 100s of interconnects, we can group all the signals into a bus using the `interface` block
