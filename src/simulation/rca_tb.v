module rca_tb;

    reg [3:0] a, b;
    reg cin;
    wire [3:0] s;
    wire cout;
    integer i, errors;
    reg [4:0] expected;

    rca dut (.a(a), .b(b), .cin(cin), .s(s), .cout(cout));

    initial begin
        $display("");
        $display("=== Ripple Carry Adder (4 bita, od full addera) ===");
        errors = 0;
        for (i = 0; i < 512; i = i + 1) begin
            {a, b, cin} = i[8:0];
            #5;
            expected = a + b + cin;
            if ({cout, s} !== expected) begin
                errors = errors + 1;
                $display("  GRESKA: %0d + %0d + %0d -> cout=%b s=%0d", a, b, cin, cout, s);
            end
        end
        a = 4'd7;  b = 4'd8; cin = 1'b0; #5 $display("   7 +  8 + 0  -> cout=%b s=%2d", cout, s);
        a = 4'd15; b = 4'd1; cin = 1'b0; #5 $display("  15 +  1 + 0  -> cout=%b s=%2d", cout, s);
        a = 4'd9;  b = 4'd9; cin = 1'b1; #5 $display("   9 +  9 + 1  -> cout=%b s=%2d", cout, s);
        $display("  512 kombinacija provereno, %0d gresaka", errors);
        $display("");
        $finish;
    end

endmodule
