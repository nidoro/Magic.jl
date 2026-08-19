#! /bin/sh
# Copyright (C) 2026 KylinSoft Co., Ltd.
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

# A core note's n_descsz is taken straight from the untrusted ELF file.
# For a bit-array ("b"/"B") core item such as NT_386_IOPERM, handle_core_item
# in readelf used to alloca() n_descsz bytes.  A malformed core claiming a
# 16 MiB descriptor would exhaust the process stack and crash readelf.
# The descriptor is kept as a sparse hole, so the input is tiny on disk.

tempfiles core-ioperm-huge.core

testrun ${abs_builddir}/core-ioperm-huge core-ioperm-huge.core

# readelf must not crash; it caps the stack allocation and prints the
# (here empty) ioperm bitmap normally.
testrun_compare ${abs_top_builddir}/src/readelf -n core-ioperm-huge.core <<EOF

Note segment of 16777236 bytes at offset 0x78:
  Owner          Data size  Type
  CORE            16777216  386_IOPERM
    ioperm: <>
EOF

exit 0
