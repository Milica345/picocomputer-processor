module csel_tb;

    reg [7:0] a, b;
    reg cin;
    wire [7:0] s;
    wire cout;
    integer i, errors;
    reg [8:0] expected;

    csel dut (.a(a), .b(b), .cin(cin), .s(s), .cout(cout));

    initial begin
        $display("");
        $display("=== Carry Select Adder (8 bita, dve grupe po 4, od RCA) ===");
        errors = 0;
        for (i = 0; i < 131072; i = i + 1) begin
            {a, b, cin} = i[16:0];
            #5;
            expected = a + b + cin;
            if ({cout, s} !== expected) begin
                errors = errors + 1;
                $display("  GRESKA: %0d + %0d + %0d -> cout=%b s=%0d", a, b, cin, cout, s);
            end
        end
        a = 8'd200; b = 8'd55;  cin = 1'b0; #5 $display("  200 +  55 + 0  -> cout=%b s=%3d", cout, s);
        a = 8'd255; b = 8'd1;   cin = 1'b0; #5 $display("  255 +   1 + 0  -> cout=%b s=%3d", cout, s);
        a = 8'd127; b = 8'd128; cin = 1'b1; #5 $display("  127 + 128 + 1  -> cout=%b s=%3d", cout, s);
        $display("  131072 kombinacija provereno, %0d gresaka", errors);
        $display("");
        $finish;
    end

endmodule
