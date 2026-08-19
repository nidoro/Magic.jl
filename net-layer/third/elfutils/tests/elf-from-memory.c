/* Test elf_from_remote_memory phdr bounds handling.
   Copyright (C) 2026 Matej Smycka
   This file is part of elfutils.

   This file is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   elfutils is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <elf.h>
#include <gelf.h>
#include <libelf.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern Elf *elf_from_remote_memory (GElf_Addr ehdr_vma, GElf_Xword pagesize,
				    GElf_Addr *loadbasep,
				    ssize_t (*read_memory) (void *, void *,
							    GElf_Addr, size_t,
							    size_t),
				    void *arg);

#define BACKSZ 256
static unsigned char backing[BACKSZ];

static ssize_t
read_mem (void *arg, void *data, GElf_Addr address, size_t minread,
	  size_t maxread)
{
  (void) arg;
  if (address >= BACKSZ)
    return 0;
  size_t avail = BACKSZ - (size_t) address;
  size_t n = avail < maxread ? avail : maxread;
  if (n < minread)
    return 0;
  memcpy (data, backing + address, n);
  return (ssize_t) n;
}

static void
init_ehdr (Elf64_Ehdr *ehdr)
{
  memset (ehdr, 0, sizeof *ehdr);
  memcpy (ehdr->e_ident, ELFMAG, SELFMAG);
  ehdr->e_ident[EI_CLASS] = ELFCLASS64;
  ehdr->e_ident[EI_DATA] = ELFDATA2LSB;
  ehdr->e_ident[EI_VERSION] = EV_CURRENT;
  ehdr->e_type = ET_CORE;
  ehdr->e_machine = EM_X86_64;
  ehdr->e_version = EV_CURRENT;
  ehdr->e_phnum = 1;
  ehdr->e_phentsize = sizeof (Elf64_Phdr);
}

int
main (void)
{
  Elf64_Ehdr ehdr;
  int result = 0;

  elf_version (EV_CURRENT);

  init_ehdr (&ehdr);
  ehdr.e_phoff = (Elf64_Off) (0ULL - (uint64_t) sizeof (Elf64_Phdr));
  /* Make sure data is in LSB order.  */
  Elf_Data xlate_data_ehdr =
    {
      .d_type = ELF_T_EHDR,
      .d_buf = &ehdr,
      .d_size = sizeof ehdr,
      .d_version = EV_CURRENT,
    };
  elf64_xlatetom (&xlate_data_ehdr, &xlate_data_ehdr, ELFDATA2LSB);
  memset (backing, 0, sizeof backing);
  memcpy (backing, &ehdr, sizeof ehdr);
  Elf *elf = elf_from_remote_memory (0, 4096, NULL, read_mem, NULL);
  if (elf != NULL)
    {
      printf ("FAIL: wrapping e_phoff did not fail safely\n");
      elf_end (elf);
      result = 1;
    }
  else
    printf ("PASS: wrapping e_phoff handled without OOB read\n");

  init_ehdr (&ehdr);
  ehdr.e_phoff = sizeof (Elf64_Ehdr);
  /* Make sure data is in LSB order.  */
  elf64_xlatetom (&xlate_data_ehdr, &xlate_data_ehdr, ELFDATA2LSB);
  Elf64_Phdr phdr;
  memset (&phdr, 0, sizeof phdr);
  phdr.p_type = PT_LOAD;
  phdr.p_filesz = BACKSZ;
  phdr.p_memsz = BACKSZ;
  phdr.p_align = 4096;
  /* Make sure data is in LSB order.  */
  Elf_Data xlate_data_phdr =
    {
      .d_type = ELF_T_PHDR,
      .d_buf = &phdr,
      .d_size = sizeof phdr,
      .d_version = EV_CURRENT,
    };
  elf64_xlatetom (&xlate_data_phdr, &xlate_data_phdr, ELFDATA2LSB);
  memset (backing, 0, sizeof backing);
  memcpy (backing, &ehdr, sizeof ehdr);
  memcpy (backing + sizeof (Elf64_Ehdr), &phdr, sizeof phdr);
  elf = elf_from_remote_memory (0, 4096, NULL, read_mem, NULL);
  GElf_Ehdr got;
  if (elf == NULL || gelf_getehdr (elf, &got) == NULL || got.e_phnum != 1)
    {
      printf ("FAIL: legitimate image rejected\n");
      result = 1;
    }
  else
    printf ("PASS: legitimate image accepted\n");
  if (elf != NULL)
    elf_end (elf);

  return result;
}
