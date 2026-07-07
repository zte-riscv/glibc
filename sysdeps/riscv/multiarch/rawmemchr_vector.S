
#include <sysdep.h>            /* 提供 ENTRY/END 宏 */
.text
.p2align 2
ENTRY (__rawmemchr_vector)
	# a0 = str 
	# a1 = c
	beqz	a1, L(do_strlen)
	li	a2, -1
	tail	memchr		

L(do_strlen):
	
	addi	sp, sp, -16
	sd	ra, 8(sp)   
	sd	s0, 0(sp)   

	mv	s0, a0     
	call	strlen

	add	a0, s0, a0

	ld	s0, 0(sp)   
	ld	ra, 8(sp)   
	addi	sp, sp, 16  

	ret

END(__rawmemchr_vector)
