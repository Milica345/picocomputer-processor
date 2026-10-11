module cla (
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] s,
    output cout
);

    wire [3:0] p;
    wire [3:0] g;
    wire [4:0] c;

    assign g = a & b;
    assign p = a | b;

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    assign cout = c[4];

    full_adder fa0 (.a(a[0]), .b(b[0]), .cin(c[0]), .s(s[0]), .cout());
    full_adder fa1 (.a(a[1]), .b(b[1]), .cin(c[1]), .s(s[1]), .cout());
    full_adder fa2 (.a(a[2]), .b(b[2]), .cin(c[2]), .s(s[2]), .cout());
    full_adder fa3 (.a(a[3]), .b(b[3]), .cin(c[3]), .s(s[3]), .cout());

endmodule
