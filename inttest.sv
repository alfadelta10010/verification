module test;
	integer i1; // 0,1,x,z, default is x
	int i2; // 0 and 1, default is 0
	shortint i3;
	longint i4;
	initial
		begin
			$display("%b", i1); //xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
			$display("%b", i2); //0000 0000 0000 0000 0000 0000 0000 0000
			$display("%b", i3); // 
			$display("%b", i4);
		end 
endmodule