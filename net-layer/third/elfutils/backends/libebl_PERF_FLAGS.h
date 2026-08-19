/* Linux perf_events sample_regs_user flags required for unwinding.
   Internal only; elfutils library users should use ebl_perf_frame_regs_mask().

   Copyright (C) 2025-2026 Red Hat, Inc.
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

#ifndef _LIBEBL_PERF_FLAGS_H
#define _LIBEBL_PERF_FLAGS_H 1

#if defined(__linux__)
/* XXX Need to exclude __linux__ arches without perf_regs.h. */
#if defined(__x86_64__) || defined(__i386__) || defined(__aarch64__) || defined(__arm__)
/* || defined(other_architecture)... */
# include <asm/perf_regs.h>
#endif
#endif

#if defined(_ASM_X86_PERF_REGS_H)
/* See the code in x86_initreg_sample.c for list of required regs and
   linux arch/.../include/asm/ptrace.h for matching pt_regs struct.  */
#define REG(R) (1ULL << PERF_REG_X86_ ## R)
/* FLAGS and segment regs are excluded from the following masks,
   since they're not needed for unwinding.  */
#define PERF_FRAME_REGISTERS_I386 (REG(AX) | REG(BX) | REG(CX) | REG(DX) \
  | REG(SI) | REG(DI) | REG(BP) | REG(SP) | REG(IP))
#define PERF_FRAME_REGISTERS_X86_64 (PERF_FRAME_REGISTERS_I386 | REG(R8) \
  | REG(R9) | REG(R10) | REG(R11) | REG(R12) | REG(R13) | REG(R14) | REG(R15))
/* Register ordering defined in linux arch/x86/include/uapi/asm/perf_regs.h;
   see the code in tools/perf/util/intel-pt.c intel_pt_add_gp_regs()
   and note how regs are added in the same order as the perf_regs.h enum.  */
#else
/* Since asm/perf_regs.h is absent, or gives the register layout for a
   different arch, we can't unwind i386 and x86_64 perf sample frames.  */
#define PERF_FRAME_REGISTERS_I386 0
#define PERF_FRAME_REGISTERS_X86_64 0
#endif /* _ASM_X86_PERF_REGS_H */

#if defined(_ASM_ARM_PERF_REGS_H)
#define REG(R) (1ULL << PERF_REG_ARM_ ## R)
/* Proper unwind set: callee-saved R4..R10, then R11 for FP, and SP,
   LR, PC. Collecting all 16 regs would also be feasible.  */
#define PERF_FRAME_REGISTERS_ARM (REG(R0) | REG(R1) | REG(R2) | REG(R3)  \
  | REG(R4) | REG(R5) | REG(R6) | REG(R7) | REG(R8) | REG(R9) | REG(R10) \
  | REG(FP) | REG(IP) | REG(SP) | REG(LR) | REG(PC))
/* Register ordering defined in linux arch/arm/include/uapi/asm/perf_regs.h.  */
#elif !defined(_ASM_ARM64_PERF_REGS_H)
/* Since asm/perf_regs.h is absent, or gives the register layout for a
   different arch, we can't unwind 32-bit ARM perf sample frames.  */
#define PERF_FRAME_REGISTERS_ARM 0
#endif /* _ASM_ARM_PERF_REGS_H */

#if defined(_ASM_ARM64_PERF_REGS_H)
#define REG(R) (1ULL << PERF_REG_ARM64_ ## R)
/* Proper unwind set: callee-saved X19..X28, then X29 for FP,
   LR for return addr, and SP, PC.  */
#define PERF_FRAME_REGISTERS_AARCH64 (REG(X19) | REG(X20) | REG(X21) \
  | REG(X22) | REG(X23) | REG(X24) | REG(X25) | REG(X26) | REG(X27)  \
  | REG(X28) | REG(X29) /*FP*/ | REG(LR) | REG(SP) | REG(PC))
/* Register ordering defined in linux arch/arm64/include/uapi/asm/perf_regs.h.  */

/* Likewise, for 32bit-on-64bit compat mode:  */
#define PERF_FRAME_REGISTERS_ARM (REG(X0) | REG(X1) | REG(X2) | REG(X3)   \
  | REG(X4) | REG(X5) | REG(X6) | REG(X7) | REG(X8) | REG(X9) | REG(X10)  \
  | REG(X11) /* FP */ | REG(X12) /* IP */ /* | skip X13..X29 */ | REG(LR) \
  | REG(SP) | REG(PC))
/* XXX Then the profiler likely needs to be instructed to request the
   intersection of these register sets rather than just
   PERF_FRAME_REGISTERS_AARCH64.  Thus, in aarch64_init.c, we have:

   eh->perf_frame_regs_mask = PERF_FRAME_REGISTERS_AARCH64
       | PERF_FRAME_REGISTERS_ARM;
*/
#else
/* Since asm/perf_regs.h is absent, or gives the register layout for a
   different arch, we can't unwind aarch64 perf sample frames.  */
#define PERF_FRAME_REGISTERS_AARCH64 0
#endif /* _ASM_ARM64_PERF_REGS_H */

static inline bool
generic_sample_sp_pc (const Dwarf_Word *regs, uint32_t n_regs,
		      const int *regs_mapping, size_t n_regs_mapping,
		      Dwarf_Word *sp, uint sp_index /* into dwarf_regs */,
		      Dwarf_Word *pc, uint pc_index /* into dwarf_regs */)
{
  if (sp != NULL) *sp = 0;
  if (pc != NULL) *pc = 0;
  /* TODO: Register locations could be cached and rechecked on a
     fastpath without needing to loop, though the overhead reduction
     is minimal.  */
  int need_sp = (sp != NULL), need_pc = (pc != NULL);
  for (size_t j = 0; (need_sp || need_pc) && n_regs_mapping > j; j++)
    {
      if (n_regs <= (uint32_t)j) break;
      if (need_sp && regs_mapping[j] == (int)sp_index)
	{
	  *sp = regs[j]; need_sp = false;
	}
      if (need_pc && regs_mapping[j] == (int)pc_index)
	{
	  *pc = regs[j]; need_pc = false;
	}
    }
  return (!need_sp && !need_pc);
}

#endif	/* libebl_PERF_FLAGS.h */
