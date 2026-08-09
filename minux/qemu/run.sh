#!/bin/sh
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)

sh "$HERE/build.sh"
qemu-system-arm -M raspi0 -kernel "$HERE/build/kernel.img" -serial stdio -display none -no-reboot
