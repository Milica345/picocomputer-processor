module csel (
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] s,
    output cout
);

    wire c_low;
    wire [3:0] s_hi0, s_hi1;
    wire c_hi0, c_hi1;

    rca rca_low (.a(a[3:0]), .b(b[3:0]), .cin(cin), .s(s[3:0]), .cout(c_low));

    rca rca_hi0 (.a(a[7:4]), .b(b[7:4]), .cin(1'b0), .s(s_hi0), .cout(c_hi0));
    rca rca_hi1 (.a(a[7:4]), .b(b[7:4]), .cin(1'b1), .s(s_hi1), .cout(c_hi1));

    assign s[7:4] = c_low ? s_hi1 : s_hi0;
    assign cout   = c_low ? c_hi1 : c_hi0;

endmodule
