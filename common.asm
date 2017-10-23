; Common subroutines.

; The addresses that shall be used to access the currah HW.
; Used for mirroring tests.
address_1000h:	defw 1000h
address_3000h:	defw 3000h
address_3001h:	defw 3001h


; Access the currah HW always with these routines.

; Write to address 1000h.
; a contains the byte to write.
write_1000h:
	push hl
	ld hl,(address_1000h)
	ld (hl),a
	pop hl
	ret
	
	
; Read from address 1000h.
; Returns: a
read_1000h:
	push hl
	ld hl,(address_1000h)
	ld a,(hl)
	call display_vert_a
	pop hl
	ret
	
	
; Intonation.
; Write to address 3000h or 3001h
; de contains the pointer to address_3000h or address_3001h
write_300xh:
	ex de,hl
	push de
	ld e,(hl)
	inc hl
	ld d,(hl)
	dec hl
	ld (de),a
	pop de
	ex de,hl
	ret


; Default initialization for the read/write routines.
; Uses 100h, 3000h and 3001 as addresses and memory read/write
; to access the addresses.
set_read_write_defaults:
	; Use address 3000h/3001h for intonation
	ld hl,3000h
	ld (address_3000h),hl
	ld hl,3001h
	ld (address_3001h),hl
	; Use address 1000h fo6683r read/write allophone
	ld hl,1000h
	ld (address_1000h),hl
	ret
	
	
; Turns the currah access (to 1000h and 3000/1h) on.
turn_currah_on:
	; check if rom is enabled
	ld a,(CS_ROM_VALUE_ADDRESS)
	cp CS_ROM_VALUE
	ret z	; Return if already enabled
	; enable currah with a mem read
	ld a,(0038h)
	ret

; Turns the currah access (to 1000h and 3000/1h) off.
turn_currah_off:
	; check if rom is enabled
	ld a,(CS_ROM_VALUE_ADDRESS)
	cp CS_ROM_VALUE
	ret nz	; Return if already disabled
	; disable currah with a mem read
	ld a,(0038h)
	ret


; Writes the output of a as a byte to the screen.
; Afterwards increases the y-position.
; Used to output the contents of the byte read from 1000h.
display_vert_a:
	push hl
	; just show in case of a change.
	ld hl,display_prev_val
	cp (hl)
	jr z,display_vert_a_end
	
	push af
	
	; store current value
	ld (hl),a
	
	; has changed, so display it
	ld hl,(display_ptr)
	ld (hl),a
	
	; increment y
	inc h
	ld a,h
	and 07h
	jr nz,display_l1
	; overflow
	ld a,h
	sub a,08h	; correct h
	ld h,a
	; increment l
	ld a,l
	add a,020h
	ld l,a
	jr nc,display_l1
	; overflow again to h
	ld a,h
	add a,08h
	ld h,a
display_l1:
	; check if too big
	ld a,h
	and 00011000b
	xor 00011000b
	jr nz,display_l2
	; too big
	ld l,DISPLAY_START_Y/8*020h
	ld h,01000000b+(DISPLAY_START_Y & 0111b)
	
display_l2:
	ld (display_ptr),hl
	pop af
	
display_vert_a_end:
	pop hl
	ret

defc DISPLAY_START_Y = 17

display_ptr:		defb	DISPLAY_START_Y/8*020h, 01000000b+(DISPLAY_START_Y & 0111b)
display_prev_val:	defb	0


; The print routines call the ZX Spectrum.
; Therefore the Currah ROM needs to be turned off.
print_string:
	call turn_currah_off
	jp print_string_address
	
print_number:
	call turn_currah_off
	jp print_number_address

; prints a hex number in bc.
print_hex_number:
	call turn_currah_off
	push bc
	ld a,b
	srl a
	srl a
	srl a
	srl a
	call print_hex_a
	pop bc
	ld a,b
	and a,0fh
	push bc
	call print_hex_a
	pop bc
	push bc
	ld a,c
	srl a
	srl a
	srl a
	srl a
	call print_hex_a
	pop bc
	ld a,c
	and a,0fh
	jp print_hex_a
	
	
print_hex_a:
	add '0'
	cp '9'+1
	jr c,print_hex_number_l1
	add 'A'-'0'
print_hex_number_l1:
	rst 10h
	ret
	
	
