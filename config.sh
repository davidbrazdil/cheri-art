#!/usr/bin/env bash

ROOT_DIR="`pwd`"

DIR_ANDROID="$ROOT_DIR/android"
DIR_CHERISDK="$ROOT_DIR/cheri-sdk"
DIR_OPENJDK="/home/db538/apps/openjdk7/usr/local/openjdk7/bin/"

check_dep()
{
	if [ x"`whereis $1`" == x ] ; then
		echo error: No $1 binary found in PATH: ${PATH}
		echo $2
		FOUNDDEPS=0
	else
		echo -- Found $1...
	fi
}

try_to_run()
{
	$@ > ${ROOT_DIR}/error.log 2>&1
	if [ $? -ne 0 ] ; then
		echo $1 failed, see error.log for details
		exit 1
	fi
}

