
<img class="" title="Currah uSpeeech" src="http://www.worldofspectrum.org/pub/sinclair/hardware-adverts/CurrahMicroSpeech.jpg" width="466" height="661" />

The Currah uSpeech (or Currah Micro Speech) was a HW peripheral for the ZX Spectrum from 1983. It was a speech device which allowed to say words from a BASIC program. A few commercial programs/games did support it as well.  It connected to the HF- and audio-output of the spectrum and mixed it's own (speech) audio and the spectrum sound onto the HF signal. So the audio could be heard from the TV speaker.

My aim is to gain enough knowledge about the Currah uSpeech and its functionality to use it in an ZX Spectrum assembler-code game.

The best source of written information about the uSpeech HW that I could find is here:

<a href="http://problemkaputt.de/zxdocs.htm">http://problemkaputt.de/zxdocs.htm</a> and here <a href="https://k1.spdns.de/Vintage/Sinclair/82/Peripherals/Currah%20uSpeech/">https://k1.spdns.de/Vintage/Sinclair/82/Peripherals/Currah%20uSpeech/</a>.

And of course the <a title="Currah_Manual" href="https://obscuretronics.files.wordpress.com/2017/09/currah_manual.pdf">Currah uSpeech_Manual</a> itself.

But there were still a lot of unclarities left. Therefore I took a real uSpeech HW (thanks to <a href="http://zxsp.blogspot.de">Kio</a>) and wrote a test program to unriddle it's last mysteries.

<hr />

<h2>Table of Contents</h2>
<a href="#hardware">The Hardware</a>

<a href="#api">The API</a>

<a href="#system">The System Behaviour</a>

<a href="#reverse">Some Reverse Engineering (Rockfall)</a>

<a href="#tests">The Tests</a>

<a href="#findings">Findings</a>

<a href="#Conclusion">Conclusion</a>

<hr />

<h2 id="hardware">The Hardware</h2>
The uSpeech has 4 connectors/cables: UHF-in, UHF-out, a line lead used for in or output and the edge connector.

The <span style="text-decoration:underline;">normal setup</span> for the uSpeech was to attach it to the Spectrum and then connect the UHF-in to the UHF-out of the ZX Spectrum, the UHF-out to the TV and the line lead (as input) to the MIC output of the ZX Spectrum.
The speech signal (together with the audio output of the ZX Spectrum) was added to the UHF-output signal of the ZX Spectrum and fed into the TV.

[caption id="attachment_329" align="alignnone" width="4608"]<img class="alignnone size-full wp-image-329" src="https://obscuretronics.files.wordpress.com/2017/10/hw_conn_1.jpg" alt="hw_conn_1" width="4608" height="3456" /> Normal setup: Spectrum Audio and UHF out are fed through the uSpeech which adds speech and the Spectrum audio to the UHF out.[/caption]

The <span style="text-decoration:underline;">other setup</span> is not so well known although it is documented in the <a title="Currah_Manual" href="https://obscuretronics.files.wordpress.com/2017/09/currah_manual.pdf">Currah uSpeech_Manual</a>:
UHF-in and UHF-out are not used, the line lead is used as output and connected to an audio amplifier. In this case the speech signal is output to the line lead. I used this setup to record speech output in some of my tests.

[caption id="attachment_330" align="alignnone" width="4608"]<img class="alignnone size-full wp-image-330" src="https://obscuretronics.files.wordpress.com/2017/10/hw_conn_2.jpg" alt="hw_conn_2" width="4608" height="3456" /> Alternate setup: The Spectrum stays connected to the TV. The audio out of the uSpeech can be connected to an amplifier or tape deck.[/caption]

Strange about this setup is that there exist mods to modify the uSpeech HW to allow line out functionality (see <a href="http://blog.bisinternet.com/retroblog/spectrums/currah-micro-speech-uspeech/">here</a> and also <a href="http://schombi.de/my-retro-collection.html">here</a>.). This wouldn't be necessary with the HW that I used. The HW in the <a href="http://blog.bisinternet.com/retroblog/spectrums/currah-micro-speech-uspeech/">link</a> is definitely a different revision, maybe it didn't came with line out functionality.

Opening the device (it's just clipped there are no screws) we find the main components of the uSpeech HW:
<ul>
	<li>2k uSpeech ROM</li>
	<li><a href="http://www.futurebots.com/spo256.pdf">SP0256-AL2</a> (Narrator Spech Processor)</li>
	<li>ULA</li>
</ul>
<img class="alignnone size-full wp-image-408" src="https://obscuretronics.files.wordpress.com/2017/10/hw.jpg" alt="hw" width="4608" height="3457" />

The pin 12 (ser out) of the SP0256 has been removed. Maybe there is an error on that PCB revision.

<img class="alignnone size-full wp-image-409" src="https://obscuretronics.files.wordpress.com/2017/10/img_20171022_204559.jpg" alt="IMG_20171022_204559" width="4608" height="3456" />

For completeness here is the back side:

<img class="alignnone size-full wp-image-404" src="https://obscuretronics.files.wordpress.com/2017/10/img_20171022_204732-730947054.jpg" alt="img_20171022_204732-730947054.jpg" width="3000" height="2250" />

I also measured the oscillator frequency. Unfortunately the frequency dropped when I reached the Osc out pin (28). So I used a trick: with the dropped frequency I measured the fequency of the speech signal. Then I put it in relation to the speech frequency without my probe connected. All in all this leads to a frequency of about 3,259 MHz. I suspect that this varies from model to model.

[gallery ids="415,416" type="rectangular"]

<hr />

<h2 id="api">The API</h2>
The uSpeech comes with a 2k ROM. It's main purpose is to provide speech output for the Spectrum Basic. But it also offers an API to use from machine code.

Both ways are described in the <a title="Currah_Manual" href="https://obscuretronics.files.wordpress.com/2017/09/currah_manual.pdf">Currah uSpeech_Manual</a> and provide a way to pass complete sentences to the uSpeech which are turned into allophones and provided to the uSpeech HW by the ROM code.

However, the machine code API is very intrusive and restrict assembler programs (games) very much in the use of the interrupt.

A third, undocumented, API is described <a href="#Conclusion">later</a>.

<hr />

<h2 id="system">The System Behaviour</h2>
In very brief the general behaviour of the uSpeech HW:

The uSpeech comes with a 2k ROM. It is enabled with an access to address 0038h. The next access will disable the ROM again.

The idea behind this was that the normal ZX Spectrum interrupt routine passed address 0038h which made the uSpeech ROM available. After the uSpeech interrupt routine was finished it again jumped to 00038h which disabled the ROM so that the normal ZX Spectrum ROM was visible. I.e. the Spectrum interrupt routine could continue normally and finish.

The uSpeech ROM code establishes the BASIC and a machine code interface.

From BASIC you could e.g. assign the s$ (LET s$="something") and the uSpeech immeditely begins to talk. It converts words or a complete sentence into allophones and sends them to the SP0256 for output. Intonation is different for upper and lower case characters.

The uSpeech ROM also observes data in the RAM for a new sentence/word. This can be used as API to a machine code program. Here, the intonation is different if bit 6 of the data is set or not.
<h2></h2>

<hr />

 
<h2 id="reverse">Some Reverse Engineering</h2>
<em>'The Rockfall case'</em>: when doing a disassembly of the rockfall game (Ian Collier) one can easily find code that does an '<em>in a,(38h)</em>' and then reads a value from ROM to see if the ROM has been toggled.
However, I was not able to see that code executing, it seemed like dead code.
On the other hand I also tried Rockfall II. There is a very similar routine used:

[caption id="attachment_122" align="alignnone" width="1000"]<img class="alignnone size-full wp-image-122" src="https://obscuretronics.files.wordpress.com/2017/09/screenshot-from-2017-09-23-20-26-35.png" alt="Screenshot from 2017-09-23 20-26-35" width="1000" height="628" /> After the port operation you can see that a read is done on 0039h of the ROM. Followed by a comparison with F1h, which translates to POP AF. The POP AF is the instruction used in the Currah ROM. In the normal Spectrum you would find E5h (PUSH HL).[/caption]

And I could verify that this indeed was executed.

It is strange that Rockfall uses an IO operation for uSpeech detection. A simple memory read seems much easier.

<hr />

<h2 id="tests">The Tests</h2>
There were a few questions that I wanted to answer by tests:
<ol>
	<li><strong>Intonation</strong>: what does intonation mean. Is it volume or pitch? If it is frequency, what frequency is it.</li>
	<li>Is the <strong>ROM toggle</strong>d only by an opcode fetch or also by a normal read operation or even an IO operation on address 0038h?</li>
	<li>Is address 1000h (and 3000/1h) only writable/readable if the Currah ROM is on?</li>
</ol>
While testing I found some other interesting behaviour an extended the tests:
<ol>
	<li>The values of the other bits when reading 1000h.</li>
	<li>Mirroring of the Currah ROM.</li>
	<li>Is the Spectrum ROM available (above 0800h) while the Currah ROM is enabled?</li>
	<li>Mirroring of the addresses 1000h and 3000/1h.</li>
</ol>
Here is the test program I used:

<img class="alignnone size-full wp-image-322" src="https://obscuretronics.files.wordpress.com/2017/10/test_overview_b.jpg" alt="test_overview_b" width="4608" height="3456" />

Source code + tap file: <a href="https://github.com/maziac/currah_uspeech_tests">https://github.com/maziac/currah_uspeech_tests</a>
<h3>Explanations:</h3>
<h4>General:</h4>
When reading from address 1000h (or mirrors) the contents of the byte is written to the screen. Only changed values are written. This leads to a vertical bar. The rightmost bit is bit 0 which is known to be the busy bit (set when SP0256 is busy). The meaning of the other bits is unknown.
<h4>out 38h:</h4>
An
<pre><code>ld bc,0038h
out (c),a
</code></pre>
is executed. Afterwards it is checked at address 0039h+i*0800h with i in [0;7] if value 0f1h is found which is the value of the uSpeech ROM at address 0039h.
If found the block is marked as red on screen.
<h4>in 38h:</h4>
Same as before but a
<pre><code>ld bc,0038h
in a,(c)
</code></pre>
is used.
<h4>mem write 38h:</h4>
Same as before but a
<pre><code>ld (0038h),a
</code></pre>
is used.
<h4>mem read 38h:</h4>
Same as before but a
<pre><code>ld a,(0038h)
</code></pre>
is used.
<h4>mem holes test:</h4>
This test is used to see if any Spectrum ROM is accessible if the uSpeech ROM has been activated. It reads a byte from the ROM, then switches the ROM and reads the same address and compares both values. If equal this is indicated by a red square. The addresses used for comparison are 0001h+i*0800h with i in [0;7].
<h4>/AA/ with 3000h:</h4>
Writes to address 3000h for low intonation and afterwards write /AA/ (18h) to address 1000h. This is done in a loop, i.e. the address 1000h is read and the next /AA/ is written when the busy bit (bit 0) is reset to 0.
This test does not access the 0039h address. So it can be used in conjunction with the tests above (e.g. "mem write 38h") to verify the using address 1000h is only working the same time that the uSpeech ROM has been enabled.
<h4>/AA/ with 3001h:</h4>
Same as above but with high intonation (address 3001h).
<h4>/AA/ with bit 6:</h4>
Writes /AA/ to address 1000h with bit 6 set (18h | 40h = 58h). Doesn't writes to 3000h or 3001h at all.
The purpose of this test is to show that bit 6 has no influence on the intonation when writing to address 1000h.
<h4>/AA/ without bit 6:</h4>
Same as above but without setting bit 6.
<h4>/AA/ at 1XXXh:</h4>
Turns the uSpeech ROM on.
Writes /AA/ to address 1XXXh, i.e. other addresses than 1000h to see if there are mirrors of 1000h.
Everytime you execute this test another address is used. The used addresss is printed at the bottom part of the screen.
The tested addresses are: 1000h, 1001h, 1002h, 1004h, 1008h, 1010h, 1020h, 1040h, 1080h, 1100h, 1200h, 1400h, 1800h.
I.e. every address line is tested once.
<h4>/AA/ with 3XXXh even:</h4>
Turns the uSpeech ROM on.
Writes /AA/ to address 1000h/3XXX(even), i.e. it tests for mirrors of 3000h.
Everytime you execute this test another address is used. The used addresss is printed at the bottom part of the screen.
The tested addresses are all mainly even: 3000h, 3001h, 3002h, 3004h, 3008h, 3010h, 3020h, 3040h, 3080h, 3100h, 3200h, 3400h, 3800h.
(Note: 3001h is included for validation of the algorithm.)
I.e. every address line is tested once.
<h4>/AA/ with 3XXXh odd:</h4>
Turns the uSpeech ROM on.
Writes /AA/ to address 1000h/3XXX(odd), i.e. it tests for mirrors of 3001h.
Everytime you execute this test another address is used. The used addresss is printed at the bottom part of the screen.
The tested addresses are all mainly odd: 3000h, 3001h, 3003h, 3007h, 300fh, 301fh, 303fh, 307fh, 30ffh, 31ffh, 33ffh, 37ffh, 3fffh.
(Note: 3000h is included for validation of the algorithm.)
I.e. every address line is tested once.
<h4>/AA/ at 2000h:</h4>
Turns the uSpeech ROM on.
Writes /AA/ to address 2000h and reads from 2000h (bit 0) repeatedly.
Used to check ifthere are mirrors at 2000h.
<h4>/AA/ at 1000h in/out:</h4>
Turns the uSpeech ROM on.
Uses in/output. Outputs /AA/ to address 1000h and reads with 'in' from 1000h.
<h4>/AA/ altern. 3000/1h write:</h4>
Turns the uSpeech ROM on.
This test is to measure the time the oscillator requires to switch from one to the other frequency.
An /AA/ is written to 1000h/3000h for a short while then an /AA/ is written to 1000h/3001h.
This is done in a loop until another key is pressed.
<h4>/AA/ altern. 3000/1h read:</h4>
Same as before but uses a read of address 3000/1h instead of a write.
Used to check if a read does work as well.
<h4> /AA/ altern. 3000/1h out:</h4>
Same as before but uses an 'out (c),a' of address 3000/1h instead of a write.
Used to check if an 'out' does work as well.
<h4>/AA/ altern. 3000/1h in:</h4>
Same as before but uses an 'in a,(c)' of address 3000/1h instead of a write.
Used to check if an 'in' does work as well.
<h4>All allophones (5-63):</h4>
Speaks all allophones from 5 to 63 each followed by a pause.
<h4>busy flag (/AA/ only once):</h4>
Turns the uSpeech ROM on.
Writes /AA/ to address 1000h once and observes the busy flag (reads address 1000h).
You see a horizontal line with the contents of the busy flag (1/0).
Additional (as usual) the contents of the complete byte is written as a vertical bar on the left, but only for changed values.
<h4>busy flag (/SH/ only once):</h4>
Same as above but with allophone /SH/.
<h4>busy flag (/SH/ only once):</h4>
Same as above but does not stop  until a key is pressed.
Intention was to take some pictures with an oscilloscope.

<hr />

<h2 id="findings">Findings</h2>
<strong>ROM toggling with 0038h</strong>:
Apart from the opcode fetch, the following assembler code is all valid to toggle the ROM:
<pre><code>    ld bc,0038h

    ; in-operation
    in a,(c) ; out-operation. contents of a does not matter.
    out (c),a

    ; another in (or out) operation
    xor a
    in a,(38h)

    ; memory read
    ld a,(0038h)

    ; memory write. contents of a does not matter.
    ld (0038h),a
</code></pre>
I.e. every operation on 0038h, let it be an IO or memory operation, an opcode fetch, a read or write, will enable/diable the ROM.

In the test pressing one of the keys 0-3 will all toggle the ROM. This can be seen in the upper left corner. Red means that the uSpeech ROM is present (red arrow). The number below indicates the memory area. Multiply the number with 0800h to get the start address. I.e. each block represents 0800h = 2k bytes.

<img class="alignnone size-full wp-image-323" src="https://obscuretronics.files.wordpress.com/2017/10/test_overview.jpg" alt="test_overview" width="4608" height="3456" />

In this video I press the keys repeatedly which results in enabling/disabling the ROM:

<video width="320" height="240" controls>
  <source src="movie.mp4" type="video/mp4">
  <source src="movie.ogg" type="video/ogg">
Your browser does not support the video tag.
</video>


[wpvideo 0CRScUDA]

<strong>1000h toggling:
</strong>Here we see that address 1000h can be used to output speech only if it is enabled by accessing address 0038h before. It is enabled together with the uSpeech ROM which can be seen by the red rectangle in the upper part.

[wpvideo J0TyaYIP]

Please note: the decreasing volume is due to the recording, in reality the volume is constant.

<strong>1000h mirroring:</strong> All addresses 1XXXh are valid for reading the status bits or writing the allophones. In binary 0001XXXX XXXXXXXX.
I tested the following addresses:
1000h, 1001h, 1002h, 1004h, 1008h, 1010h, 1020h, 1040h, 1080h, 1100h, 1200h, 1400h, 1800h.
At address 2000h there is no mirroring.

<strong>1000h accesses:</strong> Instead of a read/write to this register one can use in/out instead.

<strong>1000h reading, other bits:</strong> The picture shows in the lower half the contents of the bits read from address 1000h after an allophone was written.
Bit 0 (busy) is shown at the bottom, above are bits 1 to 7. At the left side you see a short marker separated by 2 pixels which indicates logical 0.

<img class="alignnone size-full wp-image-429" src="https://obscuretronics.files.wordpress.com/2017/10/img_20171031_142821.jpg" alt="IMG_20171031_142821" width="4608" height="3456" />

<img class="alignnone size-full wp-image-430" src="https://obscuretronics.files.wordpress.com/2017/10/img_20171031_142829.jpg" alt="IMG_20171031_142829" width="4608" height="3456" />

The bits are not floating, there seems to be some deterministic behaviour. The bits 1 to 7 seem to be behave very similar but looking into more detail not all of them contain the same value.

Bits 0, 1 and 5 contain different values.
Bits 2, 3 and 4 might be equal and bit 6 and 7 might be equal.

<strong>30001h/3001h mirroring:</strong> Very similar behaviour here. All addresses are mirrored. It is only important if the address is even or odd.
<span style="text-decoration:underline;">Mirrors for 3000h:</span> In binary 0011XXXX XXXXXXX0.
<span style="text-decoration:underline;">Mirrors for 3001h:</span> In binary 0011XXXX XXXXXXX1.
I tested for 3000h:
3002h, 3004h, 3008h, 3010h, 3020h, 3040h, 3080h, 3100h, 3200h, 3400h, 3800h.
And for 3001h:
3003h, 3007h, 300Fh, 301Fh, 303Fh, 307Fh, 30FFh, 31FFh, 33FFh, 37FFh, 3FFFh.

<strong>30001h/3001h accesses: </strong>A write or an out to this address does work whereas a read or in operation does not.

<strong>Intonation/Bit 6</strong>:
In my tests setting the bit 6 didn't have any effect on intonation when writing to address 1000h. The bit is only important if the machine code API from the manual is used. In this case setting bit 6 will lead to writing to memory location 3001h before the allophone is written. This leads to the different intonation. The uSpeech ROM code responsible for this is (address=0184h):
<pre><code>    ; a contains the allophone and bit 6 for intonation
    ld de,3000h
    bit 6,a
    jr z,l1
    ; use 3001h if bit 6 is set
    inc de
l1:
    ld (de),a
    ld (1000h),a
</code></pre>
According my measurements writing to 3000h or 3001h just changes the frequency. The volume does not change.
The frequency for 3001h is about 7% (x1.07) higher than that of 3000h.
The frequency does not instantly change but it takes about 0.05 - 0.5 secs until the new frequency is settled.
It is not necessary to write to 3001h/3001h before a write to 1000h is done. Simply the last set frequency will stay.

Here is the <a href="https://raw.githubusercontent.com/maziac/currah_uspeech_tests/master/results/Alternating_3000_3001.wav">audio</a>.

<strong>Allophone loop</strong>:
One effect that I wasn't aware off I found by accident (Although it was already partly documented in <a href="http://problemkaputt.de/zxdocs.htm">http://problemkaputt.de/zxdocs.htm</a>). Whenever an allophone is written and no new allophone is written afterwards the last allophone is repeated endlessly.
The video shows this for 2 allophones, /AA/ and /SH/.
The horizontal line at the bottom shows the value of the busy bit. I.e. it goes up after writing the allophone and goes done to 0 when finished. But we can also see that it regularly is set to 1 although nothing is written to 1000h anymore.
The vertical bar shows the content of the 1000h address when read. It is a compressed view and only displayed whenever it changes.
It seems that not the complete allophone is repeated but only the last part, i.e. you do not hear "sh sh sh sh" but "shhhhhhhh".

[wpvideo lmnoe46B]

<hr />

<h2 id="Conclusion">Conclusion</h2>
My goal was to use the uSpeech output in an assembler game. So I was looking for the best way to access Currah uSpeech HW. The ways described in the manual were not suitable for me:
<ul>
	<li>Using the BASIC interface: does not make sense for an assembler program</li>
	<li>The described machine code API: This has several issues:
<ul>
	<li>Allophones can't be input directly. The input is done as a sentence that is broken done into allophones by the uSpeech ROM.</li>
	<li>It uses memory at the end of the RAM which conflicts with custom interrupts routines,</li>
</ul>
</li>
</ul>
So the approach is to control the uSpeech HW directly. I have no need for intonation so it's enough to deal with addresses 0038h and 1000h.

To avoid a busy loop while waiting to send the next allophone to the SP256 the speech routine has to be served in an interrupt which polls the busy flag and (if not busy) writes the next allophone.

Pseudocode of the interrupt routine:
<ol>
	<li><em>Enable registers</em></li>
	<li><em>Check if SP0256 busy</em></li>
	<li><em>If not: write allophone</em></li>
	<li><em>Disable registers</em></li>
</ol>
Assemblercode:
<pre><code>    ...

    ; enable uSpeech
    ld a,(0038h)

    ; wait until SP0256 is not busy anymore 
loop:
    ld a,(1000h)
    bit 0,a
    jr nz,loop

    ; write allophone
    ld a, ...  ; load with some allophone, e.g. 18h for /AA/
    ld (1000h),a

    ; disable uSpeech
    ld a,(0038h)

    ...
</code></pre>
Note 1: The uSpeech HW is enabled here without any test if it is already enabled. If the interrupt routine is the only code that accesses address 0038h than no test is needed. (As this is a custom interrupt routine the normal interrupt routine which passes address 0038h is not executed. So no problem here.)

Note 2: If the uSpeech HW is not attached this code will work as well (of course no speech is output). Reading from address 1000h will lead to bit 0 being set or not. If set then nothing is written to 1000h ever. If it is not set the allophone is written to 1000h which is a ROM location and therefore has no effect.

Note 3: It is important to turn the uSpeech off after accessing it. Otherwise the ZX Spectrum ROM is not available. If you don't need the ROM you could also turn the uSpeech on only once (outside of the interrupt routine) and leave it on. But normally you would like to use some ROM routine e.g. for printing so you need to toggle the access.

Note 4: If you need to test (for some reason) if the uSpeech HW is available you can use the following code:
<pre><code>is_uspeech_available:
    di
    ; test if uSpeech is enabled
    ld a,(0039)
    cp 0f1h
    jr z,is_enabled    ; jump if uSpeech is available

    ; try to enable the uSpeech
    ld a,(0038h)

    ; test again
    ld a,(0039)
    cp 0f1h
    jr nz,is_not_enabled    ; jump if uSpeech is not available

is_enabled:
    ; disable uSpeech
    ld a,(0038h)

is_not_enabled:
    ei
    ret
</code></pre>
This subroutine returns with Z-flag set if the uSpeech HW is attached.
It works by reading an address value that differs in uSpeech and Spectrum ROM. In the example above the address 0039h is used. In the uSpeech ROM it contains 0f1h for 'pop af'. The ZX Spectrum ROM contains 0e5h for 'push hl'.

