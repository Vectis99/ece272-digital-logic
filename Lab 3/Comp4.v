// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
// CREATED		"Thu Apr 25 16:23:55 2019"

module Comp4(
	D,
	notD
);


input wire	[3:0] D;
output wire	[3:0] notD;

wire	[3:0] notD_ALTERA_SYNTHESIZED;




assign	notD_ALTERA_SYNTHESIZED[3] =  ~D[3];

assign	notD_ALTERA_SYNTHESIZED[2] =  ~D[2];

assign	notD_ALTERA_SYNTHESIZED[1] =  ~D[1];

assign	notD_ALTERA_SYNTHESIZED[0] =  ~D[0];

assign	notD = notD_ALTERA_SYNTHESIZED;

endmodule
