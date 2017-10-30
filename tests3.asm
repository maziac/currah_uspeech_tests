
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; 35r test screen.
;-------------------------------------------------------------------------

; Tests are:
; - busy flag once
; - busy flag continuously
; - time measurement busy after idle
; - time measurement busy after allophone



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
	


; Test if the busy signal is set even if there is no new allophone written.
; With allophone /AA/.
ct_test_busy_aa:
	; speak one allophone
	ld a,18h	; load allophone /AA/

ct_test_busy_allophone:
	push af

	; show markers
	call display_hor_zero_markers

	; Enable Currah
	call turn_currah_on
	; check key release
	call ct_wait_on_key_release
	; Reset horizontal display
	ld a,1
	ld (display_hor_a_delay_value),a
	call reset_display_hor_a
	; wait on sp0256
	call ct_wait_on_sp0256
	pop af

	ld bc,1*30*8	; display_hor_a_delay_value*(256-16)x
	ld (1000h),a

ct_test_busy_aa_loop:
	push bc
	; now visualize the busy bit
	ld a,(1000h)
	call display_vert_a
	call display_hor_a
	
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,ct_test_busy_aa_loop
	
	jp ct_silence
	
	
	
; Test if the busy signal is set even if there is no new allophone written.
; With allophone /SH/.
ct_test_busy_sh:
	; speak one allophone
	ld a,25h	; load allophone /SH/
	jp ct_test_busy_allophone
	
