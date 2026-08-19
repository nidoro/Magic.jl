#!/bin/sh
# Copyright (C) 2026 Mark J. Wielaard <mark@klomp.org>
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

. $srcdir/test-subr.sh

# Test dwarf_begin_type and dwarf_get_type with fat LTO file
# (file with both PLAIN and GNU_LTO sections)
testfiles testfile-dwarf5-fat-lto.o

testrun_compare ${abs_builddir}/dwarf-type AUTO testfile-dwarf5-fat-lto.o <<\EOF
testfile-dwarf5-fat-lto.o: AUTO -> PLAIN
EOF
testrun_compare ${abs_builddir}/dwarf-type PLAIN testfile-dwarf5-fat-lto.o <<\EOF
testfile-dwarf5-fat-lto.o: PLAIN -> PLAIN
EOF
testrun_compare ${abs_builddir}/dwarf-type DWO testfile-dwarf5-fat-lto.o <<\EOF
testfile-dwarf5-fat-lto.o: DWO -> AUTO
EOF
testrun_compare ${abs_builddir}/dwarf-type GNU_LTO testfile-dwarf5-fat-lto.o <<\EOF
testfile-dwarf5-fat-lto.o: GNU_LTO -> GNU_LTO
EOF

# Test dwarf_begin_type and dwarf_get_type with DWO (only) file
testfiles testfile-hello5.dwo

testrun_compare ${abs_builddir}/dwarf-type AUTO testfile-hello5.dwo <<\EOF
testfile-hello5.dwo: AUTO -> DWO
EOF
testrun_compare ${abs_builddir}/dwarf-type PLAIN testfile-hello5.dwo <<\EOF
testfile-hello5.dwo: PLAIN -> AUTO
EOF
testrun_compare ${abs_builddir}/dwarf-type DWO testfile-hello5.dwo <<\EOF
testfile-hello5.dwo: DWO -> DWO
EOF
testrun_compare ${abs_builddir}/dwarf-type GNU_LTO testfile-hello5.dwo <<\EOF
testfile-hello5.dwo: GNU_LTO -> AUTO
EOF

exit 0
