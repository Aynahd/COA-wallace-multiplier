`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.10.2025 16:14:15
// Design Name: 
// Module Name: full_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module full_adder_mux(
    input  wire A,
    input  wire B,
    input  wire Cin,
    output wire Sum,
    output wire Cout
);
    wire X = B ^ A;
    assign Sum = X ? ~Cin : Cin;
    assign Cout = X ? Cin : B;
endmodule


module full_adder_mux_16bit(
    input  wire [15:0] A,
    input  wire [15:0] B,
    input  wire        Cin,
    output wire [15:0] Sum,
    output wire        Cout
);

    wire [15:0] carry;

    full_adder_mux FA0  (A[0],  B[0],  Cin,      Sum[0], carry[0]);
    full_adder_mux FA1  (A[1],  B[1],  carry[0], Sum[1], carry[1]);
    full_adder_mux FA2  (A[2],  B[2],  carry[1], Sum[2], carry[2]);
    full_adder_mux FA3  (A[3],  B[3],  carry[2], Sum[3], carry[3]);
    full_adder_mux FA4  (A[4],  B[4],  carry[3], Sum[4], carry[4]);
    full_adder_mux FA5  (A[5],  B[5],  carry[4], Sum[5], carry[5]);
    full_adder_mux FA6  (A[6],  B[6],  carry[5], Sum[6], carry[6]);
    full_adder_mux FA7  (A[7],  B[7],  carry[6], Sum[7], carry[7]);
    full_adder_mux FA8  (A[8],  B[8],  carry[7], Sum[8], carry[8]);
    full_adder_mux FA9  (A[9],  B[9],  carry[8], Sum[9], carry[9]);
    full_adder_mux FA10 (A[10], B[10], carry[9], Sum[10], carry[10]);
    full_adder_mux FA11 (A[11], B[11], carry[10], Sum[11], carry[11]);
    full_adder_mux FA12 (A[12], B[12], carry[11], Sum[12], carry[12]);
    full_adder_mux FA13 (A[13], B[13], carry[12], Sum[13], carry[13]);
    full_adder_mux FA14 (A[14], B[14], carry[13], Sum[14], carry[14]);
    full_adder_mux FA15 (A[15], B[15], carry[14], Sum[15], carry[15]);

    assign Cout = carry[15];

endmodule