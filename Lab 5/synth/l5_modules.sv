//HELPER FUNCTIONS

//I wrote a truncate function because it apparently supresses warnings??? I'm not sure.
//function logic [3:0] trunc (int val, output logic );
//	trunc = val[3:0];
//endfunction
	

//PREFABRICATED MODULES
//These are ugly, but it's how the textbook does it.

//Counts from 0 to 2^(N-1). Overflows appropriately to 0.
//Parameter: Number of bits of memory + 1 (For this assignment, 41)
//CLK: increment value on positive edge
//Reset: Forces value to 0
//q: current stored value
module counter #(parameter N = 41) (input logic clk, input logic reset, output logic [N-1:0]q);
	always_ff@(posedge clk, posedge reset)
		if(reset)	q<= 0;
		else		q <= q+1;
endmodule

//Comparater not included because it is very useless. Why is it in this lab?
//module comparator #(parameter N =

//Synchronizer
//I honestly can't tell what this thing is for, it's probably not important.
//It never comes up in lab, anyway.
module sync(input logic clk, input logic d, output logic q);
	logic n1;
	always_ff@(posedge clk)
		begin
			n1 <= d; //Nonblocking
			q <= n1; //Nonblocking
		end
endmodule

//The exact same thing as lab 2, but simpler
//I had to change this from the source code because our 7segs are active low, not active high.
//data: The number to translate to display form
//segments: 7 bit number legible to the 7 segment display.
module sevenseg(input logic[3:0] data, output logic[6:0] segments);
	always_comb
		case(data)
			//              abc_defg
			0:	segments=7'b000_0001;
			1:	segments=7'b100_1111;
			2:	segments=7'b001_0010;
			3:	segments=7'b000_0110;
			4:	segments=7'b100_1100;
			5:	segments=7'b010_0100;
			6:	segments=7'b010_0000;
			7:	segments=7'b000_1111;
			8:	segments=7'b000_0000;
			9:	segments=7'b000_1100;
			10:	segments=7'b000_1000;
			11:	segments=7'b110_0000;
			12:	segments=7'b011_0001;
			13:	segments=7'b100_0010;
			14:	segments=7'b011_0000;
			15:	segments=7'b011_1000;
			default: segments = 7'b000_0000; //This should throw an error, technically. But whatever.
		endcase
endmodule

//CUSTOM MODULES
//These modules will be much nicer because I made them!

//Converts any time into a numerical system humans are familiar with. All values are floored.
//Parameters:
//		N: The number of bits of input plus 1. 40 bits is sufficient for 255 hours of processing.
//		SPD: The speed of the system clock. This is 10MHz, or 10,000,000
//t = ticks
//s = seconds
//m = minutes
//h = hours
module human_time #(parameter N = 41, parameter SPD = 20000000) (input logic [N-1:0]t, output logic [20:0]s, output logic [15:0]m, output logic [8:0]h);
	logic [N-1:0]s_untrunc;
	assign s_untrunc = t/SPD; //This assign is not giving me anything?
	always_comb //Fires every time the output could possibly be different. I just chose a super sensitive always and went with it.
		begin
			s <= (s_untrunc);
			m <= (s_untrunc/60);
			h <= (s_untrunc/3600);
		end
endmodule

//Converts the system time into a numerical system humans are familiar with. All values are floored.
//Hooked up to work properly with the system clock.
//Parameters:
//		N: The number of bits of input plus 1. 40 bits is sufficient for 255 hours of processing.
//		SPD: The speed of the system clock. This is 10MHz, or 10,000,000
//t = ticks
//s = seconds
//m = minutes
//h = hours
//clk: system clock of speed SPD
//reset: Resets the time to 0 while high.
module system_human_time #(parameter SPD = 20000000) (input logic clk, input logic reset, output logic [20:0]s, output logic [15:0]m, output logic [8:0]h);
	logic [41:0]t; //The system time, in tics
	counter #(41) u0(.clk(clk), .reset(reset), .q(t)); //Counts up t good and proper
	human_time #(41, SPD) u1(.t(t), .s(s), .m(m), .h(h)); //Pipes to the output!
endmodule

// Converts a long number into its two most significant hexidecimal digits. Wraps at 60, for clock purposes.
// val: The number to be coverted into two decimal digits.
// big: The most significant decimal digit of val
// small: The second most significant digit of val
module parser(input logic [7:0]val, output logic [3:0]big, output logic [3:0]little);
	logic [7:0] bf;
	assign bf = (val%60);
	assign little = (bf%10);
	assign big = (bf/10);
endmodule

// The top level module of the system; makes a pretty 7 segment display clock
// N: The number of bits of clock data to stored
// SPD: The speed of the clock
// clk: The system clock of speed SPD
// reset: Drive high to set time to zero
// seg0: Hour 1
// seg1: Hour 2
// seg2: Minute 1
// seg3: Minute 2
// seg4: Second 1
// seg5: Second 2
module pretty_clock #(parameter N = 41, parameter SPD = 20000000)
	(input logic clk, input logic reset, output logic [6:0]seg0, output logic [6:0]seg1, output logic [6:0] seg2, output logic [6:0] seg3, output logic [6:0] seg4, output logic [6:0] seg5);
	
	logic [20:0] s;
	logic [15:0] m;
	logic [8:0] h;
	
	//im is short for intermediate
	logic [3:0] im0;
	logic [3:0] im1;
	logic [3:0] im2;
	logic [3:0] im3;
	logic [3:0] im4;
	logic [3:0] im5;
	
	system_human_time #(SPD) timing_element(.clk(clk), .reset(reset), .s(s), .m(m), .h(h));
	
	parser p0(.val(s),.little(im0),.big(im1));
	parser p1(.val(m),.little(im2),.big(im3));
	parser p2(.val(h),.little(im4),.big(im5));
	
	sevenseg s0(.data(im0), .segments(seg0));
	sevenseg s1(.data(im1), .segments(seg1));
	sevenseg s2(.data(im2), .segments(seg2));
	sevenseg s3(.data(im3), .segments(seg3));
	sevenseg s4(.data(im4), .segments(seg4));
	sevenseg s5(.data(im5), .segments(seg5));
endmodule