# Build ogl_triangle.asm -> ogl_triangle.exe
$ErrorActionPreference = 'Stop'

# Locate nasm (on PATH, or in the MSYS2 UCRT64 tree)
$nasm = (Get-Command nasm -ErrorAction SilentlyContinue).Source
if (-not $nasm -and (Test-Path 'C:\msys64\ucrt64\bin\nasm.exe')) {
    $nasm = 'C:\msys64\ucrt64\bin\nasm.exe'
}
if (-not $nasm) {
    throw 'nasm not found. Install it with: pacman -S mingw-w64-ucrt-x86_64-nasm'
}

# Locate gcc
$gcc = (Get-Command gcc -ErrorAction SilentlyContinue).Source
if (-not $gcc) {
    throw 'gcc not found (expected an MSYS2 MinGW toolchain on PATH)'
}

Write-Host "Assembling with: $nasm"
& $nasm -f win64 ogl_triangle.asm -o ogl_triangle.obj
if ($LASTEXITCODE -ne 0) { throw 'nasm failed' }

Write-Host 'Linking with gcc'
& $gcc -m64 -nostartfiles '-Wl,--subsystem,windows' '-Wl,-e,WinMain' `
      ogl_triangle.obj -o ogl_triangle.exe `
      -lopengl32 -lgdi32 -luser32 -lkernel32
if ($LASTEXITCODE -ne 0) { throw 'link failed' }

Write-Host 'Built ogl_triangle.exe'
