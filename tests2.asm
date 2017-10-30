
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; 2nd test screen.
;-------------------------------------------------------------------------

; Tests are:
; - Mirroring with 1000h
; - /AA/ with in/out
; - Intonation read 
; - Intonation out
; - Intonation in
; - Write/read 2XXXh


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


