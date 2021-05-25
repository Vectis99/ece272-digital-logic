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
// CREATED		"Thu Apr 25 16:21:13 2019"

module Lab3(
	D,
	Seg
);


input wire	[3:0] D;
output wire	[6:0] Seg;

wire	[6:0] Seg_ALTERA_SYNTHESIZED;





Sb	b2v_inst(
	.D(D),
	.Sb(Seg_ALTERA_SYNTHESIZED[1]));


Sa	b2v_inst1(
	.D(D),
	.Sa(Seg_ALTERA_SYNTHESIZED[0]));


Sc	b2v_inst2(
	.D(D),
	.Sc(Seg_ALTERA_SYNTHESIZED[2]));


Sd	b2v_inst3(
	.D(D),
	.Sd(Seg_ALTERA_SYNTHESIZED[3]));


Se	b2v_inst4(
	.D(D),
	.Se(Seg_ALTERA_SYNTHESIZED[4]));


Sf	b2v_inst5(
	.D(D),
	.Sf(Seg_ALTERA_SYNTHESIZED[5]));


Sg	b2v_inst6(
	.D(D),
	.Sg(Seg_ALTERA_SYNTHESIZED[6]));

assign	Seg = Seg_ALTERA_SYNTHESIZED;

endmodule
