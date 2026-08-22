#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEST_DIR=$THIS_DIR/../../build/linux-x86_64/xz-5.8.3
pushd $THIS_DIR/xz-5.8.3

rm -f aclocal.m4 configure config.h.in Makefile.in Makefile
rm -rf autom4te.cache
mkdir -p $DEST_DIR

autoreconf -i -f
./configure \
    --prefix=$DEST_DIR \
    --disable-shared \
    --enable-static \
    CFLAGS="-O2 -fPIC"

make -j8
make install

popd
