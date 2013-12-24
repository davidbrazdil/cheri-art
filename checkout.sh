#!/usr/bin/env bash

source config.sh

mkdir "$DIR_ANDROID" || exit
cd "$DIR_ANDROID" || exit
repo init -u git@github.com:davidbrazdil/cheri-art.git || exit
repo sync || exit
