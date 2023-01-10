set_bg:
	pushad
	mov cx, 2000
	mov edi, 0xb8001

set_bg_loop:
	mov [ds:edi], byte 00001010b
	add edi, 2
	loop set_bg_loop
	popad
	ret

putchar:
	cmp al, 10
    je newline
	push edi
    mov edi, 0xb8000

	push eax
	mov eax, [carretpos]
	shl eax, 1
	add edi, eax
	pop eax

    mov [edi], al
	add edi, 2
	inc dword [carretpos]
	pop edi
    jmp endputchar

newline:
    push edx
	push ebx
	xor edx, edx

    mov eax, [carretpos]
	mov ebx, 80
    div ebx
	sub ebx, edx
    add [carretpos], ebx

	pop ebx
    pop edx

endputchar:
    ret

carretpos: dd 0

; remove_cursor:
; 	pushad
; 	mov   dx,0x3D4
; 	mov   al,0x0A
; 	mov   ah,bh
; 	out   dx,ax
; 	inc   ax
; 	mov   ah,bl
; 	out   dx,ax
; 	popad
; 	ret

; prints <cx> bytes starting from <si> address
show_mem_inc_dx:
	mov al, 10
	call putchar
	mov edx, 26

show_mem:
	mov edx, 26

show_mem_loop:
	cmp edx, 0
	je show_mem_inc_dx
	cmp ecx, 0
	je show_mem_end
	mov al, [esi]
	call hex_print_byte
	mov al, ' '
	call putchar
	dec ecx
	dec edx
	inc esi
	jmp show_mem_loop

show_mem_end:
	ret

; prints <al> into 2 hex digits
; changes <ax> <dx>
hex_print_byte:
	push eax
	;using al
	shr eax, 4
	and eax, 0xF
	call hex_to_ascii
	call putchar
	pop eax
	and eax, 0xF
	call hex_to_ascii
	call putchar
	ret

; converts al hex value to ascii symbol (0-F)
hex_to_ascii:
	push ebx
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
	and eax, 0xFF
	pop ebx
	ret
