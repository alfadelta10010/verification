module top;
	bit clk;
	always #50 clk = ~clk;
	
	arb_if arbif(clk);
	arb_with_mp a1(arbif);
	test_with_mp t1(arbif);
endmodule : top