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

extern _routBoth
global _routAsm
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

_routAsm:
	push rbp
	mov rbp, rsp
	push rdi
	push rsi
	push rdx
	movss xmm10, xmm0
	call _routBoth

	call _baseAddress
	add rax, 0x78b7a
	
	movss xmm0, xmm10
	pop rdx
	pop rsi
	pop rdi
	pop rbp

	push       rbp                                         ; CODE XREF=_ZN9PlayLayer6updateEPvf+1599
	mov        rbp, rsp
	push       r14
	push       rbx
	sub        rsp, 0x10
	movss      dword [rbp-0x14], xmm0
	mov        rbx, rdi
	cmp        byte [rbx+0x700], 0x0

	jmp rax