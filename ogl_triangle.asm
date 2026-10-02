;==============================================================================
; ogl_triangle.asm
;  x86-64 NASM + OpenGL (fixed-function) demo.
;
;  Opens a Win32 window, creates an OpenGL context, and renders a rotating
;  RGB triangle. Pure assembly: no C runtime is linked.
;
;  Build:
;    nasm -f win64 ogl_triangle.asm -o ogl_triangle.obj
;    gcc -m64 -nostartfiles -Wl,--subsystem,windows -Wl,-e,WinMain \
;        ogl_triangle.obj -o ogl_triangle.exe \
;        -lopengl32 -lgdi32 -luser32 -lkernel32
;
;  Calling convention (Windows x64): args in RCX,RDX,R8,R9, then stack;
;  32 bytes of shadow space; stack 16-byte aligned at each call site.
;==============================================================================

    bits 64
    default rel

    global WinMain

    ; ---- Win32 imports ----------------------------------------------------
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

    ; ---- OpenGL 1.1 imports (opengl32.dll) --------------------------------
    extern glClearColor
    extern glClear
    extern glLoadIdentity
    extern glRotatef
    extern glBegin
    extern glEnd
    extern glColor3f
    extern glVertex3f

;------------------------------------------------------------------------------
section .data

ClassName:  db "OGLAsmWindow", 0
Title:      db "NASM + OpenGL - rotating triangle", 0

; WNDCLASSEXA (80 bytes on x64)
wc:
    dd 80                    ; cbSize
    dd 0x00000023            ; style: CS_OWNDC | CS_HREDRAW | CS_VREDRAW
    dq WndProc               ; lpfnWndProc
    dd 0                     ; cbClsExtra
    dd 0                     ; cbWndExtra
    dq 0                     ; hInstance  (patched at runtime)
    dq 0                     ; hIcon
    dq 0                     ; hCursor
    dq 0                     ; hbrBackground
    dq 0                     ; lpszMenuName
    dq ClassName             ; lpszClassName
    dq 0                     ; hIconSm

; PIXELFORMATDESCRIPTOR (40 bytes)
pfd:
    dw 40                    ; nSize
    dw 1                     ; nVersion
    dd 0x00000025            ; dwFlags: PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL
                             ;          | PFD_DOUBLEBUFFER
    db 0                     ; iPixelType   = PFD_TYPE_RGBA
    db 32                    ; cColorBits
    db 0, 0, 0, 0            ; cRedBits, cRedShift, cGreenBits, cGreenShift
    db 0, 0, 0, 0            ; cBlueBits, cBlueShift, cAlphaBits, cAlphaShift
    db 0                     ; cAccumBits
    db 0, 0, 0, 0            ; cAccumRed/Green/Blue/AlphaBits
    db 24                    ; cDepthBits
    db 8                     ; cStencilBits
    db 0                     ; cAuxBuffers
    db 0                     ; iLayerType
    db 0                     ; bReserved
    dd 0                     ; dwLayerMask
    dd 0                     ; dwVisibleMask
    dd 0                     ; dwDamageMask

; Animation state
angle:      dd 0.0
angle_step: dd 0.6

; Float constants
f_one:      dd 1.0

; Vertex colours
c_red:   dd 1.0, 0.0, 0.0
c_green: dd 0.0, 1.0, 0.0
c_blue:  dd 0.0, 0.0, 1.0

; Triangle vertices (normalised device coords)
v0: dd  0.0,  0.85, 0.0
v1: dd -0.75, -0.75, 0.0
v2: dd  0.75, -0.75, 0.0

;------------------------------------------------------------------------------
section .bss

msg: resb 48                 ; MSG struct

;------------------------------------------------------------------------------
section .text

;------------------------------------------------------------------------------
; Window procedure
;   RCX = hwnd, RDX = uMsg, R8 = wParam, R9 = lParam
;------------------------------------------------------------------------------
WndProc:
    sub  rsp, 0x28
    cmp  edx, 0x0002          ; WM_DESTROY
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

;------------------------------------------------------------------------------
; Render one frame (GL context is already current)
;------------------------------------------------------------------------------
RenderScene:
    sub  rsp, 0x28

    mov  ecx, 0x00004000      ; GL_COLOR_BUFFER_BIT
    call glClear

    call glLoadIdentity

    ; angle += angle_step
    movss xmm0, [angle]
    addss xmm0, [angle_step]
    movss [angle], xmm0

    ; glRotatef(angle, 0, 0, 1)
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    movss xmm3, [f_one]
    call glRotatef

    mov  ecx, 0x0004          ; GL_TRIANGLES
    call glBegin

    ; red vertex
    movss xmm0, [c_red+0]
    movss xmm1, [c_red+4]
    movss xmm2, [c_red+8]
    call glColor3f
    movss xmm0, [v0+0]
    movss xmm1, [v0+4]
    movss xmm2, [v0+8]
    call glVertex3f

    ; green vertex
    movss xmm0, [c_green+0]
    movss xmm1, [c_green+4]
    movss xmm2, [c_green+8]
    call glColor3f
    movss xmm0, [v1+0]
    movss xmm1, [v1+4]
    movss xmm2, [v1+8]
    call glVertex3f

    ; blue vertex
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

;------------------------------------------------------------------------------
; Entry point (linked with -e WinMain, no CRT)
;------------------------------------------------------------------------------
WinMain:
    ; Frame: 168 bytes. 168 % 16 == 8, so RSP ends up 16-byte aligned.
    ;   [rsp+0x00..0x1F] shadow space
    ;   [rsp+0x78] hInstance
    ;   [rsp+0x80] hwnd
    ;   [rsp+0x88] hdc
    ;   [rsp+0x90] hglrc
    sub  rsp, 0xA8

    ; hInstance = GetModuleHandleA(NULL)
    xor  ecx, ecx
    call GetModuleHandleA
    mov  [wc+24], rax
    mov  [rsp+0x78], rax

    ; RegisterClassExA(&wc)
    lea  rcx, [wc]
    call RegisterClassExA
    test eax, eax
    jz   .fail

    ; CreateWindowExA(0, ClassName, Title, WS_OVERLAPPEDWINDOW,
    ;                 CW_USEDEFAULT, CW_USEDEFAULT, 640, 640,
    ;                 NULL, NULL, hInstance, NULL)
    xor  ecx, ecx
    lea  rdx, [ClassName]
    lea  r8,  [Title]
    mov  r9d, 0x00CF0000       ; WS_OVERLAPPEDWINDOW
    mov  dword [rsp+32], 0x80000000   ; x = CW_USEDEFAULT
    mov  dword [rsp+40], 0x80000000   ; y = CW_USEDEFAULT
    mov  dword [rsp+48], 640           ; width
    mov  dword [rsp+56], 640           ; height
    xor  eax, eax
    mov  [rsp+64], rax         ; hWndParent = NULL
    mov  [rsp+72], rax         ; hMenu = NULL
    mov  rax, [rsp+0x78]
    mov  [rsp+80], rax         ; hInstance
    xor  eax, eax
    mov  [rsp+88], rax         ; lpParam = NULL
    call CreateWindowExA
    test rax, rax
    jz   .fail
    mov  [rsp+0x80], rax       ; hwnd

    ; ShowWindow(hwnd, SW_SHOW)
    mov  rcx, rax
    mov  edx, 5
    call ShowWindow

    ; UpdateWindow(hwnd)
    mov  rcx, [rsp+0x80]
    call UpdateWindow

    ; ---- set up the OpenGL context --------------------------------------
    ; hdc = GetDC(hwnd)
    mov  rcx, [rsp+0x80]
    call GetDC
    mov  [rsp+0x88], rax

    ; ChoosePixelFormat(hdc, &pfd)
    mov  rcx, rax
    lea  rdx, [pfd]
    call ChoosePixelFormat

    ; SetPixelFormat(hdc, pf, &pfd)
    mov  rcx, [rsp+0x88]
    mov  edx, eax
    lea  r8,  [pfd]
    call SetPixelFormat

    ; hglrc = wglCreateContext(hdc)
    mov  rcx, [rsp+0x88]
    call wglCreateContext
    mov  [rsp+0x90], rax

    ; wglMakeCurrent(hdc, hglrc)
    mov  rcx, [rsp+0x88]
    mov  rdx, rax
    call wglMakeCurrent

    ; glClearColor(0, 0, 0, 1)
    xorps xmm0, xmm0
    xorps xmm1, xmm1
    xorps xmm2, xmm2
    movss xmm3, [f_one]
    call glClearColor

    ; ---- message loop with rendering ------------------------------------
.loop:
    ; PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE)
    lea  rcx, [msg]
    xor  edx, edx
    xor  r8d, r8d
    xor  r9d, r9d
    mov  dword [rsp+32], 1
    call PeekMessageA
    test eax, eax
    jz   .render

    ; a message is pending; quit if it is WM_QUIT
    mov  eax, [msg+8]
    cmp  eax, 0x0012           ; WM_QUIT
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
    mov  ecx, 10               ; throttle to ~100 fps
    call Sleep
    jmp  .loop

.cleanup:
    ; wglMakeCurrent(NULL, NULL)
    xor  ecx, ecx
    xor  edx, edx
    call wglMakeCurrent
    ; wglDeleteContext(hglrc)
    mov  rcx, [rsp+0x90]
    call wglDeleteContext
    ; ReleaseDC(hwnd, hdc)
    mov  rcx, [rsp+0x80]
    mov  rdx, [rsp+0x88]
    call ReleaseDC
    ; DestroyWindow(hwnd)
    mov  rcx, [rsp+0x80]
    call DestroyWindow

    xor  ecx, ecx
    call ExitProcess           ; exit 0

.fail:
    mov  ecx, 1
    call ExitProcess           ; exit 1
