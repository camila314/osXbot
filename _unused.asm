section .text
global _get_xPosition
_get_xPosition:
	push rbp
	mov rbp,rsp
	mov rbx, [rdi+0x670]
	movss xmm0, [rbx+0x1f4]
	pop rbp
	ret