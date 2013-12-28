#!/bin/sh
for i in llvm llvm-patches clang-wrapper; do
	[ -d $i ] && rm -rf $i
done
git clone http://git.linaro.org/git/people/bernhard.rosenkranzer/llvm-patches.git
svn co http://llvm.org/svn/llvm-project/llvm/trunk llvm
cd llvm
for i in ../llvm-patches/????-llvm-*.patch; do
	[ -e "$i" ] || continue
	if ! patch -p1 -b <"$i"; then
		echo "Patch $i fails to apply. Please rebase."
		exit 1
	fi
done
LLVM_REV="`LANG=C svn info |grep "Last Changed Rev:" |cut -d: -f2- |sed -e 's, ,,g'`"
[ -z "$LLVM_REV" ] && LLVM_REV="`date +%Y%m%d`" # Just in case svn changes output unexpectedly
cd tools
svn co http://llvm.org/svn/llvm-project/cfe/trunk clang
# svn co http://llvm.org/svn/llvm-project/polly/trunk polly
cd clang/tools
svn co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra
cd ..
for i in ../../../llvm-patches/????-clang-*.patch; do
	[ -e "$i" ] || continue
	if ! patch -p1 -b <"$i"; then
		echo "Patch $i fails to apply. Please rebase."
		exit 1
	fi
done
CLANG_REV="`LANG=C svn info |grep "Last Changed Rev:" |cut -d: -f2- |sed -e 's, ,,g'`"
[ -z "$CLANG_REV" ] && CLANG_REV="`date +%Y%m%d`" # Just in case svn changes output unexpectedly
cd ../../..
git clone http://git.linaro.org/git/people/bernhard.rosenkranzer/clang-wrapper.git

#git clone git://git.linaro.org/toolchain/binutils.git
#cd binutils
#git checkout -b linaro_binutils-2_23-branch origin/linaro_binutils-2_23-branch
#cd ..
curl -O ftp://ftp.funet.fi/pub/mirrors/sources.redhat.com/pub/binutils/releases/binutils-2.24.tar.gz
tar xf binutils-2.24.tar.gz
mv binutils-2.24 binutils
