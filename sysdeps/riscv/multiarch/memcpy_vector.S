/* Optimised memcpy for riscv with vector extension */
#include <sysdep.h>
.text
.p2align 2

ENTRY (__memcpy_vector)
    beqz    a2, .Ldone
    mv      t6, a0
    
    li      t2, 128
    bgtu    a2, t2, L(copy_long)      # count > 128
    
    li      t4, 32
    bgtu    a2, t4, L(copy32_128)     # count > vlen * 2

    
    # --- Small Copy: 0..vlen*2 bytes ---
L(small):
    vsetvli t2, a2, e8, m2, ta, ma    
    vle8.v  v2, (a1)                   
    vse8.v  v2, (a0)                   
    j       .Ldone_ret



    # --- Medium Copy: 33..128 bytes ---
L(copy32_128):
    add     t0, a1, a2                # srcend = src + count
    add     t1, a0, a2                # dstend = dstin + count
    
 
    vsetvli zero, a2, e8, m4, ta, ma

    vle8.v  v4, (a1)
    
    li      t4, 64
    vse8.v  v4, (a0)
    
    bgtu    a2, t4, L(copy128)        # count > 64
    j       .Ldone_ret

    # --- Copy 65..128 bytes ---
L(copy128):
    addi    t4, t0, -64
    vle8.v  v8, (t4)
    addi    t4, t1, -64
    vse8.v  v8, (t4)
    j       .Ldone_ret

    

    # --- Long Copy: > 128 bytes ---
    .p2align 4
L(copy_long):
    add     t0, a1, a2                # srcend
    add     t1, a0, a2                # dstend


    vsetivli zero, 16, e8, m1, ta, ma
    vle8.v  v3, (a1)                  # ldr D_q, [src]

    # ----------align to 15 ----------
    andi    t2, a1, 15                # tmp1 = src & 15

    li      t3, 16
    sub     t3, t3, t2                
    add     a1, a1, t3               
    add     a3, a0, t3               
    sub     a2, a2, t3               

    vse8.v  v3, (a0)                  # str D_q, [dstin]
    
    vsetvli zero, a2, e8, m2, ta, ma
    vle8.v  v0, (a1)                  # A_q B_q
   
    addi    t4, a1, 32
    vle8.v  v2, (t4)                  # C_q D_q
    
    li      t4, 128                   # 128
    sub     a2, a2, t4
    blez    a2, L(copy64_from_end)

L(loop64):

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
    bgtz    a2, L(loop64)

L(copy64_from_end):

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
    mv      a0, t6
    ret
       
.Ldone:
    ret

END (__memcpy_vector)