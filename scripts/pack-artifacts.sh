#!/bin/bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $THIS_DIR/.. # Repo's root

# Linux x86_64
#----------------------------

# Build liblit.so on Ubuntu 20.04 (LTS)
docker run --rm -v "$PWD":/work lit-build:20.04 bash -c "./net-layer/build-linux-x86_64.sh"

ARTIFACTS_DIR=build/linux-x86_64/artifacts-linux-x86_64

tar -czf "$ARTIFACTS_DIR.tar.gz" -C "$ARTIFACTS_DIR" .

echo
echo "-------------- Linux x86-64 Artifacts ----------------"
echo "Git Tree hash"
julia -e "using Pkg; using Pkg.GitTools; println(bytes2hex(Pkg.GitTools.tree_hash(\"$ARTIFACTS_DIR\")))"
echo
echo "Checksum of $ARTIFACTS_DIR.tar.gz"
sha256sum "$ARTIFACTS_DIR.tar.gz" | cut -d' ' -f1
echo "------------------------------------------------------"
echo

# Windows 64-bit
#----------------------------
net-layer/build-win64.sh

ARTIFACTS_DIR=build/win64/artifacts-win64

tar -czf "$ARTIFACTS_DIR.tar.gz" -C "$ARTIFACTS_DIR" .

echo
echo "------------ Windows 64-bit Artifacts ----------------"
echo "Git Tree hash"
julia -e "using Pkg; using Pkg.GitTools; println(bytes2hex(Pkg.GitTools.tree_hash(\"$ARTIFACTS_DIR\")))"
echo
echo "Checksum of $ARTIFACTS_DIR.tar.gz"
sha256sum "$ARTIFACTS_DIR.tar.gz" | cut -d' ' -f1
echo "------------------------------------------------------"
echo

popd
