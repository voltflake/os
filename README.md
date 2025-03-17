> [!WARNING]  
> I do not recommend testing it on real hardware because it can differ in some ways from my computers and might not work as expected. This is a bare metal project so be careful with it!  
## Preview
![Demonstration of running OS](preview.png)
## Installing build tools
All operating systems, including Windows. Make sure all tools available from PATH
 - [NASM assembler](https://nasm.us/) (nasm)
 - [LLVM toolchain](https://releases.llvm.org/) (clang, llvm-objcopy, ld.lld)
 - [QEMU emulator](https://www.qemu.org/download/) (qemu-system-i386)
## Building and running project
```
cd src
```
```
nasm -Werror -f elf32 -o ../build/bootloader.o bootloader.s
```
```
cd ../build
```
```
clang --target=i686-pc-none-elf -c -o kmain.o ../src/kmain.c
```
```
ld.lld -T linker.ld
```
```
llvm-objcopy --set-start=0x7c00 -O binary kernel.o kernel.bin
```
```
qemu-system-i386 -drive file=kernel.bin,format=raw
```
> [!NOTE]  
> To jump to C code uncomment line 138 in bootloader.s
