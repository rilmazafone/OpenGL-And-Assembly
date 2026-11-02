    bits 64
    default rel

    global WinMain

    extern GetModuleHandleA
    extern RegisterClassExA
    extern CreateWindowExA
    extern ShowWindow
    extern UpdateWindow
    extern GetDC
    extern ReleaseDC
    extern ChoosePixelFormat
    extern SetPixelFormat
    extern wglCreateContext
    extern wglMakeCurrent
    extern wglDeleteContext
    extern SwapBuffers
    extern DestroyWindow
    extern DefWindowProcA
    extern PeekMessageA
    extern TranslateMessage
    extern DispatchMessageA
    extern PostQuitMessage
    extern Sleep
    extern ExitProcess

    extern glClearColor
    extern glClear
    extern glLoadIdentity
    extern glRotatef
    extern glBegin
    extern glEnd
    extern glColor3f
    extern glVertex3f

section .data

ClassName:  db "OGLAsmWindow", 0
Title:      db "NASM + OpenGL - rotating triangle", 0

wc:
    dd 80
    dd 0x00000023
    dq WndProc
    dd 0
    dd 0
    dq 0
    dq 0
    dq 0
    dq 0
    dq 0
    dq ClassName
    dq 0

pfd:
    dw 40
    dw 1
    dd 0x00000025
    db 0
    db 32
    db 0, 0, 0, 0
    db 0, 0, 0, 0
    db 0
    db 0, 0, 0, 0
    db 24
    db 8
    db 0
    db 0
    db 0
    dd 0
    dd 0
    dd 0

angle:      dd 0.0
angle_step: dd 0.6

f_one:      dd 1.0

c_red:   dd 1.0, 0.0, 0.0
c_green: dd 0.0, 1.0, 0.0
c_blue:  dd 0.0, 0.0, 1.0

v0: dd  0.0,  0.85, 0.0
v1: dd -0.75, -0.75, 0.0
v2: dd  0.75, -0.75, 0.0

section .bss

msg: resb 48

section .text

WndProc:
    sub  rsp, 0x28
    cmp  edx, 0x0002
    je   .destroy
    call DefWindowProcA
    add  rsp, 0x28
    ret
.destroy:
    xor  ecx, ecx
    call PostQuitMessage
    xor  eax, eax
    add  rsp, 0x28
    ret

RenderScene:
    sub  rsp, 0x28

    mov  ecx, 0x00004000
    call glClear

    call glLoadIdentity

    movss xmm0, [angle]
    addss xmm0, [angle_step]
    movss [angle], xmm0

    xorps xmm1, xmm1
    xorps xmm2, xmm2
    movss xmm3, [f_one]
    call glRotatef

    mov  ecx, 0x0004
    call glBegin

    movss xmm0, [c_red+0]
    movss xmm1, [c_red+4]
    movss xmm2, [c_red+8]
    call glColor3f
    movss xmm0, [v0+0]
    movss xmm1, [v0+4]
    movss xmm2, [v0+8]
    call glVertex3f

    movss xmm0, [c_green+0]
    movss xmm1, [c_green+4]
    movss xmm2, [c_green+8]
    call glColor3f
    movss xmm0, [v1+0]
    movss xmm1, [v1+4]
    movss xmm2, [v1+8]
    call glVertex3f

    movss xmm0, [c_blue+0]
    movss xmm1, [c_blue+4]
    movss xmm2, [c_blue+8]
    call glColor3f
    movss xmm0, [v2+0]
    movss xmm1, [v2+4]
    movss xmm2, [v2+8]
    call glVertex3f

    call glEnd

    add  rsp, 0x28
    ret

WinMain:
    sub  rsp, 0xA8

    xor  ecx, ecx
    call GetModuleHandleA
    mov  [wc+24], rax
    mov  [rsp+0x78], rax

    lea  rcx, [wc]
    call RegisterClassExA
    test eax, eax
    jz   .fail

    xor  ecx, ecx
    lea  rdx, [ClassName]
    lea  r8,  [Title]
    mov  r9d, 0x00CF0000
    mov  dword [rsp+32], 0x80000000
    mov  dword [rsp+40], 0x80000000
    mov  dword [rsp+48], 640
    mov  dword [rsp+56], 640
    xor  eax, eax
    mov  [rsp+64], rax
    mov  [rsp+72], rax
    mov  rax, [rsp+0x78]
    mov  [rsp+80], rax
    xor  eax, eax
    mov  [rsp+88], rax
    call CreateWindowExA
    test rax, rax
    jz   .fail
    mov  [rsp+0x80], rax

    mov  rcx, rax
    mov  edx, 5
    call ShowWindow

    mov  rcx, [rsp+0x80]
    call UpdateWindow

    mov  rcx, [rsp+0x80]
    call GetDC
    mov  [rsp+0x88], rax

    mov  rcx, rax
    lea  rdx, [pfd]
    call ChoosePixelFormat

    mov  rcx, [rsp+0x88]
    mov  edx, eax
    lea  r8,  [pfd]
    call SetPixelFormat

    mov  rcx, [rsp+0x88]
    call wglCreateContext
    mov  [rsp+0x90], rax

    mov  rcx, [rsp+0x88]
    mov  rdx, rax
    call wglMakeCurrent

    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    movss xmm3, [f_one]
    call glClearColor

.loop:
    lea  rcx, [msg]
    xor  edx, edx
    xor  r8d, r8d
    xor  r9d, r9d
    mov  dword [rsp+32], 1
    call PeekMessageA
    test eax, eax
    jz   .render

    mov  eax, [msg+8]
    cmp  eax, 0x0012
    je   .cleanup
    lea  rcx, [msg]
    call TranslateMessage
    lea  rcx, [msg]
    call DispatchMessageA
    jmp  .loop

.render:
    call RenderScene
    mov  rcx, [rsp+0x88]
    call SwapBuffers
    mov  ecx, 10
    call Sleep
    jmp  .loop

.cleanup:
    xor  ecx, ecx
    xor  edx, edx
    call wglMakeCurrent
    mov  rcx, [rsp+0x90]
    call wglDeleteContext
    mov  rcx, [rsp+0x80]
    mov  rdx, [rsp+0x88]
    call ReleaseDC
    mov  rcx, [rsp+0x80]
    call DestroyWindow

    xor  ecx, ecx
    call ExitProcess

.fail:
    mov  ecx, 1
    call ExitProcess
