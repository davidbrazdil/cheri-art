#!/usr/bin/env bash

WORKING_DIR="work"
export PATH="$PATH":~/apps/openjdk7/usr/local/openjdk7/bin/
export EXPERIMENTAL_USE_JAVA7=true

export TARGET_OS=freebsd

cd "$WORKING_DIR"
. build/envsetup.sh || exit
lunch aosp_cheri-eng || exit
mmma art

