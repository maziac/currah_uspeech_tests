# Currah uSpeech 

This document is best described as a kind of amendment or complement to
the very good description of the Currah uSpeech HW/SW in
http://problemkaputt.de/zxdocs.htm or
http://problemkaputt.de/zxdocs.txt

I have done a few more tests to unriddle some of the uncertainties.

The description of the tests can be found here:
https://obscuretronics.wordpress.com/currah-uspeech

2017, T.Busse.


# The 0038h address

*Every* access to 0038h will toggle the ROM and the access to registers 1000h, 3000h and 3001h.
I.e.
~~~
ld bc,0038h
in a,(c)
out (c),a
in a,(0038h)
ld a,(0038h)
ld (0038h),a
~~~
and, of course, the opcode fetch at address 0038h, all will toggle ROM and access.


# The uSpeech ROM mirroring

The uSpeech 2k ROM (0-07ffh) is mirrored at 0800h-0fffh.
If the uSpeech ROM is enabled the original ZX Spectrum is not accessible, i.e. the addresses 1000h-4000h do not contain ZX Spectrum ROM when read.


# Intonation

Writing to addresses 3000h and 3001h will change the frequency of the allophones.
The volume is not changed.
(The written value itself has no meaning.)
3001h will lead to a 7% higher frequency. Changing from frequency 3000h to frequency 3001h is not instantly but smoothly and takes about 0.05-0.5 secs.


# Reading 1000h

Bit 0 is the busy bit. After writing to 1000h it is set and reset once the allophone is spoken.

The other bits also change their value over time. But the purpose of these bits is unknown.


# Allophone looping

Writing to address 1000h will make uSpeech HW "speak" the written allophone.
Normally, after the last allophone a pause (e.g. 0) should be written.
If that is not done the last allophone is looped. But not the complete allophone but only the repetitive part.
I.e. "/AA/" will repeated as a continuous "AAAAAAAAAAAAA". "/SH/" will be repeated as "SHHHHHHHH".
Only the last part of the allophone is repeated.

The busy bit (Bit 0 of 1000h) is set and immmediately reset regularly if no new allophone is written.


# More mirroring 

Adress 1000h has mirrors, e.g. one can use 1001h instead.


# "Best" way to use the uSpeech from Assembler

If the uSpeech ROM is enabled the ZX Spectrum ROM is inaccessible.
So best is to enable the uSpeech ROM only for a short while when accessing the uSpeech registers (1000h, 3000h and 3001h) and then turn it off again.
As we need to check the busy bit before writing the next allophone we should handle that in an interrupt routine.
The pseudo code for the interrupt routine is this:

1. Enable ROM, e.g. ld a,(0038h)
2. Read the SP0256 busy bit, e.g. ld a,(1000h)
3. If not busy write next allophone, e.g. ld (1000h),a
4. Disable ROM, e.g. ld a,(0038h)
