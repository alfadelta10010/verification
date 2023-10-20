module arb_with_mp (arb_if.DUT arbif);
	always @(posedge arbif.clk or posedge arbif.rst)
		begin
			if (arbif.rst)
				arbif.grant <= 2'b00;
			else if (arbif.request[0])  // High priority
				arbif.grant <= 2'b01;
			else if (arbif.request[1])  // Low priority
				arbif.grant <= 2'b10;
			else
				arbif.grant <= '0;
		end
endmodule