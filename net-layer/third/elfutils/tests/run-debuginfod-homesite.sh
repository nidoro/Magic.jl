#!/usr/bin/env bash
#
# Copyright (C) 2022 Red Hat, Inc.
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

type socat 2>/dev/null || exit 77

. $srcdir/debuginfod-subr.sh  # includes set -e

set -x

# This variable is essential and ensures no time-race for claiming ports occurs
# set base to a unique multiple of 100 not used in any other 'run-debuginfod-*' test
base=10200
get_ports

tempfiles vlog$PORT1
errfiles vlog$PORT1

# Test 1: Make sure attempt to open non-existent --home-html is handled gracefully
rurl="https://sourceware.org/elfutils/Debuginfod.html"
env LD_LIBRARY_PATH=$ldpath DEBUGINFOD_URLS= ${abs_builddir}/../debuginfod/debuginfod \
    $VERBOSE -p $PORT1 --home-html=non-existent.html --home-redirect=$rurl > vlog$PORT1 2>&1 &
PID1=$!
# Server must become ready
wait_ready $PORT1 'ready' 1
echo -e 'GET / HTTP/1.1\nHost: localhost\n' | socat - TCP:127.0.0.1:$PORT1 > response.txt
tempfiles response.txt
# If non-existent --home-html is passed, server should only send headers
# incl. the --home-redirect in this case ...
grep -F "Location: $rurl" response.txt
# ... followed by the version id.
tail -1 response.txt | grep -F 'debuginfod'
kill $PID1
wait $PID1

# Test 2: Test valid --home-redirect
echo "<html><body>hiya from debuginfod</body></html>" > home.html
tempfiles home.html
rurl="https://sourceware.org/elfutils/Debuginfod.html"
env LD_LIBRARY_PATH=$ldpath DEBUGINFOD_URLS= ${abs_builddir}/../debuginfod/debuginfod \
    $VERBOSE -p $PORT1 --home-html=home.html --home-redirect=$rurl > vlog$PORT1 2>&1 &
PID1=$!
# Server must become ready
wait_ready $PORT1 'ready' 1
echo -e 'GET / HTTP/1.1\nHost: localhost\n' | socat - TCP:127.0.0.1:$PORT1 > response.txt
tempfiles response.txt
grep -F 'hiya from debuginfod' response.txt
grep -F "Location: $rurl" response.txt
kill $PID1
wait $PID1

PID1=0
exit 0
