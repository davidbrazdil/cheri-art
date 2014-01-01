#!/usr/bin/env bash

source config.sh

set_origin()
{
    cd "$DIR_ANDROID"/"$1"
    try_to_run git remote add github "$2"
    try_to_run git checkout -b cheri
    try_to_run git pull github cheri
    try_to_run git push --set-upstream github cheri
}

set_origin \
  build \
  git@github.com:davidbrazdil/cheri-art_build.git
set_origin \
  external/llvm \
  git@github.com:davidbrazdil/cheri-art_llvm.git
set_origin \
  system/core \
  git@github.com:davidbrazdil/cheri-art_system_core.git

