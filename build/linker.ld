INPUT(bootloader.o kmain.o)
OUTPUT_FORMAT(elf32-i386)
OUTPUT(kernel.o)
ENTRY(start)
OUTPUT_ARCH(i386)
SECTIONS
{
  .stage1_bootloader (0x7c00) : {
    bootloader.o( .mbr_record )
  }
  .stage2_bootloader : {
    bootloader.o( .stage2_bootloader )
  }
  .kmain : { *(.text) }
  .rodata : {
    *(.rodata)
    *(.rodata*)
  }
  /DISCARD/ : {
    *(.comment)
    *(.eh_frame)
  }
}
