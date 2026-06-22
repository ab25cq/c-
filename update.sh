#!/bin/sh

export EDITOR=vin
git config --global user.email ab25cq@gmail.com
git config --global user.name ab25cq

git add .
git commit 
git remote add origin git@github.com:ab25cq/c-.git
git remote set-url origin git@github.com:ab25cq/c-.git
git push --force origin main 

