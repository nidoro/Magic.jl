/* Parses .debug_sup and .debug_dwp sections.
   Copyright (C) 2026 Mark J. Wielaard
   This file is part of elfutils.

   This file is free software; you can redistribute it and/or modify
   it under the terms of either

     * the GNU Lesser General Public License as published by the Free
       Software Foundation; either version 3 of the License, or (at
       your option) any later version

   or

     * the GNU General Public License as published by the Free
       Software Foundation; either version 2 of the License, or (at
       your option) any later version

   or both in parallel, as here.

   elfutils is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License and
   the GNU Lesser General Public License along with this program.  If
   not, see <http://www.gnu.org/licenses/>.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include "libdwelfP.h"

/* .debug_sup and .debug_dwp are identical, just the name of the flag
   is different.  */
static ssize_t
dwelf_dwarf_debug_sec (Dwarf *dwarf,
		       int idx, /* Either IDX_debug_sup or IDX_debug_dwp.  */
		       uint16_t *versionp,
		       uint8_t *is_flagp,
		       const char **filepathp,
		       const uint8_t **idp)
{
  if (dwarf == NULL)
    return -1;

  Elf_Data *data = dwarf->sectiondata[idx];
  if (data == NULL)
    {
      if (filepathp != NULL)
	*filepathp = NULL;
      if (idp != NULL)
	*idp = NULL;
      return 0;
    }

  /* Minimal is version 2 bytes, flag 1 byte, empty path 1 byte, zero
     id_len 1 byte for a total of 5.  */
  if (data->d_buf == NULL || data->d_size < 5)
    {
    bad_data:
      __libdw_seterrno (DWARF_E_INVALID_DWARF);
      return -1;
    }

  const unsigned char *readp = data->d_buf;
  const unsigned char *endp = data->d_buf + data->d_size;
  uint16_t version = read_2ubyte_unaligned_inc (dwarf, readp);
  if ((idx == IDX_debug_sup && version != 5)
      || (idx == IDX_debug_dwp && version != 6))
    goto bad_data;
  uint8_t flag = *readp++;

  const char *filepath = (const char *) readp;
  /* Must be '\0' terminated.  */
  readp = memchr (filepath, '\0', (size_t) (endp - readp));
  if (readp == NULL)
    goto bad_data;

  readp++;
  if (readp == endp)
    goto bad_data;

  uint64_t id_len;
  get_uleb128 (id_len, readp, endp);
  if (id_len > 0 && (uint64_t) (endp - readp) < id_len)
    goto bad_data;

  if (versionp != NULL)
    *versionp = version;
  if (is_flagp != NULL)
    *is_flagp = flag;
  if (filepathp != NULL)
    *filepathp = filepath;
  if (idp != NULL)
    *idp = readp;

  return id_len;
}

ssize_t
dwelf_dwarf_debug_sup (Dwarf *dwarf,
		       uint16_t *versionp,
		       uint8_t *is_supp,
		       const char **filepathp,
		       const uint8_t **idp)
{
  int idx = IDX_debug_sup;
  return dwelf_dwarf_debug_sec (dwarf, idx,
				versionp, is_supp, filepathp, idp);
}
INTDEF(dwelf_dwarf_debug_sup)

ssize_t
dwelf_dwarf_debug_dwp (Dwarf *dwarf,
		       uint16_t *versionp,
		       uint8_t *is_dwpp,
		       const char **filepathp,
		       const uint8_t **idp)
{
  int idx = IDX_debug_dwp;
  return dwelf_dwarf_debug_sec (dwarf, idx,
				versionp, is_dwpp, filepathp, idp);
}
INTDEF(dwelf_dwarf_debug_dwp)
