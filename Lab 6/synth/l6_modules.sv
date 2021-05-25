// Outputs a signal 0 for 96 continuous clock cycles, then outputs
// a logic high for 704 cycles, as per p37 of the DE10-Lite manual. 
// low: The number of clock cycles the output should be low during.
// high: The number of clock cycles the output shoudl be high during.
// clk: An arbitrary clock which determines sig
// reset: Forces the start of a new period on high. Also prevents 
//        the regular operation of clk with respect to sig.
// sig: A signal which is low for the first part of the period and
//      high for the rest of it.
module prelab #(parameter low = 96, parameter high = 704) (input logic clk, input logic reset, output logic sig);
	logic [$clog2(low + high):0] t;
	always_ff @ (posedge clk, posedge reset) begin
		if(reset | t >= low + high) begin
			t <= 0;
			sig <= 0;
		end else if (t >= low) begin
			t <= t + 1;
			sig <= 1;
		end else begin
			t <= t + 1;
			sig <= 0;
		end
	end
endmodule

// Halves the speed of an arbitrary clock
// reset: tin and initalizer
// full: The full-speed clock to cut in half
// half: A clock operating at half speed=
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


// Determines the current state of the display driver based on the system clock.
// T_ROW: Calculated constant. See "lab notes" section of lab report.
//        This should always be 800, I just made it a parameter because I don't know
//        how to define constants in system verilog.
// N_ROWS: As above; 525.
// H_LOW: The number of cycles per row to remain at logic low on the sync wave.
// V_LOW: The number of rows to VSYNC for.
// VFP: The front porch of vertical sync
// VBP: The back porch of vertical sync
// reset: tin
// sys: The system clock. *Must be 50Mhz* (period = 50ns)
// image: The image to display on the screen
// clk: The pixel clock for the VGA protocol
// row_data: The row data from image corresponding to the current row, as per t.
// hsync: The waveform representing the horizontal sync wave.
// vsync: The waveform prepresenting the vertical sync wave.
module state_manager #(parameter T_ROW = 800, parameter N_ROWS = 525, parameter H_LOW = 96, parameter V_LOW = 2/*, parameter VFP = 33, parameter VBP = 10*/)
(input logic reset, input logic sys, input logic [9:0][639:0][2:0][3:0] image,
output logic clk, output logic[639:0][2:0][3:0] row_data, output logic hsync, output logic vsync);
	logic [10*9:0] t; //The time in the current frame.
	halver h(.reset(reset), .full(sys), .half(clk)); //Get the proper clock from the system.
	vertical_porcher porcher(.image(image), .current_row(t/T_ROW), .row_data(row_data));
	//Lock the image data reader to the vertical display zone
	always_ff@(posedge clk, posedge reset) begin
		if(reset | t >= T_ROW*N_ROWS) begin //If resetting or we have reached the end of the frame (total cycle).
			t = 0;
			hsync = 0;
			vsync = 0;
			row_data = 0;
		end else begin //Not resetting and not at max
			//Increment t
			t <= t + 1;
			//Determine the current row's data package.
			//The code here was migrated to vertical porcher.
			//Determine horizontal and vertical sync based on t
			if((t%T_ROW) < H_LOW) begin //If we are in horizontal sync mode.
				hsync = 0; //During sync, bring it LOW
			end else begin
				
				hsync = 1;
			end
			if((t/T_ROW) < V_LOW) begin //In vertical sync
				vsync = 0;
			end else begin
				vsync = 1;
			end
		end
	end
endmodule

// Overrides the row data if the current row is in the zero zone (the "porch").
// Otherwise, this module indexes the current row from the image, accounting for
// relevant protocol offsets.
// N_ROWS: The number of rows per vertical PERIOD.
// VFP: The length of the porch (zero zone) at the top of the image.
// VBP: The length of the porch (zero zone) at the back of the image.
// image: An array of RGB data, with the top left (0,0) value corresponding to 
//        the first colored pixel of the image proper.
// current_row: The index of the current row of the vertical period.
// row_data: A 1d array of all of the color data in the row, again, excluding the
//           porches.
module vertical_porcher #(parameter N_ROWS = 525, parameter V_LOW = 2, parameter VFP = 33, parameter VBP = 10)
(input logic [479:0][639:0][2:0][3:0] image, input logic [9:0] current_row, output logic [639:0][2:0][3:0] row_data);
	always_comb begin
		if(current_row >= (VFP + V_LOW) & current_row < (N_ROWS - VBP)) begin
			assign row_data = image[current_row-V_LOW-VFP]; //Index the row's data from the image input
		end else begin //We are either in the front or back porch of the vertical timing
			assign row_data = 0;
		end
	end
endmodule

// I think that the following module needs an additional argument to let it know if it should output
// a blank row instead of the color; or it should just be passed in a "data" of 0,0,0.
//     Above: Resolved.
// Fills in a row of pixels from an array.
// T_HSYNC: The width of the sync band
// FPORCH: The buffer room to the left of the image, in pixels.
// BPORCH: The buffer room to the right of the image, in pixels.
// hsync: The syncwave which triggers the feeding of image data
// clk: The procedural incrementer
// data: An array containing RGB values for each pixel in the row.
//       data[0] is the first pixel, EXCLUDING buffer room.
//       data[T_HSYNC - BPORCH - 1] is the maximum index of the meaningful pixels.
// to_VGA: The bus of rgb values to be exported to the monitor.
module horizontal_executor #(parameter T_HSYNC = 704, parameter FPORCH = 48, parameter BPORCH = 16)
(input logic hsync, input logic clk, input logic [639:0][2:0][3:0] data, output logic[2:0][3:0] to_VGA);
	logic [10:0] t;
	//On row start
	always_ff@(posedge hsync) begin
		t = 0;
	end
	always_ff@(posedge clk) begin //The first positive edge of the clock should come AFTER t
		if(hsync) begin
			t <= t + 1; //Start by incrementing t.
			//Wait for graphic zone (48 cycles). MUST BE RGB 0.
			//Do nothing until next reset (16 cycles). MUST BE RGB 0.
			if(t >= FPORCH & t < T_HSYNC - BPORCH) begin
				to_VGA = data[t-FPORCH]; //Pump out a new RGB on each rising clock edge (640 cycles)
			end else begin
				to_VGA = 0; //I hope this sets the RGB to zero on all bus lanes.
			end
		end else begin
			to_VGA = 0;
		end
	end

endmodule


/* // So I think I don't actually need a vertical executor since literally all it would take care of
//    is vsync, which is already handled by state_manager.
//Makes sure that the horizontal executor goes appropriately and repeatedly in the proper order.
module vertical_executor #() 
(input logic vsync, input logic clk, input logic [9:0][10:0][2:0][3:0] data, output logic to_VGA)
	logic [9 * 10:0] t; //Not sure how big this data needs to be.
	//On beginning of vertical sync
	always_ff@(posedge vsync) begin
	//Wait 33 cycles of vertical sync; blank rows, so to speak. MUST BE RGB 0.
	//Execute horizontal_executor 480 times.
	//Wait 10 cycles of vertical sync; blank rows.
endmodule*/

// Provides the data for a static screen of colors R, G, and B.
// This is a testbench and as such does not suit expandability well.
// swt: The switch which turns the output on and off.
// rgb: a row x col RGB code.
//      RGB is represented as [0]->red, [1]->green, [2]-> blue, 
//      all in 8 bit binary notation. (Range 0-255). These will have to be changed 
//      because we are no longer in 8bit binary notation.
//      Undefined values are in the extra space at the end of the array.
module static_rgb(input logic swt, output logic[479:0][639:0][2:0][3:0] rgb);
	genvar r;
	genvar c;
	generate
	for(r=0; r<480; r=r+1) begin : mandatory_name_a //Should be 480, but I didn't want to leave undefined values
		for(c=0; c < 640; c++) begin : mandatory_name_b
			always_comb begin
				if(swt) begin
					rgb[r][c][0] <= 3; //Red screen
					rgb[r][c][1] <= 4; //Green screen
					rgb[r][c][2] <= 14; //Blue screen
				end else begin
					rgb[r][c][0] <= 0; //Red screen
					rgb[r][c][1] <= 0; //Green screen
					rgb[r][c][2] <= 0; //Blue screen
				end
			end
		end
	end
	endgenerate
	/*genvar r1;
	genvar c1;
	genvar r2;
	genvar c2;
	always@* if(swt) begin
		generate
			for(r1 = 0; r1 < 480; r1=r1+1) begin
				for(c1 = 0; c1 < 640; c1=c1+1) begin
					rgb[r1][c1][0] = 3; //Red screen
					rgb[r1][c1][0] = 4; //Green screen
					rgb[r1][c1][0] = 14; //Blue screen
				end
			end
		endgenerate
	end else begin
		generate
			for(r2 = 0; r2 < 480; r2=r2+1) begin
				for(c2 = 0; c2 < 640; c2=c2+1) begin
					rgb[r2][c2][0] = 0; //Red screen
					rgb[r2][c2][0] = 0; //Green screen
					rgb[r2][c2][0] = 0; //Blue screen
				end
			end
		endgenerate
	end*/
endmodule

/*module index_rgb(input logic[9:0][10:0][2:0][3:0] screen, input logic[10:0] row, input logic[9:0] col, output logic[2:0][3:0] rgb);
	assign rgb = screen[row][col];
endmodule*/


/* Top level */

// Makes a VGA screen switch between black and a static color.
// reset: tin
// sys: A 50MHz system clock.
// switch: The user input allowing the state of the screen to be switched.
// screen: This is where image data would be recieved if this were a real driver.
// horizontal: hsync wave, used by device.
// vertical: vsync wave, used by device. Driven low during the transition to the 
//           next frame.
// red: The red channel for the monitor
// green: The green channel for the monitor
// blue: The blue channel for the monitor.
module monitor(input logic reset, input logic sys, input logic switch, /*input logic[9:0][10:0][2:0][3:0] screen,*/ output logic horizontal, output logic vertical, output logic[3:0] red, output logic[3:0] green, output logic[3:0] blue);
	logic [479:0][639:0][2:0][3:0] image;
	logic monitor_clock;
	logic [2:0][3:0] color_bus;
	logic [639:0][2:0][3:0] row_data;
	//Instance the testbench screen
	static_rgb image_setter(.swt(switch),.rgb(image)); // This would not be used if this was a real driver. Instead,
	//                                                   image would be taken from the input.
	
	//Instance the state manager
	state_manager manager(.reset(reset), .sys(sys), .image(image), .row_data(row_data), .clk(monitor_clock), .hsync(horizontal), .vsync(vertical));
	//Instance the RGB controller
	horizontal_executor controller(.hsync(horizontal), .clk(monitor_clock), .data(row_data), .to_VGA(color_bus));
	assign red = color_bus[0];
	assign green = color_bus[1];
	assign blue = color_bus[2];
endmodule