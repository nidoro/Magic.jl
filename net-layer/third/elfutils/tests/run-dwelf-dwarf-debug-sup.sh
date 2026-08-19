#! /bin/sh
# Test for dwelf_dwarf_debug_sup
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

testfiles testfile-dwarf5-ref-sup testfile-dwarf5.sup
testrun_compare ${abs_top_builddir}/tests/dwelf-dwarf-debug-sup testfile-dwarf5-ref-sup<<\EOF
version: 5
is_sup: no
filepath: testfile-dwarf5.sup
id_len: 20
id: 90e34252e5688d4ff284d787d161b6fe44115436
EOF

testrun_compare ${abs_top_builddir}/tests/dwelf-dwarf-debug-sup testfile-dwarf5.sup<<\EOF
version: 5
is_sup: yes
filepath: 
id_len: 20
id: 90e34252e5688d4ff284d787d161b6fe44115436
EOF
