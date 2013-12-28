#!/bin/bash

# temporary measure to clean up the Jenkins build slave
rm -rf /tmp/*

apt-get update
apt-get install -y --force-yes sed wget subversion git coreutils \
		unzip bzip2 tar gzip cpio gawk make \
		build-essential gcc g++ chrpath autoconf automake \
		texi2html texinfo realpath libffi-dev libgmp-dev

# Make sure we don't have any old cruft floating around
apt-get remove -y --force-yes libcloog-isl-dev libisl-dev libcloog-isl3 libisl8 libppl0.11-dev || :

# We need to build our own ISL -- polly needs a fairly recent version.
rm -rf isl
git clone git://repo.or.cz/isl.git
cd isl
git checkout -b stable isl-0.12.1
./autogen.sh
./configure --prefix=/usr --enable-static --enable-shared
make -j24
make install
cd ..

# Cloog-ISL too, so we can link to the current ISL
rm -rf cloog
git clone git://repo.or.cz/cloog.git
cd cloog
git checkout -b stable cloog-0.18.0
./autogen.sh
./configure --prefix=/usr --enable-static --enable-shared --with-isl=system --with-bits=gmp
make -j24
make install
cd ..
