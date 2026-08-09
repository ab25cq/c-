# minux

`minux` is the first safe C- operating-system experiment.

The current milestone is intentionally small: it builds a no-heap emulator with
an MMU page table, checked memory translation, trap state, a timer interrupt,
a tiny syscall ABI, and a toy Unix-like kernel program that runs on the
emulated machine.

The implementation uses C- safety features that matter for embedded and OS
work:

- `no_heap = true` in `C-.toml`
- `stack Machine` for a large fixed machine state
- `Span<T>` for bounds-checked RAM, register, code, and page-table access
- `FixedVec<T>` for process-table storage without heap allocation
- `unsafe` only around hosted I/O (`putchar`)

Implemented emulator/kernel pieces:

- page-based MMU translation
- trap records for syscalls, timer IRQs, page faults, and illegal instructions
- timer interrupt accounting
- `write(fd, addr, len)`-style syscall over emulated user memory
- `getpid`, `exit`, `yield`, `open`, `read`, and `putchar` syscalls
- fixed-size process table storage with saved PC and register state
- round-robin scheduling through `yield`
- a tiny read-only VFS entry for `/motd`

This is not yet a cycle-accurate Raspberry Pi Zero or ARM1176 emulator. The
next steps are to replace the toy instruction set with an ARM subset, add
exception vectors and processor modes, model UART/timer/interrupt devices more
faithfully, and grow the kernel toward scheduling, file descriptors, and a VFS.

## QEMU Raspberry Pi Zero

For hardware-accurate emulation, use QEMU instead of the toy hosted emulator:

```sh
cpm build
cpm run
```

This builds `src/kernel.c-` with `c- -bare -no-heap`, links it with
`arm-none-eabi-gcc`, and `cpm run` boots it with:

```sh
qemu-system-arm -M raspi0 -kernel target/debug/kernel.elf -serial stdio -display none -no-reboot
```

The QEMU kernel currently prints through the Raspberry Pi Zero PL011 UART and
then exercises a tiny safe RAM filesystem before running a fixed process table.
The filesystem uses fixed inode/data arrays in `Kernel`, with all indexing done
through `Span<T>`. The shell has small built-in `pwd`, `ls`, and `run`
commands:

- fixed maximum file count
- fixed maximum file name length
- fixed maximum file data length
- `fs_create`
- `fs_write`
- `fs_read`
- `fs_list`
- program loading from a filesystem file

After that, the BCM2835 system timer raises IRQs; the IRQ handler sets a
reschedule flag, and the idle loop switches to the next runnable task. The two
initial toy processes currently emit one character per time slice, so their
output is intentionally interleaved.

The process runner now has an explicit user/kernel split. A user step runs with
`MODE_USER` in the kernel state and can only raise a syscall trap such as
`putchar` or `exit`; UART, filesystem, process-table, and program-loading work
is performed after switching back to `MODE_KERNEL`.

The QEMU boot code also installs an SVC vector and runs a startup hardware
probe that drops from privileged SVC mode into ARM User mode, executes
`svc #0`, enters the kernel SVC handler, verifies that SPSR reports User mode,
and returns to the kernel. Normal toy-process `putchar` and `exit` syscalls now
use the same hardware path: the kernel switches to ARM User mode, the user side
executes `svc #0`, the SVC handler records the saved User-mode r0/r1/r2
registers, and the kernel dispatcher handles the syscall after returning to
`MODE_KERNEL`. Each process now has a fixed user stack slot, saved r0-r3
syscall context, and a saved User-mode PC/LR/CPSR frame in the process table.
The kernel validates that SVC saved a nonzero user PC and User-mode CPSR after
each toy-process syscall. SVC entry passes saved LR to C- as the return PC, and
the kernel stores it separately from the toy program counter. The process runner
still uses the toy per-process `entry`/`pc` model for program logic; the next
step is to return from SVC directly back to the selected user process instead
of advancing that toy PC in kernel code.

The shell process prints a scripted
`pwd`, `ls`, and `run /bin/app` sequence. `pwd` prints the root directory,
`ls` lists the fixed RAM filesystem, and `run` loads `/bin/app` from the
filesystem and spawns it as a third process:

```text
hello world
fs:
/etc/motd
/bin/app
minuxfs
$ pwd
/
$ ls
/etc/motd
/bin/app
$ run /bin/app
apipn[i3t][
1]
```

The UART address setup is kept in `unsafe`, while the kernel body uses C-
safe/no-heap features such as `Register<T>`, `Span<T>`, stack structs, and
fixed arrays. Timer vector entry and IRQ save/restore are in `qemu/boot.S`.
This is now the preferred path for real emulation work; the hosted toy emulator
remains as a fast language/runtime experiment.
