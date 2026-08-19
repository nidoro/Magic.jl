/* Test dwarf_begin_type and dwarf_get_type functionality.
   Copyright (C) 2024 Red Hat, Inc.
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

#include <config.h>
#include <dwarf.h>
#include <libdw.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const char *
type_name (Dwarf_Type type)
{
  switch (type)
    {
    case DWARF_T_AUTO: return "AUTO";
    case DWARF_T_PLAIN: return "PLAIN";
    case DWARF_T_DWO: return "DWO";
    case DWARF_T_GNU_LTO: return "GNU_LTO";
    default: return "UNKNOWN";
    }
}

Dwarf_Type
name_type (const char *name)
{
  if (strcmp (name, "AUTO") == 0)
    return DWARF_T_AUTO;
  else if (strcmp (name, "PLAIN") == 0)
    return DWARF_T_PLAIN;
  else if (strcmp (name, "DWO") == 0)
    return DWARF_T_DWO;
  else if (strcmp (name, "GNU_LTO") == 0)
    return DWARF_T_GNU_LTO;
  else
    {
      printf ("Unknown type name: %s\n", name);
      exit (1);
    }
}

int
main (int argc, char *argv[])
{
  if (argc < 3)
    {
      fprintf (stderr, "Need <type> and <testfile>\n");
      return 1;
    }

  const char *tname = argv[1];
  const char *file = argv[2];
  Dwarf_Type type = name_type (tname);

  int fd = open (file, O_RDONLY);
  if (fd < 0)
    {
      printf ("Cannot open %s\n", file);
      return 1;
    }

  Dwarf *dbg = dwarf_begin_type (fd, DWARF_C_READ, type);
  Dwarf_Type dwarf_type = dwarf_get_type (dbg);
  printf ("%s: %s -> %s\n", file, type_name (type), type_name (dwarf_type));
  dwarf_end (dbg);
  close (fd);
  return 0;
}
