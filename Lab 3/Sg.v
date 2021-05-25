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
// CREATED		"Thu Apr 25 16:25:56 2019"

module Sg(
	D,
	Sg
);


input wire	[3:0] D;
output wire	Sg;

wire	[3:0] notD;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_2;





Comp4	b2v_inst(
	.D(D),
	.notD(notD));

assign	SYNTHESIZED_WIRE_2 = notD[3] & D[2] & D[1] & D[0];

assign	SYNTHESIZED_WIRE_0 = D[3] & D[2] & notD[1] & notD[0];

assign	SYNTHESIZED_WIRE_1 = notD[3] & notD[2] & notD[1];

assign	Sg = SYNTHESIZED_WIRE_0 | SYNTHESIZED_WIRE_1 | SYNTHESIZED_WIRE_2;


endmodule
