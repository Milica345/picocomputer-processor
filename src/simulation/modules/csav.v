module csav (
    input [3:0] a,
    input [3:0] b,
    input [3:0] c,
    output [3:0] s,
    output [4:0] cout
);

    wire [3:0] carry;

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .s(s[0]), .cout(carry[0]));
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .s(s[1]), .cout(carry[1]));
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .s(s[2]), .cout(carry[2]));
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .s(s[3]), .cout(carry[3]));

    assign cout = {carry, 1'b0};

endmodule
