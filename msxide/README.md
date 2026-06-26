# msxide

Early MSX/Z80 emulator workbench written in c-.

This project currently provides:

- Z80 CPU core skeleton with broad base opcode coverage
- CB-prefixed bit/rotate/set/reset operations
- ED-prefixed block copy support for `LDI`/`LDIR`/`LDD`/`LDDR`
- 64KB memory
- MSX-style ROM loader
- VDP port stubs
- curses IDE with registers, disassembly, memory view, run/pause/step/reset
- `--self-test` for small Z80 programs covering load/store, branch, CB, and LDIR

ROMs are not included. Put legally obtained dumps here:

```text
roms/msx.rom       combined BIOS/BASIC ROM, loaded at 0000h
roms/basic.rom     optional BASIC ROM, loaded at 8000h
```

Run:

```sh
cpm build
target/debug/msxide --self-test
target/debug/msxide
```

Keys:

- `s`: step one instruction
- `r`: run
- `p`: pause
- `R`: reset
- `h`: help
- `q`: quit

Full MSX-BASIC boot still needs DD/FD indexed opcodes, the remaining ED
instructions, and more accurate MSX hardware emulation: slots, VDP, PSG,
PPI/keyboard, timers, and interrupt timing.
