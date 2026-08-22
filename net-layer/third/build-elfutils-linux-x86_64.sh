#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEST_DIR=$THIS_DIR/../../build/linux-x86_64/elfutils
pushd $THIS_DIR/elfutils

mkdir -p $DEST_DIR

make distclean
autoreconf -i -f
CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure --prefix=$DEST_DIR --enable-maintainer-mode --disable-debuginfod --enable-static

make -j8
make install

popd
