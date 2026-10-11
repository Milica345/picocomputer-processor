`include "uvm_macros.svh"
import uvm_pkg::*;

interface register_if (input bit clk);
    logic rst_n;
    logic cl;
    logic ld;
    logic [3:0] in;
    logic inc;
    logic dec;
    logic sr;
    logic ir;
    logic sl;
    logic il;
    logic [3:0] out;
endinterface

class register_item extends uvm_sequence_item;

    rand bit cl;
    rand bit ld;
    rand bit [3:0] in;
    rand bit inc;
    rand bit dec;
    rand bit sr;
    rand bit ir;
    rand bit sl;
    rand bit il;
    bit [3:0] out;

    rand bit [2:0] op;

    `uvm_object_utils_begin(register_item)
        `uvm_field_int(cl, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(ld, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(in, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(inc, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(dec, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(sr, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(ir, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(sl, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(il, UVM_DEFAULT | UVM_BIN)
        `uvm_field_int(out, UVM_NOPRINT)
    `uvm_object_utils_end

    constraint c_op {
        op inside {[0:7]};
    }

    constraint c_ctrl {
        if (op < 6) {
            cl  == (op == 0);
            ld  == (op == 1);
            inc == (op == 2);
            dec == (op == 3);
            sr  == (op == 4);
            sl  == (op == 5);
        }
    }

    function new(string name = "register_item");
        super.new(name);
    endfunction

    virtual function string my_print();
        return $sformatf(
            "cl = %1b ld = %1b in = %4b inc = %1b dec = %1b sr = %1b ir = %1b sl = %1b il = %1b out = %4b",
            cl, ld, in, inc, dec, sr, ir, sl, il, out
        );
    endfunction

endclass

class generator extends uvm_sequence;

    `uvm_object_utils(generator)

    function new(string name = "generator");
        super.new(name);
    endfunction

    int num = 200;

    virtual task body();
        for (int i = 0; i < num; i++) begin
            register_item item = register_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("Generator", "Randomizacija nije uspela.")
            `uvm_info("Generator", $sformatf("Item %0d/%0d created", i + 1, num), UVM_HIGH)
            finish_item(item);
        end
    endtask

endclass

class driver extends uvm_driver #(register_item);

    `uvm_component_utils(driver)

    function new(string name = "driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual register_if vif;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual register_if)::get(this, "", "register_vif", vif))
            `uvm_fatal("Driver", "No interface.")
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            register_item item;
            seq_item_port.get_next_item(item);
            `uvm_info("Driver", $sformatf("%s", item.my_print()), UVM_HIGH)
            vif.cl <= item.cl;
            vif.ld <= item.ld;
            vif.in <= item.in;
            vif.inc <= item.inc;
            vif.dec <= item.dec;
            vif.sr <= item.sr;
            vif.ir <= item.ir;
            vif.sl <= item.sl;
            vif.il <= item.il;
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask

endclass

class monitor extends uvm_monitor;

    `uvm_component_utils(monitor)

    function new(string name = "monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual register_if vif;
    uvm_analysis_port #(register_item) mon_analysis_port;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual register_if)::get(this, "", "register_vif", vif))
            `uvm_fatal("Monitor", "No interface.")
        mon_analysis_port = new("mon_analysis_port", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        @(posedge vif.clk);
        forever begin
            register_item item = register_item::type_id::create("item");
            @(posedge vif.clk);
            item.cl = vif.cl;
            item.ld = vif.ld;
            item.in = vif.in;
            item.inc = vif.inc;
            item.dec = vif.dec;
            item.sr = vif.sr;
            item.ir = vif.ir;
            item.sl = vif.sl;
            item.il = vif.il;
            item.out = vif.out;
            `uvm_info("Monitor", $sformatf("%s", item.my_print()), UVM_HIGH)
            mon_analysis_port.write(item);
        end
    endtask

endclass

class agent extends uvm_agent;

    `uvm_component_utils(agent)

    function new(string name = "agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    driver d0;
    monitor m0;
    uvm_sequencer #(register_item) s0;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        d0 = driver::type_id::create("d0", this);
        m0 = monitor::type_id::create("m0", this);
        s0 = uvm_sequencer #(register_item)::type_id::create("s0", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        d0.seq_item_port.connect(s0.seq_item_export);
    endfunction

endclass

class scoreboard extends uvm_scoreboard;

    `uvm_component_utils(scoreboard)

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    uvm_analysis_imp #(register_item, scoreboard) mon_analysis_imp;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_analysis_imp = new("mon_analysis_imp", this);
    endfunction

    bit [3:0] model = 4'h0;
    int unsigned pass_cnt = 0;
    int unsigned fail_cnt = 0;

    virtual function void write(register_item item);
        if (model == item.out) begin
            pass_cnt++;
            `uvm_info("Scoreboard", $sformatf("PASS! out = %4b", item.out), UVM_HIGH)
        end
        else begin
            fail_cnt++;
            `uvm_error("Scoreboard", $sformatf("FAIL! expected = %4b, got = %4b", model, item.out))
        end

        if (item.cl)
            model = 4'h0;
        else if (item.ld)
            model = item.in;
        else if (item.inc)
            model = model + 4'h1;
        else if (item.dec)
            model = model - 4'h1;
        else if (item.sr)
            model = {item.ir, model[3:1]};
        else if (item.sl)
            model = {model[2:0], item.il};
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("Scoreboard", $sformatf("Provereno %0d transakcija: %0d PASS, %0d FAIL",
                  pass_cnt + fail_cnt, pass_cnt, fail_cnt), UVM_NONE)
    endfunction

endclass

class env extends uvm_env;

    `uvm_component_utils(env)

    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    agent a0;
    scoreboard sb0;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a0 = agent::type_id::create("a0", this);
        sb0 = scoreboard::type_id::create("sb0", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a0.m0.mon_analysis_port.connect(sb0.mon_analysis_imp);
    endfunction

endclass

class test extends uvm_test;

    `uvm_component_utils(test)

    function new(string name = "test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual register_if vif;
    env e0;
    generator g0;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual register_if)::get(this, "", "register_vif", vif))
            `uvm_fatal("Test", "No interface.")
        e0 = env::type_id::create("e0", this);
        g0 = generator::type_id::create("g0");
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        vif.rst_n <= 1'b0;
        vif.cl <= 1'b0;
        vif.ld <= 1'b0;
        vif.in <= 4'h0;
        vif.inc <= 1'b0;
        vif.dec <= 1'b0;
        vif.sr <= 1'b0;
        vif.ir <= 1'b0;
        vif.sl <= 1'b0;
        vif.il <= 1'b0;
        #20 vif.rst_n <= 1'b1;
        g0.start(e0.a0.s0);
        #20;
        phase.drop_objection(this);
    endtask

endclass

module top;

    bit clk;

    register_if dut_if (
        .clk(clk)
    );

    register dut (
        .clk(clk),
        .rst_n(dut_if.rst_n),
        .cl(dut_if.cl),
        .ld(dut_if.ld),
        .in(dut_if.in),
        .inc(dut_if.inc),
        .dec(dut_if.dec),
        .sr(dut_if.sr),
        .ir(dut_if.ir),
        .sl(dut_if.sl),
        .il(dut_if.il),
        .out(dut_if.out)
    );

    initial begin
        clk = 1'b0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        uvm_config_db #(virtual register_if)::set(null, "*", "register_vif", dut_if);
        run_test("test");
    end

endmodule
