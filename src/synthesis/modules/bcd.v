module bcd (
    input [5:0] in,
    output [3:0] ones,
    output [3:0] tens
);

    wire [5:0] ones_full;
    wire [5:0] tens_full;

    assign ones_full = in % 6'd10;
    assign tens_full = in / 6'd10;

    assign ones = ones_full[3:0];
    assign tens = tens_full[3:0];

endmodule
