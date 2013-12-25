#!/usr/bin/env bash

source config.sh

export PATH="$DIR_BIN":"$PATH":"$DIR_OPENJDK"
export EXPERIMENTAL_USE_JAVA7=true

export TARGET_OS=freebsd

cd "$DIR_ANDROID"

PREBUILT_COMPILER_ROOT="prebuilts/gcc/freebsd-x86/mips"
PREBUILT_COMPILER_PATH="$PREBUILT_COMPILER_ROOT/mips64-unknown-freebsd"
rm -rf "$PREBUILT_COMPILER_PATH"
mkdir -p "$PREBUILT_COMPILER_ROOT"
ln -s "$DIR_CHERISDK" "$PREBUILT_COMPILER_PATH" 


. build/envsetup.sh || exit
lunch aosp_cheri-eng || exit
mmma art

