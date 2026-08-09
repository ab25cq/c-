#!/bin/sh
set -eu

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HERE=$(cd "$(dirname "$0")" && pwd)
BUILD="$HERE/build"

mkdir -p "$BUILD"

"$ROOT/c-" -bare -no-heap "$HERE/kernel.c-" > "$BUILD/kernel.c"
printf '#define CMINUS_BARE_IMPL\n#include <c-bare.h>\n' > "$BUILD/c-bare-runtime.c"

arm-none-eabi-gcc -mcpu=arm1176jzf-s -marm -ffreestanding -fno-builtin -fno-stack-protector -Os -I"$HERE/../lib" -I"$BUILD" -c "$HERE/boot.S" -o "$BUILD/boot.o"
arm-none-eabi-gcc -mcpu=arm1176jzf-s -marm -ffreestanding -fno-builtin -fno-stack-protector -Os -I"$HERE/../lib" -I"$BUILD" -c "$HERE/board.c" -o "$BUILD/board.o"
arm-none-eabi-gcc -mcpu=arm1176jzf-s -marm -ffreestanding -fno-builtin -fno-stack-protector -Os -I"$HERE/../lib" -I"$BUILD" -c "$BUILD/c-bare-runtime.c" -o "$BUILD/c-bare-runtime.o"
arm-none-eabi-gcc -mcpu=arm1176jzf-s -marm -ffreestanding -fno-builtin -fno-stack-protector -Os -I"$HERE/../lib" -I"$BUILD" -c "$BUILD/kernel.c" -o "$BUILD/kernel.o"

arm-none-eabi-gcc -nostdlib -T "$HERE/linker.ld" "$BUILD/boot.o" "$BUILD/board.o" "$BUILD/kernel.o" "$BUILD/c-bare-runtime.o" -lgcc -o "$BUILD/kernel.elf"
arm-none-eabi-objcopy "$BUILD/kernel.elf" -O binary "$BUILD/kernel.img"
arm-none-eabi-size "$BUILD/kernel.elf"
