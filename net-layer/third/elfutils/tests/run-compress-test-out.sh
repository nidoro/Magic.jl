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

testrun_elfcompress_out()
{
  testfile="$1"
  testfiles ${testfile}

  # Direct compress
  testrun ${abs_top_builddir}/src/elfcompress -v -t zlib-gnu ${testfile}
  testrun ${abs_top_builddir}/src/elflint --gnu-ld ${testfile}

  # Decompress with -o being the input file
  testrun ${abs_top_builddir}/src/elfcompress -v -t none -o ${testfile} \
	  ${testfile}
  testrun ${abs_top_builddir}/src/elflint --gnu-ld ${testfile}

  # Compress with -o being an existing file
  tempfiles ${testfile}.tmp
  touch ${testfile}.tmp
  testrun ${abs_top_builddir}/src/elfcompress -v -t zlib -o ${testfile}.tmp \
	  ${testfile}
  testrun ${abs_top_builddir}/src/elflint --gnu-ld ${testfile}.tmp

  # Decompress with -o being a symlink to the input
  tempfiles ${testfile}.link
  ln -s ${testfile}.tmp ${testfile}.link
  testrun ${abs_top_builddir}/src/elfcompress -v -t none -o ${testfile}.link \
	  ${testfile}.tmp
  testrun ${abs_top_builddir}/src/elflint --gnu-ld ${testfile}.link

  # Compress with input being a symlink to a file in a nested directory
  tempfiles ${testfile}.deep
  mkdir deep
  cp ${testfile} deep/
  ln -s deep/${testfile} ${testfile}.deep
  testrun ${abs_top_builddir}/src/elfcompress -v -t zlib ${testfile}.deep
  testrun ${abs_top_builddir}/src/elflint --gnu-ld deep/${testfile}
  rm deep/${testfile}
  rmdir deep
}

# The actual test file shouldn't matter, but just use a couple of
# different ones.

# Random ELF32 testfile
testrun_elfcompress_out testfile4

# Random ELF64 testfile
testrun_elfcompress_out testfile12

# Random ELF64BE testfile
testrun_elfcompress_out testfileppc64

# Random ELF32BE testfile
testrun_elfcompress_out testfileppc32

exit 0
