module csum_tb;

    reg a, b;
    wire s0, c0, s1, c1;
    integer i;

    csum dut (.a(a), .b(b), .s0(s0), .c0(c0), .s1(s1), .c1(c1));

    initial begin
        $display("");
        $display("=== Conditional Sum Adder (jednorazredni) ===");
        $display("  a  b | ulazni prenos 0: c0 s0 | ulazni prenos 1: c1 s1");
        for (i = 0; i < 4; i = i + 1) begin
            {a, b} = i[1:0];
            #5;
            $display("  %b  %b |                  %b  %b |                  %b  %b",
                     a, b, c0, s0, c1, s1);
        end
        $display("");
        $finish;
    end

endmodule
