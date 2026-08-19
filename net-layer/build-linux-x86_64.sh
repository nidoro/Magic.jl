#!/bin/bash

set -xe

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $THIS_DIR

mkdir -p ../build/linux-x86_64/artifacts-linux-x86_64

g++ \
    -g \
    -static-libstdc++ \
    -static-libgcc \
    -pthread \
    -Wno-unused-result \
    -shared \
    -fPIC \
    -DBACKWARD_HAS_DW=1 \
    -o ../build/linux-x86_64/artifacts-linux-x86_64/libmagic.so \
    \
        -I../net-layer/third \
        -I../build/linux-x86_64/elfutils/include \
        -I../build/linux-x86_64/openssl-1.1.1t/include \
        -I../build/linux-x86_64/libwebsockets-4.3.2/include \
        -I../build/linux-x86_64/sqlite-amalgamation-3420000/include \
        -I../build/linux-x86_64/icu-release-78.1/include \
    \
    $THIS_DIR/src/Magic.cpp \
    \
        -L../build/linux-x86_64/elfutils/lib \
        -L../build/linux-x86_64/bzip2-1.0.8/lib \
        -L../build/linux-x86_64/zstd-1.5.7/lib \
        -L../build/linux-x86_64/xz-5.8.3/lib \
        -L../build/linux-x86_64/openssl-1.1.1t/lib \
        -L../build/linux-x86_64/libwebsockets-4.3.2/lib \
        -L../build/linux-x86_64/sqlite-amalgamation-3420000/lib \
        -L../build/linux-x86_64/icu-release-78.1/lib \
    \
    -Wl,--whole-archive \
        -l:libwebsockets.a \
        -l:libssl.a \
        -l:libcrypto.a \
    -Wl,--no-whole-archive \
    \
    -Wl,--start-group \
        -l:libSqliteIcu.a \
        -l:libicui18n.a \
        -l:libicuuc.a \
        -l:libicudata.a \
        -l:libicuio.a \
        -l:libsqlite3.a \
        -l:libdw.a \
        -l:libelf.a \
        -l:libbz2.a \
        -l:libzstd.a \
        -l:liblzma.a \
    -Wl,--end-group

popd
