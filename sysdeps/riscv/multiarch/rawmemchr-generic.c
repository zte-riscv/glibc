/* Re-include the default memcpy implementation.
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

#include <string.h>

/* 1. 修复拼写错误：从 RAWMEMRCHR 改为 RAWMEMCHR */
#define RAWMEMCHR __rawmemchr_generic

#if IS_IN(libc)
/* 2. 取消定义 libc_hidden_builtin_def，防止生成默认的 hidden alias */
# undef libc_hidden_builtin_def
# define libc_hidden_builtin_def(x)

/* 3. 取消定义 weak_alias，防止它试图再次生成 rawmemchr 的弱别名（会导致符号冲突） */
# undef weak_alias
# define weak_alias(name, aliasname)
#endif

#include <string/rawmemchr.c>

/* 4. 手动为 generic 版本生成 hidden definition，以便 libc 内部可以调用它 */
#if IS_IN(libc)
libc_hidden_def (__rawmemchr_generic)
#endif
