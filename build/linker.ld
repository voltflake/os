INPUT(bootloader.o kmain.o)
OUTPUT_FORMAT(elf32-i386)
OUTPUT(kernel.o)
ENTRY(start)
OUTPUT_ARCH(i386)
SECTIONS
{
  .bootloader (0x7c00) : {
    bootloader.o( .text )
  }
  .kmain (0x7e00) : { *(.text) }
  .rodata : { *(.rodata) }
  .comment : { *(.comment) }
  .eh_frame : { *(.eh_frame) }
}