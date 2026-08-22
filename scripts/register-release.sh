#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: Version required. Example: 1.0.0"
    echo "Usage: $0 <version_number>"
    exit 1
fi

MAGIC_VERSION=$1
COMMIT_SHA=$(git rev-list -n 1 v$MAGIC_VERSION)

gh api repos/:owner/:repo/commits/$COMMIT_SHA/comments \
-f body="@JuliaRegistrator register

Release notes:

$(cat RELEASE.md)"
