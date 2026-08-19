#!/usr/bin/env bash
#
# Copyright (C) 2026 Red Hat, Inc.
# This file is part of elfutils.
#
# This file is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# elfutils is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

. $srcdir/debuginfod-subr.sh

set -x
unset VALGRIND_CMD

# set base to a unique multiple of 100 not used in any other 'run-debuginfod-*' test
base=12100
get_ports

DB=${PWD}/.debuginfod_tmp.sqlite
tempfiles $DB
export DEBUGINFOD_CACHE_PATH=${PWD}/.client_cache

# Copy the source file to the current directory so that debuginfod can index it
# since the binary was compiled with -fdebug-prefix-map=$(pwd)=.
# Therefore, DWARF points to the relative path testfile-debug-map.c in the cwd.
cp ${abs_srcdir}/testfile-debug-map.c .
tempfiles testfile-debug-map.c

# Unpack the test binary
testfiles testfile-debug-map

# Run debuginfod on current directory (in file/directory mode, scanning .)
env LD_LIBRARY_PATH=$ldpath ${abs_builddir}/../debuginfod/debuginfod $VERBOSE -F -p $PORT1 -d $DB -t0 -g0 . > vlog$PORT1 2>&1 &
PID1=$!
tempfiles vlog$PORT1
errfiles  vlog$PORT1

wait_ready $PORT1 'ready' 1
wait_ready $PORT1 'thread_work_total{role="traverse"}' 1
wait_ready $PORT1 'thread_work_pending{role="scan"}' 0
wait_ready $PORT1 'thread_busy{role="scan"}' 0

# Check that we can find the source file via debuginfod-find using relative pathnames!
# The build ID of testfile-debug-map is 4c1385643bcb37d365c59001932e908171c9f2dd.
# We test with both a relative path name starting with . and a plain relative path name.
export DEBUGINFOD_URLS="http://127.0.0.1:$PORT1/"

# Test finding with relative path starting with '.'
filename1=`testrun ${abs_top_builddir}/debuginfod/debuginfod-find source 4c1385643bcb37d365c59001932e908171c9f2dd ./testfile-debug-map.c`
cmp $filename1 testfile-debug-map.c

# Test finding with relative path starting with filename
filename2=`testrun ${abs_top_builddir}/debuginfod/debuginfod-find source 4c1385643bcb37d365c59001932e908171c9f2dd testfile-debug-map.c`
cmp $filename2 testfile-debug-map.c

kill $PID1
wait $PID1
PID1=0

exit 0
