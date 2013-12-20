#!/usr/bin/env bash

CHERIBSD_SDK="/home/db538/cheri-sdk/sdk"
OPENJDK="/home/db538/apps/openjdk7/usr/local/openjdk7/bin/"

WORKING_DIR="work"
export PATH="$PATH":"$OPENJDK"
export EXPERIMENTAL_USE_JAVA7=true

export TARGET_OS=freebsd

cd "$WORKING_DIR"

PREBUILT_COMPILER_ROOT="prebuilts/gcc/freebsd-x86/mips"
PREBUILT_COMPILER_PATH="$PREBUILT_COMPILER_ROOT/mips64-unknown-freebsd"
rm -rf "$PREBUILT_COMPILER_PATH"
mkdir -p "$PREBUILT_COMPILER_ROOT"
ln -s "$CHERIBSD_SDK" "$PREBUILT_COMPILER_PATH" 


. build/envsetup.sh || exit
lunch aosp_cheri-eng || exit
mmma art

