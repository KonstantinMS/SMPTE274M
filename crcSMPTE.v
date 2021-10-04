`timescale 1ns / 1ps
//https://bues.ch/cms/hacking/crcgen
// CRC polynomial coefficients: x^18 + x^5 + x^4 + 1
//                              0x23000 (hex)
// CRC width:                   18 bits
// CRC shift direction:         right (little endian)
// Input word width:            10 bits

module crcSMPTE (
	input [17:0] crcIn,
	input [9:0] data,
	output [17:0] crcOut
);
	assign crcOut[0] = crcIn[10];
	assign crcOut[1] = crcIn[11];
	assign crcOut[2] = crcIn[12];
	assign crcOut[3] = (crcIn[0] ^ crcIn[13] ^ data[0]);
	assign crcOut[4] = (crcIn[0] ^ crcIn[1] ^ crcIn[14] ^ data[0] ^ data[1]);
	assign crcOut[5] = (crcIn[1] ^ crcIn[2] ^ crcIn[15] ^ data[1] ^ data[2]);
	assign crcOut[6] = (crcIn[2] ^ crcIn[3] ^ crcIn[16] ^ data[2] ^ data[3]);
	assign crcOut[7] = (crcIn[3] ^ crcIn[4] ^ crcIn[17] ^ data[3] ^ data[4]);
	assign crcOut[8] = (crcIn[0] ^ crcIn[4] ^ crcIn[5] ^ data[0] ^ data[4] ^ data[5]);
	assign crcOut[9] = (crcIn[1] ^ crcIn[5] ^ crcIn[6] ^ data[1] ^ data[5] ^ data[6]);
	assign crcOut[10] = (crcIn[2] ^ crcIn[6] ^ crcIn[7] ^ data[2] ^ data[6] ^ data[7]);
	assign crcOut[11] = (crcIn[3] ^ crcIn[7] ^ crcIn[8] ^ data[3] ^ data[7] ^ data[8]);
	assign crcOut[12] = (crcIn[4] ^ crcIn[8] ^ crcIn[9] ^ data[4] ^ data[8] ^ data[9]);
	assign crcOut[13] = (crcIn[5] ^ crcIn[9] ^ data[5] ^ data[9]);
	assign crcOut[14] = (crcIn[6] ^ data[6]);
	assign crcOut[15] = (crcIn[7] ^ data[7]);
	assign crcOut[16] = (crcIn[8] ^ data[8]);
	assign crcOut[17] = (crcIn[9] ^ data[9]);
endmodule
