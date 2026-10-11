# picoComputer Processor

A 16-bit FSM-based processor implemented in Verilog and synthesized for an Altera FPGA board,
with PS/2 keyboard input, VGA output, seven-segment display drivers, and a UVM testbench
with code coverage analysis.

Developed for the *Computer VLSI Systems* course at the School of Electrical Engineering,
University of Belgrade.

## Architecture

The processor follows the picoComputer architecture: a 64-word memory of 16-bit words, split
into a fixed zone (addresses 0–7, acting as general purpose registers) and a free zone holding
the program, data and a downward-growing stack.

| Register | Width | Purpose |
|---|---|---|
| `PC` | 6 | program counter, starts at address 8 |
| `SP` | 6 | stack pointer, starts at 63 (first free location) |
| `IR` | 32 | instruction register, holds both instruction words |
| `MAR` | 6 | memory address register |
| `MDR` | 16 | memory data register |
| `A` | 16 | accumulator |

The control unit is a single finite state machine. Because the memory has a registered output,
every read costs one wait state, and indirect addressing costs a second read — this shapes the
whole state machine.

## Instruction set

Each operand is 4 bits: the high bit selects addressing mode (`0` direct, `1` indirect) and the
low three bits give the address. The value `0000` means "operand unused".

| Opcode | Instruction | Operation | Words |
|---|---|---|:---:|
| `0000` | `MOV X, Y` | `mem[X] <- mem[Y]` | 1 |
| `0000` | `MOV` block | copy `n` elements from `Y` to `X` (third operand starts with 1) | 1 |
| `0001` | `ADD X, Y, Z` | `mem[X] <- mem[Y] + mem[Z]` | 1 |
| `0010` | `SUB X, Y, Z` | `mem[X] <- mem[Y] - mem[Z]` | 1 |
| `0011` | `MUL X, Y, Z` | `mem[X] <- mem[Y] * mem[Z]` | 1 |
| `0100` | `DIV X, Y, Z` | `mem[X] <- mem[Y] / mem[Z]` | 1 |
| `0101` | `BEQ X, Y` | branch to second word if `mem[X] == mem[Y]` | 2 |
| `0110` | `BGT X, Y` | branch to second word if `mem[X] > mem[Y]` | 2 |
| `0111` | `IN X` | `mem[X] <- input` (blocking) | 1 |
| `1000` | `OUT X` | output `<- mem[X]` | 1 |
| `1001` | `ADDC X, C, Z` | `mem[X] <- C + mem[Z]`, constant in second word | 2 |
| `1010` | `PUSH X` | `mem[SP] <- mem[X]`, then `SP - 1` | 1 |
| `1011` | `POP X` | `SP + 1`, then `mem[X] <- mem[SP]` | 1 |
| `1100` | `JSR addr` | push return address, jump to subroutine | 1 |
| `1110` | `RTS` | pop return address into `PC` | 1 |
| `1111` | `STOP X, Y, Z` | print non-zero operands, then halt | 1 |

Arithmetic instructions share a single ALU; the ALU opcode is derived as `opcode[2:0] - 1`.

## Peripherals

- **`ps2`** — PS/2 keyboard receiver. Filters the keyboard clock, detects falling edges, and
  decodes the 11-bit frame (start bit, 8 data bits LSB first, odd parity, stop bit). Frames
  resynchronize on the start bit, which also recovers from any loss of sync.
- **`scan_codes`** — translates key *release* sequences (`F0` + scan code) into digits, with a
  `status`/`control` handshake so the blocking `IN` instruction waits for real input.
- **`vga`** — VGA controller at 800x600, driven directly from the 50 MHz board clock
  (no divider needed, since that mode's pixel clock is exactly 50 MHz).
- **`color_codes`** — maps each digit of a two-digit number to a colour; the screen shows the
  tens digit on the left half and the units digit on the right.
- **`bcd`** / **`ssd`** — split `PC` and `SP` into decimal digits and drive the seven-segment
  displays.
- **`clk_div`** — slows the 50 MHz board clock to 1 Hz for the processor and memory.

## Adders

A separate set of modules implements the classic adder families, each with its own testbench:

| Testbench | Adder | Built from | Source files |
|---|---|---|---|
| `fa_tb` | Full Adder | basic cell | `full_adder.v` |
| `csum_tb` | Conditional Sum (1 bit) | standalone | `csum.v` |
| `rca_tb` | Ripple Carry (4 bit) | 4x full adder, chained | `full_adder.v`, `rca.v` |
| `cla_tb` | Carry Lookahead (4 bit) | 4x full adder + lookahead logic | `full_adder.v`, `cla.v` |
| `csav_tb` | Carry Save (3 operands) | 4x full adder, no carry chain | `full_adder.v`, `csav.v` |
| `csel_tb` | Carry Select (8 bit) | 3x RCA (each 4x full adder) | `full_adder.v`, `rca.v`, `csel.v` |

All adders are verified exhaustively: 512 combinations for the 4-bit adders, 4096 for the carry
save adder, and 131072 for the 8-bit carry select adder — all passing with zero mismatches.

## Verification

`src/simulation/top.sv` is a UVM testbench for the register module, built from the standard
components: sequence item, sequence, driver, monitor, agent, scoreboard, environment and test.
The scoreboard holds an independent reference model of the register and compares it against the
design on every transaction.

The sequence item constrains the stimulus so all six register operations are hit evenly —
without that, the lowest-priority operation would almost never be exercised.

Running with coverage produces a code coverage report for `register.v`:

```
vlog -sv -coveropt 3 +cover +acc src/simulation/modules/register.v src/simulation/top.sv
vsim -coverage work.top -c -do "coverage save -onexit -directive -codeAll register_cov.ucdb; run -all; quit -f"
vcover report -html register_cov.ucdb
```

Result: statement and branch coverage of 100%, toggle coverage 99.3%, with zero errors across
200 transactions. Requires Questa (ModelSim Starter Edition lacks the UVM and coverage licences).

## Building

From the `tooling` directory:

```
make simul_all    # compile and run the simulation
make synth_all    # analysis, synthesis, place and route
make synth_pgm    # program the board over JTAG
```

The target board is selected in `tooling/makefile`:

| Board | `SYNTH_TOP_LEVEL_MODULE` | `SYNTH_DEVICE_FAMILY` | `SYNTH_DEVICE_PART` |
|---|---|---|---|
| DE0-CV | `DE0_CV_TOP` | `CycloneV` | `5CEBA4F23C7` |
| DE0 | `DE0_TOP` | `CycloneIII` | `EP3C16F484C6` |

Tool paths (`SIMUL_TOOL_EXE_DIR_PATH`, `SYNTH_TOOL_EXE_DIR_PATH`) also live in the makefile and
need to match the local Quartus install.

To simulate one of the adders instead of the processor, point
`tooling/config/list-src-files-simul.lst` at that adder's source files and set
`SIMUL_TOP_LEVEL_MODULE` to its testbench name.

## Synthesis results

| Board | Device | Logic | Registers | Memory |
|---|---|---|---|---|
| DE0-CV | `5CEBA4F23C7` | 529 ALMs (3%) | 315 | 1024 bits |
| DE0 | `EP3C16F484C6` | 1218 LEs (8%) | 297 | 1024 bits |

Memory is inferred as a block RAM and initialized from `tooling/mem_init.mif`.

## Board controls

| Control | Function |
|---|---|
| `SW9` | asynchronous reset (down = held in reset) |
| `LED[4:0]` | standard output, the last value printed by `OUT` |
| `LED[5]` | lit while the processor is waiting for keyboard input |
| `HEX` displays | `PC` and `SP` |

## Repository layout

```
src/simulation/          testbenches and simulation-only modules
  modules/               alu, register, and the adder family
  top.v                  first-stage simulation testbench
  top.sv                 UVM testbench with code coverage
  *_tb.v                 one testbench per adder
src/synthesis/           synthesizable design
  modules/               cpu, alu, register, memory, peripherals, top level
  DE0_TOP.v              board wrapper for DE0 (Cyclone III)
  DE0_CV_TOP.v           board wrapper for DE0-CV (Cyclone V)
tooling/                 makefile, source lists, board constraints, memory image
```

## Third-party code

`src/synthesis/DE0_TOP.v`, `src/synthesis/DE0_CV_TOP.v` and the board constraint files under
`tooling/config/boards/` are Terasic board templates, included under their original copyright
and licence notices. `src/synthesis/modules/memory.v` was provided with the course assignment.
The course template also shipped a prebuilt xPack GNU Make distribution under `tooling/xpack/`;
it is excluded from this repository, so building requires `make` to be available locally.
