#!/bin/sh

WORKING_DIR=work
mkdir "$WORKING_DIR" || exit
cd "$WORKING_DIR" || exit
repo init -u git@github.com:davidbrazdil/cheri-art.git || exit
repo sync || exit
