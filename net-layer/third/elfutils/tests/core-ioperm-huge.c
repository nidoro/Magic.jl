/* Build a minimal ET_CORE ELF with a single NT_386_IOPERM note whose
   n_descsz is far larger than a typical process stack, to exercise the
   bit-array ("b"/"B") path in handle_core_item.
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

/* NT_386_IOPERM lives in elfutils' own elf.h but not necessarily in the
   system <elf.h>, so define it when missing.  */
#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include <elf.h>
#ifndef NT_386_IOPERM
# define NT_386_IOPERM 0x201
#endif
#include <libelf.h>

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Larger than any plausible process stack so an unfixed readelf, which
   alloca()s n_descsz bytes, crashes; a fixed one caps the allocation.  */
#define DESCSZ (16 * 1024 * 1024)

static void
put (int fd, const void *buf, size_t n)
{
  if (write (fd, buf, n) != (ssize_t) n)
    {
      perror ("write");
      _exit (2);
    }
}

int
main (int argc, char **argv)
{
  if (argc != 2)
    {
      fprintf (stderr, "usage: %s output.core\n", argv[0]);
      return 2;
    }

  int fd = open (argv[1], O_WRONLY | O_CREAT | O_TRUNC, 0600);
  if (fd < 0)
    {
      perror ("open");
      return 2;
    }

  /* Layout:  Elf64_Ehdr (64) | Elf64_Phdr (56) | Elf64_Nhdr (12)
   *          | "CORE\0" padded to 8 | desc (DESCSZ, sparse).  */
  const size_t phoff = sizeof (Elf64_Ehdr);
  const size_t note_off = phoff + sizeof (Elf64_Phdr);
  const char name[] = "CORE";
  const size_t name_padded = (sizeof (name) + 3) & ~(size_t) 3; /* 8 */
  const size_t filesz = sizeof (Elf64_Nhdr) + name_padded + DESCSZ;
  Elf_Data data;
  data.d_version = EV_CURRENT;
  data.d_off = 0;
  data.d_align = 1;

  Elf64_Ehdr ehdr;
  memset (&ehdr, 0, sizeof ehdr);
  memcpy (ehdr.e_ident, ELFMAG, SELFMAG);
  ehdr.e_ident[EI_CLASS] = ELFCLASS64;
  ehdr.e_ident[EI_DATA] = ELFDATA2LSB;
  ehdr.e_ident[EI_VERSION] = EV_CURRENT;
  ehdr.e_type = ET_CORE;
  ehdr.e_machine = EM_X86_64;
  ehdr.e_version = EV_CURRENT;
  ehdr.e_phoff = phoff;
  ehdr.e_ehsize = sizeof (Elf64_Ehdr);
  ehdr.e_phentsize = sizeof (Elf64_Phdr);
  ehdr.e_phnum = 1;

  data.d_buf = &ehdr;
  data.d_size = sizeof ehdr;
  data.d_type = ELF_T_EHDR;
  elf64_xlatetof (&data, &data, ELFDATA2LSB);
  put (fd, &ehdr, sizeof ehdr);

  Elf64_Phdr phdr;
  memset (&phdr, 0, sizeof phdr);
  phdr.p_type = PT_NOTE;
  phdr.p_flags = PF_R;
  phdr.p_offset = note_off;
  phdr.p_filesz = filesz;
  phdr.p_memsz = filesz;
  phdr.p_align = 4;

  data.d_buf = &phdr;
  data.d_size = sizeof phdr;
  data.d_type = ELF_T_PHDR;
  elf64_xlatetof (&data, &data, ELFDATA2LSB);
  put (fd, &phdr, sizeof phdr);

  Elf64_Nhdr nhdr;
  memset (&nhdr, 0, sizeof nhdr);
  nhdr.n_namesz = sizeof (name); /* 5, includes the NUL */
  nhdr.n_descsz = DESCSZ;
  nhdr.n_type = NT_386_IOPERM;

  data.d_buf = &nhdr;
  data.d_size = sizeof nhdr;
  data.d_type = ELF_T_NHDR;
  elf64_xlatetof (&data, &data, ELFDATA2LSB);
  put (fd, &nhdr, sizeof nhdr);

  char namebuf[8];
  memset (namebuf, 0, sizeof namebuf);
  memcpy (namebuf, name, sizeof (name));
  put (fd, namebuf, name_padded);

  /* Make the descriptor a sparse hole instead of writing 16 MiB.  */
  if (lseek (fd, (off_t) (note_off + filesz - 1), SEEK_SET) == (off_t) -1
      || write (fd, "", 1) != 1)
    {
      perror ("lseek/write");
      _exit (2);
    }

  if (close (fd) != 0)
    {
      perror ("close");
      return 2;
    }
  return 0;
}
