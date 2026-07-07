/* Enumerate available IFUNC implementations of a function.  RISCV version.
   Copyright (C) 2024 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */

#include <ifunc-impl-list.h>
#include <string.h>
#include <sys/hwprobe.h>

size_t
__libc_ifunc_impl_list (const char *name, struct libc_ifunc_impl *array,
			size_t max)
{
  size_t i = max;

  bool fast_unaligned = false;
  bool v_ext = false;

  struct riscv_hwprobe pair = { .key = RISCV_HWPROBE_KEY_CPUPERF_0 };
  if (__riscv_hwprobe (&pair, 1, 0, NULL, 0) == 0
      && (pair.value & RISCV_HWPROBE_MISALIGNED_MASK)
          == RISCV_HWPROBE_MISALIGNED_FAST)
    fast_unaligned = true;

  pair.key = RISCV_HWPROBE_KEY_IMA_EXT_0;
  pair.value = 0;
  if (__riscv_hwprobe (&pair, 1, 0, NULL, 0) == 0
      && (pair.value & RISCV_HWPROBE_IMA_V) == RISCV_HWPROBE_IMA_V)
    v_ext = true;

  IFUNC_IMPL (i, name, memcpy,
	      IFUNC_IMPL_ADD (array, i, memcpy, fast_unaligned,
			      __memcpy_noalignment)
	      IFUNC_IMPL_ADD (array, i, memcpy, v_ext, __memcpy_vector)
	      IFUNC_IMPL_ADD (array, i, memcpy, 1, __memcpy_generic))

  IFUNC_IMPL (i, name, memset,
	      IFUNC_IMPL_ADD (array, i, memset, v_ext,
			      __memset_vector)
	      IFUNC_IMPL_ADD (array, i, memset, 1, __memset_generic))

  IFUNC_IMPL (i, name, memchr,
              IFUNC_IMPL_ADD (array, i, memchr, v_ext,
                              __memchr_vector)
              IFUNC_IMPL_ADD (array, i, memchr, 1, __memchr_generic))

  IFUNC_IMPL (i, name, memrchr,
              IFUNC_IMPL_ADD (array, i, memrchr, v_ext,__memrchr_vector)
              IFUNC_IMPL_ADD (array, i, memrchr, 1, __memrchr_generic))

  IFUNC_IMPL (i, name, rawmemchr,
              IFUNC_IMPL_ADD (array, i, rawmemchr, v_ext,
                              __rawmemchr_vector))

  IFUNC_IMPL (i, name, memmove,
              IFUNC_IMPL_ADD (array, i, memmove, v_ext,
                              __memmove_vector)
              IFUNC_IMPL_ADD (array, i, memmove, 1, __memmove_generic))

  IFUNC_IMPL (i, name, memcmp,
              IFUNC_IMPL_ADD (array, i, memcmp, v_ext,
                              __memcmp_vector)
             IFUNC_IMPL_ADD (array, i, memcmp, 1, __memcmp_generic))

  IFUNC_IMPL (i, name, strlen,
              IFUNC_IMPL_ADD (array, i, strlen, v_ext,
                              __strlen_vector)
              IFUNC_IMPL_ADD (array, i, strlen, 1, __strlen_generic))

  return 0;
}
