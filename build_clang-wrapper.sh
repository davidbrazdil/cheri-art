#!/usr/bin/env bash

source config.sh

LLVM_ROOT="/usr/local/llvm33/bin"
LLVM_TARGET="x86_64-unknown-freebsd10.0"

pushd "$DIR_CLANGWRAPPER"
clang -O2 -DCLANG_PATH=\"$LLVM_ROOT\" -DCLANG_TARGET=\"$LLVM_TARGET\" -o clang-wrapper clang-wrapper.c
popd

pushd "$DIR_BIN"
cp "$DIR_CLANGWRAPPER"/clang-wrapper .
rm -f gcc;       ln -s clang-wrapper gcc
rm -f g++;       ln -s clang-wrapper g++
rm -f cc;        ln -s clang-wrapper cc
rm -f c++;       ln -s clang-wrapper c++
rm -f gcc-4.7.3; ln -s clang-wrapper gcc-4.7.3
popd
