; Constant definitions.

; Printing text
defc print_string_address = 8252
defc print_number_address = 6683
defc AT	= 016h ; ZX Spectrum ASCII Control code: AT, y, x
defc INK = 010h ; ZX Spectrum ASCII Control code: INK, color (Bits 0-2)
defc PAPER = 011h

; Screen   
defc SCREEN_COLOR = 05800h
defc SCREEN_COLOR_SIZE	= 0300h   ; =768
defc SCREEN	= 04000h
defc SCREEN_WIDTH_IN_BYTES = 32
defc SCREEN_SIZE	= 01800h
defc TRANSPARENT	= 8

; Colors
defc BLACK	= 00h
defc BLUE	= 01h
defc RED	= 02h
defc MAGENTA= 03h
defc GREEN	= 04h
defc CYAN	= 05h
defc YELLOW	= 06h
defc WHITE	= 07h
defc BRIGHT	= 01000000b

; Keyboard ports: Bits 0-4. Bit is low if pressed.
; Example: in PORT_KEYB_54321, 2 is bit 1. in PORT_KEYB_67890, 0 is bit 0
defc PORT_KEYB_54321	= 0f7feh ; 5, 4, 3, 2, 1
defc PORT_KEYB_67890	= 0effeh ; 6, 7, 8, 9, 0
defc PORT_KEYB_BNMSHIFTSPACE	= 0x7FFE ; B, N, M, Symbol Shift, Space

; Constants for the currah uspeech.
; Note: in the Currah ROM there is a 'pop af' (f1h).
; In the spectrum ROM there is a 'push hl' (0e5h).
defc CS_ROM_VALUE=0f1h	; ROM value at 0039h
defc CS_ROM_SIZE=0800h
defc CS_ROM_VALUE_ADDRESS=0039h
