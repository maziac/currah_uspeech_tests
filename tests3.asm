
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
; a contains the allophone to speak (different allophones need different time)
ct_test_busy_time_measure:
	ld (ct_test_busy_time_measure_used_allophone),a
	call clear_left_and_bottom
	call turn_currah_on
	; check that uSpeech is on
	ld a,(CS_ROM_VALUE_ADDRESS)
	cp CS_ROM_VALUE
	ret nz	; avoid executing if uSpeech is not attached.

	ld bc,1000h
	ld de,1
		
	; wait until busy is 0
ct_test_busy_time_measure_wait1:
	ld a,(bc)
	bit 0,a
	jr nz,ct_test_busy_time_measure_wait1
	
	; write allophone
	ld a,(ct_test_busy_time_measure_used_allophone)
	ld (bc),a

	; check immediately 
	ld a,(bc)	; 7 T
	rra	
	ld hl,10000		; counter
	jr c,ct_test_busy_time_measure_overflow1	; save value 0 (10000-10000) if immediately (7T) set
	
	; wait and count until busy is 1
	or a	; clear carry
ct_test_busy_time_measure_wait2:
	sbc hl,de
	jr z,ct_test_busy_time_measure_overflow1
	ld a,(bc)
	bit 0,a
	jr z,ct_test_busy_time_measure_wait2
	
ct_test_busy_time_measure_overflow1:
	push hl	; save value

	; Loop for a few times
	exx
defc TIME_MEASURE_LOOP_COUNT = 5
	ld b,TIME_MEASURE_LOOP_COUNT+1

ct_test_busy_time_measure_loop:
	exx
	
	; wait and count until busy is again 0
	ld hl,10000	; counter
	or a	; clear carry
ct_test_busy_time_measure_wait3:
	sbc hl,de		; 15 T
	jr z,ct_test_busy_time_measure_overflow2	; 7 T
	ld a,(bc)	; 7 T
	bit 0,a		; 8 T
	jr nz,ct_test_busy_time_measure_wait3	; 12 T
	; Total: 49 T = 49 *1/3,5MHz = 14 us
	
ct_test_busy_time_measure_overflow2:
	push hl	; save value
	
	; speak another allophone
	ld a,(ct_test_busy_time_measure_used_allophone)
	ld (bc),a
	
	; wait until busy = 1
ct_test_busy_time_measure_wait4:
	ld a,(bc)
	bit 0,a
	jr z,ct_test_busy_time_measure_wait4

	exx
	djnz ct_test_busy_time_measure_loop
	exx
	
	; print t3
	ld de,text_duration3
	ld bc,text_duration3_end-text_duration3
	call print_string
	
	ld a,TIME_MEASURE_LOOP_COUNT

ct_test_busy_time_print_loop:
	; print t1
	pop bc
	push af
	call print_10000_number
	; print space
	ld a,' '
	rst 10h
	
	pop af
	dec a
	jr nz,ct_test_busy_time_print_loop
	
	; print t1
	ld de,text_duration1
	ld bc,text_duration1_end-text_duration1
	call print_string
	
	pop hl
	pop bc
	push hl
	
	; t1
	call print_10000_number
	
	; print t2
	ld de,text_duration2
	ld bc,text_duration2_end-text_duration2
	call print_string

	; t2
	pop bc
	call print_10000_number
	
	; end
	call turn_currah_on
	jp ct_silence

; The used allophone.
ct_test_busy_time_measure_used_allophone:	defb 0


; Do the test with /AA/, 63.7ms.
ct_test_busy_time_measure_with_aa:
	ld a,18h
	jp ct_test_busy_time_measure

; Do the test with /JH/, 98.4ms.
ct_test_busy_time_measure_with_jh:
	ld a,0ah
	jp ct_test_busy_time_measure

	
; prints number in bc, but calculates 10000-bc beforehand.
print_10000_number:
	ld hl,10000
	or a
	sbc hl,bc
	ld c,l
	ld b,h
	jp print_number
	

; print at left lower corner
text_duration1:
	defb AT,17,1
	defb "Multiply by 14 us."
	defb AT,18,1
	defb "                            "
	defb AT,18,1
	defb "t1="
text_duration1_end:

text_duration2:
	defb ", "
	defb "t2="
text_duration2_end:

text_duration3:
	defb AT,19,1
	defb "                            "
	defb AT,19,1
	defb "t3="
text_duration3_end:
