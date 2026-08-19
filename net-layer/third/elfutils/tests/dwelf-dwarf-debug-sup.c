/* Test program for dwelf_dwarf_debug_sup
   Copyright (C) 2026 Mark J. Wielaard <mark@klomp.org>
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

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <system.h>

#include <assert.h>
#include <errno.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include <unistd.h>

#include ELFUTILS_HEADER(dwelf)

int
main (int argc, char **argv)
{
  if (argc != 2)
    {
      fprintf(stderr, "Usage: %s <dwarf-file>\n", argv[0]);
      return 1;
    }

  const char *file = argv[1];
  int fd = open(file, O_RDONLY);
  if (fd < 0)
    {
      perror("open");
      return 1;
    }

  Dwarf *dwarf = dwarf_begin(fd, DWARF_C_READ);
  if (dwarf == NULL)
    {
      fprintf(stderr, "dwarf_begin: %s\n", dwarf_errmsg(-1));
      close(fd);
      return 1;
    }

  uint16_t version;
  uint8_t is_sup;
  const char *filepath;
  const unsigned char *id;
  ssize_t id_len = dwelf_dwarf_debug_sup (dwarf, &version, &is_sup,
					  &filepath, &id);

  if (id_len == 0 && filepath == NULL)
    {
      printf("%s: No .debug_sup section found\n", file);
    }
  else if (id_len < 0)
    {
      fprintf(stderr, "%s: Error reading .debug_sup: %s\n",
	      file, dwarf_errmsg(-1));
      dwarf_end(dwarf);
      close(fd);
      return 1;
    }
  else
    {
      printf("version: %u\n", version);
      printf("is_sup: %s\n", is_sup ? "yes" : "no");
      printf("filepath: %s\n", filepath);
      printf("id_len: %zd\n", id_len);
      printf("id: ");
      for (ssize_t i = 0; i < id_len; i++)
	printf("%02x", id[i]);
      printf("\n");
    }

  /* Cleanup */
  dwarf_end(dwarf);
  close(fd);

  return 0;
}
