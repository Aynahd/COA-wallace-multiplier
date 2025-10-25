// full_adder: 1-bit structural full adder
module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire x = b ^ a;
    assign sum = x ? ~cin : cin;
    assign cout = x ? cin : b;
endmodule


// csa32: 32-bit carry-save adder (structural)
// Inputs: x,y,z (32-bit) -- Outputs: sum (32-bit), carry_sh (32-bit)
// carry_sh is the carry bits shifted-left by 1 (i.e. ready to be added without further shift)
module csa32 (
    input  wire [31:0] x,
    input  wire [31:0] y,
    input  wire [31:0] z,
    output wire [31:0] sum,
    output wire [31:0] carry_sh
);
    wire [31:0] carry_bit;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : fa_bits
            full_adder fa (
                .a   (x[i]),
                .b   (y[i]),
                .cin (z[i]),
                .sum (sum[i]),
                .cout(carry_bit[i])
            );
        end
    endgenerate

    // shift carries left by 1 bit: carry_sh[0] = 0, carry_sh[i] = carry_bit[i-1]
    assign carry_sh = { carry_bit[30:0], 1'b0 }; // carry_bit[31] is dropped (fits in 32-bit product)
endmodule


// ripple_adder32: structural ripple-carry adder, produces 32-bit sum.
// (carry-out is produced but not used externally)
module ripple_adder32 (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum,
    output wire       cout
);
    wire [31:0] carry;
    genvar j;
    generate
        for (j = 0; j < 32; j = j + 1) begin : rfa
            if (j == 0) begin
                full_adder fa0 (
                    .a   (a[0]),
                    .b   (b[0]),
                    .cin (1'b0),
                    .sum (sum[0]),
                    .cout(carry[0])
                );
            end else begin
                full_adder faj (
                    .a   (a[j]),
                    .b   (b[j]),
                    .cin (carry[j-1]),
                    .sum (sum[j]),
                    .cout(carry[j])
                );
            end
        end
    endgenerate
    assign cout = carry[31];
endmodule


// Top: Wallace-style 16x16 multiplier (structural, combinational)
module wallace16x16_struct (
    input  wire [15:0] A,
    input  wire [15:0] B,
    output wire [31:0] P
);
    // Partial products: 16 operands of 32-bit each (B times A[i], shifted by i)
    wire [31:0] pp [0:15];
    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : gen_pp
            // place B at LSB side then shift left by k
            wire [31:0] B_ext = {16'b0, B}; // 32-bit extension of B
            assign pp[k] = A[k] ? (B_ext << k) : 32'b0;
        end
    endgenerate

    // Reduction tree using CSA blocks
    // Stage names and signals follow the plan described in the assistant analysis.
    // Stage1: group triples (pp0,pp1,pp2), (pp3,pp4,pp5), (pp6,pp7,pp8), (pp9,pp10,pp11), (pp12,pp13,pp14)
    wire [31:0] s0, c0, s1, c1, s2, c2, s3, c3, s4, c4;
    csa32 csa_s0 (.x(pp[0]),  .y(pp[1]),  .z(pp[2]),  .sum(s0), .carry_sh(c0));
    csa32 csa_s1 (.x(pp[3]),  .y(pp[4]),  .z(pp[5]),  .sum(s1), .carry_sh(c1));
    csa32 csa_s2 (.x(pp[6]),  .y(pp[7]),  .z(pp[8]),  .sum(s2), .carry_sh(c2));
    csa32 csa_s3 (.x(pp[9]),  .y(pp[10]), .z(pp[11]), .sum(s3), .carry_sh(c3));
    csa32 csa_s4 (.x(pp[12]), .y(pp[13]), .z(pp[14]), .sum(s4), .carry_sh(c4));
    // leftover pp[15] remains as an operand

    // Stage2: group (s0,c0,s1), (c1,s2,c2), (s3,c3,s4)
    wire [31:0] s5, c5, s6, c6, s7, c7;
    csa32 csa_s5 (.x(s0), .y(c0), .z(s1), .sum(s5), .carry_sh(c5));
    csa32 csa_s6 (.x(c1), .y(s2), .z(c2), .sum(s6), .carry_sh(c6));
    csa32 csa_s7 (.x(s3), .y(c3), .z(s4), .sum(s7), .carry_sh(c7));

    // Stage3: group (s5,c5,s6), (c6,s7,c7)
    wire [31:0] s8, c8, s9, c9;
    csa32 csa_s8 (.x(s5), .y(c5), .z(s6), .sum(s8), .carry_sh(c8));
    csa32 csa_s9 (.x(c6), .y(s7), .z(c7), .sum(s9), .carry_sh(c9));

    // Stage4: group (s8,c8,s9), (c9,c4,pp15)
    wire [31:0] s10, c10, s11, c11;
    csa32 csa_s10 (.x(s8), .y(c8), .z(s9),  .sum(s10), .carry_sh(c10));
    csa32 csa_s11 (.x(c9), .y(c4), .z(pp[15]),.sum(s11), .carry_sh(c11));

    // Stage5: group (s10,c10,s11), leftover c11
    wire [31:0] s12, c12;
    csa32 csa_s12 (.x(s10), .y(c10), .z(s11), .sum(s12), .carry_sh(c12));

    // Stage6: group (s12,c12,c11) -> final two operands s13, c13
    wire [31:0] s13, c13;
    csa32 csa_s13 (.x(s12), .y(c12), .z(c11), .sum(s13), .carry_sh(c13));

    // Final adder (structural ripple adder) to add the last two operands
    ripple_adder32 final_add (
        .a   (s13),
        .b   (c13),
        .sum (P),
        .cout() // ignored
    );

endmodule


// Simple testbench (behavioral test only - testbench itself uses behavioral features)
module tb_wallace16x16;
    reg  [15:0] A;
    reg  [15:0] B;
    wire [31:0] P;
    integer i;
    integer errors;

    wallace16x16_struct uut (
        .A(A),
        .B(B),
        .P(P)
    );

    initial begin
        errors = 0;
        // some directed tests
        A = 16'h0000; B = 16'h0000; #1; check();
        A = 16'h0001; B = 16'h0001; #1; check();
        A = 16'hFFFF; B = 16'h0001; #1; check();
        A = 16'hFFFF; B = 16'hFFFF; #1; check();

        // random tests
        for (i = 0; i < 2000; i = i + 1) begin
            A = $random;
            B = $random;
            #1;
            check();
        end

        if (errors == 0) $display("All tests passed.");
        else $display("%0d mismatches found.", errors);
        $finish;
    end

    task check;
        reg [31:0] ref;
        begin
            ref = A * B;
            if (P !== ref) begin
                $display("Mismatch: A=%0h B=%0h got=%0h ref=%0h", A, B, P, ref);
                errors = errors + 1;
            end
        end
    endtask
endmodule
