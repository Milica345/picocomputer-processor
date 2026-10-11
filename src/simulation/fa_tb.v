module fa_tb;

    reg a, b, cin;
    wire s, cout;
    integer i;

    full_adder dut (.a(a), .b(b), .cin(cin), .s(s), .cout(cout));

    initial begin
        $display("");
        $display("=== Full Adder ===");
        $display("  a  b  cin | cout  s");
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #5;
            $display("  %b  %b   %b  |  %b    %b", a, b, cin, cout, s);
        end
        $display("");
        $finish;
    end

endmodule
