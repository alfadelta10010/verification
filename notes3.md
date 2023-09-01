# Queues
- A queue is a variable size ordered collection of homogenous elements
- Like a dynamic array, queues can grow and shrink
- Queue supports adding and removing elements anywhere
- Queues are bounded (has a max no. of elements) or unbounded (limitless)
```verilog
bit queue_1[$]; // Queue of bits
int queue_1[$]; // Queue of integers
byte queue_3[$:255]; // Bounded queue of bytes, 256 elements
string queue_4[$]; //queue of strings
```

## Queue methods
- Explaining `push` and `pop`
```verilog
bit[31:0] q1[$]; // queue of 32 bts
bit[31:0] b1, b2; // 32 bits
initial begin
	q1.push_front(45); // Inserts element 45 at front of queue
	q1.push_back(55); // Inserts element 55 at end of queue
	q1.push_front(65); // Inserts element 65 at front of queue
	q1.push_back(75); // Inserts element 75 at end of queue
	b1 = q1.pop_front(); // Removes and returns the first element, not copies
	b2 = q1.pop_back(); // Removes and returns the last element, not copies
end
```
- A queue is not physically limitless as computer has constraints
- Order after push: `|65|45|55|75|`
- Order after pop: `|45|55|`
- Explaining `insert` and `delete`:
```verilog
module tb;
	int index = 1; int j;
	int q[$] = {5, 6, 7};
	int q2[$] = {20, 30};
	initial begin
		q.insert(index, 10); 
		// has two components, index and value
		// index is where the value is inserted, moving all elements back by 1
		//{5, 10, 6, 7}
		q.insert(4, q2)
		// inserting another queue into the queue
		//{5, 10, 6, 20, 30, 7}
		q.delete(1);
		// Delete entry 1
		// {5, 6, 20, 30, 7}
		q.push_front(9); // {9, 5, 6, 20, 30, 7}
		j = q.pop_back(); // {9, 5, 6, 20, 30}
		q.push_back(8); // {9, 5, 6, 20, 30, 8}
		j = q.pop_front(); // {5, 6, 20, 30, 8}
		q.delete(); // deletes entire queue
```
> In exam, always explain with a code

- Explaining `find`:
```verilog
int d[] = '{9, 1, 12, 3, 3, 4, 4, 32, 12};
int tq[$];
tq = d.find with(item > 3);
// tq = {9, 12, 4, 4, 32, 12}
tq = d.find_index with(item > 3);
// tq = {0, 2, 4, 5, 6, 7}
tq = d.find_first with(item > 42);
//tq = {}
tq = d.find_first_index with(item==12);
// tq = {2}
tq = d.find_last_index with(item==12);
// tq = {7}

```
- `item` represents a single element of the array
- `find_index()` returns the indices of all the elements satisfying the given expression
- Shared with dynamic arrays

# Array methods
- there are many array methods that you can use on any unpacked array types (fixed, dynaic, queue, associative)
- Array reduction methods
- Array locator methods
- Array sorting and ordering
> impt 7m, can be this or queue methods

## Array reduction methods
- A basic array reduction method takes and array and reduces it a single value
```verilog
byte b[$] = {2, 3, 4, 5};
int w;
w = b.sum(); //14 = 2 + 3 + 4 + 5
w = b.product(); //120 = 2 * 3 * 4 * 5
w = b.and(); // 0000_0000 = 2 & 3 & 4 & 5 (no common 1s hence its all zeros
w = b.or(); // 
w = b.xor(); // 
```

## Array locator methods
- Largest value, if value is there, etc
- Array locator methods find data in an unpacked array
```verilog
int f[6] = '{1,6,2,6,8,6}; //Fixed size array
int d[] = '{2,4,6,8,10}; //Dynamic array
int q[$] = '{1,3,5,7}; //queue
int tq[$]; //result queue

tq = q.min(); //
tq = d.max(); //
tq = f.unique(); //
```
- In a `with` clause, the item name is called the **iterator argument** and represents a single element of the array
```verilog
int d[] 
TAKE FROM SLIDES
```
- Declaring the iderator argument
```verilog
tq = d.find_first with (item==4);
tq = d.find_first() with (item==4);
tq = d.find_first(item) with (item==4);
tq = d.find_first(x) with (x==4);
```
- The above are all same
- To total up a subset of value in the array
```verilog
int count, total, d[] = '{9,1,8,3,4,4,};
count = d.sum(x) with (x > 7); // 2 = 1+0+1+0+0+0
total = d.sum(x) with ((x > 7) * x); // 17 = 9+0+8+0+0+0
count = d.sum(x) with (x < 8); // 4 = 0+1+0+1+1+1
total = d.sum(x) with ((x <
**copy from slides**
```
- Array sorting and ordering
```verilog
int d[] = '{9,1,8}
d.reverse();
d.sort();
d.rsort();
d.shuffle();
**copy from slides**
```
> Man was in tooooooo much of a rush
> Have a hands-on experience with arrays, need to know properly before next class