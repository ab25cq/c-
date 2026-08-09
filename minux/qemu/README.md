# minux on QEMU Raspberry Pi Zero

This target uses QEMU's `raspi0` machine instead of the toy hosted emulator.

Required tools:

- `qemu-system-arm`
- `arm-none-eabi-gcc`
- `arm-none-eabi-objcopy`
- `arm-none-eabi-size`

Build only:

```sh
cpm build
```

Run on QEMU:

```sh
cpm run
```

The current root `src/kernel.c-` is a freestanding C- program compiled with `c- -bare
-no-heap`, linked at `0x8000`, and booted by QEMU's Raspberry Pi Zero machine.
It writes to the PL011 UART at `0x20201000`, which is connected to stdio by
`-serial stdio`.
