# Makefile 
# Uses z88dk.
# Just adjust ASSEMBLER, LINKER to your needs.
# APPMAKE will create the tap or sna binaries.

PROJ = currah_uspeech_tests
INC_FILES = constants.inc
ASM_FILES = ui.asm tests1.asm tests2.asm tests3.asm common.asm
OBJ_FILES = $(subst .asm,.o,$(ASM_FILES))
LIS_FILES = $(subst .asm,.lis,$(ASM_FILES))
#LABELS_OUT = $(PROJ).labels
# The assembler output listing file:
LIST_OUT = $(PROJ).list
ASSEMBLER = ../../z88dk/bin/z80asm
LINKER = ../../z88dk/bin/z80asm
APPMAKE = export ZCCCFG="/Volumes/Macintosh HD 2/Projects/zesarux/z88dk/src/appmake"; ../../z88dk/bin/appmake
ORG = 32768
DBG_BP = dbg_breakpoint.tmp
DBG_CUSTOM = debug.scpt
DBG_SCRIPT = dbg_script.dbg

default:	$(PROJ).tap $(PROJ).sna $(LIST_OUT) $(DBG_SCRIPT)

clean:
	-rm -f *.o *.bin *.tap *.sna *.sym *.map *.err *.lis

$(PROJ).bin:	$(PROJ).asm $(ASM_FILES) $(INC_FILES) Makefile
	$(ASSEMBLER) -s -l -b -m --cpu=z80 --origin=$(ORG) --output=$@ $(PROJ).asm

%.tap:	%.bin
	$(APPMAKE) +zx -b $< --org $(ORG) --blockname "cshwtest"
	
%.sna:	%.bin
	$(APPMAKE) +zx -b $< --org $(ORG) --sna

%.list:	%.bin
	awk -v org=$(ORG) '!/^ / { if(FILENAME != curfile) {curfile=FILENAME; if(lastadr != "") org=lastadr;};  $$1=""; lastadr=strtonum("0x"$$2)+strtonum(org); $$2=sprintf("%X",lastadr); gsub(/^ /,"",$$0); print $$0;}' $(PROJ).lis | sed 's/\([0-9A-F ]* [0-9A-F][0-9A-F] \)/\1\t\t/g' > $@
		
%.dbg:	$(LIST_OUT) $(DBG_CUSTOM)
	# Create breakpoint debug script (use "BP" in c-files or asm-files):
	cat $(LIST_OUT) | grep "BP\s*$$" | sed -e 's/^\([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]\).*/printf "Breakpoint at \0"\nbp \1/g' > $(DBG_BP)
	# Concatenate debug scripts
	cat $(DBG_BP) $(DBG_CUSTOM) > $(DBG_SCRIPT)
