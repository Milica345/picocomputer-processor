module vga (
    input clk,
    input rst_n,
    input [23:0] code,
    output hsync,
    output vsync,
    output [3:0] red,
    output [3:0] green,
    output [3:0] blue
);

    localparam H_VISIBLE = 800;
    localparam H_FRONT   = 56;
    localparam H_SYNC    = 120;
    localparam H_BACK    = 64;
    localparam H_TOTAL   = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;

    localparam V_VISIBLE = 600;
    localparam V_FRONT   = 37;
    localparam V_SYNC    = 6;
    localparam V_BACK    = 23;
    localparam V_TOTAL   = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;

    localparam H_SYNC_ON  = H_VISIBLE + H_FRONT;
    localparam H_SYNC_OFF = H_SYNC_ON + H_SYNC;
    localparam V_SYNC_ON  = V_VISIBLE + V_FRONT;
    localparam V_SYNC_OFF = V_SYNC_ON + V_SYNC;

    reg [10:0] h_next, h_reg;
    reg [9:0] v_next, v_reg;
    reg [11:0] pixel;

    wire visible = (h_reg < H_VISIBLE) && (v_reg < V_VISIBLE);

    assign hsync = (h_reg >= H_SYNC_ON) && (h_reg < H_SYNC_OFF);
    assign vsync = (v_reg >= V_SYNC_ON) && (v_reg < V_SYNC_OFF);

    assign red = pixel[11:8];
    assign green = pixel[7:4];
    assign blue = pixel[3:0];

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            h_reg <= 11'd0;
            v_reg <= 10'd0;
        end
        else begin
            h_reg <= h_next;
            v_reg <= v_next;
        end
    end

    always @(*) begin
        h_next = h_reg + 1'b1;
        v_next = v_reg;
        if (h_reg == H_TOTAL - 1) begin
            h_next = 11'd0;
            if (v_reg == V_TOTAL - 1)
                v_next = 10'd0;
            else
                v_next = v_reg + 1'b1;
        end
    end

    always @(*) begin
        if (!visible)
            pixel = 12'h000;
        else if (h_reg < H_VISIBLE / 2)
            pixel = code[23:12];
        else
            pixel = code[11:0];
    end

endmodule
