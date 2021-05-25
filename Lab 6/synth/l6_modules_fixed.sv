// I had to restart the lab from scratch because I did not know there was a restriction as to the maximum register size.
// In order to develop the driver I had intended, I will have to store the image data in SDRAM; which currently is outside of
// the scope of what I currently would like to do.

/*CONSTANTS*/
// Horizontal sync: 96
// Horizontal front porch: 48
// Horizontal display: 640
// Horizontal display end: 784
// Horizontal back porch: 16
// Horizontal total: 800

// Vertical sync: 2
// Vertical front porch: 33
// Vertical display: 480
// Vertical back porch: 10
// Vertical total: 525


/* RECYCLED MODULES FROM LAB 5 */

// Counts from 0 to 2^(N-1). Overflows appropriately to 0.
// MAX: The maximum value this counter can reach.
// CLK: increment value on positive edge
// Reset: Forces value to 0
// q: current stored value
module counter #(parameter MAX = 15, parameter MAX_BITS = 4) (input logic clk, input logic reset, output logic [MAX_BITS-1:0]q);
	always_ff@(posedge clk, posedge reset)
		if(reset)	q<= 0;
		else if (q  > MAX-1)	q <= 0;
		else		q <= q+1;
endmodule

/*MODULES*/

// Halves the speed of an arbitrary clock
// reset: tin and initalizer
// full: The full-speed clock to cut in half
// half: A clock operating at half speed
module halver (input logic reset, input logic full, output logic half);
	always_ff@(posedge full, posedge reset) begin
		if(reset) begin
			half <= full;
		end else begin
			//Not reseting, do the behavior.
			if(!half) begin
				half <= 1;
			end else begin
				half <= 0;
			end
		end
	end
endmodule

//module counter

// Generates properly proportioned VGA syncwaves.
// reset: tin
// clk: A 25Mhz clock.
// hsync: The horizontal syncwave, for VGA
// vsync: The vertical syncwave, for VGA
module syncer #(parameter H_LOW = 96, parameter H_PERIOD = 800, parameter V_LOW = 2, parameter V_PERIOD = 525) (input logic reset, input logic clk, output logic hsync, output logic vsync);
	logic [$clog2(H_PERIOD*V_PERIOD):0] t;
	//log2(800*525) = 18.6
	counter #((H_PERIOD*V_PERIOD), 19) timer (.reset(reset), .clk(clk), .q(t));
	assign hsync = t%H_PERIOD >= H_LOW;
	assign vsync = t/H_PERIOD >= V_LOW;
endmodule

// Redirects the appropriate data stream based on the hsync and vsync states.
// reset: tin
// clk: The clock being used by the sync wave generator
// hsync: the horizontal syncwave
// data: The RGB value to forward to the vga system.
// data_clk: A clock which queries data on the rising edge of each pixel.
//           This feature is still being implemented; expect bugs.
// to_vga: Data to be plugged into the red, green, and blue channels of the VGA port.
module data_pipe #(parameter V_BLANKS = 35, parameter DISPLAY_ROWS = 480, parameter V_TOTAL = 525) 
(input logic reset, input logic hsync, input logic clk, input logic [2:0][3:0] data, output logic data_clk, output logic [2:0][3:0] to_vga);
	logic [10:0] row; //$clog2(800) < 10
	logic [10:0] col; //'
	logic col_reset;
	
	//assign col_reset = ( == );
	//log2(525) ~= 10
	counter #((525 - 1), 10) row_tracker (.reset(reset), .clk(hsync), .q(row));
	counter #((800 - 1), 10) col_tracker (.reset(reset), .clk(clk), .q(col));
	
	//Data clk is highly unstable and should not be relied upon.
	always_comb begin
		//Logic is supposed to be:
		// If the row is above the minimum and below the maximum and hsync is on.
		if((row > V_BLANKS - 1) & (row < (V_BLANKS + DISPLAY_ROWS)) & hsync & (col >= 48 + 96) & (col < 48 + 96 +640)) begin
			to_vga <= data;
			data_clk <= clk;
		end else begin
			to_vga <= 0;
			data_clk <= 0;
		end
	end
	/*Alternatively, change this logic to be sequential.*/
	/*
	always_ff@(posedge clk) begin
		if(row >= V_BLANKS & row < V_BLANKS + DISPLAY_ROWS & hsync)
			data_clk = clk;
			to_vga = data;
		end else begin //The contents of this block do not need to be synced.
			to_vga <= 0;
			data_clk <= 0;
		end
	end
	*/
endmodule

// Testbench for realtime color modification.
// Each RGB can be one of:
//     15 <- 3
//     10 <- 2
//     5 <- 1
//     0 <- 0
// c_switches: A bunch of switches the user flips to change the color
// rgb: The user-defined RGB value.
module manual_data (input logic [5:0] c_switches, output logic [2:0][3:0] rgb);
	assign rgb[0] = 5*c_switches[1:0];
	assign rgb[1] = 5*c_switches[3:1];
	assign rgb[2] = 5*c_switches[5:4];
endmodule

// Top level module: Puts user inputted colors on a VGA screen.
// reset: tin
// sys_clk: A 50MHz clock signal
// c_switches: A bunch of switches the user flips to change the color
// hsync: Protocol required signal; fires per row
// vsync: Protocol required signal; fires per column
// red: Red VGA pin
// green: Green VGA pin
// blue: Blue VGA pin
module monitor
(input logic reset, input logic sys_clk, input logic[5:0] c_switches, 
output logic hsync, output logic vsync, 
output logic [3:0] red, output logic [3:0] green, output logic[3:0] blue);
	logic protocol_clock;
	logic [2:0][3:0] coerced_rgb;
	logic [2:0][3:0] live_rgb;
	manual_data ui(.c_switches(c_switches), .rgb(coerced_rgb));
	halver to_protocol_speed(.reset(reset), .full(sys_clk), .half(protocol_clock));
	syncer stater(.reset(reset), .clk(protocol_clock), .hsync(hsync), .vsync(vsync));
	data_pipe thinker(.reset(reset), .clk(protocol_clock), .hsync(hsync), .data(coerced_rgb), .to_vga(live_rgb));
	assign red = live_rgb[0];
	assign green = live_rgb[1];
	assign blue = live_rgb[2];
endmodule