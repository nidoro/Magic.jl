#! /bin/sh
# Test for --debug-dump=info+ and finding split unit (in wrong file).
# Copyright (C) 2018 Red Hat, Inc.
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

# see tests/testfile-dwarf-45.source
testfiles testfile-splitdwarf-5
testfiles testfile-world5.dwo

# note, wrong file, renamed as if this contains the correct dwo...
tempfiles testfile-hello5.dwo
cp testfile-world5.dwo testfile-hello5.dwo

testrun ${abs_top_builddir}/src/readelf --debug-dump=info+ testfile-splitdwarf-5

# dwp that isn't called testfile-main-split.dwp
# echo "int main () { return 42; }" > main.c
# gcc -g -O2 -gsplit-dwarf -o testfile-main-split main.c
# eu-dwp -e testfile-main-split -o testfile-dwp-main-split
# rm testfile-main-split-main.dwo

testfiles testfile-main-split testfile-dwp-main-split
testrun_compare  ${abs_top_builddir}/src/readelf --debug-dump=info+ testfile-main-split <<\EOF

DWARF section [28] '.debug_info' at offset 0x22f8:
 [Offset]
 Compilation unit at offset 0:
 Version: 5, Abbreviation section offset: 0, Address size: 8, Offset size: 4
 Unit type: skeleton (4), Unit id: 0x9a565c0d42a52e75
 [    14]  skeleton_unit        abbrev: 1
           ranges               (sec_offset) range list [     c]
           low_pc               (addr) 000000000000000000
           stmt_list            (sec_offset) 0
           dwo_name             (strp) "testfile-main-split-main.dwo"
           comp_dir             (strp) "/tmp"
           GNU_pubnames         (flag_present) yes
           addr_base            (sec_offset) address base [     8]
 Split compilation unit at offset 0:
 Version: 5, Abbreviation section offset: 0, Address size: 8, Offset size: 4
 Unit type: split_compile (5), Unit id: 0x9a565c0d42a52e75
 {    14}  compile_unit         abbrev: 1
           producer             (strx) "GNU C23 16.1.1 20260515 (Red Hat 16.1.1-2) -mtune=generic -march=x86-64 -mtls-dialect=gnu2 -g -gsplit-dwarf -O2"
           language             (data1) C11 (29)
           language_name        (data1) C (3)
           language_version     (data4) 202311
           name                 (strx) "main.c"
           comp_dir             (strx) "/tmp"
 {    1e}    subprogram           abbrev: 2
             external             (flag_present) yes
             name                 (strx) "main"
             decl_file            (data1) main.c (1)
             decl_line            (data1) 1
             decl_column          (data1) 5
             prototyped           (flag_present) yes
             type                 (ref4) {    32}
             low_pc               (addrx) [0] 0x0000000000400360 <main>
             high_pc              (data8) 6 (0x0000000000400366)
             frame_base           (exprloc) 
              [ 0] call_frame_cfa
             call_all_calls       (flag_present) yes
 {    32}    base_type            abbrev: 3
             byte_size            (data1) 4
             encoding             (data1) signed (5)
             name                 (string) "int"
EOF

exit 0
