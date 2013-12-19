#!/usr/bin/env bash

WORKING_DIR="work"
export PATH="$PATH":~/apps/openjdk7/usr/local/openjdk7/bin/
export EXPERIMENTAL_USE_JAVA7=true

cd "$WORKING_DIR"
. build/envsetup.sh || exit
lunch aosp_mips-eng || exit
mmma art


