;structure of variable size that describes all gdt memmory blocks
gdt_start:
	dq 0		;null descriptor, necessary!

gdt_code_segment:
	dw 0xffff	;limit bits 1-16, aka segment size
	dw 0x0000	;base bits 1-16
	db 0x00		;base bits 17-24

	db 0b10011110 ;access byte, aka access rules
	;1 r/w bit
	;	data segment:
	;		set to 1 if data segment can be written
	;		data sector always can be read.
	;	code segment:
	;		set to 1 if code segment can be read 
	;		0 should be initialy set 0, hardware sets this bit to 1 when it's accessed
	;2 direction/conforming bit
	;	data segment: 
	;		shows in which way descriptor allocated
	;		0 - space allocated after pointer, 1 - before pointer
	;	code segment:
	;		0 - can be called only from same or higher privilage level
	;		1 - can be called from any privilage level
	;		(for example jump from userspace to kernel)
	;3 execute bit, says if segment can execute instructions, data or code seg
	;4 bit that needs to be set if this is data or code segment
	;5-6 privilage level bits, 0-full control, 3-userspace
	;7 present bit, says if descriptor active

	db 0b01001111 ;4 low are limit bits 17-20, 4 high bits are flags
	;7	granularity, 0 is byte granularity, 1 is page granularity (aka 4Kb)
	;6	code segment:
	;		if 0 this is 16bit segment, if 1 it's 32bit segment
	;	data segment:
	;		if 0 offset for ds is 16bit, if 1 offset is 32bit
	;5	x86-64 mode bit, if 1 (bit6 must be 0), makes segment 64bit
	;4	x86-64 mode bit, software bit, not used by hardware

	db 0x00			;base bits 25-32


gdt_data_segment:
	dw 0xffff		;limit bits 1-16, aka segment size
	dw 0x0000		;base bits 1-16
	db 0x00			;base bits 17-24
	db 0b10010010	;access byte, aka access rules
	db 0b01001111	;4 low bits are limit bits 17-20, 4 high bits are flags
	db 0x00			;base bits 25-32
gdt_end:

;gdt descriptor, loaded by lgdt instruction
;consists of 32 bit gdt size value and pointer to gdt structure
gdt_desc:
	dw gdt_end - gdt_start - 1	;size of gdt structure - 1
	dd gdt_start				;pointer to gdt structure