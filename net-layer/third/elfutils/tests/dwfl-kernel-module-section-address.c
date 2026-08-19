/* Test handling of kernel module sections absent from sysfs.
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
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include ELFUTILS_HEADER(dwfl)

static char modname[64];

static void
check_absent (const char *secname, GElf_Xword size)
{
  GElf_Shdr shdr = { .sh_size = size };
  Dwarf_Addr addr = 0;

  int result = dwfl_linux_kernel_module_section_address (NULL, NULL,
							  modname, 0,
							  secname, 0,
							  &shdr, &addr);
  assert (result == DWARF_CB_OK);
  assert (addr == (Dwarf_Addr) -1l);
}

static void
check_unknown (void)
{
  GElf_Shdr shdr = { .sh_size = 1 };
  Dwarf_Addr addr = 0;

  errno = 0;
  int result = dwfl_linux_kernel_module_section_address (NULL, NULL,
							  modname, 0,
							  ".unknown", 0,
							  &shdr, &addr);
  assert (result == DWARF_CB_ABORT);
  assert (errno == ENOENT);
  assert (addr == 0);
}

int
main (void)
{
  int written = snprintf (modname, sizeof (modname),
			  "elfutils_test_%ld", (long) getpid ());
  assert (written > 0 && (size_t) written < sizeof (modname));

  /* Existing special cases.  */
  check_absent (".modinfo", 1);
  check_absent (".data.percpu", 1);
  check_absent (".exit.text", 1);

  /* The kernel clears SHF_ALLOC for these module version sections.  */
  check_absent ("__versions", 1);
  check_absent ("__version_ext_crcs", 1);
  check_absent ("__version_ext_names", 1);

  /* The kernel module loader uses two dots in the per-CPU section name.  */
  check_absent (".data..percpu", 1);

  /* Zero-sized sections are not exposed through module sysfs.  */
  check_absent (".bss", 0);

  /* Other missing sections must still abort the callback.  */
  check_unknown ();

  return 0;
}
