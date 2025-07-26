@echo off
"C:\Program Files\NASM\nasm" -f bin bootloader.asm -o build\bootloader.bin
"C:\Program Files\qemu\qemu-system-x86_64.exe" -L "C:\Program Files\qemu" build\bootloader.bin -vga virtio
echo ----------------
pause