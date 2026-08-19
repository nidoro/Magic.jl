# Copyright (C) 2021 Red Hat, Inc.
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

# sourced from run-stackprof-*.sh tests (must be bash scripts)

. $srcdir/test-subr.sh

check_perf_event_open() {
    tempfiles perf-test.out
    if ! testrun timeout 2 ${abs_top_builddir}/src/stackprof -v -- /bin/true > perf-test.out 2>&1; then
        if grep -q "perf_event_open.*failed\|Operation not permitted\|Permission denied" perf-test.out; then
            return 77
        fi
    fi
    return 0
}

stackprof_debuginfod_setup() {
    # uncomment to test with networked debuginfod
    #export DEBUGINFOD_URLS=https://debuginfod.elfutils.org/
    return 0
}

stackprof_check_gmon_out() {
    for f in gmon.*.out
    do
        exe="`basename "$f" .out`.exe"
        if [ ! -f "$exe" ]; then
            buildid=`echo "$f" | cut -f2 -d.`
            if ! testrun ${abs_top_builddir}/debuginfod/debuginfod-find -v executable $buildid; then
                echo "$exe not found, skipping"
                continue
            fi
            ln -s "`${abs_top_builddir}/debuginfod/debuginfod-find executable $buildid`" "$exe"
        fi
        tempfiles "$exe" gprof_output.txt
        exe_info="$exe (`readlink $exe`)"
        # try a plain gprof run on the executable
        if gprof "$exe" "$f" > gprof_output.txt 2>&1; then
            echo "$exe_info"
            cat gprof_output.txt
            continue
        fi
        # else fall back to debuginfod
        if ! testrun ${abs_top_builddir}/debuginfod/debuginfod-find -v debuginfo $exe; then
            echo "$exe_info is a stripped binary, debuginfo not found, skipping"
            continue
        fi
        debuginfo="`${abs_top_builddir}/debuginfod/debuginfod-find debuginfo $exe`"
        echo "$exe_info"
        gprof "$debuginfo" "$f"
    done
}
