`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.10.2025
// Design Name: Wallace Tree Multiplier (4x4)
// Module Name: wallace_tree_multiplier_4x4
// Description: Structural 4x4 Wallace tree multiplier using and_gate and full_adder_mux
//////////////////////////////////////////////////////////////////////////////////

module wallace(
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [7:0] PROD
);

    // -------------------------------------------------
    // Step 1: Partial Product Generation (AND gates)
    // -------------------------------------------------
    wire pp00, pp01, pp02, pp03;
    wire pp10, pp11, pp12, pp13;
    wire pp20, pp21, pp22, pp23;
    wire pp30, pp31, pp32, pp33;

    and_gate g00 (.A(A[0]), .B(B[0]), .Y(pp00));
    and_gate g01 (.A(A[1]), .B(B[0]), .Y(pp01));
    and_gate g02 (.A(A[2]), .B(B[0]), .Y(pp02));
    and_gate g03 (.A(A[3]), .B(B[0]), .Y(pp03));

    and_gate g10 (.A(A[0]), .B(B[1]), .Y(pp10));
    and_gate g11 (.A(A[1]), .B(B[1]), .Y(pp11));
    and_gate g12 (.A(A[2]), .B(B[1]), .Y(pp12));
    and_gate g13 (.A(A[3]), .B(B[1]), .Y(pp13));

    and_gate g20 (.A(A[0]), .B(B[2]), .Y(pp20));
    and_gate g21 (.A(A[1]), .B(B[2]), .Y(pp21));
    and_gate g22 (.A(A[2]), .B(B[2]), .Y(pp22));
    and_gate g23 (.A(A[3]), .B(B[2]), .Y(pp23));

    and_gate g30 (.A(A[0]), .B(B[3]), .Y(pp30));
    and_gate g31 (.A(A[1]), .B(B[3]), .Y(pp31));
    and_gate g32 (.A(A[2]), .B(B[3]), .Y(pp32));
    and_gate g33 (.A(A[3]), .B(B[3]), .Y(pp33));

    // -------------------------------------------------
    // Step 2: Wallace Tree Reduction (Full Adders)
    // -------------------------------------------------
    // Column-wise compression
    // We will compress from LSB to MSB

    // Output bit 0
    assign PROD[0] = pp00;

    // Column 1: pp01, pp10
    wire s11, c11;
    full_adder_mux FA1 (.A(pp01), .B(pp10), .Cin(1'b0), .Sum(s11), .Cout(c11));
    assign PROD[1] = s11;

    // Column 2: pp02, pp11, pp20
    wire s12, c12;
    full_adder_mux FA2 (.A(pp02), .B(pp11), .Cin(pp20), .Sum(s12), .Cout(c12));

    // Column 3: pp03, pp12, pp21
    wire s13, c13;
    full_adder_mux FA3 (.A(pp03), .B(pp12), .Cin(pp21), .Sum(s13), .Cout(c13));

    // Column 4: pp13, pp22, pp31
    wire s14, c14;
    full_adder_mux FA4 (.A(pp13), .B(pp22), .Cin(pp31), .Sum(s14), .Cout(c14));

    // Column 5: pp23, pp32
    wire s15, c15;
    full_adder_mux FA5 (.A(pp23), .B(pp32), .Cin(1'b0), .Sum(s15), .Cout(c15));

    // Column 6: pp33
    assign PROD[7] = pp33; // MSB contributes directly, plus carries combined later

    // -------------------------------------------------
    // Step 3: Combine carries with next columns
    // -------------------------------------------------
    // Column 2 output
    wire s22, c22;
    full_adder_mux FA6 (.A(s12), .B(c11), .Cin(1'b0), .Sum(s22), .Cout(c22));
    assign PROD[2] = s22;

    // Column 3 output
    wire s23, c23;
    full_adder_mux FA7 (.A(s13), .B(c12), .Cin(c22), .Sum(s23), .Cout(c23));
    assign PROD[3] = s23;

    // Column 4 output
    wire s24, c24;
    full_adder_mux FA8 (.A(s14), .B(c13), .Cin(c23), .Sum(s24), .Cout(c24));
    assign PROD[4] = s24;

    // Column 5 output
    wire s25, c25;
    full_adder_mux FA9 (.A(s15), .B(c14), .Cin(c24), .Sum(s25), .Cout(c25));
    assign PROD[5] = s25;

    // Column 6 (final carries)
    wire s26, c26;
    full_adder_mux FA10 (.A(pp33), .B(c15), .Cin(c25), .Sum(s26), .Cout(c26));
    assign PROD[6] = s26;
    assign PROD[7] = c26; // final carry

endmodule
