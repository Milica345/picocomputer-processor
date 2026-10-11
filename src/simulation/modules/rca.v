module rca (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] s,
    output cout
);

    wire [4:0] c;

    assign c[0] = cin;
    assign cout = c[4];

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .s(s[0]), .cout(c[1]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .s(s[1]), .cout(c[2]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .s(s[2]), .cout(c[3]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .s(s[3]), .cout(c[4]));

endmodule
