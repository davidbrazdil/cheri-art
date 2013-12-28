#!/bin/sh
[ -z "$CFLAGS" ] && CFLAGS="-O2"
[ -z "$CXXFLAGS" ] && CXXFLAGS="-O2"
[ -z "$CPUS" ] && CPUS="`getconf _NPROCESSORS_ONLN`"
#[ -z "$CPUS" ] && CPUS="`cat /proc/cpuinfo  |grep ^processor |wc -l`"
[ -z "$CPUS" ] && CPUS=4
cd binutils
for i in $TARGETS; do
	mkdir build-$i
	cd build-$i
	if echo $i |grep -q aarch64; then
		GOLD=--disable-gold
	else
		GOLD=--enable-gold=default
	fi
	../configure --prefix=/llvm-toolchain \
		--target=$i \
		$GOLD
	if ! gmake -j $CPUS; then
		echo "Binutils failed to build for $i."
		exit 1
	fi
	cd ..
done
cd ../llvm
./configure --prefix=/llvm-toolchain \
	--enable-shared \
	--enable-jit \
	--enable-optimized \
	--enable-targets=all \
	--enable-threads
if ! gmake -j$CPUS; then
	echo "LLVM/Clang failed to build."
	exit 1
fi
cd ../clang-wrapper
if ! LD_LIBRARY_PATH="../llvm/Release+Asserts/lib":"$LD_LIBRARY_PATH" ../llvm/Release+Asserts/bin/clang -O2 -DCLANG_PATH=\".\" -o clang-wrapper clang-wrapper.c; then
	echo "clang-wrapper failed to build."
	exit 1
fi
cd ..
