#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: Version required. Example: 1.0.0"
    echo "Usage: $0 <version_number>"
    exit 1
fi

MAGIC_VERSION=$1
EXTRA_ARGS=

if [ $# -gt 1 ]; then
    EXTRA_ARGS="${@:2}"
fi

gh release create v$MAGIC_VERSION \
    $EXTRA_ARGS \
    --notes-file RELEASE.md \
    ./build/linux-x86_64/artifacts-linux-x86_64.tar.gz \
    ./build/win64/artifacts-win64.tar.gz
