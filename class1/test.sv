module test;
byte my_byte;
integer my_integer;
int my_int;
bit [15:0] my_bit;
shortint my_short_int1;
shortint my_short_int2;
assign my_integer = 32'b000_1111_xxxx_zzzz;
assign my_int = my_integer;
assign my_bit = 16'h8000;
assign my_short_int1 = my_bit;
assign my_short_int2 = my_short_int1 - 1;

initial
	begin
		$display ("The value of a = %h", my_integer);
		$display ("The value of a = ", my_bit);
		$display ("The value of a = ", my_short_int1);
                $display ("The value of a = ", my_short_int2);
	end
endmodule
