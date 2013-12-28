#!/bin/bash -x

LOCAL_DIR="`pwd`"

if [ -z "$WORKSPACE" ]; then
	# This is a local build rather than Jenkins
	WORKSPACE="`mktemp -d /tmp/clang-build-results-XXXXXX`"
	TEMP="$LOCAL_DIR/out/"
    mkdir -p "$TEMP"
else
	# Not a lot of space in /tmp on the Jenkins build nodes
	TEMP="`mktemp -d $WORKSPACE/clang-destdir-XXXXX`"
fi
TARGETS="x86_64-portbld-freebsd10.0 i386-portbld-freebsd10.0"

. ./get-source.sh

. ./build.sh

. ./install.sh
