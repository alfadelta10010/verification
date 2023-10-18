# Interface
- Interface represents a bundle of nets or variables, with intelligence such as synchronization, and functional code.
- An interface can be instantiated like a module but also connected to ports like a signal.
- Syntax:
```verilog
interface interface_name (arguments);
	<interface_items>
endinterface
```
- The interface straddles two modules
```
┌───────────────────────────────────────────────┐
│                                               │
│    Top Module                                 │
│  ┌──────────────┐           ┌──────────────┐  │
│  │              │           │              │  │
│  │            ┌─┼───────────┼─┐            │  │
│  │  Testbench │ │ Interface │ │  Arbiter   │  │
│  │            └─┼───────────┼─┘            │  │
│  │              │           │              │  │
│  └──────────────┘           └──────────────┘  │
│                                               │
│                                               │
└───────────────────────────────────────────────┘
```
- Arbiter: The arbiter is a mediator between different system components and system resources.
- All the nets in the interface, by default, bidirectional (`inout`)
- All variables in the interface, by default, are `ref` type
- Taking a basic example for using interface as a port:
```verilog
interface simple_bus;
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic wr, rd;
endinterface

module RTL (simple_bus intf, input logic clk);
	logic [31:0] mem [16];
	always @(posedge clk)
		if(intf.wr == READ) //pseudo code
			intf.rdata <= mem[intf.addr];
endmodule
```
- The RTL and TB is pseudo-code btw
```
       ┌──┬─────────────┐      
 ──────│WR│    RTL      │      
       ├──┘             │      
       ├────┐           │      
 ──────│ADDR│           │      
       ├────┘           │      
       ├─────┐   ┌──────┤      
 ──────│WDATA│   │ RDATA│
       ├─────┘   └──────┤
       ├──┐             │
 ──────│RD│             │
       ├──┘             │
       ├─────┐          │
 ──────│Reset│          │
       ├─────┘          │
       ├───┐            │
 ──────│Clk│            │
       └───┴────────────┘
```
- Taking a look at the testbench:
```verilog
program TB(simple_bus tbif, input clk);
	initial begin
		tbif.wr = 1;
		tbif.wdata = $urandom;
		tbif.addr = 5;
	end
endprogram
```
- In the `top` module:
```verilog
module top;
	logic clk = 0
	always #5 clk = !clk;
	simple_bus intf_inst();
	RTL dut_inst(intf_inst clk); // positional mapping
	TB test_inst(.tbif(intf_inst), .clk(clk)); // nominal mapping
endmodule
```
- Interface block can be written in `top` module or `rtl` module
- Interface can be used for both testbench & design, or "interface for testbench and direct mapping in design", or vice versa.
> :warning: legacy code slides

- Referring `2.TB Using simple interface`'s `top.sv`, 
- We see that the structure is as follows:
```
┌────────────────────────────────────────────────────────────┐
│    Top Module                                              │
│  ┌──────────────┐                  ┌─────────────────┐     │
│  │              ├─────┐     ┌──────┤                 │     │
│  │              │   ┌▼─────▼┐    │                 │     │
│  │  Testbench   ├─►│Interface│◄──┤   Design        │     │
│  │              │   └▲─────▲┘    │                 │     │
│  │              ├─────┘     └──────┤                 │     │
│  └──────────────┘                  └─────────────────┘     │
└────────────────────────────────────────────────────────────┘
```


- However, one issue: how does designer know which is input and which are output?

# Modports
- A modport defines the port direction that the module sees for the signas in the interface
```verilog
interface simple_bus(input clk); // Define the interface
	logic [31:0] rdata, wdata;
	logic [3:0] addr;
	logic rd, wr;
	
	modport dut_ports (input addr, wr, rd, wdata, clk, output rdata);
	modport tb_ports (output addr, wr, rd, wdata input rdata, clk);
endinterface
```
- The modport definitions do not contain vector sizes of types
- The modport declaration only defines that the connected module sees input or output
```
       ┌──┬─────────────┐      
 ────►│WR│    RTL      │      
       ├──┘             │      
       ├────┐           │      
 ────►│ADDR│           │      
       ├────┘           │      
       ├─────┐   ┌──────┤      
 ────►│WDATA│   │ RDATA├───►
       ├─────┘   └──────┤
       ├──┐             │
 ────►│RD│             │
       ├──┘             │
       ├─────┐          │
 ────►│Reset│          │
       ├─────┘          │
       ├───┐            │
 ────►│Clk│            │
       └───┴────────────┘
```
:warning: refer `5.TB using modports legacy 1`
- this approach describes in `` module

:warning: refer `6.TB using modports legacy 2`
- this approach describes in `` module

# Arbiter Communication Model

```
┌────────────────────────────────────────────┐
│          Testbench                         │
│    ┌──────────────────────────────────┐    │
│    │                                  │    │
│    │ request[1:0]┌───────┐ grant[1:0] │    │
│    ├────────────►       ├──────────►│    │
│    │             │Arbiter│            │    │
│    │   rst       │       │    clk     │    │
│    ├────────────►       ◄────▲────►    │
└────┘             └───────┘     │      └────┘
```
- Truth table

|`rst`|`req[0]`|`req[1]`|`grnt[0]`|`grnt[1]`|
|:-:|:-:|:-:|:-:|:-:|
|1|X|X|0|0|
|0|0|1|0|1|
|0|1|0|1|0|
|0|1|1|P|P|

- Last case is based on priority
- The arbiter code:
```verilog
module arb_with_port (output logic [1:0] grant,
					  input logic [1:0] request,
					  input bit rst, clk);
	always @(posedge clk or posedge rst)
		begin
			if (rst)
				grant <= 2'b00;
			else if (request[0]) // High priority
				grant <= 2'b01;
			else if (request[1]) // Low priority
				grant <= 2'b10;
			else
				grant <= 2'b00;
		end
endmodule
```
- The testbench code:
```verilog
module test_with_port (input logic [1:0] grant,
					   output logic [1:0] request,
					   input bit clk,
					   output bit rst);
endmodule
```
:warning: copy from page 131, textbook

