/* Multiple versions of memcpy.
   All versions must be listed in ifunc-impl-list.c.
   Copyright (C) 2017-2024 Free Software Foundation, Inc.
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

#if IS_IN (libc)
# undef rawmemchr
# define rawmemchr __redirect_rawmemchr
/* 同时需要重定向 __rawmemchr */
# undef __rawmemchr
# define __rawmemchr __redirect___rawmemchr

# include <stdint.h>
# include <string.h>
# include <ifunc-init.h>
# include <riscv-ifunc.h>
# include <sys/hwprobe.h>

extern __typeof (__redirect_rawmemchr) __libc_rawmemchr;
extern __typeof (__redirect_rawmemchr) __rawmemchr_vector attribute_hidden;

static inline __typeof (__redirect_rawmemchr) *
select_rawmemchr_ifunc (uint64_t dl_hwcap, __riscv_hwprobe_t hwprobe_func)
{
  unsigned long long int v;
  if (__riscv_hwprobe_one (hwprobe_func, RISCV_HWPROBE_KEY_IMA_EXT_0, &v) == 0
      && (v & RISCV_HWPROBE_IMA_V) == RISCV_HWPROBE_IMA_V)
    return __rawmemchr_vector;

  return __libc_rawmemchr;
}

riscv_libc_ifunc (__libc_rawmemchr, select_rawmemchr_ifunc);

# undef rawmemchr
strong_alias (__libc_rawmemchr, rawmemchr);
# undef __rawmemchr
strong_alias (__libc_rawmemchr, __rawmemchr);

# ifdef SHARED
__hidden_ver1 (rawmemchr, __GI_rawmemchr, __redirect_rawmemchr)
  __attribute__ ((visibility ("hidden"))) __attribute_copy__ (rawmemchr);
__hidden_ver1 (__rawmemchr, __GI___rawmemchr, __redirect___rawmemchr)
  __attribute__ ((visibility ("hidden"))) __attribute_copy__ (__rawmemchr);
# endif

#else
# include <string/rawmemchr.c>
#endif
