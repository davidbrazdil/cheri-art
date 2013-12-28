#!/bin/sh

cd binutils
for i in $TARGETS; do
	cd build-$i
	if ! gmake install DESTDIR="$TEMP"; then
		echo "Binutils failed to install for $i"
		exit 1
	fi
	cd ..
done
cd ..
cd llvm
if ! gmake install DESTDIR="$TEMP"; then
	echo "LLVM/Clang failed to install."
	exit 1
fi
cd ..
if ! mv clang-wrapper/clang-wrapper "$TEMP"/llvm-toolchain/bin/; then
	echo "Clang-Wrapper failed to install."
	exit 1
fi

BIN_FOLDER="$TEMP"/llvm-toolchain/bin
pushd "$BIN_FOLDER"
for i in $TARGETS; do
	ln -s clang-wrapper $i-gcc
	ln -s clang-wrapper $i-g++
	ln -s clang-wrapper $i-cc
	ln -s clang-wrapper $i-c++
	ln -s clang-wrapper $i-gcc-4.7.3

    pushd "$BIN_FOLDER"/../"$i"/bin
    cp "$BIN_FOLDER"/$i-* .
    cp "$BIN_FOLDER"/clang-wrapper .
    popd
done
popd

