#include <sysdep.h>

#define dstin   a0
#define val     a1
#define count   a2
#define valw    a1
#define dst     a3
#define dstend  a4
#define tmp1    a5
#define tmp2    a6


#define ZVA_THRESHOLD    256           
#define NT_THRESHOLD     (1*1024*1024)  

.text
.p2align 2
ENTRY(__memset_vector)

    andi    valw, valw, 0xff
    li      tmp1, 0x0101010101010101
    mul     val, valw, tmp1
    
    add     dstend, dstin, count

    li      tmp1, 96
    bgtu    count, tmp1, L_set_long
    li      tmp1, 16
    bgeu    count, tmp1, L_set_medium

    # --- Small Copy: 8 <= count < 16 ---
    andi    tmp1, count, 8
    beqz    tmp1, 1f
    sd      val, 0(dstin)
    sd      val, -8(dstend)
    ret

1:  andi    tmp1, count, 4
    beqz    tmp1, 2f
    sw      valw, 0(dstin)
    sw      valw, -4(dstend)
    ret

2:  beqz    count, 3f
    sb      valw, 0(dstin)
    andi    tmp1, count, 2
    beqz    tmp1, 3f
    sh      valw, -2(dstend)
3:  ret

L_set_medium:
    li      tmp2, 16
    vsetvli zero, tmp2, e8, m1, ta, ma
    vmv.v.x v0, valw
    
    vse8.v  v0, (dstin)
    andi    tmp1, count, 64
    bnez    tmp1, L_set96

    addi    tmp1, dstend, -16                       
    vse8.v  v0, (tmp1)
    andi    tmp1, count, 32                         
    beqz    tmp1, 1f

    addi    tmp1, dstin, 16                         
    vse8.v  v0, (tmp1)
    addi    tmp1, dstend, -32       
    vse8.v  v0, (tmp1)
1:  ret

    .p2align 4
L_set96:
    addi    tmp1, dstin, 16
    vse8.v  v0, (tmp1)
    addi    tmp1, dstin, 32
    vse8.v  v0, (tmp1)
    addi    tmp1, dstin, 48
    vse8.v  v0, (tmp1)
    addi    tmp1, dstend, -32
    vse8.v  v0, (tmp1)
    addi    tmp1, dstend, -16
    vse8.v  v0, (tmp1)
    ret

    .p2align 3
L_set_long:
    andi    dst, dstin, -16
    
    li      tmp2, 16
    vsetvli zero, tmp2, e8, m1, ta, ma
    vmv.v.x v0, valw
    
    vse8.v  v0, (dstin)
    addi    tmp1, dst, 16
    vse8.v  v0, (tmp1)

    li      tmp2, 32
    vsetvli zero, tmp2, e8, m2, ta, ma
    vmv.v.x v0, valw
    bnez    valw, L_no_zva

    li      tmp1, NT_THRESHOLD
    bgtu    count, tmp1, L_no_zva


L_zva_64:
    addi    tmp1, dst, 32
    vse8.v  v0, (tmp1)
    
    andi    dst, dstin, -64
    sub     count, dstend, dst
    addi    count, count, -(64 + 64)

    addi    tmp1, dstend, -64
    vse8.v  v0, (tmp1)
    
    addi    tmp1, dstend, -32
    vse8.v  v0, (tmp1)
    
    blez    count, 2f

    .p2align 3
1:  addi    dst, dst, 64
    cbo.zero (dst)
    addi    count, count, -64
    bgtz    count, 1b
2:  ret

    .p2align 3
L_no_zva:
    sub     count, dstend, dst
    addi    count, count, -(64 + 32)
    blez    count, L_tail64

    .p2align 3
1:  addi    tmp1, dst, 32
    vse8.v  v0, (tmp1)
   
    addi    tmp1, dst, 64
    vse8.v  v0, (tmp1)
    
    addi    dst, dst, 64
    addi    count, count, -64
    bgtz    count, 1b

L_tail64:
    addi    tmp1, dstend, -64
    vse8.v  v0, (tmp1)
   
    addi    tmp1, dstend, -32
    vse8.v  v0, (tmp1)
    
    ret

END(__memset_vector)