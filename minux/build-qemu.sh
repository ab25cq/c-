#!/bin/sh
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)

cd "$HERE"
cpm build
