#!/bin/sh

git clone https://android.googlesource.com/platform/build
git clone https://android.googlesource.com/platform/art
mkdir external
cd external && git clone https://android.googlesource.com/platform/external/stlport
