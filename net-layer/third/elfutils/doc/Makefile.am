## Process this file with automake to create Makefile.in
## Configure input file for elfutils.
##
## Copyright (C) 1996-2001, 2002, 2005, 2019-2020 Red Hat, Inc.
## This file is part of elfutils.
##
## This file is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## elfutils is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
EXTRA_DIST = COPYING-GFDL README

# Section 1, Executable programs or shell commands
# The tools manpages that depend on program prefix (will get eu- prefixed)
dist_man1_MANS=readelf.1 elfclassify.1 srcfiles.1 stackprof.1

# Tools that don't get a program prefix
notrans_dist_man1_MANS= debuginfod-find.1

# Section 3, Library calls
# libelf man pages (all notrans)
notrans_dist_man3_MANS= elf32_checksum.3 \
			elf32_fsize.3 \
			elf32_getchdr.3 \
			elf32_getehdr.3 \
			elf32_getphdr.3 \
			elf32_getshdr.3 \
			elf32_newehdr.3 \
			elf32_newphdr.3 \
			elf32_offscn.3 \
			elf32_xlatetof.3 \
			elf32_xlatetom.3 \
			elf64_checksum.3 \
			elf64_fsize.3 \
			elf64_getchdr.3 \
			elf64_getehdr.3 \
			elf64_getphdr.3 \
			elf64_getshdr.3 \
			elf64_newehdr.3 \
			elf64_newphdr.3 \
			elf64_offscn.3 \
			elf64_xlatetof.3 \
			elf64_xlatetom.3 \
			elf_begin.3 \
			elf_clone.3 \
			elf_cntl.3 \
			elf_end.3 \
			elf_errmsg.3 \
			elf_errno.3 \
			elf_fill.3 \
			elf_flagelf.3 \
			elf_flagehdr.3 \
			elf_flagphdr.3 \
			elf_flagscn.3 \
			elf_flagdata.3 \
			elf_flagshdr.3 \
			elf_getarhdr.3 \
			elf_getaroff.3 \
			elf_getarsym.3 \
			elf_getbase.3 \
			elf_getdata.3 \
			elf_getdata_rawchunk.3 \
			elf_getident.3 \
			elf_getphdrnum.3 \
			elf_getscn.3 \
			elf_getshdrnum.3 \
			elf_getshdrstrndx.3 \
			elf_getshnum.3 \
			elf_getshstrndx.3 \
			elf_hash.3 \
			elf_gnu_hash.3 \
			elf_kind.3 \
			elf_memory.3 \
			elf_ndxscn.3 \
			elf_newdata.3 \
			elf_newscn.3 \
			elf_next.3 \
			elf_nextscn.3 \
			elf_rand.3 \
			elf_rawdata.3 \
			elf_rawfile.3 \
			elf_scnshndx.3 \
			elf_strptr.3 \
			elf_update.3 \
			elf_version.3 \
			gelf.3 \
			gelf_checksum.3 \
			gelf_fsize.3 \
			gelf_getauxv.3 \
			gelf_getchdr.3 \
			gelf_getclass.3 \
			gelf_getdyn.3 \
			gelf_getehdr.3 \
			gelf_getlib.3 \
			gelf_getmove.3 \
			gelf_getnote.3 \
			gelf_getphdr.3 \
			gelf_getrel.3 \
			gelf_getrela.3 \
			gelf_getsym.3 \
			gelf_getsyminfo.3 \
			gelf_getsymshndx.3 \
			gelf_getversym.3 \
			gelf_getverdef.3 \
			gelf_getverdaux.3 \
			gelf_getverneed.3 \
			gelf_getvernaux.3 \
			gelf_getshdr.3 \
			gelf_newehdr.3 \
			gelf_newphdr.3 \
			gelf_offscn.3 \
			gelf_update_auxv.3 \
			gelf_update_ehdr.3 \
			gelf_update_dyn.3 \
			gelf_update_lib.3 \
			gelf_update_move.3 \
			gelf_update_phdr.3 \
			gelf_update_shdr.3 \
			gelf_update_rel.3 \
			gelf_update_rela.3 \
			gelf_update_sym.3 \
			gelf_update_syminfo.3 \
			gelf_update_symshndx.3 \
			gelf_update_versym.3 \
			gelf_update_verdef.3 \
			gelf_update_verdaux.3 \
			gelf_update_verneed.3 \
			gelf_update_vernaux.3 \
			gelf_xlatetof.3 \
			gelf_xlatetom.3 \
			libelf.3

# libdebuginfod man pages (also notrans)
# Note we include them even when not building them because we want
# to ship (dist) them always. It is up to the user if they build the
# library or not, but they should always get the manual.
notrans_dist_man3_MANS += debuginfod_add_http_header.3
notrans_dist_man3_MANS += debuginfod_begin.3
notrans_dist_man3_MANS += debuginfod_end.3
notrans_dist_man3_MANS += debuginfod_find_debuginfo.3
notrans_dist_man3_MANS += debuginfod_find_executable.3
notrans_dist_man3_MANS += debuginfod_find_source.3
notrans_dist_man3_MANS += debuginfod_find_section.3
notrans_dist_man3_MANS += debuginfod_find_metadata.3
notrans_dist_man3_MANS += debuginfod_get_user_data.3
notrans_dist_man3_MANS += debuginfod_get_url.3
notrans_dist_man3_MANS += debuginfod_set_progressfn.3
notrans_dist_man3_MANS += debuginfod_set_user_data.3

# Section 7, Miscellaneous (including macro packages and conventions)
notrans_dist_man7_MANS= debuginfod-client-config.7

# Section 8, System administration commands
notrans_dist_man8_MANS= debuginfod.8 debuginfod.service.8
