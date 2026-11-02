# NASM + OpenGL demo

A tiny Windows GUI program written entirely in x86-64 assembly (NASM) that
opens a window, creates an OpenGL context, and draws a rotating RGB triangle.

No C runtime is linked — the entry point is hand-written assembly that calls
the Win32 and OpenGL APIs directly.

The assembly code itself is hand-written. Only the surrounding tooling, such
as the build script (`build.ps1`), and this documentation were made with
DeepSeek.

## Files

| File              | Purpose                                        |
|-------------------|------------------------------------------------|
| `ogl_triangle.asm`| NASM source (Win32 + OpenGL fixed-function)    |
| `build.ps1`       | Build script (assemble + link)                 |

## Requirements

- [NASM](https://www.nasm.us/) — `pacman -S mingw-w64-ucrt-x86_64-nasm`
- MinGW `gcc` (MSYS2) for linking

## Build

```powershell
.\build.ps1
```

## Run

```powershell
.\ogl_triangle.exe
```

Close the window to exit.

## How it works

`WinMain` registers a window class (`WNDCLASSEXA`) and creates a 640×640
window with `CreateWindowExA`. It then gets a device context with `GetDC`,
picks a double-buffered RGBA pixel format (`PIXELFORMATDESCRIPTOR`), and
makes an OpenGL context current with `wglCreateContext`/`wglMakeCurrent`.

The message loop pumps Win32 messages with `PeekMessageA`; when no message
is pending it calls `RenderScene`, which clears the colour buffer, advances
the rotation by a fixed step, and draws one triangle whose vertices are
coloured red, green, and blue. `SwapBuffers` presents each frame, throttled
with `Sleep(10)`, and `WM_DESTROY` triggers cleanup of the GL context.
