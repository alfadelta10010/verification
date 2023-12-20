# Self Checking Testbench
```
 ┌──────┐               Mailbox       Mailbox
 │Packet│              (or) queue     (or) queue
 └───┬──┘                   │            │
     │                      │ ┌─────────┐│ ┌──────────┐
┌────▼────┐      ┌─────────┐│ │Reference├┴─►Scoreboard│
│Generator│      │Monitor_1├┴─► Model   │  └────▲─────┘
└────┬────┘      └───▲─────┘  └─────────┘       │
     │Mailbox        │Virtual Interface         │
 ┌───▼──┐       ┌────┴────────────┐             │
 │Driver├───────►    Interface    │         ┌───┴─────┐
 └──────┘Virtual│   ┌─────────┐   ├─────────►Monitor_2│
       Interface│   │         │   │Virtual  └─────────┘
                │   │ ┌─────┐ │   │Interface
                │   ├─► DUT ├─►   │
                │   │ └─────┘ │   │
                └───┘         └───┘
```
#### Packet
- Packet class is also known as **transaction class**
- We decalre all the input and output signals available in the design in the packet class
- The inputs will be declared as `rand`

#### Generator
- The Generator will randomize the input signals
- The randomized inputs are pur into the mailbox using the put method
- The generator will create handle for packet

#### Driver
- `<copy from slides>`

## Simulation
#### DUT
```verilog
module half_adder(s,c,a,b);
  input a,b;
  output s,c;
  xor x1( s,a,b);
  and a1(c,a,b);
endmodule
```

#### Packet
```verilog
class transaction;
// Stimulus are declared with rand keyword
  rand bit a;  
  rand bit b;
  bit sum;
  bit carry;

//Function for Displaying values of a, b and sum, carry  
  function void display(string name);
    $display("-------------------------");
    $display(" %s ",name);
    $display("-------------------------");
    $display("a = %0d,   b = %0d",a,b);
    $display("sum = %0d, carry = %0d",sum,carry);
    $display("-------------------------");
  endfunction
endclass
```

#### Generator
```verilog
class generator;
	transaction trans; //Handle of Transaction class
	mailbox gen2driv;  //Mailbox declaration
	function new(mailbox gen2driv);  //creation of mailbox and constructor
		this.gen2driv = gen2driv;
	endfunction
	task main();
		repeat(1)
			begin
				trans = new();
				trans.randomize();
				trans.display("Generator");
				gen2driv.put(trans);
			end
	endtask
endclass
```