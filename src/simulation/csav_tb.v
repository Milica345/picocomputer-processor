module csav_tb;

    reg [3:0] a, b, c;
    wire [3:0] s;
    wire [4:0] cout;
    integer i, errors;
    reg [5:0] expected;

    wire [5:0] total = {2'b00, s} + {1'b0, cout};

    csav dut (.a(a), .b(b), .c(c), .s(s), .cout(cout));

    initial begin
        $display("");
        $display("=== Carry Save Adder (4 bita, tri operanda, od full addera) ===");
        errors = 0;
        for (i = 0; i < 4096; i = i + 1) begin
            {a, b, c} = i[11:0];
            #5;
            expected = {2'b00, a} + {2'b00, b} + {2'b00, c};
            if (total !== expected) begin
                errors = errors + 1;
                $display("  GRESKA: %0d + %0d + %0d -> s=%0d cout=%0d", a, b, c, s, cout);
            end
        end
        a = 4'd5;  b = 4'd6;  c = 4'd7;  #5
            $display("   5 +  6 +  7 = %2d  ->  s=%2d + cout=%2d = %2d",
                     {2'b00,a}+{2'b00,b}+{2'b00,c}, s, cout, total);
        a = 4'd15; b = 4'd15; c = 4'd15; #5
            $display("  15 + 15 + 15 = %2d  ->  s=%2d + cout=%2d = %2d",
                     {2'b00,a}+{2'b00,b}+{2'b00,c}, s, cout, total);
        $display("  4096 kombinacija provereno, %0d gresaka", errors);
        $display("");
        $finish;
    end

endmodule
