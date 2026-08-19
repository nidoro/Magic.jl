#! /bin/sh
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

# See testfile-dwp.source.
testfiles testfile-dwp-4.dwp testfile-dwp-5.dwp

testrun_compare ${abs_top_builddir}/src/readelf --debug-dump=cu_index testfile-dwp-4.dwp <<\EOF

DWARF section [ 9] '.debug_cu_index' at offset 0x6c80 contains 376 bytes :
 Version:        2
 Columns:        6
 Entries:        3
 Slots:         16

 Offset table
 slot  dwo id              info  abbrv   line   locs stroff  macro
 [  0] 947a8b559fb59920     404    585    164    283   3748   3469
 [  5] afdbe8f5b7425c95     286    370     82      0   1876   1735
 [  9] 0682b8eb2e720699       0      0      0      0      0      0

 Size table
 slot  dwo id              info  abbrv   line   locs stroff  macro
 [  0] 947a8b559fb59920     453    414     83    241   1908   1735
 [  5] afdbe8f5b7425c95     118    215     82      0   1872   1734
 [  9] 0682b8eb2e720699     286    370     82    283   1876   1735

DWARF section [10] '.debug_tu_index' at offset 0x6df8 contains 328 bytes :
 Version:        2
 Columns:        6
 Entries:        2
 Slots:         16

 Offset table
 slot  tu sig             types  abbrv   line   locs stroff  macro
 [ 12] 063b4ae40c9316fc     111    370     82      0   1876   1735
 [ 14] f35612db645f377e       0      0      0      0      0      0

 Size table
 slot  tu sig             types  abbrv   line   locs stroff  macro
 [ 12] 063b4ae40c9316fc     109    215     82      0   1872   1734
 [ 14] f35612db645f377e     111    370     82    283   1876   1735
EOF

testrun_compare ${abs_top_builddir}/src/readelf --debug-dump=cu_index testfile-dwp-5.dwp<<\EOF

DWARF section [10] '.debug_tu_index' at offset 0x6ca1 contains 204 bytes :
 Version:        5
 Columns:        7
 Entries:        2
 Slots:          4

 Offset table
 slot  tu sig              info  abbrv   line   locs stroff  macro   rngs
 [  0] 063b4ae40c9316fc     376    352    127      0   1884   1734      0
 [  2] f35612db645f377e       0      0      0      0      0      0      0

 Size table
 slot  tu sig              info  abbrv   line   locs stroff  macro   rngs
 [  0] 063b4ae40c9316fc     110    202    127      0   1880   1733      0
 [  2] f35612db645f377e     112    352    127    219   1884   1734     34

DWARF section [11] '.debug_cu_index' at offset 0x6d6d contains 308 bytes :
 Version:        5
 Columns:        7
 Entries:        3
 Slots:          8

 Offset table
 slot  dwo id              info  abbrv   line   locs stroff  macro   rngs
 [  2] 2970268d42208082     606    554    254    219   3764   3467     34
 [  3] 225988b4ba73f4b3     112      0      0      0      0      0      0
 [  6] 1082731073ccdfbe     486    352    127      0   1884   1734      0

 Size table
 slot  dwo id              info  abbrv   line   locs stroff  macro   rngs
 [  2] 2970268d42208082     403    394    129    201   1916   1734     67
 [  3] 225988b4ba73f4b3     264    352    127    219   1884   1734     34
 [  6] 1082731073ccdfbe     120    202    127      0   1880   1733      0
EOF
