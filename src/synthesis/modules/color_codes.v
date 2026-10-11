module color_codes (
    input [5:0] num,
    output [23:0] code
);

    wire [3:0] ones;
    wire [3:0] tens;

    bcd bcd_inst (
        .in(num),
        .ones(ones),
        .tens(tens)
    );

    function [11:0] color;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: color = 12'h000;
                4'd1: color = 12'hF00;
                4'd2: color = 12'hF80;
                4'd3: color = 12'hFF0;
                4'd4: color = 12'h0F0;
                4'd5: color = 12'h0FF;
                4'd6: color = 12'h08F;
                4'd7: color = 12'h00F;
                4'd8: color = 12'hF0F;
                4'd9: color = 12'hFFF;
                default: color = 12'h000;
            endcase
        end
    endfunction

    assign code = {color(tens), color(ones)};

endmodule
