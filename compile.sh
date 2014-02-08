#!/usr/bin/env bash

source config.sh

export PATH="$DIRS_EXTRA":"$PATH"
export EXPERIMENTAL_USE_JAVA7=true

export TARGET_OS=freebsd

export CC=clang
export CPP=clang++
export CXX=clang++  
export AR=/usr/local/bin/ar

cd "$DIR_ANDROID"

PREBUILT_COMPILER_ROOT="prebuilts/gcc/freebsd-x86/mips64"
PREBUILT_COMPILER_PATH="$PREBUILT_COMPILER_ROOT/mips64-unknown-freebsd"
rm -rf "$PREBUILT_COMPILER_PATH"
mkdir -p "$PREBUILT_COMPILER_ROOT"
ln -s "$DIR_CHERISDK"/sdk "$PREBUILT_COMPILER_PATH" 

AR_REPLACEMENT="$PREBUILT_COMPILER_PATH"/bin/mips4-unknown-freebsd-ar
rm -f "$AR_REPLACEMENT"
ln -s "$AR" "$AR_REPLACEMENT"

. build/envsetup.sh || exit
lunch cheri_mips-eng || exit
mmma showcommands art

