#!/bin/bash

set -xe

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $THIS_DIR

mkdir -p ../build/win64/artifacts-win64

x86_64-w64-mingw32-gcc \
    -g \
    -static-libstdc++ \
    -static-libgcc \
    -pthread \
    -Wno-unused-result \
    -shared \
    -fPIC \
    -o ../build/win64/artifacts-win64/liblit.dll \
    \
        -I../build/win64/openssl-OpenSSL_1_1_1t/include \
        -I../build/win64/libwebsockets-4.3.2/include \
        -I../build/win64/sqlite-amalgamation-3420000/include \
        -I../build/win64/icu-release-78.1/include \
    \
        -L../build/win64/openssl-OpenSSL_1_1_1t/lib \
        -L../build/win64/libwebsockets-4.3.2/lib \
        -L../build/win64/sqlite-amalgamation-3420000/lib \
        -L../build/win64/icu-release-78.1/lib \
    \
    -Wl,--whole-archive \
        -l:libwebsockets.dll.a \
        -l:libssl.dll.a \
        -l:libcrypto.dll.a \
    -Wl,--no-whole-archive \
    \
    -Wl,--start-group \
        -l:libSqliteIcu.dll.a \
        -l:libicuin.dll.a \
        -l:libicuuc.dll.a \
        -l:libicuio.dll.a \
        -l:libsqlite3.dll.a \
    -Wl,--end-group \
    \
    src/Lit.cpp

popd
