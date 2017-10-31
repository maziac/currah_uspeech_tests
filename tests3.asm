
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; 35r test screen.
;-------------------------------------------------------------------------

; Tests are:
; - busy flag once
; - busy flag continuously
; - time measurement busy after idle
; - time measurement busy after allophone


; Test if the busy signal is set even if there is no new allophone written.
; With allophone /AA/.
ct_test_busy_aa:
	ld a,0ch	; dec bc = 0ch
	ld (ct_test_busy_self_modyfying),a
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
	; check key press
	call ct_input
	or a
	jr nz,ct_test_busy_aa_end
	
	push bc
	; now visualize the busy bit
	ld a,(1000h)
	call display_vert_a
	call display_hor_a
	
	pop bc

ct_test_busy_self_modyfying:
	dec bc	; dec bc = 0ch
	
	ld a,b
	or c
	jr nz,ct_test_busy_aa_loop
	
ct_test_busy_aa_end:
	jp ct_silence
	
	
	
; Test if the busy signal is set even if there is no new allophone written.
; With allophone /SH/.
ct_test_busy_sh:
	; speak one allophone
	ld a,25h	; load allophone /SH/
	jp ct_test_busy_allophone
	

; Like ct_test_busy_aa but doesn't stop automatically.
; Stops if another key is pressed.
; Used to check LRQ, SBY via a real oscilloscope.
ct_test_busy_until_key:
	xor a	; 0 = nop
	ld (ct_test_busy_self_modyfying),a
	ld a,18h	; load allophone /AA/
	jp ct_test_busy_allophone
	
