module cpu #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH - 1:0] mem,
    input [DATA_WIDTH - 1:0] in,
    input control,
    output status,
    output we,
    output [ADDR_WIDTH - 1:0] addr,
    output [DATA_WIDTH - 1:0] data,
    output [DATA_WIDTH - 1:0] out,
    output [ADDR_WIDTH - 1:0] pc,
    output [ADDR_WIDTH - 1:0] sp
);

    localparam OP_MOV  = 4'b0000;
    localparam OP_ADD  = 4'b0001;
    localparam OP_SUB  = 4'b0010;
    localparam OP_MUL  = 4'b0011;
    localparam OP_DIV  = 4'b0100;
    localparam OP_IN   = 4'b0111;
    localparam OP_OUT  = 4'b1000;
    localparam OP_STOP = 4'b1111;
    localparam OP_ADDC = 4'b1001;
    localparam OP_BGT  = 4'b0110;
    localparam OP_PUSH = 4'b1010;
    localparam OP_POP  = 4'b1011;
    localparam OP_BEQ  = 4'b0101;
    localparam OP_JSR  = 4'b1100;
    localparam OP_RTS  = 4'b1110;

    localparam INIT      = 5'd0;

    localparam FETCH_MAR = 5'd1;
    localparam FETCH_MEM = 5'd2;
    localparam FETCH_IR  = 5'd3;
    localparam DECODE    = 5'd4;

    localparam SRC_MAR   = 5'd5;
    localparam SRC_MEM   = 5'd6;
    localparam SRC_IND   = 5'd7;
    localparam SRC_MEM2  = 5'd8;
    localparam SRC_LOAD  = 5'd9;

    localparam OPR_MAR   = 5'd10;
    localparam OPR_MEM   = 5'd11;
    localparam OPR_IND   = 5'd12;
    localparam OPR_MEM2  = 5'd13;
    localparam OPR_LOAD  = 5'd14;

    localparam IN_WAIT   = 5'd26;

    localparam FETCH2_MAR = 6'd27;
    localparam FETCH2_MEM = 6'd28;
    localparam FETCH2_IR  = 6'd29;

    localparam DST_MAR   = 5'd15;
    localparam DST_MEM   = 5'd16;
    localparam DST_IND   = 5'd17;
    localparam DST_WRITE = 5'd18;

    localparam PRN_MAR   = 5'd19;
    localparam PRN_MEM   = 5'd20;
    localparam PRN_IND   = 5'd21;
    localparam PRN_MEM2  = 5'd22;
    localparam PRN_LOAD  = 5'd23;
    localparam PRN_NEXT  = 5'd24;

    localparam HALT      = 5'd25;

    localparam BGT_MAR      = 6'd30;
    localparam BGT_MEM      = 6'd31;
    localparam BGT_IND      = 6'd32;
    localparam BGT_MEM2     = 6'd33;
    localparam BGT_LOAD     = 6'd34;
    localparam BGT_ADDR_MAR = 6'd35;
    localparam BGT_ADDR_MEM = 6'd36;
    localparam BGT_ADDR_IR  = 6'd37;
    localparam BGT_TEST     = 6'd38;

    localparam PUSH_MAR   = 6'd39;
    localparam PUSH_MEM   = 6'd40;
    localparam PUSH_IND   = 6'd41;
    localparam PUSH_MEM2  = 6'd42;
    localparam PUSH_LOAD  = 6'd43;
    localparam PUSH_WRITE = 6'd44;

    localparam POP_INC   = 6'd45;
    localparam POP_MAR   = 6'd46;
    localparam POP_MEM   = 6'd47;
    localparam POP_LOAD  = 6'd48;
    localparam POP_DMEM  = 6'd49;
    localparam POP_IND   = 6'd50;
    localparam POP_WRITE = 6'd51;

    localparam JSR_MAR   = 6'd52;
    localparam JSR_WRITE = 6'd53;

    localparam RTS_INC   = 6'd54;
    localparam RTS_MAR   = 6'd55;
    localparam RTS_MEM   = 6'd56;
    localparam RTS_LOAD  = 6'd57;

    localparam MOVN_SMAR  = 7'd58;
    localparam MOVN_SMEM  = 7'd59;
    localparam MOVN_SIND  = 7'd60;
    localparam MOVN_DMAR  = 7'd61;
    localparam MOVN_DMEM  = 7'd62;
    localparam MOVN_DIND  = 7'd63;
    localparam MOVN_RMAR  = 7'd64;
    localparam MOVN_RMEM  = 7'd65;
    localparam MOVN_RLOAD = 7'd66;
    localparam MOVN_WRITE = 7'd67;

    reg [6:0] state_next, state_reg;

    reg [1:0] prn_next, prn_reg;

    reg bgt_next, bgt_reg;

    reg [ADDR_WIDTH - 1:0] msrc_next, msrc_reg;
    reg [ADDR_WIDTH - 1:0] mdst_next, mdst_reg;
    reg [3:0] mcnt_next, mcnt_reg;

    reg pc_ld, pc_inc;
    reg [ADDR_WIDTH - 1:0] pc_in;
    reg sp_ld;
    reg sp_dec;
    reg sp_inc;
    reg [ADDR_WIDTH - 1:0] sp_in;
    reg ir_ld;
    reg [2 * DATA_WIDTH - 1:0] ir_in;
    reg mar_ld;
    reg [ADDR_WIDTH - 1:0] mar_in;
    reg mdr_ld;
    reg [DATA_WIDTH - 1:0] mdr_in;
    reg acc_ld;
    reg [DATA_WIDTH - 1:0] acc_in;
    reg out_ld;
    reg [DATA_WIDTH - 1:0] out_in;

    wire [2 * DATA_WIDTH - 1:0] ir_out;
    wire [ADDR_WIDTH - 1:0] mar_out;
    wire [DATA_WIDTH - 1:0] mdr_out;
    wire [DATA_WIDTH - 1:0] acc_out;
    wire [DATA_WIDTH - 1:0] alu_f;

    wire [DATA_WIDTH - 1:0] ir_word = ir_out[2 * DATA_WIDTH - 1:DATA_WIDTH];
    wire [3:0] ir_op = ir_word[DATA_WIDTH - 1:DATA_WIDTH - 4];
    wire [3:0] ir_x = ir_word[DATA_WIDTH - 5:DATA_WIDTH - 8];
    wire [3:0] ir_y = ir_word[DATA_WIDTH - 9:DATA_WIDTH - 12];
    wire [3:0] ir_z = ir_word[DATA_WIDTH - 13:DATA_WIDTH - 16];

    wire [3:0] prn_op = (prn_reg == 2'd0) ? ir_x : (prn_reg == 2'd1) ? ir_y : ir_z;

    wire [3:0] bgt_op = bgt_reg ? ir_y : ir_x;

    assign status = (state_reg == IN_WAIT);
    assign we = (state_reg == DST_WRITE) || (state_reg == PUSH_WRITE) ||
                (state_reg == POP_WRITE) || (state_reg == JSR_WRITE) ||
                (state_reg == MOVN_WRITE);
    assign addr = mar_out;
    assign data = mdr_out;

    register #(.DATA_WIDTH(ADDR_WIDTH)) pc_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(pc_ld), .in(pc_in),
        .inc(pc_inc), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(pc)
    );

    register #(.DATA_WIDTH(ADDR_WIDTH)) sp_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(sp_ld), .in(sp_in),
        .inc(sp_inc), .dec(sp_dec), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(sp)
    );

    register #(.DATA_WIDTH(2 * DATA_WIDTH)) ir_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(ir_ld), .in(ir_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(ir_out)
    );

    register #(.DATA_WIDTH(ADDR_WIDTH)) mar_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(mar_ld), .in(mar_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mar_out)
    );

    register #(.DATA_WIDTH(DATA_WIDTH)) mdr_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(mdr_ld), .in(mdr_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(mdr_out)
    );

    register #(.DATA_WIDTH(DATA_WIDTH)) acc_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(acc_ld), .in(acc_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(acc_out)
    );

    register #(.DATA_WIDTH(DATA_WIDTH)) out_inst (
        .clk(clk), .rst_n(rst_n), .cl(1'b0), .ld(out_ld), .in(out_in),
        .inc(1'b0), .dec(1'b0), .sr(1'b0), .ir(1'b0), .sl(1'b0), .il(1'b0),
        .out(out)
    );

    alu #(.DATA_WIDTH(DATA_WIDTH)) alu_inst (
        .oc(ir_op[2:0] - 3'b001),
        .a(acc_out),
        .b(mdr_out),
        .f(alu_f)
    );

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= INIT;
            prn_reg <= 2'd0;
            bgt_reg <= 1'b0;
            msrc_reg <= {ADDR_WIDTH{1'b0}};
            mdst_reg <= {ADDR_WIDTH{1'b0}};
            mcnt_reg <= 4'd0;
        end
        else begin
            state_reg <= state_next;
            prn_reg <= prn_next;
            bgt_reg <= bgt_next;
            msrc_reg <= msrc_next;
            mdst_reg <= mdst_next;
            mcnt_reg <= mcnt_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        prn_next = prn_reg;
        bgt_next = bgt_reg;
        msrc_next = msrc_reg;
        mdst_next = mdst_reg;
        mcnt_next = mcnt_reg;
        pc_ld = 1'b0;
        pc_inc = 1'b0;
        pc_in = {ADDR_WIDTH{1'b0}};
        sp_ld = 1'b0;
        sp_dec = 1'b0;
        sp_inc = 1'b0;
        sp_in = {ADDR_WIDTH{1'b0}};
        ir_ld = 1'b0;
        ir_in = {(2 * DATA_WIDTH){1'b0}};
        mar_ld = 1'b0;
        mar_in = {ADDR_WIDTH{1'b0}};
        mdr_ld = 1'b0;
        mdr_in = {DATA_WIDTH{1'b0}};
        acc_ld = 1'b0;
        acc_in = {DATA_WIDTH{1'b0}};
        out_ld = 1'b0;
        out_in = {DATA_WIDTH{1'b0}};

        case (state_reg)
            INIT: begin
                pc_ld = 1'b1;
                pc_in = 8;
                sp_ld = 1'b1;
                sp_in = {ADDR_WIDTH{1'b1}};
                state_next = FETCH_MAR;
            end

            FETCH_MAR: begin
                mar_ld = 1'b1;
                mar_in = pc;
                state_next = FETCH_MEM;
            end

            FETCH_MEM: begin
                state_next = FETCH_IR;
            end

            FETCH_IR: begin
                ir_ld = 1'b1;
                ir_in = {mem, {DATA_WIDTH{1'b0}}};
                pc_inc = 1'b1;
                prn_next = 2'd0;
                state_next = DECODE;
            end

            DECODE: begin
                case (ir_op)
                    OP_ADD, OP_SUB, OP_MUL, OP_DIV: state_next = SRC_MAR;
                    OP_MOV: state_next = ir_z[3] ? MOVN_SMAR : SRC_MAR;
                    OP_IN: state_next = IN_WAIT;
                    OP_ADDC: state_next = FETCH2_MAR;
                    OP_BGT, OP_BEQ: begin
                        bgt_next = 1'b0;
                        state_next = BGT_MAR;
                    end
                    OP_PUSH: state_next = PUSH_MAR;
                    OP_POP: state_next = POP_INC;
                    OP_JSR: state_next = JSR_MAR;
                    OP_RTS: state_next = RTS_INC;
                    OP_OUT, OP_STOP: state_next = PRN_MAR;
                    default: state_next = FETCH_MAR;
                endcase
            end

            IN_WAIT: begin
                if (control)
                    state_next = DST_MAR;
            end

            FETCH2_MAR: begin
                mar_ld = 1'b1;
                mar_in = pc;
                state_next = FETCH2_MEM;
            end

            FETCH2_MEM: begin
                state_next = FETCH2_IR;
            end

            FETCH2_IR: begin
                ir_ld = 1'b1;
                ir_in = {ir_word, mem};
                acc_ld = 1'b1;
                acc_in = mem;
                pc_inc = 1'b1;
                state_next = OPR_MAR;
            end

            SRC_MAR: begin
                mar_ld = 1'b1;
                mar_in = ir_y[2:0];
                state_next = SRC_MEM;
            end

            SRC_MEM: begin
                state_next = ir_y[3] ? SRC_IND : SRC_LOAD;
            end

            SRC_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = SRC_MEM2;
            end

            SRC_MEM2: begin
                state_next = SRC_LOAD;
            end

            SRC_LOAD: begin
                acc_ld = 1'b1;
                acc_in = mem;
                state_next = (ir_op == OP_MOV) ? DST_MAR : OPR_MAR;
            end

            OPR_MAR: begin
                mar_ld = 1'b1;
                mar_in = ir_z[2:0];
                state_next = OPR_MEM;
            end

            OPR_MEM: begin
                state_next = ir_z[3] ? OPR_IND : OPR_LOAD;
            end

            OPR_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = OPR_MEM2;
            end

            OPR_MEM2: begin
                state_next = OPR_LOAD;
            end

            OPR_LOAD: begin
                mdr_ld = 1'b1;
                mdr_in = mem;
                state_next = DST_MAR;
            end

            DST_MAR: begin
                mar_ld = 1'b1;
                mar_in = ir_x[2:0];
                mdr_ld = 1'b1;
                if (ir_op == OP_IN)
                    mdr_in = in;
                else if (ir_op == OP_MOV)
                    mdr_in = acc_out;
                else
                    mdr_in = alu_f;
                state_next = ir_x[3] ? DST_MEM : DST_WRITE;
            end

            DST_MEM: begin
                state_next = DST_IND;
            end

            DST_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = DST_WRITE;
            end

            DST_WRITE: begin
                state_next = FETCH_MAR;
            end

            PRN_MAR: begin
                if (prn_op == 4'b0000) begin
                    state_next = PRN_NEXT;
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = prn_op[2:0];
                    state_next = PRN_MEM;
                end
            end

            PRN_MEM: begin
                state_next = prn_op[3] ? PRN_IND : PRN_LOAD;
            end

            PRN_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = PRN_MEM2;
            end

            PRN_MEM2: begin
                state_next = PRN_LOAD;
            end

            PRN_LOAD: begin
                out_ld = 1'b1;
                out_in = mem;
                state_next = PRN_NEXT;
            end

            PRN_NEXT: begin
                if (ir_op == OP_OUT)
                    state_next = FETCH_MAR;
                else if (prn_reg == 2'd2)
                    state_next = HALT;
                else begin
                    prn_next = prn_reg + 2'd1;
                    state_next = PRN_MAR;
                end
            end

            BGT_MAR: begin
                if (bgt_op == 4'b0000) begin
                    if (bgt_reg) begin
                        mdr_ld = 1'b1;
                        mdr_in = {DATA_WIDTH{1'b0}};
                        state_next = BGT_ADDR_MAR;
                    end
                    else begin
                        acc_ld = 1'b1;
                        acc_in = {DATA_WIDTH{1'b0}};
                        bgt_next = 1'b1;
                        state_next = BGT_MAR;
                    end
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = bgt_op[2:0];
                    state_next = BGT_MEM;
                end
            end

            BGT_MEM: begin
                state_next = bgt_op[3] ? BGT_IND : BGT_LOAD;
            end

            BGT_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = BGT_MEM2;
            end

            BGT_MEM2: begin
                state_next = BGT_LOAD;
            end

            BGT_LOAD: begin
                if (bgt_reg) begin
                    mdr_ld = 1'b1;
                    mdr_in = mem;
                    state_next = BGT_ADDR_MAR;
                end
                else begin
                    acc_ld = 1'b1;
                    acc_in = mem;
                    bgt_next = 1'b1;
                    state_next = BGT_MAR;
                end
            end

            BGT_ADDR_MAR: begin
                mar_ld = 1'b1;
                mar_in = pc;
                state_next = BGT_ADDR_MEM;
            end

            BGT_ADDR_MEM: begin
                state_next = BGT_ADDR_IR;
            end

            BGT_ADDR_IR: begin
                ir_ld = 1'b1;
                ir_in = {ir_word, mem};
                pc_inc = 1'b1;
                state_next = BGT_TEST;
            end

            BGT_TEST: begin
                if ((ir_op == OP_BGT && acc_out > mdr_out) ||
                    (ir_op == OP_BEQ && acc_out == mdr_out)) begin
                    pc_ld = 1'b1;
                    pc_in = ir_out[ADDR_WIDTH - 1:0];
                end
                state_next = FETCH_MAR;
            end

            PUSH_MAR: begin
                mar_ld = 1'b1;
                mar_in = ir_x[2:0];
                state_next = PUSH_MEM;
            end

            PUSH_MEM: begin
                state_next = ir_x[3] ? PUSH_IND : PUSH_LOAD;
            end

            PUSH_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = PUSH_MEM2;
            end

            PUSH_MEM2: begin
                state_next = PUSH_LOAD;
            end

            PUSH_LOAD: begin
                mdr_ld = 1'b1;
                mdr_in = mem;
                mar_ld = 1'b1;
                mar_in = sp;
                state_next = PUSH_WRITE;
            end

            PUSH_WRITE: begin
                sp_dec = 1'b1;
                state_next = FETCH_MAR;
            end

            POP_INC: begin
                sp_inc = 1'b1;
                state_next = POP_MAR;
            end

            POP_MAR: begin
                mar_ld = 1'b1;
                mar_in = sp;
                state_next = POP_MEM;
            end

            POP_MEM: begin
                state_next = POP_LOAD;
            end

            POP_LOAD: begin
                mdr_ld = 1'b1;
                mdr_in = mem;
                mar_ld = 1'b1;
                mar_in = ir_x[2:0];
                state_next = ir_x[3] ? POP_DMEM : POP_WRITE;
            end

            POP_DMEM: begin
                state_next = POP_IND;
            end

            POP_IND: begin
                mar_ld = 1'b1;
                mar_in = mem[ADDR_WIDTH - 1:0];
                state_next = POP_WRITE;
            end

            POP_WRITE: begin
                state_next = FETCH_MAR;
            end

            JSR_MAR: begin
                mdr_ld = 1'b1;
                mdr_in = pc;
                mar_ld = 1'b1;
                mar_in = sp;
                state_next = JSR_WRITE;
            end

            JSR_WRITE: begin
                sp_dec = 1'b1;
                pc_ld = 1'b1;
                pc_in = ir_word[ADDR_WIDTH - 1:0];
                state_next = FETCH_MAR;
            end

            RTS_INC: begin
                sp_inc = 1'b1;
                state_next = RTS_MAR;
            end

            RTS_MAR: begin
                mar_ld = 1'b1;
                mar_in = sp;
                state_next = RTS_MEM;
            end

            RTS_MEM: begin
                state_next = RTS_LOAD;
            end

            RTS_LOAD: begin
                pc_ld = 1'b1;
                pc_in = mem[ADDR_WIDTH - 1:0];
                state_next = FETCH_MAR;
            end

            MOVN_SMAR: begin
                mcnt_next = {1'b0, ir_z[2:0]};
                if (ir_y[3]) begin
                    mar_ld = 1'b1;
                    mar_in = ir_y[2:0];
                    state_next = MOVN_SMEM;
                end
                else begin
                    msrc_next = ir_y[2:0];
                    state_next = MOVN_DMAR;
                end
            end

            MOVN_SMEM: begin
                state_next = MOVN_SIND;
            end

            MOVN_SIND: begin
                msrc_next = mem[ADDR_WIDTH - 1:0];
                state_next = MOVN_DMAR;
            end

            MOVN_DMAR: begin
                if (ir_x[3]) begin
                    mar_ld = 1'b1;
                    mar_in = ir_x[2:0];
                    state_next = MOVN_DMEM;
                end
                else begin
                    mdst_next = ir_x[2:0];
                    state_next = MOVN_RMAR;
                end
            end

            MOVN_DMEM: begin
                state_next = MOVN_DIND;
            end

            MOVN_DIND: begin
                mdst_next = mem[ADDR_WIDTH - 1:0];
                state_next = MOVN_RMAR;
            end

            MOVN_RMAR: begin
                if (mcnt_reg == 4'd0) begin
                    state_next = FETCH_MAR;
                end
                else begin
                    mar_ld = 1'b1;
                    mar_in = msrc_reg;
                    state_next = MOVN_RMEM;
                end
            end

            MOVN_RMEM: begin
                state_next = MOVN_RLOAD;
            end

            MOVN_RLOAD: begin
                mdr_ld = 1'b1;
                mdr_in = mem;
                mar_ld = 1'b1;
                mar_in = mdst_reg;
                state_next = MOVN_WRITE;
            end

            MOVN_WRITE: begin
                msrc_next = msrc_reg + 1'b1;
                mdst_next = mdst_reg + 1'b1;
                mcnt_next = mcnt_reg - 1'b1;
                state_next = MOVN_RMAR;
            end

            HALT: begin
                state_next = HALT;
            end

            default: begin
                state_next = INIT;
            end
        endcase
    end

endmodule
