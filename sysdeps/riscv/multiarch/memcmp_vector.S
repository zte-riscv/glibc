

/* Optimised memcmp for riscv with vector extension
*/

#include <sysdep.h>            

.text
.p2align 2
ENTRY(__memcmp_vector)
    mv t2, zero
    beqz a2, .Ldone

    li          t1, 5            /* scalar path cheaper for 1-4 elts */
    bltu        a2, t1, .Lscalar

    /* main loop, vlenb*2 elts at a time */
    vsetvli     t1, a2, e8, m2, ta, ma

1:
    vle8.v      v2, (a0)        /* load elts */
    vle8.v      v4, (a1)
    vmsne.vv    v0, v2, v4      /* compare */
    vfirst.m    t3, v0
    bgez        t3, .Lvec_diff  /* found a difference ? */
    add         a0, a0, t1      /* not yet, advance everything */
    add         a1, a1, t1
    sub         a2, a2, t1
    bgeu        a2, t1, 1b

    bnez        a2, .Ltail
    mv          a0, zero
    ret

.Ltail:
    /* handle tail. we know a2 < vlenb*2 so just load and compare the lot */
    vsetvli     t1, a2, e8, m2, ta, ma
    vle8.v      v2, (a0)
    vle8.v      v4, (a1)
    vmsne.vv    v0, v2, v4
    vfirst.m    t3, v0
    bgez        t3, .Lvec_diff
    mv          a0, zero         /* no diff found */
    ret

.Lvec_diff:         /* v2, v4 differ at elt t3 */
    add a0, a0, t3
    add a1, a1, t3
    lbu t0, (a0)
    lbu t1, (a1)
    sub a0, t0, t1
    ret

.Lscalar:
    add  t3, a0, a2

1:
    lbu t0, (a0)
    lbu t1, (a1)
    sub t2, t0, t1
    bnez t2, .Ldone
    addi a0, a0, 1
    addi a1, a1, 1
    bltu a0, t3, 1b

.Ldone:
    mv a0, t2
    ret


END(__memcmp_vector)