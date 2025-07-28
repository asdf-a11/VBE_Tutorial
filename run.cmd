@echo off
REM uses nasm to compile the bootloader into a flat binary file
"C:\Program Files\NASM\nasm" -f bin bootloader.asm -o build\bootloader.bin
REM uses quemu as the virtual machine
REM make sure to change paths to suit your system
"C:\Program Files\qemu\qemu-system-x86_64.exe" -L "C:\Program Files\qemu" build\bootloader.bin -vga virtio
echo ----------------
