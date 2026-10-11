module scan_codes (
    input clk,
    input rst_n,
    input [15:0] code,
    input status,
    output control,
    output [3:0] num
);

    localparam BREAK = 8'hF0;

    reg control_next, control_reg;
    reg [3:0] num_next, num_reg;
    reg [15:0] prev_next, prev_reg;

    reg [3:0] digit;
    reg digit_valid;

    assign control = control_reg;
    assign num = num_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= 1'b0;
            num_reg <= 4'd0;
            prev_reg <= 16'h0000;
        end
        else begin
            control_reg <= control_next;
            num_reg <= num_next;
            prev_reg <= prev_next;
        end
    end

    always @(*) begin
        digit_valid = 1'b1;
        case (code[7:0])
            8'h45, 8'h70: digit = 4'd0;
            8'h16, 8'h69: digit = 4'd1;
            8'h1E, 8'h72: digit = 4'd2;
            8'h26, 8'h7A: digit = 4'd3;
            8'h25, 8'h6B: digit = 4'd4;
            8'h2E, 8'h73: digit = 4'd5;
            8'h36, 8'h74: digit = 4'd6;
            8'h3D, 8'h6C: digit = 4'd7;
            8'h3E, 8'h75: digit = 4'd8;
            8'h46, 8'h7D: digit = 4'd9;
            default: begin
                digit = 4'd0;
                digit_valid = 1'b0;
            end
        endcase
    end

    always @(*) begin
        control_next = control_reg;
        num_next = num_reg;
        prev_next = code;
        if (!status) begin
            control_next = 1'b0;
        end
        else if (code != prev_reg && code[15:8] == BREAK && digit_valid) begin
            num_next = digit;
            control_next = 1'b1;
        end
    end

endmodule
