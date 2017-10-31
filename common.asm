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
	push hl
	ex de,hl	; ld hl from de
	push bc
	ld c,(hl)
	inc hl
	ld b,(hl)
	dec hl
	push af
	
write_3000xh_self_modifying_code:
	ld (bc),a
	nop
	
	pop af
	pop bc
	ex de,hl
	pop hl
	ret

write_300xh_mem_write:
	ld (bc),a
	nop
	
write_300xh_mem_read:
	ld a,(bc)
	nop
	
write_300xh_out:
	out (c),a

write_300xh_in:
	in a,(c)
	
; Sets the access to the 300xh addresses.
; mem write, read on in/out.
set_300xh_mem_write:
	ld hl,write_300xh_mem_write
set_300xh:
	ld bc,2
	ld de,write_3000xh_self_modifying_code
	ldir
	ret
	
set_300xh_mem_read:
	ld hl,write_300xh_mem_read
	jr set_300xh

set_300xh_out:
	ld hl,write_300xh_out
	jr set_300xh

set_300xh_in:
	ld hl,write_300xh_in
	jr set_300xh


; Default initialization for the read/write routines.
; Uses 100h, 3000h and 3001 as addresses and memory read/write
; to access the addresses.
set_read_write_defaults:
	; Use mem write for intonation
	call set_300xh_mem_write
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
	add 'A'-'0'-10
print_hex_number_l1:
	rst 10h
	ret
	
	
; Clears left side and bottom 3rd.
clear_left_and_bottom:
	; save
	push af
	push hl
	push de
	push bc
	; left
	xor a
	ld hl,SCREEN
	ld b,SCREEN_HEIGHT
	ld de,SCREEN_WIDTH_IN_BYTES
clear_left_and_bottom_loop:
	ld (hl),a
	add hl,de
	djnz clear_left_and_bottom_loop
	; bottom
	ld hl,SCREEN+16*SCREEN_WIDTH_IN_BYTES*8
	ld de,SCREEN+16*SCREEN_WIDTH_IN_BYTES*8+1
	ld bc,8*SCREEN_WIDTH_IN_BYTES*8-1
	ld (hl),a
	ldir
	; restore
	pop bc
	pop de
	pop hl
	pop af
	ret


; Displays the contents of all bits of a horizontally.
; Like an oszilloscope.
; Bit 0 is the lowest line, bit 7 the topmost.
; 'display_hor_a_delay_value' should be set to a suitable value.
; Depending on the caller function the drawn lines might be fast or slow.
; With this value the drawing speed can be adjusted.
display_hor_a:
	ld (display_hor_a_value),a
	; check if address needs to be incremented.
	ld hl,display_hor_a_counter
	dec (hl)
	jr nz,display_hor_a_no_inc
	ld a,(display_hor_a_delay_value)
	ld (hl),a
	
	ld a,(display_hor_a_rotation)
	; rotate
	rrc a
	ld (display_hor_a_rotation),a
	jr nc,display_hor_a_no_inc
	; increment screen address
	ld hl,(display_hor_a_address)
	inc hl
	ld (display_hor_a_address),hl
	; check overflow
	ld a,l
	and 00011111b
	call z,reset_display_hor_a
	
	; clear all lines
	xor a
	
	ld de,-(00100000b)
	set 2,h
	ld (hl),a
	inc h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	dec h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	inc h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	dec h
	ld (hl),a
	
	res 2,h
	ld de,00100000b
	ld (hl),a
	inc h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	dec h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	inc h
	ld (hl),a
	
	add hl,de
	ld (hl),a
	dec h
	ld (hl),a
	
display_hor_a_no_inc:

	ld de,-(00100000b)
	
	; Display 1's in a
	ld hl,(display_hor_a_address)
	ld a,(display_hor_a_value)
	call sub_display_hor_values
	
	; Display 0's in a
	ld hl,(display_hor_a_address)
	inc h	; 0's
	ld a,(display_hor_a_value)
	xor 0ffh
	call sub_display_hor_values
	ret
	
	
; Displays either 0 or 1 points.
sub_display_hor_values:
	ld b,4
	ld c,a
	
display_hor_a_loop_ones:
	set 2,h
	rrc c ; rotate with carry
	jr nc,display_hor_a_l1
	
	; write to screen
	ld a,(display_hor_a_rotation)
	or (hl)
	ld (hl),a
	
display_hor_a_l1:
	; next bit, next line
	res 2,h
	rrc c ; rotate with carry
	jr nc,display_hor_a_l2
	
	; write to screen
	ld a,(display_hor_a_rotation)
	or (hl)
	ld (hl),a
	
display_hor_a_l2:
	; next bit, next line
	add hl,de
	djnz display_hor_a_loop_ones
	
	ret
	
; Rests the values for the display_hor_a subroutine, so that it 
; starts again on the left side.	
reset_display_hor_a:
	ld hl,0101010011100001b
	ld (display_hor_a_address),hl
	ld a,00000001b
	ld (display_hor_a_rotation),a
	ld a,(display_hor_a_delay_value)
	ld (display_hor_a_counter),a
	ret

; Pointer to current screen address, rotation and delay counter.
display_hor_a_address:		defw 0
display_hor_a_rotation:		defb 0
display_hor_a_counter:		defb 0
display_hor_a_delay_value:	defb 0
; Temporary store for the bits in a
display_hor_a_value:		defb 0	

	
; Displays for all 8 horizontal lines a marker indicating 0 at the left side.
display_hor_zero_markers:
	call reset_display_hor_a
	inc h
	
	; set zero markers
	ld a,00011100b
	
	ld de,-(00100000b)
	set 2,h
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	res 2,h
	ld de,00100000b
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	add hl,de
	ld (hl),a	; zero marker
	
	ret
	
