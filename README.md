# NASM + OpenGL demo

A tiny Windows GUI program written entirely in x86-64 assembly (NASM) that
opens a window, creates an OpenGL context, and draws a rotating RGB triangle.

No C runtime is linked — the entry point is hand-written assembly that calls
the Win32 and OpenGL APIs directly.

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
