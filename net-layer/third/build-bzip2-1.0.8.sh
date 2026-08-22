#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEST_DIR=$THIS_DIR/../../build/linux-x86_64/bzip2-1.0.8
pushd $THIS_DIR/bzip2-1.0.8

mkdir -p $DEST_DIR

make clean
make CFLAGS="-O2 -fPIC -Wall -Winline" -j8
make install PREFIX=$DEST_DIR

popd
