
;-------------------------------------------------------------------------
; currah_uspeech_test.asm
; This program here is to test the functionality of the Currah uSpeech HW.
;-------------------------------------------------------------------------

; Prints out some text, waits for key input and calls test functionality.
; Please note that within the tests it should be avoided to call ROM functionality
; like printing.
; Tests are:
; Mirroring with
; - out 38
; - in 38
; - mem write 38
; - mem read 38
; Output of "aaaaahhh" with:
; - 3000
; - 3001
; - alternating 3000/3001
; - bit 6
; - without bit 6
; - busy bit after only one allophone


; The different tests:

; Writes a color bar in the first line and then
; the outcome of a comparison of the byte at address (0,800h,1000h,1800h,etc)
; in the second line.
; Each column represents the next 800h value.
; Red means that the byte from the Currah rom has been found.
; White if not.
ct_currah_mirror_test:
	call ct_draw_mirror_bar
	; test memory
	ld ix,SCREEN_COLOR
	ld hl,CS_ROM_VALUE_ADDRESS
	ld b,4000h/CS_ROM_SIZE
	ld de,CS_ROM_SIZE
ct_mirror_test_loop:
	; compare rom value
	ld a,(hl)
	cp CS_ROM_VALUE
	ld a,WHITE<<3
	jr nz,ct_mirror_test_l1
	ld a,BRIGHT+(RED<<3)	; value found
ct_mirror_test_l1:
	ld (ix+0),a

	; next
	inc ix
	add hl,de
	djnz ct_mirror_test_loop

	ret


; Draws the mirror bar. Alternating colored blocks.
ct_draw_mirror_bar:
	; draw bar in first line
	ld b,4000h/CS_ROM_SIZE/2
	ld hl,SCREEN_COLOR+020h
	ld e,#(WHITE<<3)+BLACK
	ld d,#(BLACK<<3)+WHITE
ct_mirror_bar_l1:
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	djnz ct_mirror_bar_l1
	ret


; out to 38h
ct_test_out_38:
	xor a
	ld bc,0038h
	out (c),a
	; do mirror test
	call ct_currah_mirror_test
	ret

; in to 38h
ct_test_in_38:
	ld bc,0038h
	in a,(c)
	; do mirror test
	call ct_currah_mirror_test
	ret

; memory write to 38h
ct_mem_write_38:
	xor a
	ld (0038h),a
	; do mirror test
	call ct_currah_mirror_test
	ret

; memory read from 38h
ct_mem_read_38:
	ld a,(0038h)
	; do mirror test
	call ct_currah_mirror_test
	ret


; Test mirroring of the currah rom to see if there are any holes in
; memory addressing in case the curran rom is activated.
; Writes a color bar in the first line and then
; the outcome of a comparison of the byte at address (0,800h,1000h,1800h,etc)
; in the second line.
; Each column represents the next 800h value.
; Red means that the byte from the spectrum rom has been found.
; White if not.
ct_spectrum_mem_holes_test:
	call ct_draw_mirror_bar
	; test memory
	ld ix,SCREEN_COLOR
	ld hl,1
	ld b,4000h/CS_ROM_SIZE
	ld de,CS_ROM_SIZE
	
ct_holes_test_loop:
	; switch access
	ld (0038h),a
	; get byte from spectrum rom
	ld a,(hl)
	; switch access
	ld (0038h),a
	; compare byte with switched rom
	cp (hl)
	ld a,WHITE<<3
	jr nz,ct_holes_test_l1
	ld a,BRIGHT+(RED<<3)	; value is the same
ct_holes_test_l1:
	ld (ix+0),a

	; next
	inc ix
	add hl,de
	djnz ct_holes_test_loop

	ret

; sub routine that does an active wait as long as the
; SP0256 is still busy.
ct_wait_on_sp0256:
	call read_1000h
	bit 0,a	; Bit 0 = LRQ
	ret z	; ret if not busy
	
	; return also if there is a key press
	call ct_input
	or a
	ret nz

	jr ct_wait_on_sp0256

; sub routine to speak an "aa" allophone.
; de=should contain 3000h or 3001h for the intonation.
ct_speak_aa_with_de:
	; wait on sp0256
	call ct_wait_on_sp0256
	; speak
	ld a,18h	; /AA/
	call write_300xh
	call write_1000h
	ret


; speaks "aahh" with a mem write to 3000h on every allophone.
; Ends on key press.
ct_aahh_with_3000:
	; Initialize test
	call set_read_write_defaults
	
	ld de,address_3000h
ct_aahh_with_intonation:
	; check key release
	call ct_wait_on_key_release
ct_aahh_with_de_l1:
	; speak "aa"
	call ct_speak_aa_with_de
	; loop as long as no key is pressed
	call ct_input
	or a
	jr z,ct_aahh_with_de_l1

ct_silence:	
	; silence
	xor a
	ld (1000h),a
	ret

; speaks "aahh" with a mem write to 3001h on every allophone.
; Ends on key press.
ct_aahh_with_3001:
	; Initialize test
	call set_read_write_defaults
	ld de,address_3001h
	jr ct_aahh_with_intonation



; speaks "aahh" with bit 6 set on every allophone.
; nothing is written to 3000h or 3001h.
ct_test_with_bit_6:
	; Initialize test
	call set_read_write_defaults

	; speak "aa"
	ld e,18h	; /AA/
	set 6,e		; set bit 6

ct_bit_6:
	; check key release
	call ct_wait_on_key_release

ct_bit_6_loop:
	; wait on sp0256
	call ct_wait_on_sp0256
	; speak
	ld a,e	; load allophone (with or without bit 6)
	call write_1000h
	; loop as long as no key is pressed
	call ct_input
	or a
	jr z,ct_bit_6_loop
	jr ct_silence

; speaks "aahh" with bit 6 being reset on every allophone.
; nothing is written to 3000h or 3001h.
ct_test_without_bit_6:
	; Initialize test
	call set_read_write_defaults

	; speak "aa"
	ld e,18h	; /AA/
	; do not set bit 6
	jr ct_bit_6


