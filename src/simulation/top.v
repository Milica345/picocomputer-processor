module top;
    reg [2:0] oc;
    reg [3:0] a, b;
    wire [3:0] f;

    reg clk, rst_n, cl, ld, inc, dec, sr, ir, sl, il;
    reg [3:0] in;
    wire [3:0] out;

    integer index;
     
    alu alu1( .oc(oc), .a(a), .b(b), .f(f));
    register reg1( .clk(clk), .rst_n(rst_n), .cl(cl), .ld(ld), .in(in), .inc(inc), .dec(dec), .sr(sr), .ir(ir), .sl(sl), .il(il), .out(out));

    initial begin
        clk = 1'b0;

        $monitor("Vreme: %0d; Opreracija: %3b; Ulaz A: %4b; Ulaz B: %4b; Izlaz: %4b", $time, oc, a, b, f);
        for(index = 0; index < 2**11; index = index + 1) begin
            {oc[2:0], a[3:0], b[3:0]} = index;
            #5;
        end

        $stop;

        rst_n = 1'b0;
        cl = 1'b0;
        ld = 1'b0;
        inc = 1'b0;
        dec = 1'b0;
        sr = 1'b0;
        ir = 1'b0;
        sl = 1'b0;
        il = 1'b0;
        in = 4'h0;

        #2 rst_n = 1'b1; 

        repeat (1000) begin
            #5;
            cl = $urandom % 2;
            ld = $urandom % 2;
            inc = $urandom % 2;
            dec = $urandom % 2;
            sr = $urandom % 2;
            ir = $urandom % 2;
            sl = $urandom % 2;
            il = $urandom % 2;
            in = $urandom_range(15);
        end
        #10 $finish;
    end

    always @(out)
        $strobe("Vreme: %0d; CL: %d; LD: %d; IN: %d; INC: %d; DEC: %d; SR: %d; IR: %d; SL: %d; IL: %d; OUT: %d", $time, cl, ld, in, inc, dec, sr, ir, sl, il, out);


    always #5 clk = ~clk;


endmodule