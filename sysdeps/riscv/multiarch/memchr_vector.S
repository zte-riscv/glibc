#include <sysdep.h>

.text
.p2align 2
ENTRY(__memchr_vector)

    beqz    a2, .Lnot_found
    andi    a1, a1, 0xFF

    li      t4, 64
    bltu    a2, t4, .Ltail_entry        
    
    vsetvli t0, t4, e8, m4, ta, ma

1:  
    vle8ff.v    v4, (a0)
    csrr        t1, vl
    vmseq.vx    v0, v4, a1
    vfirst.m    t3, v0
    bgez        t3, .Lvec_found
    add         a0, a0, t1
    sub         a2, a2, t1
    bgeu        a2, t4, 1b

    beqz    a2, .Lnot_found

.Ltail_entry:
    li      a3, 16
    bltu    a2, a3, .Ltail_vec_lm1

.Ltail_vec_lm2:
    vsetvli     t0, a2, e8, m2, ta, ma
    vle8ff.v    v4, (a0)
    csrr        t1, vl
    vmseq.vx    v0, v4, a1
    vfirst.m    t3, v0
    bgez        t3, .Lvec_found
    sub         a2, a2, t1
    add         a0, a0, t1
    beqz        a2, .Lnot_found     

.Ltail_vec_lm1:
    vsetvli     t0, a2, e8, m1, ta, ma
    vle8ff.v    v4, (a0)
    csrr        t1, vl
    vmseq.vx    v0, v4, a1
    vfirst.m    t3, v0
    bgez        t3, .Lvec_found
    sub         a2, a2, t1
    add         a0, a0, t1
    beqz        a2, .Lnot_found     

.Lbytewise_tail:
  
2:
    lbu     t1, (a0)
    beq     t1, a1, .Lfound_scalar
    addi    a0, a0, 1
    addi    a2, a2, -1
    bnez    a2, 2b
    j       .Lnot_found

.Lfound_scalar:
    ret

.Lvec_found:
    add     a0, a0, t3
    ret

.Lnot_found:
    li      a0, 0
    ret

END(__memchr_vector)