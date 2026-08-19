#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DEST_DIR=$THIS_DIR/../../build/linux-x86_64/zstd-1.5.7
pushd $THIS_DIR/zstd-1.5.7

mkdir -p $DEST_DIR

make -j8 lib MOREFLAGS="-fPIC"
make install PREFIX=$DEST_DIR

popd
