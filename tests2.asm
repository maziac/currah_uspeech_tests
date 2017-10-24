
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; 2nd test screen.
;-------------------------------------------------------------------------

; Tests are:
; Mirroring with 1000h
; - 
; Output of "aaaaahhh" with:
; - in/out 1000h instead of read/write 1000h
; - alternating 3000/3001 with out to 3000/1
; - 


; sub routine to speak an "aa" allophone with intonation.
ct_speak_aa:
	; wait on sp0256
	call ct_wait_on_sp0256
	; speak
	ld a,18h	; /AA/
	ld hl,(address_3000h)
	ld (hl),a
	call write_1000h
	ret


; speaks "aahh" with a mem write to 1XXXh (i.e. 1001h, 1002h, 1004h, etc).
; This is to test mirroring.
; Ends on key press.
ct_aahh_mirror:
	; check key release
	call ct_wait_on_key_release
	; Reset 3000h
	ld hl,3000h
	ld (address_3000h),hl
	; Test mirror at next address (i.e. shift bits)
	ld de,(address_1000h)
	or a
	ld hl,1000h	; test on overflow
	sbc hl,de
	jr nz,ct_aahh_mirror_shift
	inc e	; de=1001h, set rightmost bit
	jr ct_aahh_mirror_l2
ct_aahh_mirror_shift:
	; shift
	sla e
	rl d
	ld a,d
	and 00001111b
	or 00010000b
	ld d,a
ct_aahh_mirror_l2:	
	ld (address_1000h),de
	push de
	
ct_aahh_mirror_l3:
	; print
	ld de,text_aahh_mirror_address
	ld bc,#text_aahh_mirror_address_end-text_aahh_mirror_address
	call print_string
	pop bc
	call print_hex_number	

	; Enable Currah ROM and registers
	call turn_currah_on

ct_aahh_mirror_l1:
	; speak "aa"
	call ct_speak_aa
	; loop as long as no key is pressed
	call ct_input
	or a
	jr z,ct_aahh_mirror_l1

ct_aahh_mirror_silence:	
	; silence
	xor a
	ld (1000h),a
	ret
	
; print at left lower corner
text_aahh_mirror_address:
	defb AT,20,1
	defb "                            "
	defb AT,20,1
	defb "Used address="
text_aahh_mirror_address_end:
	

; speaks "aahh" with a mem write to 1000h and intonation set to 
; 3XXXh (i.e. 3001h, 3002h, 3004h, 3008h, etc).
; Used to test mainly the even addresses.
; This is to test mirroring.
; Ends on key press.
ct_aahh_3000_mirror:
	; check key release
	call ct_wait_on_key_release
	; Reset 1000h
	ld hl,1000h
	ld (address_1000h),hl
	; Test mirror at next address (i.e. shift bits)
	ld de,(address_3000h)
	or a
	ld hl,3000h	; test on overflow
	sbc hl,de
	jr nz,ct_aahh_3000_mirror_shift
	inc e	; de=3001h, set rightmost bit
	jr ct_aahh_3000_mirror_l2
ct_aahh_3000_mirror_shift:
	; shift
	sla e
	rl d
	ld a,d
	and 00001111b
	or  00110000b
	ld d,a
ct_aahh_3000_mirror_l2:	
	ld (address_3000h),de
	push de

	; Set to 3001h for comparison
	call turn_currah_on
	ld (3001h),a
	
	jp ct_aahh_mirror_l3
	

; speaks "aahh" with a mem write to 1000h and intonation set to 
; 3XXXh (i.e. 3001h, 3003h, 3005h, 3009h, etc).
; Used to test mainly the odd addresses.
; This is to test mirroring.
; Ends on key press.
ct_aahh_3001_mirror:
	; check key release
	call ct_wait_on_key_release
	; Reset 1000h
	ld hl,1000h
	ld (address_1000h),hl
	; Test mirror at next address (i.e. shift bits)
	ld de,(address_3000h)
	or a
	ld hl,3fffh	; test on overflow
	sbc hl,de
	jr nz,ct_aahh_3001_mirror_shift
	ld de,3000h
	jr ct_aahh_3001_mirror_l2
ct_aahh_3001_mirror_shift:
	; shift
	scf	; set carry flag
	rl e
	rl d
	ld a,d
	and 00001111b
	or  00110000b
	ld d,a
ct_aahh_3001_mirror_l2:	
	ld (address_3000h),de
	push de

	; Set to 3000h for comparison
	call turn_currah_on
	ld (3000h),a
	
	jp ct_aahh_mirror_l3



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
	
