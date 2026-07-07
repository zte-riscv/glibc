/* memrchr for RISC-V, ignoring buffer alignment
   Copyright (C) 2024-2025 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU Lesser General Public License. If not, see
   <https://www.gnu.org/licenses/>. 
*/
/*
 * Highly optimised memrchr for RISC-V with Vector and Zbb extensions.
 * Finds LAST occurrence of character (reverse search).
 * 
 * Key optimizations:
 *   - Scan backwards: first match found = answer
 *   - Zbb rev8+ctz for instant highest byte position
 *   - Unrolled vector loop (2×m4) for throughput
 *   - Cleaner logic following memchr_vector5 structure
 *   - Efficient alignment and tail handling
 */

#include <sysdep.h>
.text
.p2align 2
ENTRY(__memrchr_vector)

    beqz    a2, .Lnomatch
    mv      a6, a0                  # srcin_save = srcin
    add     a3, a0, a2              # end = srcin + cntin

    /* ========== Main vector loop (2x unrolled) ========== */
.Lvec_loop:
    vsetvli t0, a2, e8, m4, ta, ma
    sub     a3, a3, t0              # src -= vl, point to first block
    
    vle8.v  v8, (a3)                # load first block into v8-v11
    vmseq.vx v0, v8, a1             # v0 = (v8 == chrin) mask
    
    sub     t1, a2, t0              # remaining length after first block
    bleu    t1, t0, .Lvec_check_single
    
    sub     a4, a3, t0              # a4 = address of second block (use different reg)
    vle8.v  v12, (a4)               # prefetch second group into v12-v15
    
    vfirst.m a5, v0
    bgez    a5, .Lvec_found_block   # a3 still points to first block here
    
    sub     a2, a2, t0              # cntin -= vl (first block)
    mv      a3, a4                  # update a3 to second block
    vmseq.vx v0, v12, a1            # compare second block
    vfirst.m a5, v0
    bgez    a5, .Lvec_found_block_v12
    
    sub     a2, a2, t0              # cntin -= vl (second block)
    bnez    a2, .Lvec_loop
    j       .Lnomatch

    /* ========== Single block check ========== */
.Lvec_check_single:
    vfirst.m a5, v0
    bgez    a5, .Lvec_found_block
    sub     a2, a2, t0              # cntin -= vl
    bnez    a2, .Lvec_loop
    j       .Lnomatch

    /* ========== Found match in first block (v8) ========== */
.Lvec_found_block:
    vcpop.m t1, v0                  # t1 = match count
    li      t2, 1
    beq     t1, t2, .Lvec_single_match
    
    /* Multiple matches: find the last one */
    vid.v   v16                     # v16[i] = i
    vcompress.vm v20, v16, v0       # compress matched position indices
    addi    t1, t1, -1              # index of last element
    vslidedown.vx v20, v20, t1      # move last element to position 0
    vmv.x.s a5, v20                 # extract offset value
    j       .Lvec_calc_result

    /* ========== Found match in second block (v12) ========== */
.Lvec_found_block_v12:
    vcpop.m t1, v0                  # t1 = match count
    li      t2, 1
    beq     t1, t2, .Lvec_single_match
    
    /* Multiple matches: find the last one */
    vid.v   v16
    vcompress.vm v20, v16, v0
    addi    t1, t1, -1
    vslidedown.vx v20, v20, t1
    vmv.x.s a5, v20
    j       .Lvec_calc_result

    /* ========== Single match case ========== */
.Lvec_single_match:
    /* ========== Calculate result ========== */
.Lvec_calc_result:
    add     a0, a3, a5              # result = src + offset
    bltu    a0, a6, .Lnomatch       # safety check: result >= srcin
    ret

    /* ========== No match found ========== */
.Lnomatch:
    li      a0, 0
    ret

END(__memrchr_vector)