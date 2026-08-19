/* Get Dwarf Frame state for perf stack sample data.
   Copyright (C) 2025 Red Hat, Inc.
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

   You should have received copies of the GNU General Public License and
   the GNU Lesser General Public License along with this program.  If
   not, see <http://www.gnu.org/licenses/>.  */

#ifdef HAVE_CONFIG_H
# include <config.h>
#endif

#include "libdwfl_stacktraceP.h"

/* Various functions providing arch-specific info:  */

Ebl *default_ebl = NULL;
GElf_Half default_ebl_machine = EM_NONE;

uint64_t
dwflst_perf_sample_preferred_regs_mask (GElf_Half machine)
{
  /* XXX The most likely case is that this will only be called once,
     for the current architecture.  So we keep one Ebl* around for
     answering this query and replace it in the unlikely case of
     getting called with different architectures.  */
  if (default_ebl != NULL && default_ebl_machine != machine)
    {
      ebl_closebackend(default_ebl);
      default_ebl = NULL;
    }
  if (default_ebl == NULL)
    {
      default_ebl = ebl_openbackend_machine(machine);
      default_ebl_machine = machine;
    }
  if (default_ebl != NULL)
    return ebl_perf_frame_regs_mask (default_ebl);
  return 0;
}

GElf_Half
dwflst_arch_from_uname (const char *umachine)
{
  if (strncmp(umachine, "x86_64", 6) == 0)
    return EM_X86_64;
  else if (strncmp(umachine, "i686", 4) == 0
	   || strncmp(umachine, "i386", 4) == 0)
    return EM_386;
  else if (strncmp(umachine, "aarch64", 7) == 0)
    return EM_AARCH64;
  else if (strncmp(umachine, "armv7l", 6) == 0)
    return EM_ARM;
  /* XXX Other architectures not yet supported. */
  return EM_NONE;
}

/* XXX The per-machine switches suggest the following implementations
   could be folded into backends/, but we would need to create a Ebl
   to handle the dispatch:  */

uint32_t
dwflst_arch_expected_frame_nregs (GElf_Half machine)
{
  /* For aarch64, we actually use fewer than ebl->frame_nregs to unwind:  */
  if (machine == EM_AARCH64)
    return 14;
  if (machine == EM_ARM)
    return 16;
  /* On x86, expect everything except FLAGS:  */
  if (machine == EM_X86_64 || machine == EM_386)
    /* XXX An external user of the library can't access the Ebl, hence
       can't conveniently provide it to us it here.  We provide the
       constant directly rather than initializing a new Ebl.  */
    return machine == EM_X86_64 ? 17 : 9;
    /* return ebl_frame_nregs(ebl); */
  /* XXX Other architectures are not supported yet.
     In general, it's fine to be on the permissive side here
     for a minimum expected number of registers.  */
  return 0;
}

int
dwflst_arch_sp_dwarf_reg (GElf_Half machine, bool force_abi32)
{
  switch (machine) {
  case EM_X86_64:
    return force_abi32 ? 4 : 7;
  case EM_386:
    return 4;
  case EM_ARM:
    return 13;
  case EM_AARCH64:
    return force_abi32 ? 13 : 31;
  default:
    /* XXX Other architectures are not supported yet.  */
    return -1;
  }
}

int
dwflst_arch_sp_perf_reg (GElf_Half machine,
			 uint64_t perf_regs_mask, bool is_abi32)
{
  int sp_perf_index;
  if (machine == EM_X86_64 || machine == EM_386)
    sp_perf_index = 7; /* uniform on 32/64-bit abi */
    /* compare backends/x86_initreg_sample.c;
       for dwarf_index, would be (is_abi32 ? 4 : 7) */
  else if (machine == EM_ARM || machine == EM_AARCH64)
    sp_perf_index = (is_abi32 ? 13 : 31);
    /* basic linear mapping of perf_regs<->dwarf_regs */
  else
    /* XXX Other architectures are not supported yet.  */
    return -1;

  if (perf_regs_mask == 0)
    /* Assume all registers present:  */
    return sp_perf_index;

  /* Iterate perf_regs_mask to find
     k == index of sp in perf_regs_mask
     j == index of sp in regs[]  */
  int j, k; uint64_t bit;
  for (k = 0, j = -1, bit = 1;
       k <= sp_perf_index; k++, bit <<= 1)
    {
      if ((bit & perf_regs_mask))
	j++;
      else
	continue; /* sp may not be present */
      if (k == sp_perf_index)
	return j;
    }
  return -2;
}

/* Stack sample handling:  */

struct sample_info {
  pid_t pid;
  pid_t tid;
  Dwarf_Addr base_addr;
  const uint8_t *stack;
  size_t stack_size;
  const Dwarf_Word *regs;
  uint n_regs;
  const int *regs_mapping;
  size_t n_regs_mapping;
  int elfclass;
  Dwarf_Addr pc;
};

/* The next few functions imitate the corefile interface for a single
   stack sample, with very restricted access to registers and memory. */

/* Just yield the single thread id matching the sample. */
static pid_t
sample_next_thread (Dwfl *dwfl __attribute__ ((unused)), void *dwfl_arg,
		    void **thread_argp)
{
  struct sample_info *sample_arg =
    (struct sample_info *)dwfl_arg;
  if (*thread_argp == NULL)
    {
      *thread_argp = (void *)0xea7b3375;
      return sample_arg->tid;
    }
  else
    return 0;
}

/* Just check that the thread id matches the sample. */
static bool
sample_getthread (Dwfl *dwfl __attribute__ ((unused)), pid_t tid,
		  void *dwfl_arg, void **thread_argp)
{
  struct sample_info *sample_arg =
    (struct sample_info *)dwfl_arg;
  *thread_argp = (void *)sample_arg;
  if (sample_arg->tid != tid)
    {
      __libdwfl_seterrno(DWFL_E_INVALID_ARGUMENT);
      return false;
    }
  return true;
}

#define copy_word_64(result, d) \
  if ((((uintptr_t) (d)) & (sizeof (uint64_t) - 1)) == 0) \
    *(result) = *(uint64_t *)(d); \
  else \
    memcpy ((result), (d), sizeof (uint64_t));

#define copy_word_32(result, d) \
  if ((((uintptr_t) (d)) & (sizeof (uint32_t) - 1)) == 0) \
    *(result) = *(uint32_t *)(d); \
  else \
    memcpy ((result), (d), sizeof (uint32_t));

#define copy_word(result, d, elfclass) \
  if ((elfclass) == ELFCLASS64)	\
    { copy_word_64((result), (d)); } \
  else if ((elfclass) == ELFCLASS32) \
    { copy_word_32((result), (d)); } \
  else \
    *(result) = 0;

static bool
elf_memory_read (Dwfl *dwfl, Dwarf_Addr addr, Dwarf_Word *result, void *arg)
{
  struct sample_info *sample_arg =
    (struct sample_info *)arg;
  Dwfl_Module *mod = INTUSE(dwfl_addrmodule) (dwfl, addr);
  Dwarf_Addr bias;
  Elf_Scn *section = INTUSE(dwfl_module_address_section) (mod, &addr, &bias);

  if (!section)
    {
      __libdwfl_seterrno(DWFL_E_ADDR_OUTOFRANGE);
      return false;
    }

  Elf_Data *data = elf_getdata(section, NULL);
  if (data && data->d_buf && data->d_size > addr) {
    uint8_t *d = ((uint8_t *)data->d_buf) + addr;
    copy_word(result, d, sample_arg->elfclass);
    return true;
  }
  __libdwfl_seterrno(DWFL_E_ADDR_OUTOFRANGE);
  return false;
}

static bool
sample_memory_read (Dwfl *dwfl, Dwarf_Addr addr, Dwarf_Word *result, void *arg)
{
  struct sample_info *sample_arg =
    (struct sample_info *)arg;
  /* Imitate read_cached_memory() with the stack sample data as the cache. */
  if (addr < sample_arg->base_addr ||
      addr - sample_arg->base_addr >= sample_arg->stack_size)
    return elf_memory_read(dwfl, addr, result, arg);
  const uint8_t *d = &sample_arg->stack[addr - sample_arg->base_addr];
  copy_word(result, d, sample_arg->elfclass);
  return true;
}


static bool
sample_set_initial_registers (Dwfl_Thread *thread, void *arg)
{
  struct sample_info *sample_arg =
    (struct sample_info *)arg;
  INTUSE(dwfl_thread_state_register_pc) (thread, sample_arg->pc);
  Dwfl_Process *process = thread->process;
  Ebl *ebl = process->ebl;
  return ebl_set_initial_registers_sample
    (ebl, sample_arg->regs, sample_arg->n_regs,
     sample_arg->regs_mapping, sample_arg->n_regs_mapping,
     __libdwfl_set_initial_registers_thread, thread);
}

static void
sample_detach (Dwfl *dwfl __attribute__ ((unused)), void *dwfl_arg)
{
  struct sample_info *sample_arg =
    (struct sample_info *)dwfl_arg;
  free (sample_arg);
}

static const Dwfl_Thread_Callbacks sample_thread_callbacks =
  {
    sample_next_thread,
    sample_getthread,
    sample_memory_read,
    sample_set_initial_registers,
    sample_detach,
    NULL, /* sample_thread_detach */
  };

int
dwflst_sample_getframes (Dwfl *dwfl, Elf *elf,
			 pid_t pid, pid_t tid,
			 const void *stack, size_t stack_size,
			 const Dwarf_Word *regs, uint n_regs,
			 const int *regs_mapping, size_t n_regs_mapping,
			 int (*callback) (Dwfl_Frame *state, void *arg),
			 void *arg)
{
  /* TODO: Lock the dwfl to ensure attach_state does not interfere
     with other dwfl_perf_sample_getframes calls. */

  struct sample_info *sample_arg;
  bool attached = false;
  if (dwfl->process != NULL)
    {
      sample_arg = dwfl->process->callbacks_arg;
      attached = true;
    }
  else
    {
      sample_arg = malloc (sizeof *sample_arg);
      if (sample_arg == NULL)
	{
	  __libdwfl_seterrno(DWFL_E_NOMEM);
	  return -1;
	}
    }

  sample_arg->pid = pid;
  sample_arg->tid = tid;
  sample_arg->stack = (const uint8_t *)stack;
  sample_arg->stack_size = stack_size;
  sample_arg->regs = regs;
  sample_arg->n_regs = n_regs;
  sample_arg->regs_mapping = regs_mapping;
  sample_arg->n_regs_mapping = n_regs_mapping;

  if (! attached
      && ! INTUSE(dwfl_attach_state) (dwfl, elf, pid,
				      &sample_thread_callbacks, sample_arg))
    {
      free(sample_arg);
      return -1;
    }

  Dwfl_Process *process = dwfl->process;
  Ebl *ebl = process->ebl;
  sample_arg->elfclass = ebl_get_elfclass(ebl);
  ebl_sample_sp_pc(ebl, regs, n_regs,
                   regs_mapping, n_regs_mapping,
                   &sample_arg->base_addr, &sample_arg->pc);

  return INTUSE(dwfl_getthread_frames) (dwfl, tid, callback, arg);
}

int
dwflst_perf_sample_getframes (Dwfl *dwfl, Elf *elf,
			      pid_t pid, pid_t tid,
			      const void *stack, size_t stack_size,
			      const Dwarf_Word *regs, uint32_t n_regs,
			      uint64_t perf_regs_mask, uint32_t abi,
			      int (*callback) (Dwfl_Frame *state, void *arg),
			      void *arg)
{
  /* TODO: Lock the dwfl to ensure attach_state does not interfere
     with other dwfl_perf_sample_getframes calls. */

  struct sample_info *sample_arg;
  bool attached = false;
  if (dwfl->process != NULL)
    {
      sample_arg = dwfl->process->callbacks_arg;
      attached = true;
    }
  else
    {
      sample_arg = malloc (sizeof *sample_arg);
      if (sample_arg == NULL)
	{
	  __libdwfl_seterrno(DWFL_E_NOMEM);
	  return -1;
	}
    }

  sample_arg->pid = pid;
  sample_arg->tid = tid;
  sample_arg->stack = (const uint8_t *)stack;
  sample_arg->stack_size = stack_size;
  sample_arg->regs = regs;
  sample_arg->n_regs = n_regs;

  if (! attached
      && ! INTUSE(dwfl_attach_state) (dwfl, elf, pid,
				      &sample_thread_callbacks, sample_arg))
    {
      free(sample_arg);
      return -1;
    }

  /* Select the regs_mapping based on architecture.  This will be
     cached in ebl to avoid having to recompute the regs_mapping array
     when perf_regs_mask is consistent for the entire session: */
  Dwfl_Process *process = dwfl->process;
  Ebl *ebl = process->ebl;
  if (!ebl_sample_perf_regs_mapping(ebl,
				    perf_regs_mask, abi,
				    &sample_arg->regs_mapping, &sample_arg->n_regs_mapping))
    {
      __libdwfl_seterrno(DWFL_E_LIBEBL_BAD);
      return -1;
    }
  sample_arg->elfclass = ebl_get_elfclass(ebl);
  ebl_sample_sp_pc(ebl, regs, n_regs,
                   sample_arg->regs_mapping, sample_arg->n_regs_mapping,
                   &sample_arg->base_addr, &sample_arg->pc);

  /* XXX May want to check if abi matches ebl_get_elfclass(ebl). */
  return INTUSE(dwfl_getthread_frames) (dwfl, tid, callback, arg);
}
