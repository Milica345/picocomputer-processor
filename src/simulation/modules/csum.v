module csum (
    input a,
    input b,
    output s0,
    output c0,
    output s1,
    output c1
);

    assign s0 = a ^ b;
    assign c0 = a & b;

    assign s1 = ~(a ^ b);
    assign c1 = a | b;

endmodule
