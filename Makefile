# Makefile 
# Uses z88dk.
# Just adjust ASSEMBLER and APPMAKE to your needs.
# APPMAKE will create the tap or sna binaries.

PROJ = currah_uspeech_tests
INC_FILES = constants.inc
ASSEMBLER = ../../z88dk/z88dk.bin/bin/z80asm
APPMAKE = export ZCCCFG="/Volumes/SDDPCIE2TB/Projects/zxspectrum/z88dk/z88dk.bin/src/appmake"; ../../z88dk/z88dk.bin/bin/appmake
ORG = 32768


default:	$(PROJ).tap $(PROJ).sna $(LIST_OUT) $(DBG_SCRIPT)

clean:
	-rm -f *.o *.bin *.tap *.sna *.sym *.map *.err *.lis

$(PROJ).bin:	$(PROJ).asm $(ASM_FILES) $(INC_FILES) Makefile
	$(ASSEMBLER) -s -l -b -m --cpu=z80 --origin=$(ORG) --output=$@ $(PROJ).asm

%.tap:	%.bin
	$(APPMAKE) +zx -b $< --org $(ORG) --blockname "cshwtest"
	
%.sna:	%.bin
	$(APPMAKE) +zx -b $< --org $(ORG) --sna
