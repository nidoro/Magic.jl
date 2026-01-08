#!/bin/bash

export TARGET=x86_64-w64-mingw32
export CC=${TARGET}-gcc
export CXX=${TARGET}-g++
export WINDRES=${TARGET}-windres

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

DEST_DIR=$THIS_DIR/../../../build/win64/libwebsockets-4.3.2
mkdir -p $DEST_DIR

cd $DEST_DIR
rm -rf build
rm $THIS_DIR/CMakeCache.txt
mkdir build
cd build

cmake $THIS_DIR \
  -DCMAKE_INSTALL_PREFIX=.. \
  -DCMAKE_C_FLAGS="-fPIC" \
  -DCMAKE_CXX_FLAGS="-fPIC" \
  -DCMAKE_BUILD_TYPE=RELEASE \
  -DLWS_OPENSSL_INCLUDE_DIRS="../../openssl-OpenSSL_1_1_1t/include" \
  -DLWS_OPENSSL_LIBRARIES="../../openssl-OpenSSL_1_1_1t/lib/libssl.dll.a;../../openssl-OpenSSL_1_1_1t/lib/libcrypto.dll.a" \
  \
  -DCMAKE_SYSTEM_NAME=Windows \
  -DCMAKE_SYSTEM_PROCESSOR=x86_64 \
  -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc \
  -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ \
  -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres \
  -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
  -DCMAKE_C_FLAGS="-Wno-enum-int-mismatch"

make -j8
make install
cd ..
