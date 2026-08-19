/* Test elf_getarsym on a truncated in-memory 32-bit archive index.
   Copyright (C) 2026 KylinSoft Co., Ltd.
   This file is part of elfutils.

   This file is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   elfutils is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* elf_getarsym reads the number of entries of an archive symbol index
   through read_number_entries ().  On the mmap path, taken for images
   created with elf_memory (), it used to copy sizeof (union { uint64_t;
   uint32_t; }) == 8 bytes instead of the width-appropriate 4 bytes for
   a 32-bit ("symdef") index.  For a minimal archive whose index member
   holds only the 4-byte count field, that copied 4 bytes past the end
   of the caller's buffer.

   This reproduces by building such a minimal 32-bit archive in an
   elf_memory () image placed at the very end of a page, with an
   inaccessible guard page immediately following it.  An unfixed build
   reads into the guard page and crashes; a fixed build reads exactly 4
   bytes and returns the (zero-entry) index normally.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <ar.h>
#include <errno.h>
#include <libelf.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

/* SARMAG + sizeof (struct ar_hdr) + a 4-byte 32-bit index count.  */
#define ARSZ (8 + 60 + 4)

/* Build a minimal 32-bit ("symdef") archive whose index member consists
   of only the count field, encoding zero entries.  */
static void
build_archive (unsigned char *p)
{
  memset (p, 0, ARSZ - 4);
  memcpy (p, "!<arch>\n", 8);

  struct ar_hdr *hdr = (struct ar_hdr *) (p + 8);
  memset (hdr, ' ', sizeof *hdr);
  memcpy (hdr->ar_name, "/               ", 16);
  memcpy (hdr->ar_date, "0           ", 12);
  memcpy (hdr->ar_uid, "0     ", 6);
  memcpy (hdr->ar_gid, "0     ", 6);
  memcpy (hdr->ar_mode, "100644  ", 8);
  memcpy (hdr->ar_size, "4         ", 10);
  memcpy (hdr->ar_fmag, "`\n", 2);
}

static void
build_archive_count (unsigned char *p)
{
  /* 4-byte count, stored big-endian as on disk; zero entries.  */
  p[68] = 0;
  p[69] = 0;
  p[70] = 0;
  p[71] = 0;
}

int
main (void)
{
  int result = 1;
  int result2 = 1;

  long pgsz = sysconf (_SC_PAGESIZE);
  if (pgsz <= 0 || (size_t) pgsz < ARSZ)
    {
      printf ("SKIP: unusable page size (%ld)\n", pgsz);
      return 77;
    }

  /* Map two pages and make the second one inaccessible.  The archive is
     placed at the end of the first page so that an 8-byte read of the
     4-byte count field at offset 68 crosses into the guard page.  */
  unsigned char *map = mmap (NULL, (size_t) pgsz * 2,
                PROT_READ | PROT_WRITE,
                MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (map == MAP_FAILED)
    {
      printf ("SKIP: mmap failed: %m\n");
      return 77;
    }
  if (mprotect (map + pgsz, (size_t) pgsz, PROT_NONE) != 0)
    {
      printf ("SKIP: mprotect failed: %m\n");
      munmap (map, (size_t) pgsz * 2);
      return 77;
    }

  unsigned char *buf = map + pgsz - ARSZ;
  build_archive (buf);
  build_archive_count (buf);

  if (elf_version (EV_CURRENT) == EV_NONE)
    {
      printf ("FAIL: elf_version: %s\n", elf_errmsg (-1));
      goto out;
    }

  Elf *elf = elf_memory ((char *) buf, ARSZ);
  if (elf == NULL)
    {
      printf ("FAIL: elf_memory: %s\n", elf_errmsg (-1));
      goto out;
    }

  size_t narsym = (size_t) -1;
  Elf_Arsym *arsym = elf_getarsym (elf, &narsym);
  /* A zero-entry index still gets the terminating sentinel entry, so
     the table is non-NULL and the reported count is one.  */
  if (arsym == NULL || narsym != 1
      || arsym[0].as_name != NULL || arsym[0].as_off != 0
      || arsym[0].as_hash != ~0UL)
    {
      printf ("FAIL: unexpected arsym (narsym=%zu, arsym=%p)\n",
         narsym, (void *) arsym);
      result = 1;
    }
  else
    {
      printf ("PASS: truncated 32-bit index read within bounds\n");
      result = 0;
    }

  elf_end (elf);

  /* Again, but without the index member.  Will fail, but shouldn't
     crash.  */
  buf = map + pgsz - ARSZ + 4;
  build_archive (buf);

  elf = elf_memory ((char *) buf, ARSZ - 4);
  if (elf == NULL)
    {
      printf ("FAIL: elf_memory: %s\n", elf_errmsg (-1));
      goto out;
    }

  arsym = elf_getarsym (elf, &narsym);

  if (arsym != NULL)
    {
      printf ("FAIL: 2 unexpected arsym (narsym=%zu, arsym=%p)\n",
         narsym, (void *) arsym);
      result2 = 1;
    }
  else
    {
      printf ("PASS: 2 read archive header within bounds\n");
      result2 = 0;
    }

  elf_end (elf);

out:
  munmap (map, (size_t) pgsz * 2);
  return result + result2;
}
