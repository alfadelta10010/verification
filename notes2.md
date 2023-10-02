# Arrays
In SV theres two types of array formats:
- Unpacked arrays
- Packed arrays

## Unpacked array
```verilog
bit pes [7:0]; - Verbose declaration
bit pes [8]; - Compact declaration
```
- `[7:0]` - Dimension
- `pes` - name of array
- Does not store in the same memory address (0x0000, 0x0004, ...)
```verilog
bit [7:0] pes [4];
``` 
- Still an unpacked array, since theres a dimension after the name
- It is a **packed unpacked** array, aka memory location 0x0000 has `[7:0]` bits, and 0x0004 has `[15:8]` bits, and so on till 32 bits
- Assigning a packed array to an unpacked array gives a compile error
```verilog
bit [7:0] b_unpack [4];
input [31:0] din;
din = b_unpack //compile error
dim = {b_unpack[3], b_unpack[2], b_unpack[1], b_unpack[0]}
```
- Using a concatination operator, we can assign a packed array to an unpacked array.
```verilog
module test;
	bit [3:0] [7:0] array;
	input [7:0] array1 [3:0];

	logic [31:0] din1 = 
	initial
		{array1[0], array1[1], array1[2], array1[3],} = din1;
		array1 = din1;//compile time error 
	end
	logic din2 =
	initial
		array = din2;
	initial begin
```
- :warning: **Take from slides**


## Packed array
```verilog
bit [7:0] pes;
```
- `[7:0]` - Dimension
- `pes` - name of array
- Stores in same memory address (0x0000)
```verilog
bit [3:0] [7:0] arr;
```
- `[3:0]` = No. of arr elements
- `[7:0]` = No. of bits in a single arr

##Verilog Multi-dimensional arrays
```verilog
module test;
	int arr1 [4]; //unpacked array
	int arr2 [4]; //unpacked array
	int arr3 [4]; //unpacked array
	int arr4 [4]; //unpacked array
	int arr5 [4]; //unpacked array
	int arr6 [4]; //unpacked array
	
	int mda [6][4]; //2 dimesional array of 4 bit wide, 6 times
	
	initial begin
		for (int i = 0; i < 4; i++) begin
			arr1[1] = 5;
			$display("arr[%0d] = %0d", i, arr1[i]);
		end
		for (int i = 0; i < 4; i++) begin
			for (int j = 0; j < 4; j++) begin
				mda[i][j] = i + j;
				$display("mda[%0d][%0d] = %0d", i, j, mda[i][j]);
			end
		end
	end
endmodule;
```
- Very very tedious
> Note: Using `$random` compiler directive generates random signed values, and `$urandom` generates random unsigned values

## SystemVerilog Multi-dimensional arrays
- Initialisation at declaration
```verilog
int arr[5] = '{10, 11, 12, 13, 14};
string str[4] = '{"garima", "abhiram", "alisha", "aarav"};
int arr2[5] = '{1, 2, 3, 4, 5};
```
- Using the `'` operator along with the concatination operator, we can assign at run time

## Types of Arrays
- Fixed size arrays
- Dynamic arrays
- Associative arrays
- Queues

### Fixed Size arrays
- All the arrays we have used so far are fixed size arrays
```verilog
int arr [0:3] //verbose big endian declaration
int arr [0:3] //verbose big endian declaration
int arr [4] //compact declaration
```
- If the code tries to read from an out-of-bounds address, then it returns the default value for the data type
- For 4-state datatype like logic, it would be X
- For 2-state datatype like bit and int, it would be 0
- This applies to all array types.

### Dynamic arrays
- Compiling - Checks for syntax and semantics, and all static data types are allocated memory, which persists till the end of the simulation
- Hence, static data types' memory allocation happens at compile time
- On the other hand, the dynamic data types have memory allocated once they are written to, and it persists till end of simulation
- THere's three dynamic data types in SystemVerilog:
	- Dynamic arrays
	- Associative arrays
	- Queues
- We use dynamic data types for real time applications
- **some slide theory he skipped**
```verilog
module test;
	int d1[], d2[];
	initial begin
		d1 = new[4];
		d1[0] = 11; (or) d1 = '{10, 11, 12, 13};
		d2 = d1; // All elements of d1 are copied to d2, and d2 has a length of 4
		d1 = new[8](d1); // d1 has 8 memory locations, and the initial 4 values are retained
		d1 = new[100]; // d1 has 100 memory locations, and it's all 0s
		$display("size of d1 = %0d", d1.size()); // The size of d1 (100 locations) is printed
		d2.delete(); // d2 is no more T_T
	end // at this point, its only d1 with 100 0s
endmodule // after this point, nothing remains
```
- Create a dynamic array called ArrayFull - it should contain 10 numbers. Create two more dynamic arrays - ArrayEven and ArrayOdd - it should contain even numbers and odd numbers from ArrayFull
```verilog
module hw;
	int ArrayFull[];
	int ArrayEven[], ArrayOdd[];
	-----
```
- Dynamic arrays are useful for contiguous collections of variable whose numbers change dynamically

### Associative Arrays
- Associative arrays allocate stoage only when used, not that we have to declare size before using (like dynamic)
- :warning: **copy from slides**
```verilog
module test;
	bit [7:0] arr [int];
	initial begin
		arr[0] = 10;
		arr[4] = 20; // there's no index 1, 2, 3, size = 2
		arr[7] = 30; // size = 3
		$display("size = %0d", arr.size()); // 3
		arr.delete(4); // deletes 4th index
		if(arr.exists(7)) // checks if index 7 exists
			arr[8] = 40;	// if yes
		else arr[7] = 40;
	end
endmodule
```
```verilog
module test;
	bit [7:0] arr [string];
	initial begin
		arr["ram"] = 10;
		arr["srini"] = 20;
		arr["raja"] = 30;
		$display("size = %0d", arr.size()); // 3
		arr.delete("raja"); // deletes 4th index
		if(arr.exists("srini") // checks if index 7 exists
			arr["ravi"] = 40;	// if yes
		else arr["srini"] = 40;
	end
endmodule
```
- In dynamic:
```verilog
int d1[];
d1 = new[10];
d1 = '{5, 6, 7}
```
- rest memory locations are wasted
- This is not the case in Associative
- When the size of the collection is unknown, or the data spacve is sparse, an associative array is better

### Queues
- A queue is a cariable sise ordered collection of homogeneous elements
- Like a dynamic array, queues can grow and shrink
- Queue supports adding and removing elements anywhere
- Queues are declared using the same syntax as unpacked arrays, but specifying $ as the array size.
- In queue 0 represents the first and $ representing the last entries
- A queue can be bounded or unbounded
- Bounded queue: Queue with their number of entries limited (or) queue size specified
- Unbounded queue: Queue with 

-----------------------------------------------------------------------------------
### Revision
- `int a [6];` - unpacked
- `int a [0:5];` - unpacked verbose big endian
- `int a [5:0];` - unpacked verbose little endian
- `int a [];` - dynamic
- `int a [int];` - associative 

-----------------------------------------------------------------------------------
## Array functions
```
a[0] = 15;
a[2] = 30;
a[4] = 60;
a[6] = 80;
```
- `array.first(var)` = Returns the first index of array to var `= 0`
- `array.next(var)` = Returns the next index of array to var `= 2`
- `array.last(var)` = Returns the last index of array to var `= 6`
- `array.prev(var)` = Returns the prior index of array to var `= 4`
- It remembers through pointer location in functions
- `array.size()` = Returns size of array 
- `array.num()` = Same as above, just newer
- `array.delete(var)` = Deletes value of array at index var
- `array.exists(var)` = Gives a true/false if a value exists in array at index var

