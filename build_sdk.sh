#!/usr/bin/env bash

source config.sh

pushd "$DIR_CHERISDK"
MAKEOBJDIRPREFIX="`pwd`/tmp" ./build_sdk.sh 

CLANGWRAPPER_ROOT="`pwd`"/clang-wrapper
if [ -d "$CLANGWRAPPER_ROOT" ] ; then
        echo Updating clang-wrapper...
        pushd "$CLANGWRAPPER_ROOT"
        try_to_run git pull --rebase
        popd
else
        echo Fetching clang-wrapper...
        try_to_run git clone https://git.linaro.org/people/bernhard.rosenkranzer/clang-wrapper.git
fi

echo Building clang-wrapper...
pushd "$CLANGWRAPPER_ROOT"
try_to_run clang -O2 -DCLANG_PATH=\".\" -o clang-wrapper clang-wrapper.c
popd

echo Creating links to clang-wrapper...
BIN_DIR="`pwd`"/sdk/bin/
try_to_run mv "$CLANGWRAPPER_ROOT/clang-wrapper" "${BIN_DIR}"
pushd "${BIN_DIR}"
for i in cheri-unknown-freebsd mips4-unknown-freebsd mips64-unknown-freebsd; do
        for j in gcc g++ cc c++ gcc-4.7.3; do 
                rm -f $i-$j; ln -s clang-wrapper $i-$j
        done
done
popd

popd
