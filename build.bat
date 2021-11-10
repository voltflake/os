@echo off
cd src

nasm -Werror -f elf -o ../build/bootloader.o bootloader.s
if %errorlevel% neq 0 goto error
cls

clang -target i386-PC-UnknownOS-ELF -c -o ../build/kmain.o kmain.c
if %errorlevel% neq 0 goto error
cls

cd ../build/

ld -m i386pe -Ttext 0x7c00 -o kernel.tmp bootloader.o kmain.o
if %errorlevel% neq 0 goto error

objcopy --set-start=0x7c00 -O binary kernel.tmp kernel.bin
if %errorlevel% neq 0 goto error

ddrelease64 if=/dev/zero of=floppy.img bs=512 count=2880
if %errorlevel% neq 0 goto error
ddrelease64 if=kernel.bin of=floppy.img seek=0 count=2 conv=notrunc
if %errorlevel% neq 0 goto error

#del kernel.tmp
#del *.o
#del kernel.bin

cd ..
cls
echo Built Succeesfuly
goto :EOF

:error
echo Build failed with error code %errorlevel%
exit /b %errorlevel%