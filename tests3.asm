
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
	ld a,0bh	; dec bc = 0bh
	ld (ct_test_busy_self_modyfying),a
	; speak one allophone
	ld a,18h	; load allophone /AA/

ct_test_busy_allophone:
	push af

	; clear part of the screen
	call clear_left_and_bottom

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
	ld a,0bh	; dec bc = 0bh
	ld (ct_test_busy_self_modyfying),a
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
	


; Measures the time of the busy flag.
; 2 times are measured: 
; 1. time between write 1000h and busy=1
; 2. time between change busy=1/0 and busy=0/1 if write to 1000h after busy=1/0
ct_test_busy_time_measure:
	call clear_left_and_bottom
	call turn_currah_on
	; check that uSpeech is on
	ld a,(CS_ROM_VALUE_ADDRESS)
	cp CS_ROM_VALUE
	jr nz,ct_test_busy_time_measure_end	; avoid executing if uSpeech is not attached.

	ld bc,1000h
	ld hl,0		; counter
	ld de,1
	
	; wait until busy is 0
ct_test_busy_time_measure_wait1:
	ld a,(bc)
	bit 0,a
	jr nz,ct_test_busy_time_measure_wait1
	
	; write allophone
	ld a,18h	; /AA/
	ld (bc),a

	; wait and count until busy is 1
ct_test_busy_time_measure_wait2:
	add hl,de
	jr z,ct_test_busy_time_measure_overflow
	ld a,(bc)
	bit 0,a
	jr z,ct_test_busy_time_measure_wait2
	
ct_test_busy_time_measure_overflow:
	push hl	; save value
	
	; print
	ld de,text_duration1
	ld bc,#text_duration1_end-text_duration1
	call print_string
	
	; print t1
	pop bc
	call print_hex_number
	
	
ct_test_busy_time_measure_end:
	call turn_currah_on
	jp ct_silence
	

; print at left lower corner
text_duration1:
	defb AT,20,1
	defb "                            "
	defb AT,20,1
	defb "t1="
text_duration1_end:

text_duration2:
	defb ", "
	defb "t2="
text_duration2_end:
