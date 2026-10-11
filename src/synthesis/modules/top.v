module top #(
    parameter DIVISOR = 50_000_000,
    parameter FILE_NAME = "mem_init.mif",
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input [1:0] kbd,
    input [2:0] btn,
    input [9:0] sw,
    output [13:0] mnt,
    output [9:0] led,
    output [27:0] hex
);

    wire rst_n;
    wire clk_cpu;

    wire we;
    wire [ADDR_WIDTH - 1:0] addr;
    wire [DATA_WIDTH - 1:0] data;
    wire [DATA_WIDTH - 1:0] mem;
    wire [DATA_WIDTH - 1:0] out;
    wire [ADDR_WIDTH - 1:0] pc;
    wire [ADDR_WIDTH - 1:0] sp;

    wire status;
    wire control;
    wire [15:0] scan_code;
    wire [3:0] num;

    wire [23:0] color_code;
    wire hsync;
    wire vsync;
    wire [3:0] red;
    wire [3:0] green;
    wire [3:0] blue;

    wire [3:0] pc_ones, pc_tens;
    wire [3:0] sp_ones, sp_tens;
    wire [6:0] hex_pc_ones, hex_pc_tens;
    wire [6:0] hex_sp_ones, hex_sp_tens;

    assign rst_n = sw[9];
    assign mnt = {hsync, vsync, red, green, blue};
    assign led = {4'b0000, status, out[4:0]};
    assign hex = {hex_sp_tens, hex_sp_ones, hex_pc_tens, hex_pc_ones};

    clk_div #(
        .DIVISOR(DIVISOR)
    ) clk_div_inst (
        .clk(clk),
        .rst_n(rst_n),
        .out(clk_cpu)
    );

    memory #(
        .FILE_NAME(FILE_NAME),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memory_inst (
        .clk(clk_cpu),
        .we(we),
        .addr(addr),
        .data(data),
        .out(mem)
    );

    cpu #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) cpu_inst (
        .clk(clk_cpu),
        .rst_n(rst_n),
        .mem(mem),
        .in({{(DATA_WIDTH - 4){1'b0}}, num}),
        .control(control),
        .status(status),
        .we(we),
        .addr(addr),
        .data(data),
        .out(out),
        .pc(pc),
        .sp(sp)
    );

    ps2 ps2_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ps2_clk(kbd[0]),
        .ps2_data(kbd[1]),
        .code(scan_code)
    );

    scan_codes scan_codes_inst (
        .clk(clk),
        .rst_n(rst_n),
        .code(scan_code),
        .status(status),
        .control(control),
        .num(num)
    );

    color_codes color_codes_inst (
        .num(out[5:0]),
        .code(color_code)
    );

    vga vga_inst (
        .clk(clk),
        .rst_n(rst_n),
        .code(color_code),
        .hsync(hsync),
        .vsync(vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    bcd bcd_pc_inst (
        .in(pc),
        .ones(pc_ones),
        .tens(pc_tens)
    );

    bcd bcd_sp_inst (
        .in(sp),
        .ones(sp_ones),
        .tens(sp_tens)
    );

    ssd ssd_pc_ones_inst (
        .in(pc_ones),
        .out(hex_pc_ones)
    );

    ssd ssd_pc_tens_inst (
        .in(pc_tens),
        .out(hex_pc_tens)
    );

    ssd ssd_sp_ones_inst (
        .in(sp_ones),
        .out(hex_sp_ones)
    );

    ssd ssd_sp_tens_inst (
        .in(sp_tens),
        .out(hex_sp_tens)
    );

endmodule
