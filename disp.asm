section .text
global _get_xPosition
_get_xPosition:
	push rbp
	mov rbp,rsp
	movsd xmm0, [rdi+0x6b0]
	pop rbp
	ret
extern _baseAddress
extern _eventTapCallback
global _dispatchAsm
_dispatchAsm:
	push rbp
	mov rbp, rsp
	push rdi
	push rsi
	push rdx
	call _eventTapCallback

	call _baseAddress
	add rax, 0xe81a4
	
	pop rdx
	pop rsi
	pop rdi
	pop rbp

	push       rbp                                         ; CODE XREF=-[AppController ddhidJoystick:buttonDown:]+134, -[AppController ddhidJoystick:buttonUp:]+97, -[EAGLView keyDown:]+145, -[EAGLView keyUp:]+111
	mov        rbp, rsp
	push       r15
	push       r14
	push       r13
	push       r12
	push       rbx
	sub        rsp, 0x18
	mov r12d, edx

	jmp rax