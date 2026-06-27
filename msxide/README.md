# msxide

Early MSX/Z80 emulator workbench written in c-.

This project currently provides:

- Z80 CPU core skeleton with broad base opcode coverage
- CB-prefixed bit/rotate/set/reset operations
- DD/FD-prefixed IX/IY addressing for common load/store, ALU, stack, jump, and indexed-CB operations
- ED-prefixed block copy support for `LDI`/`LDIR`/`LDD`/`LDDR`
- 64KB memory
- MSX-style ROM loader
- VDP port stubs
- curses display with a fullscreen MSX-BASIC-like blue text screen
- minimal built-in BASIC-like command handling for `PRINT`, `CLS`, line-numbered
  program storage, `RUN`, `LIST`, `NEW`, `END`, and `STOP`
- `--self-test` for small Z80 programs covering load/store, branch, CB, IX/IY, indexed-CB, and LDIR

ROMs are not included. Put legally obtained dumps here:

```text
roms/msx.rom       combined BIOS/BASIC ROM, loaded at 0000h
roms/basic.rom     optional BASIC ROM, loaded at 8000h
```

For a redistributable smoke-test ROM, build the clean-room mock BASIC ROM:

```sh
cc -std=c99 -Wall -Wextra tools/make_mock_basic_rom.c -o target/make_mock_basic_rom
target/make_mock_basic_rom
target/debug/msxide --rom-test
```

The generated `roms/msx.rom` prints a small `C- BASIC` banner through msxide's
debug console port. It is not Microsoft MSX-BASIC and does not contain any
dumped or reverse-engineered vendor ROM code.

Run:

```sh
cpm build
target/debug/msxide --self-test
target/debug/msxide --rom-test
target/debug/msxide --basic-test
target/debug/msxide
```

The main curses view is intentionally machine-like: the terminal is a blue text
screen showing ROM console output and typed BASIC-like input. Debugger-style
register and memory panes are hidden from the normal view.

Keys:

- `PRINT "HELLO"`: print text
- `CLS`: clear the screen
- `10 PRINT "HELLO"`: store a numbered program line
- `RUN`: run stored numbered lines in line-number order
- `LIST`: show stored numbered lines
- `NEW`: clear stored numbered lines
- Arrow keys: move the visible text cursor; right/down grow blank columns/lines
- `ESC`: quit

Full MSX-BASIC boot still needs more edge-case Z80 instructions, the remaining
ED instructions, and more accurate MSX hardware emulation: slots, VDP, PSG,
PPI/keyboard, timers, and interrupt timing.
