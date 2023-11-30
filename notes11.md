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

- Type and data declarations within the program are local to the program scope and have static lifetime
- Variables declared within the scope of a program, including variables declared as ports, are called **program variables**
- Similarly, nets decalred within scope of a program are called **program nets**
- Program variables and nets are collectivaely termed **program signals**
- Reference to program signals from outside any program block shall be an error.

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
- Instantiating the program block, in the top module:
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
					data_out <= mem[addr];
					out_enable <= 1'b1;
				end
			else
				out_enable <= 1'b0;
		end
endmodule
```
- Synchronous WRITE and Synchronous READ (posedge clk)

- Creating the test bench with program block
```verilog
program testbench(clk, tb_reset, tb_wr, tb_rd, tb_addr, tb_wdata, tb_rdata, response);
	parameter reg[15:0] ADDR_WIDTH = 4;
	parameter reg[15:0] DATA_WIDTH = 32;
	parameter reg[15:0] MEM_SIZE = 16;
	
	input clk;
	output tb_reset;
	output tb_wr; //for write wr = 1
	output tb_rd; //for write wr = 1
	output [ADDR_WIDTH - 1:0] tb_addr;
	output [DATA_WIDTH - 1:0] tb_wdata;
	input [DATA_WIDTH - 1:0] tb_rdata;
	input response;
	
	reg tb_reset;
	reg tb_wr; //for write wr = 1
	reg tb_rd; //for write wr = 1	
	reg [ADDR_WIDTH - 1:0] tb_addr;
	reg [DATA_WIDTH - 1:0] tb_wdata;
	
	reg [DATA_WIDTH - 1:0] ref_arr [MEM_SIZE]; //Expected Data
	reg [DATA_WIDTH - 1:0] got_arr [MEM_SIZE]; //Actual Data
	
	bit [4:0] matched, mis_matched;
	
	initial
		begin
			#1
			$display("[tb] Simulation Started at time: %0t", $time);
			tb_reset = 0;
			reset();
			write();
			repeat(2) @(posedge clk);
			read();
			repeat(2) @(posedge clk);
			compare();
			result();
			#1 $display("[tb] Simulation Ended at time: %0t", $time);
		end
	
	task reset();
		#1
		$display("[tb] Applying reset at time: %0t", $time);
		tb_reset = 1;
		#3
		tb_reset = 0;
		$display("[tb] DUT out of reset at time: %0t", $time);
	endtask
	
	task write();
	endtask
	
	task read();
	endtask
	
	task compare();
	endtask
	
	task result();
	endtask
endprogram
```

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
- This debugging leads to waste of time and does not add value to the design.
- To solve this, enter `interface` block
- Instead of using 100s of interconnects, we can group all the signals into a bus using the `interface` block
