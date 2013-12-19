#!/usr/bin/env bash

WORKING_DIR="work"


cd "$WORKING_DIR"
. build/envsetup.sh || exit
lunch aosp_mips-eng || exit
export EXPERIMENTAL_USE_JAVA7=true
mmma art


