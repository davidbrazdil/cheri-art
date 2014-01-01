#!/usr/bin/env bash

source config.sh

mkdir -p "$DIR_CHERISDK"
cd "$DIR_CHERISDK"

FOUNDDEPS=1
echo Checking dependencies...
check_dep cmake "Required for building LLVM"
check_dep ninja "Required for building LLVM"
check_dep clang "Required for building clang-wrapper"
check_dep clang++ "Required for building LLVM"
check_dep git "Required for fetching source code"

WD=`pwd`
if [ x"${MAKEOBJDIRPREFIX}" == x ] ; then
	export MAKEOBJDIRPREFIX=${WD}/tmp
	mkdir -p "$MAKEOBJDIRPREFIX"
fi
if [ x"${JFLAG}" == x ] ; then
	JFLAG=-j1
	echo No JFLAG specified, defaulting to -j1
fi
if [ ${FOUNDDEPS} == 0 ] ; then
	exit 1
fi
echo All dependencies satisfied

SYSROOT_DIR="$WD/out"
if [ ! -d "${SYSROOT_DIR}" ] ; then
	mkdir -p "${SYSROOT_DIR}"
fi
CPUTYPE=mipsfpu      # set to 'mips' for soft-float SDK

if [ -d llvm ] ; then
	echo Updating CHERI-LLVM...
	cd llvm
	try_to_run git pull --rebase
	cd tools
else
	echo Fetching CHERI-LLVM...
	try_to_run git clone http://github.com/CTSRD-CHERI/llvm
	cd llvm/tools
fi
if [ -d clang ] ; then
	echo Updating CHERI-Clang...
	cd clang
	try_to_run git pull --rebase
	cd ..
else
	echo Fetching CHERI-Clang...
	try_to_run git clone https://github.com/CTSRD-CHERI/clang
fi
cd ..

if [ -d Build ] ; then
	cd Build
else
	mkdir Build
	cd Build
	echo Configuring LLVM Build...
	try_to_run cmake .. -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DCMAKE_BUILD_TYPE=Release -DDEFAULT_SYSROOT=${SYSROOT_DIR} -DLLVM_DEFAULT_TARGET_TRIPLE=cheri-unknown-freebsd -DCMAKE_INSTALL_PREFIX=${SYSROOT_DIR} -G Ninja
fi

echo Building LLVM...
try_to_run ninja
echo Installing LLVM...
try_to_run ninja install
cd ../..

# delete some things that we don't need...
rm -rf ${SYSROOT_DIR}/lib/lib*
rm -rf ${SYSROOT_DIR}/share
rm -rf ${SYSROOT_DIR}/include

CLANGWRAPPER_ROOT="$WD"/clang-wrapper
if [ -d "$CLANGWRAPPER_ROOT" ] ; then
	echo Updating clang-wrapper...
    cd "$CLANGWRAPPER_ROOT"
	try_to_run git pull --rebase
else
	echo Fetching clang-wrapper...
	try_to_run git clone https://git.linaro.org/people/bernhard.rosenkranzer/clang-wrapper.git
fi

echo Building clang-wrapper...
cd "$CLANGWRAPPER_ROOT"
try_to_run clang -O2 -DCLANG_PATH=\".\" -o clang-wrapper clang-wrapper.c

CHERIBSD_ROOT="$WD"/cheribsd
if [ -d "$CHERIBSD_ROOT" ] ; then
	echo Updating CHERIbsd...
	cd "$CHERIBSD_ROOT" 
	try_to_run git pull --rebase
else
	echo Fetching CHERIbsd...
    cd "$WD"
	try_to_run git clone https://github.com/CTSRD-CHERI/cheribsd
    cd "$CHERIBSD_ROOT"
    echo Applying CHERIbsd Makefile patch...
    try_to_run git am --signoff < "$ROOT_DIR"/cheribsd_base-txz.patch
fi

cd ${CHERIBSD_ROOT}
echo Building the toolchain...
CHERIBSD_OBJ="`pwd`"
CHERITOOLS_OBJ="${MAKEOBJDIRPREFIX}/mips.mips64/`pwd`/tmp/usr/bin/"
try_to_run make $JFLAG toolchain TARGET=mips TARGET_ARCH=mips64 CPUTYPE=${CPUTYPE} -DNOCLEAN
echo Building FreeBSD base distribution...
try_to_run make ${JFLAG} -DWITHOUT_SVNLITE TARGET=mips TARGET_ARCH=mips64 CPUTYPE=${CPUTYPE} -DDB_FROM_SRC -DNOCLEAN buildworld
cd release

echo Creating base system tarball...
try_to_run make ${JFLAG} -DWITHOUT_SVNLITE TARGET=mips TARGET_ARCH=mips64 CPUTYPE=${CPUTYPE} -DDB_FROM_SRC -DNOCLEAN base.txz -DNO_ROOT

echo Populating SDK...
cd ${SYSROOT_DIR}
try_to_run tar xJ --include="usr/include" --include="lib/" --include="usr/lib/" -f ${CHERIBSD_OBJ}/release/base.txz 

echo Installing tools...
TOOLS="as lint objdump strings addr2line c++filt crunchide gcov nm readelf strip ld objcopy size"
for TOOL in ${TOOLS} ; do
	cp -f ${CHERITOOLS_OBJ}/${TOOL} ${SYSROOT_DIR}/bin/${TOOL}
done
TOOLS="${TOOLS} clang clang++ llvm-mc llvm-objdump llvm-readobj llvm-size llc"
for TOOL in ${TOOLS} ; do
	ln -fs $TOOL ${SYSROOT_DIR}/bin/cheri-unknown-freebsd-${TOOL}
	ln -fs $TOOL ${SYSROOT_DIR}/bin/mips4-unknown-freebsd-${TOOL}
	ln -fs $TOOL ${SYSROOT_DIR}/bin/mips64-unknown-freebsd-${TOOL}
done

echo Fixing absolute paths in symbolic links inside lib directory...
echo | cat | cc -x c - -o ${SYSROOT_DIR}/bin/fixlinks <<EOF
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
	DIR *dir = opendir(".");
	struct dirent *file;
	while ((file = readdir(dir)) != NULL)
	{
		if (file->d_type == DT_LNK)
		{
			char buffer[1024];
			size_t index = readlink(file->d_name, buffer, 1023);
			buffer[index] = 0;
			if (buffer[0] == '/')
			{
				char *newName;
				asprintf(&newName, "../..%s", buffer);
				if (unlink(file->d_name))
				{
					perror("Failed to remove old link");
					exit(1);
				}
				if (symlink(newName, file->d_name))
				{
					perror("Failed to create link");
					exit(1);
				}
				free(newName);
			}
		}
	}
	closedir(dir);
}
EOF

cd ${SYSROOT_DIR}/usr/lib
try_to_run ../../bin/fixlinks 
echo Compiling cheridis helper...
echo | cat | cc -DLLVM_PATH=\"${SYSROOT_DIR}/bin/\" -x c - -o ${SYSROOT_DIR}/bin/cheridis <<EOF
#include <stdio.h>
#include <string.h>

int main(int argc, char** argv)
{
	FILE *dis = popen(LLVM_PATH "llvm-mc -disassemble -triple=cheri-unknown-freebsd", "w");
	for (int i=1 ; i<argc ; i++)
	{
		char *inst = argv[i];
		if (strlen(inst) == 10)
		{
			if (inst[0] != '0' || inst[1] != 'x') continue;
			inst += 2;
		}
		else if (strlen(inst) != 8) continue;
		for (int byte=0 ; byte<8 ; byte+=2)
		{
			fprintf(dis, "0x%.2s ", &inst[byte]);
		}
	}
	pclose(dis);
}
EOF

echo Creating links to clang-wrapper...
try_to_run mv "$CLANGWRAPPER_ROOT/clang-wrapper" "${SYSROOT_DIR}/bin/"
cd "${SYSROOT_DIR}/bin/"
for i in cheri-unknown-freebsd mips4-unknown-freebsd mips64-unknown-freebsd; do
	ln -s clang-wrapper $i-gcc
	ln -s clang-wrapper $i-g++
	ln -s clang-wrapper $i-cc
	ln -s clang-wrapper $i-c++
	ln -s clang-wrapper $i-gcc-4.7.3
done

echo Done.  Use ${SYSROOT_DIR}/bin/freebsd-unknown-clang to compile code.
echo Add --sysroot=${SYSROOT_DIR} -B${SYSROOT_DIR} to your CFLAGS
rm -f error.log

