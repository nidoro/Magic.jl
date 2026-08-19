/* Get Dwarf Frame state from modules present in DWFL.
   Copyright (C) 2013 Red Hat, Inc.
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

#include "libdwflP.h"

bool
dwfl_thread_state_registers (Dwfl_Thread *thread, int firstreg,
			     unsigned nregs, const Dwarf_Word *regs)
{
  Dwfl_Frame *state = thread->unwound;
  assert (state && state->unwound == NULL);
  assert (state->initial_frame);

  if (firstreg == -2 && nregs == 1) {
    thread->aarch64.pauth_insn_mask = regs[0];
    return true;
  }

  for (unsigned regno = firstreg; regno < firstreg + nregs; regno++)
    if (! __libdwfl_frame_reg_set (state, regno, regs[regno - firstreg]))
      {
	__libdwfl_seterrno (DWFL_E_INVALID_REGISTER);
	return false;
      }
  return true;
}
INTDEF(dwfl_thread_state_registers)

void
dwfl_thread_state_register_pc (Dwfl_Thread *thread, Dwarf_Word pc)
{
  Dwfl_Frame *state = thread->unwound;
  assert (state && state->unwound == NULL);
  assert (state->initial_frame);
  state->pc = pc;
  state->pc_state = DWFL_FRAME_STATE_PC_SET;
}
INTDEF(dwfl_thread_state_register_pc)

int
dwfl_frame_reg (Dwfl_Frame *state, unsigned regno, Dwarf_Word *val)
{
  int res = __libdwfl_frame_reg_get (state, regno, val);
  if (res == -1)
      __libdwfl_seterrno (DWFL_E_INVALID_REGISTER);
  else if (res == 1)
      __libdwfl_seterrno (DWFL_E_REGISTER_VAL_UNKNOWN);
  return res;
}
INTDEF(dwfl_frame_reg)

/* Implement the ebl_set_initial_registers_tid setfunc callback.  */

bool
/* Not internal_function, since that allows calling-convention changes
   e.g. on i386, and stable ABI is needed to use this as an
   ebl_tid_registers_t * callback in linux-pid-attach.c and
   libdwfl_stacktrace.  */
__libdwfl_set_initial_registers_thread (int firstreg, unsigned nregs,
				   const Dwarf_Word *regs, void *arg)
{
  Dwfl_Thread *thread = (Dwfl_Thread *) arg;
  if (firstreg == -1)
    {
      assert (nregs == 1);
      INTUSE(dwfl_thread_state_register_pc) (thread, *regs);
      return true;
    }
  else if (firstreg == -2)
    {
      assert (nregs == 1);
      INTUSE(dwfl_thread_state_registers) (thread, firstreg, nregs, regs);
      return true;
     }
  assert (nregs > 0);
  return INTUSE(dwfl_thread_state_registers) (thread, firstreg, nregs, regs);
}
