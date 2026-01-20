#!/bin/bash

export JULIA_PKG_IGNORE_HASHES=1
export JULIA_PKG_PRECOMPILE_AUTO=0
wine ~/julia-1.10.10-win64/bin/julia.exe --project
