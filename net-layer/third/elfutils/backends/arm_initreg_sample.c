/* Populate process registers from a register sample.
   Copyright (C) 2026 Red Hat Inc.
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

#define BACKEND arm_
#include "libebl_CPU.h"
#include "libebl_PERF_FLAGS.h"

bool
arm_sample_sp_pc (const Dwarf_Word *regs, uint32_t n_regs,
		  const int *regs_mapping, size_t n_regs_mapping,
		  Dwarf_Word *sp, Dwarf_Word *pc)
{
  return generic_sample_sp_pc (regs, n_regs, regs_mapping, n_regs_mapping,
			       sp, 13 /* index of sp in dwarf_regs */,
			       pc, 15 /* index of pc in dwarf_regs */);
}

/* XXX The default ebl_set_initial_registers_sample implementation can
   be used -- whereas the ptrace code in arm_initreg.c has to unpack a
   register file of 32-bit words into a Dwarf_Word array, here we
   should already be provided an appropriately-packed array
   originating from perf_events.  */
