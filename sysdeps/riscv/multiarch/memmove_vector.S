/* Optimized memcpy/memmove using LMUL=8 (vl8r) and Vectorized Tail */
#include <sysdep.h>

.text
.p2align 2
ENTRY(__memmove_vector)

    beqz    a2, .Ldone
    mv      a6, a0
    
    li      t2, 128
    bgtu    a2, t2, .Lcopy_long      # count > 128
    
    li      t4, 32
    bgtu    a2, t4, .Lcopy32_128     # count > vlen * 2

    
    # --- Small Copy: 0..vlen*2 bytes ---
.Lsmall:
    vsetvli t2, a2, e8, m1, ta, ma    
    
    vle8.v  v1, (a1)                   
    
    add     t1, a1, a2                 
    sub     t1, t1, t2                 
    vle8.v  v2, (t1)                   

    add     t0, a0, a2                   
    sub     t0, t0, t2                 
    
    vse8.v  v1, (a0)                   
    vse8.v  v2, (t0)                  

    j       .Ldone_ret


    # --- Medium Copy: 33..128 bytes ---
.Lcopy32_128:
    add     t0, a1, a2                # srcend = src + count
    add     t1, a0, a2                # dstend = dstin + count
    
    vsetvli zero, a2, e8, m2, ta, ma

    vle8.v  v0, (a1)
    addi    t4, t0, -32
    vle8.v  v2, (t4)
    li      t4, 64
    bgtu    a2, t4, .Lcopy128        # count > 64
    
    vse8.v  v0, (a0)
    addi    t4, t1, -32
    vse8.v  v2, (t4)
    j       .Ldone_ret

    # --- Copy 65..128 bytes ---
.Lcopy128:

    addi    t4, a1, 32
    vle8.v  v4, (t4)
    li      t4, 96
    bleu    a2, t4, .Lcopy96         # count <= 96
    
    addi    t4, t0, -64
    vle8.v  v6, (t4)
    addi    t4, t1, -64
    vse8.v  v6, (t4)

.Lcopy96:
    vse8.v  v0, (a0)                  # stp A, B
    addi    t4, a0, 32                # stp E, F
    vse8.v  v4, (t4)
    addi    t4, t1, -32               # stp C, D
    vse8.v  v2, (t4)
    j       .Ldone_ret

.Lcopy_long:
    add     t0, a1, a2                # srcend
    add     t1, a0, a2                # dstend

    sub     t3, a0, a1                 # t3 = dst - src
    beqz    t3, .Lreturn               # dst == src
    bleu    t3, a2, .Lmove_long        # 0 < t3 <= len
    
    # ---------- align 16 ----------
    andi    t2, a1, 15              # t0 = a1 & 15     (0 ~ 15)
    li      t3, 16
    sub     t2, t3, t2              # t0 = 16 - (a1 & 15)   → 1~16
    
    vsetvli zero, t2, e8, m1, ta, ma  
    vle8.v  v3, (a1)
    add     a1, a1, t2                # src += offset
    add     a3, a0, t2                # a3 = dst + offset 
    sub     a2, a2, t2                # len -= offset
    vse8.v  v3, (a0)

    vsetvli zero, a2, e8, m2, ta, ma
    vle8.v  v0, (a1)                  # A_q B_q
   
    addi    t4, a1, 32
    vle8.v  v2, (t4)                  # C_q D_q
    
    li      t4, 128                   # 128
    sub     a2, a2, t4
    blez    a2, .Lcopy64_from_end

.Lloop64:

    vse8.v  v0, (a3)                # A_q B_q
   
    addi    t4, a1, 64
    vle8.v  v0, (t4)

    addi    t4, a3, 32
    vse8.v  v2, (t4)

    addi    t4, a1, 96
    vle8.v  v2, (t4)
 
    addi    a1, a1, 64
    addi    a3, a3, 64
    addi    a2, a2, -64
    bgtz    a2, .Lloop64

.Lcopy64_from_end:

    addi    t4, t0, -64
    vle8.v  v4, (t4)                  # E_q # F_q

    vse8.v  v0, (a3)                  # A_q B_q

    addi    t4, t0, -32
    vle8.v  v0, (t4)                  
              
    addi    t4, a3, 32                # C_q D_q
    vse8.v  v2, (t4)                  
               
    addi    t4, t1, -64
    vse8.v  v4, (t4)

    addi    t4, t1, -32
    vse8.v  v0, (t4)

    j       .Ldone_ret

.Ldone_ret:
    mv      a0, a6
    ret
       
.Ldone:
    ret

.Lmove_long:
    beq     a0, a1, .Lreturn

    add     t3, a1, a2                # srcend
    add     t4, a0, a2                # dstend

    # ----------align srcend  ----------
    andi    t2, t3, 15
    beqz    t2, 1f
    
    vsetvli zero, t2, e8, m1, ta, ma  
    sub     t3, t3, t2                
    vle8.v  v0, (t3)                  
    sub     t4, t4, t2                
    vse8.v  v0, (t4)                  
    sub     a2, a2, t2                

    # ----------  64  ----------
    vsetvli zero, a2, e8, m2, ta, ma
    addi    t6, t3, -32
    vle8.v  v4, (t6)       
    addi    t6, t3, -64
    vle8.v  v6, (t6)      

    li      t5, 128
    sub     a2, a2, t5
    blez    a2, .Llast64_backwards

    # ----------  ----------
.Lloop64_backwards:
    addi    t6, t4, -32
    vse8.v  v4, (t6)

    addi    t6, t3, -96
    vle8.v  v4, (t6)

    addi    t6, t4, -64
    vse8.v  v6, (t6)

    addi    t6, t3, -128
    vle8.v  v6, (t6)

    addi    t3, t3, -64
    addi    t4, t4, -64
    addi    a2, a2, -64
    bgtz    a2, .Lloop64_backwards
    
.Llast64_backwards:

    vle8.v  v8, (a1)
    addi    t6, a1, 32
    vle8.v  v10, (t6)

    addi    t6, t4, -32
    vse8.v  v4, (t6)
    addi    t6, t4, -64
    vse8.v  v6, (t6)
    
    vse8.v  v8, (a0)
    addi    t6, a0, 32
    vse8.v  v10, (t6)

.Lreturn:
    mv      a0, a6
    ret


END(__memmove_vector)