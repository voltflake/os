; NOTE: When using elf object file format offsets are all relative, so we need to
;       tell linker our absolute offset for labels (-Ttext 0x7c00)
;       This info is not reliable!

[bits 16]
extern kmain
global start

SECTION .mbr_record
start:
    cli             ; We do not want to be interrupted
    xor ax, ax      ; 0 AX
    mov ds, ax      ; Set Data Segment to 0
    mov es, ax      ; Set Extra Segment to 0
    mov fs, ax      ; Set Extra Segment to 0
    mov gs, ax      ; Set Extra Segment to 0
    mov ss, ax      ; Set Stack Segment to 0
    mov sp, ax      ; Set Stack Pointer to 0
jmp 0:LowStart  ; Jump to new Address

LowStart:
; NOTE: Small stack size can hang bios on interrupt!
;       That means bios uses stack space initialised in kernel-space.
; setup stack space
mov bp, 0xFFFF
mov sp, bp

mov [DriveNum], dl
sti

; set video mode to text mode 80x25
mov al, 0x03
mov ah, 0x00
int 0x10

; reset disk system.
mov ah, 0x00
int 0x13

; NOTE: Reading more sectors than available on disk result in error.
; read disk sectors into memory.
mov ah, 2          ; read operation
mov al, 2          ; read 2 sectors
mov ch, 0          ; cylinder number
mov cl, 2          ; sector number
mov dh, 0          ; head number
mov dl, [DriveNum] ; drive number
mov bx, 0x7e00     ; points to data buffer
int 0x13
jc disk_error

jmp stage2

disk_error:
    call hex_print_byte16
    jmp halt16

; prints al
putchar16:
    mov ah, 0x0e
    int 0x10
    ret

; prints <al> into 2 hex digits
; changes <ax>
hex_print_byte16:
	push ax
	;using al
    and al, 0xF0
	shr al, 4
	call hex_to_ascii16
	call putchar16
	pop ax
	and al, 0x0F
	call hex_to_ascii16
	call putchar16
	ret

; converts al hex value to ascii symbol (0-F)
hex_to_ascii16:
	push bx
	; pre-calculate both values to avoid branching
	mov bl, al
	mov bh, al

	add bh, 0x30
	add bl, 0x37
	; check if value can fit in range of ascii digits
	cmp al, 9
	; use apropirate shift
	mov al, bh
	cmova ax, bx
	pop bx
	ret

halt16:
    hlt
    jmp halt16

DriveNum db 0
times (510 - 16*4 - ($-$$)) nop    ; Pad For MBR Partition Table

db 0x80 ; bootable
db 0x00 ; fisrt CHS
db 0x02
db 0x00
db 0x0B ; type
db 0x00 ; last CHS
db 0x05
db 0x00
dd 1    ; Logical sector index
dd 4    ; Partition size
PT2 times 16 db 0             ; Second Partition Entry
PT3 times 16 db 0             ; Third Partition Entry
PT4 times 16 db 0             ; Fourth Partition Entry

dw 0xAA55                     ; Boot Signature

SECTION .stage2_bootloader
stage2:
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

; start of 32bit protected mode
[bits 32]
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
mov ecx, 27*25 ;25 rows
call show_mem

; jump into C enviroment
; call kmain

jmp halt32

halt32:
    hlt
    jmp halt32

; protected mode functions stored here
[bits 32]
%include "functions32.s"

; real mode functions stored here
[bits 16]
%include "functions16.s"
%include "gdt.s"
