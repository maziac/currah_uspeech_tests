# Currah uSpeech Tests

The Currah uSpeech is a speech sythesizer peripheral for the ZX Spectrum from 1983.

This document is best described as a kind of amendment or complement to
the very good description of the Currah uSpeech HW/SW in
http://problemkaputt.de/zxdocs.txt
which describes the internals of the uSpeech.

I have done a few more tests to unriddle some of the uncertainties.

The description of the tests can be found here:
https://obscuretronics.wordpress.com/currah-uspeech

The project here is the test program I've used. 

Please note that the test program, of course, only makes sense if you own the Currah uSpeech HW
or if you develop an emulator and would like to compare the results.

Have fun,
T.Busse,
2017


# Building

## Configuration

If you want to build on your own you need the
z88dk assembler (https://github.com/z88dk).

Modify the asmz80 file in this directory to point to your installation of the z88dk, otherwise the project will not build.

## Make
If you just want to use the program there is no need for building.
For ease of use I also included the tap-file (currah_uspeech_tests.tap) itself.

Just run
~~~
> make
~~~
The result is a tap file that can be loaded through the tape interface of the ZX Spectrum 
or with an emulator.

## Debugging

Please note that the makefile also produces a script file for debugging with mess.
I.e. if you put a "; ABP" at the end of a line in the assembler sources a 
dbg_script.dbg is created that already sets the correct breakpoints.
If you want to add custom options put them in debug.scpt.

Mess needs to be started with the options "-debug -debugscript dbg_script.dbg".


# The uSpeech Findings

## The 0038h address

_Every_ access to 0038h will toggle the ROM and the access to registers 1000h, 3000h and 3001h.
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


## The uSpeech ROM mirroring

The uSpeech 2k ROM (0-07ffh) is mirrored at 0800h-0fffh.
If the uSpeech ROM is enabled the original ZX Spectrum is not accessible, i.e. the addresses 1000h-3fffh do not contain ZX Spectrum ROM when read.


## Intonation

Writing to addresses 3000h and 3001h will change the frequency of the allophones.
The volume is not changed.
(The written value itself has no meaning.)
3001h will lead to a 7% higher frequency. Changing from frequency 3000h to frequency 3001h is not instantly but smoothly and takes about 0.05-0.5 secs.


## Reading 1000h

Bit 0 is the busy bit. After writing to 1000h it is set and reset once the allophone is spoken.

The other bits also change their value over time. But the purpose of these bits is unknown.

Bits 0, 1 and 5 contain different values.

Bits 2, 3 and 4 might be equal and bit 6 and 7 might be equal.


## Allophone looping

Writing to address 1000h will make uSpeech HW "speak" the written allophone.
Normally, after the last allophone a pause (e.g. 0) should be written.
If that is not done the last allophone is looped. 
E.g. "/AA/" will repeated as a continuous "AAAAAAAAAAAAA".
Only the last part of the allophone is looped, i.e. "/SH/" will become "SHHHHHHHH"
and not "SH SH SH SH SH".

The busy bit (Bit 0 of 1000h) is set, after the allophone is done it is reset (0).
Afterwards it is regularly set to 1 for a short time. 


## More mirroring 

Adress 1000h has mirrors. All addresses
0001XXXX XXXXXXXX (binary format)
can be used for reading the status bit or writing an allophone.

2000h is no mirror of 1000h.

For 3000h the mirrors are: 0011XXXX XXXXXXX0 (binary).

For 3001h the mirrors are: 0011XXXX XXXXXXX1 (binary).


## in/out

Similar to address 0038h the address 1000h and 3000h can also be accessed via I/O.

Instead of read/write to 1000h an 'in/out' can be used as well.

For address 3000/1h an 'out' does work as well.
An 'in' or a memory read to that address has no effect.


## Oscillator frequency


The oscillator frequency for low intonation is about 3,05MHz.
The 3001h high intonation is 7% higher i.e. 3,26MHz.
This might/will vary with different HW.


# "Best" way to use the uSpeech from Assembler

If the uSpeech ROM is enabled the ZX Spectrum ROM is inaccessible.
So best is to enable the uSpeech ROM only for a short while when accessing the uSpeech registers (1000h, 3000h and 3001h) and then turn it off again.
As we need to check the busy bit before writing the next allophone we should handle that in an interrupt routine.
The pseudo code for the interrupt routine is this:

1. Enable ROM, e.g. ld a,(0038h)
2. Read the SP0256 busy bit, e.g. ld a,(1000h)
3. If not busy write next allophone, e.g. ld (1000h),a
4. Disable ROM, e.g. ld a,(0038h)
