module ps2 (
    input clk,
    input rst_n,
    input ps2_clk,
    input ps2_data,
    output [15:0] code
);

    wire ps2_clk_deb;
    wire ps2_clk_fall;

    reg [3:0] cnt_next, cnt_reg;
    reg [10:0] frame_next, frame_reg;
    reg [15:0] code_next, code_reg;

    assign code = code_reg;

    debouncer debouncer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(ps2_clk),
        .out(ps2_clk_deb)
    );

    red red_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in(~ps2_clk_deb),
        .out(ps2_clk_fall)
    );

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            cnt_reg <= 4'd0;
            frame_reg <= 11'd0;
            code_reg <= 16'h0000;
        end
        else begin
            cnt_reg <= cnt_next;
            frame_reg <= frame_next;
            code_reg <= code_next;
        end
    end

    always @(*) begin
        cnt_next = cnt_reg;
        frame_next = frame_reg;
        code_next = code_reg;
        if (ps2_clk_fall) begin
            if (cnt_reg == 4'd0) begin
                if (!ps2_data) begin
                    frame_next = {ps2_data, frame_reg[10:1]};
                    cnt_next = 4'd1;
                end
            end
            else begin
                frame_next = {ps2_data, frame_reg[10:1]};
                if (cnt_reg == 4'd10) begin
                    cnt_next = 4'd0;
                    if (!frame_next[0] && frame_next[10] && (^frame_next[9:1]))
                        code_next = {code_reg[7:0], frame_next[8:1]};
                end
                else begin
                    cnt_next = cnt_reg + 1'b1;
                end
            end
        end
    end

endmodule
