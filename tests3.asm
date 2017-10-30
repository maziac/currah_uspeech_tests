
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; 35r test screen.
;-------------------------------------------------------------------------

; Tests are:
; - busy flag


; Test if the busy signal is set even if there is no new allophone written.
; With allophone /AA/.
ct_test_busy_aa:
	; Enable Currah
	call turn_currah_on
	; check key release
	call ct_wait_on_key_release
	; wait on sp0256
	call ct_wait_on_sp0256
	
	; speak one allophone
	ld a,18h	; load allophone /AA/
	
ct_test_busy_allophone:
	call write_1000h
	ld b,30*8	; (256-16)x
	ld de,0101000011100000b+1
	ld hl,0101000111100000b+1
	ld c,00000001b
ct_test_busy_loop:
	; rotate
	rrc c
	jr nc,ct_test_busy_l1
	; clear next byte on screen
	inc de
	inc hl
	xor a
	ld (de),a
	ld (hl),a
ct_test_busy_l1:

	; loop for a short while
	ld a,100
ct_test_busy_inner_loop:	
	push af
	
	; now visualize the busy bit
	ld a,(1000h)
	call display_vert_a
	bit 0,a	; Bit 0 = LRQ, 1=busy
	jr z,ct_test_busy_l2
	
	; bit is 1
	ld a,(de)
	or c
	ld (de),a
	jr ct_test_busy_l3

ct_test_busy_l2:
	; bit is 0
	ld a,(hl)
	or c
	ld (hl),a

ct_test_busy_l3:
	pop af
	dec a
	jr nz,ct_test_busy_inner_loop

	djnz ct_test_busy_loop
	
	jp ct_silence
	
	
	
; Test if the busy signal is set even if there is no new allophone written.
; With allophone /SH/.
ct_test_busy_sh:
	; check key release
	call ct_wait_on_key_release
	; wait on sp0256
	call ct_wait_on_sp0256
	
	; speak one allophone
	ld a,25h	; load allophone /SH/
	jp ct_test_busy_allophone
	
