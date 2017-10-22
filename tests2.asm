
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


; sub routine to speak an "aa" allophone.
; It does not make a call to ddress 3000h
ct_speak_aa:
	; wait on sp0256
	call ct_wait_on_sp0256
	; speak
	ld a,18h	; /AA/
	call write_1000h
	ret


; speaks "aahh" with a mem write to 1001h.
; This is to test mirroring.
; Ends on key press.
ct_aahh_mirror:
	; Enable Currah ROM and registers
	call turn_currah_on
	; Initialize test
	call set_read_write_defaults
	; Test mirror at 1001h
	ld hl,1001h
	ld (address_1000h),hl

	; check key release
	call ct_wait_on_key_release
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
	

; Tests for 1000h mirrors.
; I.e. it compares each address between 1000h and 1fffh with the
; ROM (the ZX Spectrum ROM).
; If an address value is not equal this is indicated.
ct_1000h_mirror:
	; start address
	ld hl,1000h
	ld de,2000h	; count (1000h-1fffh)
	ld bc,0	; count the values

	; Turn busy bit on
	call turn_currah_on
	ld a,18h	; /aa/
	ld (1000h),a
	
ct_1000h_mirror_loop:
	; disable currah
	call turn_currah_off
	; get Spectrum ROM value
	ld a,(hl)
	; enable currah
	push af
	call turn_currah_on
	pop af
	; compare
	cp (hl)
	jr z,ct_1000h_mirror_l1
	; not equal, count
	inc bc
ct_1000h_mirror_l1:	
	; next
	inc hl
	dec de
	ld a,d
	or e
	jr nz, ct_1000h_mirror_loop
	
	; silence
	xor a
	ld (1000h),a
	
	; Print text
	push bc
	ld de,text_mirror_count
	ld bc,#text_mirror_count_end-text_mirror_count
	call print_string
	pop bc

	; print the number of occurences
	call print_number	
	ret
	
	
; print at left lower corner
text_mirror_count:
	defb AT,20,1
	defb "Mirror count="
text_mirror_count_end:
	



; Tests the area 1000h to 4000h if currah is turned on.
; Writes the values to the screen.
; In fact, as these are mirrors, it does only write a value
; if it changed compared to the previous one. So the number is reduced
; significantly.
ct_1000h_values:
	; Print text
	ld de,text_read_values
	ld bc,#text_read_values_end-text_read_values
	call print_string

	; start address
	ld hl,1000h
	ld de,3000h	; count (1000h-3fffh)
	ld b,6	; print max 4 values

	; Turn busy bit on
	call turn_currah_on
	ld a,18h	; /aa/
	ld (1000h),a
	
	ld a,(hl)	; previous value
	xor 10101010b	; make sure the first value is printed
	ld c,a
	
ct_1000h_values_loop:
	ld a,c
	ld c,(hl)
	cp c	; compare with previous value
	jr z,ct_1000h_values_same
	
	; not equal, print
	push bc
	ld b,0
	call print_number
	pop bc
	
	; check if max count exceeded
	dec b
	jr z,ct_1000h_values_end
	
	; print a space
	push bc
	ld a,' '
	rst 10h
	
	; turn currah on again
	call turn_currah_on
	pop bc
	ld a,c	; previous value
	
ct_1000h_values_same:	
	; next
	inc hl
	dec de
	ld a,d
	or e
	jr nz, ct_1000h_values_loop
	
ct_1000h_values_end:
	; silence
	xor a
	ld (1000h),a
	
	ret
	
	
; print at left lower corner
text_read_values:
	defb AT,20,1
	defb "Values="
text_read_values_end:
	




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
	
