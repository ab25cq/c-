#!/bin/sh
set -eu

export EDITOR=vin
git config --global user.email ab25cq@gmail.com
git config --global user.name ab25cq

git add .
if ! git diff --cached --quiet; then
    git commit
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin git@github.com:ab25cq/c-.git
fi
git remote set-url origin git@github.com:ab25cq/c-.git
git push origin HEAD:main
