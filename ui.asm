; User Interface.
; Prints the text and observes the keyboard.
; Calls the test according the pressed key.
; Shows several screens with different tests.
; Use SPACE to cycle through the screens.



; START
main:
	; do not disturb tests with interrupts.
	di

	; prepare printing
	ld a,2              ; upper screen
    call 5633           ; open channel

	; load screen-1
	ld a,-1
	ld (test_screen_index),a

ct_ui_first_table:
	ld hl,screen_table - 10*2	; 10 jump table entries
	ld (screen_table_ptr),hl

ct_ui_show_screen:
	; black border
	xor a
	out (0xfe),a
	; clear screen
	xor a
	call clear_screen

	; next test screen
	ld hl,(screen_table_ptr)
	ld de,10*2	; 10 jump table entries
	add hl,de
	; get text
	ld e,(hl)
	inc hl
	ld a,(hl)
	or a	; If upper part of the address is 0 start all over again
	jr z,ct_ui_first_table
	ld d,a
	
	; get length
	inc hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld (screen_table_ptr),hl
	
	; de now points to the text of the screen
	; bc contains the size
	call print_string
	
	; clear colors
	ld a,WHITE
	call fill_screen_with_color 

ct_ui_loop:
	; wait until key has been released
	call ct_wait_on_key_release
	
	; Select test case
ct_wait_on_input:
	call ct_input
	or a
	jr z,ct_wait_on_input

	; Check for SPACE
	cp ' '
	jr z,ct_ui_show_screen
	
	; Check key
	sub '0'
	jr c,ct_wait_on_input
	cp 9+1
	jr nc,ct_wait_on_input

	; Get pointer to test
	ld l,a
	ld h,0
	add hl,hl	; *2
	ld de,(screen_table_ptr)
	add hl,de
	ld e,(hl)
	inc hl
	ld h,(hl)
	ld l,e
	
	; Get  line of text
	add ct_start_y
	ld c,a
	
	; save registers
	push hl
	push bc

	; clear colors
	ld a,WHITE
	call fill_screen_with_color

	; select line
	; calculate color screen position
	pop hl	; get y-position in l
	ld h,0
	; multiply with 32 (screen width
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	; draw a yellow color line
	ld a,#YELLOW<<3	; Yellow background
	ld de,SCREEN_COLOR+1
	add hl,de
	ld bc,SCREEN_WIDTH_IN_BYTES-1
	call fill_memory

	; run test
	pop hl	; hl points to the test case subroutine
	call ct_call_test

	jp ct_ui_loop


; A subroutine to make a call to hl.
ct_call_test:
	; check if valid test address is available
	ld a,h
	or a
	ret z	; if not just return
	; jump to test routine
	jp (hl)


; Scans the keyboard for input.
; Returns: a contains the ASCII code.
; 0 if no key pressed.
ct_input:
	push bc
	call ct_input_bc
	pop bc
	ret
ct_input_bc:
	; 1 - 5
	ld bc,PORT_KEYB_54321
	in a,(c)
	ld c,a
	ld a,'1'
	ld b,5
ct_input_l1:
	srl c
	ret nc	; return if pressed
	inc a
	djnz ct_input_l1

	; 6 - 0
	ld bc,PORT_KEYB_67890
	in a,(c)
	ld c,a
	ld a,'0'
	srl c
	ret nc	; return if '0' pressed
	ld b,4
	ld a,'9'
ct_input_l2:
	srl c
	ret nc	; return if pressed
	dec a
	djnz ct_input_l2

	; SPACE
	ld bc,PORT_KEYB_BNMSHIFTSPACE
	in a,(c)
	bit 0,a	; SPACE
	ld a,' '
	ret z
	
	; no key pressed
	xor a
	ret


; Waits until key has been released.
ct_wait_on_key_release:
	call ct_input
	or a
	jr nz,ct_wait_on_key_release
	ret


; Subroutine to fill a memory area.
; bc = size
; hl = destination
; a = value to fill
fill_memory:
	ld (hl),a
	ld e,l
	ld d,h
	inc de
	dec bc
	ldir
	ret

; Fills the color screen with a value.
; Leaves out the space for the mirror test.
; a = color to fill
fill_screen_with_color:
	ld hl,SCREEN_COLOR+4000h/CS_ROM_SIZE
	ld bc,SCREEN_COLOR_SIZE-4000h/CS_ROM_SIZE
	jp fill_memory
	
; Clears the screen (without color attributes)
clear_screen:
	ld hl,SCREEN
	ld bc,SCREEN_SIZE
	xor a
	jp fill_memory
	
	


; The current shown screen
test_screen_index:	defb 0

; The pointer to the screen_table.
screen_table_ptr: defw screen_table

; Contains the start addresses of the text for the screens and the length.
screen_table:
	; Text
	defw currah_tests1_text, currah_tests1_text_end-currah_tests1_text
	; Tests
	defw ct_test_out_38
	defw ct_test_in_38
	defw ct_mem_write_38
	defw ct_mem_read_38
	defw ct_spectrum_mem_holes_test
	defw ct_aahh_with_3000
	defw ct_aahh_with_3001
	defw ct_aahh_with_alt_3000_1
	defw ct_test_with_bit_6
	defw ct_test_without_bit_6

	; Text
	defw currah_tests2_text, currah_tests2_text_end-currah_tests2_text
	; Tests
	defw ct_aahh_mirror
	defw ct_1000h_mirror
	defw ct_1000h_values
	defw ct_test_busy_aa
	defw ct_test_busy_sh
	defw 0
	defw 0
	defw 0
	defw 0
	defw 0

	; End
	defw 0

; Texts to show as help.
currah_tests1_text:
defc ct_start_y=6
defc ct_start_x=2
	defb PAPER, TRANSPARENT
	defb INK, TRANSPARENT
	defb AT,1,0
	defb "01234567 ROM"
	defb AT,ct_start_y+0,ct_start_x
	defb "0: out 38h"
	defb AT,ct_start_y+1,ct_start_x
	defb "1: in 38h"
	defb AT,ct_start_y+2,ct_start_x
	defb "2: mem write 38h"
	defb AT,ct_start_y+3,ct_start_x
	defb "3: mem read 38h"
	defb AT,ct_start_y+4,ct_start_x
	defb "4: mem holes test"
	defb AT,ct_start_y+5,ct_start_x
	defb "5: \"aahh\" with 3000h"
	defb AT,ct_start_y+6,ct_start_x
	defb "6: \"aahh\" with 3001h"
	defb AT,ct_start_y+7,ct_start_x
	defb "7: \"aahh\" altern. 3000/1h"
	defb AT,ct_start_y+8,ct_start_x
	defb "8: \"aahh\" with bit 6"
	defb AT,ct_start_y+9,ct_start_x
	defb "9: \"aahh\" without bit 6"
	defb AT,ct_start_y+10,ct_start_x
	defb "<SPACE> - next screen"
	defb AT,20,3
	defb "Currah MicroSpeech Tests v1.0"
	defb AT,21,8
	defb "2017, written by T.Busse"
currah_tests1_text_end:

currah_tests2_text:
	defb AT,ct_start_y+0,ct_start_x
	defb "0: \"aahh\" at 1001h"
	defb AT,ct_start_y+1,ct_start_x
	defb "1: 1000h-3000h read - compare"
	defb AT,ct_start_y+2,ct_start_x
	defb "2: 1000h-4000h read - values"
	defb AT,ct_start_y+3,ct_start_x
	defb "3: busy flag (\"aa\" only once)"
	defb AT,ct_start_y+4,ct_start_x
	defb "4: busy flag (\"sh\" only once)"
	defb AT,ct_start_y+5,ct_start_x
	defb "5: -"
	defb AT,ct_start_y+6,ct_start_x
	defb "6: -"
	defb AT,ct_start_y+7,ct_start_x
	defb "7: -"
	defb AT,ct_start_y+8,ct_start_x
	defb "8: -"
	defb AT,ct_start_y+9,ct_start_x
	defb "9: -"
	defb AT,ct_start_y+10,ct_start_x
	defb "<SPACE> - next screen"
	defb AT,21,29
	defb "(2)"
currah_tests2_text_end:




