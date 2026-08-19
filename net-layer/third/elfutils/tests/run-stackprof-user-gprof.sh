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

. $srcdir/stackprof-subr.sh

set -x
unset VALGRIND_CMD

# prerequisites
type timeout 2>/dev/null || (echo "no timeout installed"; exit 77)
type gprof 2>/dev/null || (echo "no gprof installed"; exit 77)
check_perf_event_open || (echo "perf_event_open fails (check kernel.perf_event_paranoid + kernel config)"; exit 77)

tempfiles test.out

# run on single executable, with gprof output
testrun ${abs_top_builddir}/src/stackprof -v -g -- timeout 2 /bin/sh -c "while true; do true; done" 2>&1 | tee test.out
tempfiles gmon.*
grep "^perf_event_attr configuration" test.out
grep "Starting stack profile collection pid" test.out || (grep "ERROR: Unsupported architecture" test.out && echo "unsupported arch" && exit 77)
grep -E "^buildid [0-9a-f]+" test.out

stackprof_debuginfod_setup
stackprof_check_gmon_out

exit 0
