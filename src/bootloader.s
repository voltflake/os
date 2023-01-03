; tell NASM to use 8086 instructions
[bits 16]

; tell NASM offset for labels
; [org 0x7c00]

; NOTE: When using elf object file format offsets are all relative, so we need to
;       tell linker our absolute offset for labels (-Ttext 0x7c00)
;       This info is not reliable!

extern kmain
global start

start:

; set all segments to 0
jmp 0:set_segments
set_segments:
xor ax, ax
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

; NOTE: Small stack size can hang bios on interrupt!
;       That means bios uses stack space initialised in kernel-space.

; setup stack space
mov bp, 0xF000
mov sp, bp

; set video mode to text mode 80x25
mov al, 0x03
mov ah, 0x00
int 0x10

; reset floppy drive
reset_drive:
mov ah, 0x00  ; reset function
;mov dl, 0x00  ; drive
int 0x13   ; disk int
mov al, ah
jc reset_drive

; read sectors from floppy to RAM
read_sector:
mov ah, 0x02    ; read sectors from drive
;mov dl, 0x00    ; drive id to load
mov ch, 0       ; cylinder/track index
mov dh, 0       ; head index
mov cl, 2       ; sector number
mov al, 8       ; sectors to read
mov bx, 0x7e00  ; pointer to buffer, ES is 0
int 0x13
jc read_sector

; ignore maskable interrupts (not critical hardware interrupts?)
cli

; disable PIC (hardware interrupts)
; SEE: http://www.brokenthorn.com/Resources/OSDevPic.html
mov al, 0x11
out 0x20, al
out 0xa0, al

mov al, 0xe0
out 0x21, al
mov al, 0xe8
out 0xa1, al

mov al, 0x1
out 0x21, al
out 0xa1, al

mov al, 0xff
out 0x21, al
out 0xa1, al

; disable NMI
; SEE: https://en.wikipedia.org/wiki/Non-maskable_interrupt
; SEE: https://wiki.osdev.org/NMI
in al, 0x70
or al, 0x80
out 0x70, al

; enable A20 line
; TODO: add methods of activating A20 before using "fast A20"
; SEE: http://independent-software.com/operating-system-development-enabling-a20-line.html
call check_a20
cmp al, 1
je a20_ready
in al, 0x92
or al, 2
out 0x92, al
a20_ready:

; load GDT
; SEE: https://en.wikipedia.org/wiki/Global_Descriptor_Table
; SEE: https://www.youtube.com/watch?v=JO0z6s6s1bs
lgdt [ds:gdt_desc]

; set PM bit
mov eax, cr0
or eax, 0x1
mov cr0, eax

; clear pipeline & update code segment
jmp gdt_code_segment-gdt_start:protected_mode

; tell NASM to use i386 instructions
[bits 32]

; start of 32bit protected mode
protected_mode:

; update segment registers
mov ax, gdt_data_segment-gdt_start
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax

; setup stack
mov ebp, 0x90000
mov esp, ebp

; set colors for text mode
call set_bg

; function that shows bootsector content on screen
mov esi, 0x7c00
mov ecx, 26*25 ;25 rows
call show_mem

; jump into C enviroment
call kmain

; halt cpu
hlt

; emergency infinite jump
; just in case of cpu waking up somehow on real hardware
jmp $

; protected mode functions stored here
%include "functions32.s"

; tell NASM to use 8086 instructions
[bits 16]

; real mode functions stored here
%include "functions16.s"
%include "gdt.s"

; fill rest of sector space with zeros
times 510-($-$$) db 0

; fill last 2 bytes of sector with MBR boot signature
dw 0xaa55