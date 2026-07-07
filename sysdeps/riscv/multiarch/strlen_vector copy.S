#include <sysdep.h>
    .text
    .p2align 2
ENTRY(__strlen_vector)
    beqz    a0, .Lret0

    li      t2, 0                   

# ---------- Step 1: 对齐到 64 字节 ----------
    andi    t0, a0, 63              # t0 = src % 64
    beqz    t0, .Lset_main          
    
    neg     t0, t0
    andi    t0, t0, 63              

    vsetvli t1, t0, e8, m4, ta, ma  
    vle8.v      v4, (a0)
    vmseq.vi    v0, v4, 0           
    vfirst.m    t3, v0
    bgez        t3, .Lfound_head    

    add     a0, a0, t1              
    add     t2, t2, t1              

.Lset_main:
    vsetvli t1, zero, e8, m4, ta, ma 

    .p2align 3
.Lloop:
    vle8.v   v8, (a0)
    vmseq.vi v0, v8, 0
    vfirst.m t3, v0
    bgez     t3, .Lfound

    add      a0, a0, t1
    add      t2, t2, t1             
    j        .Lloop

.Lfound:
    add      a0, t2, t3             
    ret

.Lfound_head:
    mv       a0, t3                 
    ret

.Lret0:
    li       a0, 0
    ret
END(__strlen_vector)