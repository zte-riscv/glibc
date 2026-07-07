#include <sysdep.h>

.text
.p2align 2
ENTRY(__memchr_vector)

    beqz    a2, .Lnot_found

    li      t0, 0xFF
    and     a1, a1, t0
    
    andi    t3, a2, ~0x3f              
    beqz    t3, .Ltail_entry           
    add     t4, a0, t3    

    vsetvli t0, a2, e8, m4, ta, ma              

1:  
    vle8.v      v4, (a0)
    vmseq.vx    v0, v4, a1
    vfirst.m    t3, v0
    bgez        t3, .Lvec_found         
    add     a0, a0, t0                  
    bltu    a0, t4, 1b 
    andi    a2, a2, 0x3f                
    beqz    a2, .Lnot_found                 

   
.Ltail_entry:

    li      a3, 8
    bltu    a2, a3, .Lbytewise_tail
                 
                 
    vsetvli t0, a2, e8, m2, ta, ma
.LM2:
    vle8.v      v4, (a0)
    vmseq.vx    v0, v4, a1
    vfirst.m    t3, v0
    bgez        t3, .Lvec_found
    sub a2,a2,t0
    bgeu    a2, t0, .LM2
    beqz    a2, .Lnot_found                 # 向量尾部没找到，结束
    

#if __riscv_xlen == 64
.Lscalar:
    li      a3, 8
    bltu    a2, a3, .Lbytewise_tail     
    li      t1, 0x0101010101010101
    slli    a4, t1, 7
    mul     t2, a1, t1

.Lswar_aligned_loop:
    ld      t4, (a0)
    xor     t4, t4, t2
    sub     t5, t4, t1
    not     t4, t4
    and     t4, t5, t4
    and     t4, t4, a4
    bnez    t4, .Lswar_found

    add     a0, a0, 8
    addi     a2, a2, -8
    bgeu    a2, a3, .Lswar_aligned_loop

    beqz    a2, .Lnot_found             

.Lbytewise_tail:
1:
    lbu     t1, (a0)
    beq     t1, a1, .Lfound_scalar
    addi     a0, a0, 1
    addi     a2, a2, -1
    bgez      a2, 1b
    j       .Lnot_found

.Lswar_found:
    ctz     t5, t4
    srli    t5, t5, 3
    add     a0, a0, t5
    ret                             

.Lfound_scalar:
    ret

#else 
.Lscalar:
    j .Lbytewise_tail
#endif

.Lvec_found:
    add         a0, a0, t3
    ret
.Lfound:
    ret

.Lnot_found:
    li      a0, 0
    ret

END(__memchr_vector)