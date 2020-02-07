
; Game engine code --------------------------------------------------------------

; DEFINE DEBUG
; DEFINE FASTVRAMDUMP

; Arcade Game Designer.
; (C) 2008 - 2018 Jonathan Cauldwell.
; MSX version (C) jltursan
; Based on ZX Spectrum Engine v0.7.4
;
; Notes about Music & SFX engine
; From the EngineMSX itself, 5 routines are being called right now:
;
; * music_init: initializes the music engine. If your engine doesn't needs this, use ret to do nothing
; * sfx_init: initializes the sfx engine. Idem
; * music_play: plays a music frame from the ISR. The idea is to set a buffer with all the PSG register ready to dump
; * sfx_play: plays a sfx frame from the ISR. Idem
; * psgrout: generic routine to dump all PSG registers
;
; 07/01/2020: Fixed: Now evnt18 doesn't disables sprites at all; so you can use the sprites in an ending scene (if you need to hide them, use now SPRITESOFF)
; 07/01/2020: Added: Due the change in evnt18, a new command SPRITESOFF has been added to the compiler, it hides all sprites by setting 208 Y-coord to sprite 0
; 09/01/2020: Fixed: CLS & CLW routines now erase scrmap buffer and also disable sprites (Thanks to FX).
; 01/02/2020: Fixed: ROM stack initialization bug in MSX machines with drives (specially TR)
;
; ptxt: core routine that prints a font character (no color)
; pchr: core routine that prints a BLOCK (pattern+color)

ROM=0
DISK=1
TAPE=2

; --- All MSX 1 BIOS calls ---

MSX_CHKRAM	equ $0000
MSX_RDSLT	equ $000C
MSX_CHRGTR	equ $0010
MSX_WRSLT	equ $0014
MSX_OUTDO	equ $0018
MSX_CALSLT	equ $001C
MSX_DCOMPR	equ $0020
MSX_ENASLT	equ $0024
MSX_GETYPR	equ $0028
MSX_CALLF	equ $0030
MSX_KEYINT	equ $0038
MSX_INITIO	equ $003B
MSX_INIFNK	equ $003E
MSX_DISSCR	equ $0041
MSX_ENASCR	equ $0044
MSX_WRTVDP	equ $0047
MSX_RDVRM	equ $004A
MSX_WRTVRM	equ $004D
MSX_SETRD	equ $0050
MSX_SETWRT	equ $0053
MSX_FILVRM	equ $0056
MSX_LDIRMV	equ $0059
MSX_LDIRVM	equ $005C
MSX_CHGMOD	equ $005F
MSX_CHGCLR	equ $0062
MSX_NMI		equ $0066
MSX_CLRSPR	equ $0069
MSX_INITXT	equ $006C
MSX_INIT32	equ $006F
MSX_INIGRP	equ $0072
MSX_INIMLT	equ $0075
MSX_SETTXT	equ $0078
MSX_SETT32	equ $007B
MSX_SETGRP	equ $007E
MSX_SETMLT	equ $0081
MSX_CALPAT	equ $0084
MSX_CALATR	equ $0087
MSX_GSPSIZ	equ $008A
MSX_GRPPRT	equ $008D
MSX_GICINI	equ $0090
MSX_WRTPSG	equ $0093
MSX_RDPSG	equ $0096
MSX_STRTMS	equ $0099
MSX_CHSNS	equ $009C
MSX_CHGET	equ $009F
MSX_CHPUT	equ $00A2
MSX_LPTOUT	equ $00A5
MSX_LPTSTT	equ $00A8
MSX_CNVCHR	equ $00AB
MSX_PINLIN	equ $00AE
MSX_INLIN	equ $00B1
MSX_QINLIN	equ $00B4
MSX_BREAKX	equ $00B7
MSX_ISCNTC	equ $00BA
MSX_CKCNTC	equ $00BD
MSX_BEEP	equ $00C0
MSX_CLS		equ $00C3
MSX_POSIT	equ $00C6
MSX_FNKSB	equ $00C9
MSX_ERAFNK	equ $00CC
MSX_DSPFNK	equ $00CF
MSX_TOTEXT	equ $00D2
MSX_GTSTCK	equ $00D5
MSX_GTTRIG	equ $00D8
MSX_GTPAD	equ $00DB
MSX_GTPDL	equ $00DE
MSX_TAPION	equ $00E1
MSX_TAPIN	equ $00E4
MSX_TAPIOF	equ $00E7
MSX_TAPOON	equ $00EA
MSX_TAPOUT	equ $00ED
MSX_TAPOOF	equ $00F0
MSX_STMOTR	equ $00F3
MSX_LFTQ	equ $00F6
MSX_PUTQ	equ $00F9
MSX_RIGHTC	equ $00FC
MSX_LEFTC	equ $00FF
MSX_UPC		equ $0102
MSX_TUPC	equ $0105
MSX_DOWNC	equ $0108
MSX_TDOWNC	equ $010B
MSX_SCALXY	equ $010E
MSX_MAPXY	equ $0111
MSX_FETCHC	equ $0114
MSX_STOREC	equ $0117
MSX_SETATR	equ $011A
MSX_READC	equ $011D
MSX_SETC	equ $0120
MSX_NSETCX	equ $0123
MSX_GTASPC	equ $0126
MSX_PNTINI	equ $0129
MSX_SCANR	equ $012C
MSX_SCANL	equ $012F
MSX_CHGCAP	equ $0132
MSX_CHGSND	equ $0135
MSX_RSLREG	equ $0138
MSX_WSLREG	equ $013B
MSX_RDVDP	equ $013E
MSX_SNSMAT	equ $0141
MSX_PHYDIO	equ $0144
MSX_FORMAT	equ $0147
MSX_ISFLIO	equ $014A
MSX_OUTDLP	equ $014D
MSX_GETVCP	equ $0150
MSX_GETVC2	equ $0153
MSX_KILBUF	equ $0156
MSX_CALBAS	equ $0159
; --- end of all MSX 1 BIOS calls ---
; Diskrom motor off entry point
MSX_MTOFF	equ	$4029


; I/O PORTS
MSX_DEVID	equ	$40
MSX_SWTIO	equ $41

; VDP PORTS
MSX_VDPDRW	equ	$98	;98H    Read/write data VDP
MSX_VDPCW	equ	$99	;99H    write command to VDP
MSX_VDPSR	equ	$99	;99H    read status from VDP

; RAM PORT
MSX_RAMIO	equ	$A8

; PPI C PORT
MSX_PPICM	equ $AB

; VRAM addresses
MSX_CHRTBL	equ 0000h
MSX_NAMTBL	equ 1800h
MSX_CLRTBL	equ 2000h
MSX_SPRTBL	equ 3800h
MSX_SPRATR	equ 1B00h

; BIOS routine - Turbo-R computers only!
MSX_CHGCPU	equ     0180h
; Constantes de la BIOS
MSX_MSXVER	equ     002dh
; System variables addresses
MSX_VDPPRT	equ	$0007	; VDP port 0
MSX_MSLOT	equ	$F348
MSX_CLIKSW	equ	$F3DB	; Keyboard click sound
MSX_FORCLR	equ	$F3E9	; Foreground colour
MSX_BAKCLR	equ	$F3EA	; Background colour
MSX_BDRCLR	equ	$F3EB	; Border colour
MSX_RG0SAV	equ	$F3DF 	; 	Mirror of VDP register 0 (Basic: VDP(0))
MSX_RG1SAV	equ	$F3E0 	; 	Mirror of VDP register 1 (Basic: VDP(1))
MSX_RG2SAV	equ	$F3E1 	; 	Mirror of VDP register 2 (Basic: VDP(2))
MSX_RG3SAV	equ	$F3E2 	; 	Mirror of VDP register 3 (Basic: VDP(3))
MSX_RG4SAV	equ	$F3E3 	; 	Mirror of VDP register 4 (Basic: VDP(4))
MSX_RG5SAV	equ	$F3E4 	; 	Mirror of VDP register 5 (Basic: VDP(5))
MSX_RG6SAV	equ	$F3E5 	; 	Mirror of VDP register 6 (Basic: VDP(6))
MSX_RG7SAV	equ	$F3E6 	; Mirror of VDP register 7 (Basic: VDP(7))
MSX_RG9SAV	equ	$FFE8	; Mirror of VDP register 9 (Basic: VDP(9))
MSX_STATFL	equ	$F3E7 	; 	Mirror of VDP(8) status register (S#0)
MSX_REPCNT  equ $F3F7
MSX_FNKSTR	equ	$F87F	; Ubicacion textos teclas funcion (se reaprovecha como RAM, 160 bytes)
MSX_NEWKEY	equ	$FBE5
MSX_HIMEM	equ $FC4A	; Highest available RAM
MSX_JIFFY	equ	$FC9E
MSX_EXPTBL	equ	$FCC1	; Bios Slot / Expansion Slot	
MSX_HTIMI   equ $FD9F
MSX_SSSREG	equ $FFFF	; secondary slot select register

; MSX characteristics
MSX_MAXROWS	equ 24
MSX_MAXCOLS	equ 32
MSX_MAXCX	equ 255
MSX_MAXCY	equ 191
MSX_SPRHS	equ 16
MSX_SPRVS	equ 16

; MSX MACROS

	macro BORDER clr
		push af
        ld a,clr             ;Get data to set
        di
        out (MSX_VDPCW),a
        ld a,$87             ;Get register #
        out (MSX_VDPCW),a
		pop af
        ei
	endmacro

	; Set VDP for write (based on DE or HL)
	macro SETWRT reg
	ifdifi reg,de
		ld a,l
		di
		out (MSX_VDPCW),a
		ld a,h
	else
		ld a,e
		di
		out (MSX_VDPCW),a
		ld a,d
	endif
		or 64
		out (MSX_VDPCW),a
		ei		
	endmacro

	; Set VDP for read (based on DE or HL)
	macro SETRD reg
	ifdifi reg,de
		ld a,l
		di
		out (MSX_VDPCW),a
		ld a,h
	else
		ld a,e
		di
		out (MSX_VDPCW),a
		ld a,d
	endif
		and $3F
		out (MSX_VDPCW),a
		ei
	endmacro

	macro HALT1
		ld hl,clock         ; previous clock setting.		
		inc (hl)
.wait:
		ld a,(MSX_JIFFY)        ; current clock setting.
		cp (hl)             ; subtract last reading.
		jp z,.wait        ; yes, no more processing please.
		ld (hl),a
	endmacro

	macro HALT2
		ifdef DEBUG
		BORDER 13
		endif
		ei
		ld hl,MSX_JIFFY
		ld a,(hl)
.wait:
		cp (hl)
		jr z,.wait
		ifdef DEBUG
		BORDER 14
		endif
	endmacro

	macro ADD_HL_A
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a	
	endmacro

	macro ADD_DE_A
		add a,e
		ld e,a
		adc a,d
		sub e
		ld d,a	
	endmacro

	macro ADD_BC_A
		add a,c
		ld c,a
		adc a,b
		sub c
		ld b,a	
	endmacro

	macro EX_SP_DE
		ex de,hl
		ex (sp),hl
		ex de,hl
	endmacro
	
; =============================================================================================
 
; Block characteristics.

PLATFM	equ 1               ; platform.
WALL	equ PLATFM + 1      ; solid wall.
LADDER	equ WALL + 1        ; ladder.
FODDER	equ LADDER + 1      ; fodder block.
DEADLY	equ FODDER + 1      ; deadly block.
CUSTOM	equ DEADLY + 1      ; custom block.
WATER	equ CUSTOM + 1      ; water block.
COLECT	equ WATER + 1       ; collectable block.
NUMTYP	equ COLECT + 1      ; number of types.

; MSX system clock variable
clock	equ	MSX_JIFFY

; Objects

	if DISTYPE=ROM

OBJSIZ 	equ 67				; size of each object entry
ODTSIZ 	equ 3			   	; object data size
		
	else
	
OBJSIZ 	equ 70				; size of each object entry
ODTSIZ 	equ 6			   	; object data size

	endif

; Sprites.

NUMSPR 	equ 32              ; number of sprites.
TABSIZ 	equ 17              ; size of each entry.
SPRBUF 	equ NUMSPR * TABSIZ ; size of entire table.
NMESIZ 	equ 5               ; bytes stored in nmetab for each sprite.
X      	equ 3               ; new x coordinate of sprite.
Y      	equ X + 1           ; new y coordinate of sprite.
PAM1ST	equ 5               ; first sprite parameter, old x (ix+5).

	
; Particle engine.

	if PFLAG

NUMSHR	equ 54              ; pieces of shrapnel.
SHRSIZ	equ 9               ; bytes per particle.
VAPTIM	equ 10				; vapour particle life time
		
	endif
	
; Game starts here.  No reason why screen data couldn't go between start and contrl to put them in
; contended RAM, leaving the code and rest of the game in uncontended memory at 32768 and beyond.

start:
	if DISTYPE=ROM
		ld sp,$F380
	else
 		ld hl,(MSX_HIMEM)
		dec hl
		ld sp,hl
	endif
 		
	if DISTYPE=DISK
		call drvmotoff
	endif
		
		; ld sp,$F380

		; ld hl,TIMETICKS
		; ld e,50

		; initialize vars
		
		ld hl,varbegin
		ld de,varbegin+1
		ld bc,(varend-varbegin)-1
		ld (hl),0
		ldir
		
		ld a,(MSX_MSXVER)      	; version del MSX
		inc a
		dec a
		jr z,.common
		dec a
		jr z,.MSX2
		dec a
		jr z,.MSX2P
		; ld e,60
		; it's a TR		
	if EFLAG
		ld a,255
		ld (snddelay),a
	endif
		jr .MSX2
.MSX2P:
		in a,(MSX_DEVID)
		cpl
		push af
		ld a,8
		out (MSX_DEVID),a  		;out the manufacturer code 8 (Panasonic) to I/O port 40h
		in a,(MSX_DEVID)   		;read the value you have just written
		cpl          			;complement all bits of the value
		cp 8         			;if it does not match the value you originally wrote,
		jr nz,.notWX  			;it is not a WX/WSX/FX.
		xor a        			;write 0 to I/O port 41h
		out (MSX_SWTIO),a  		;and the mode changes to high-speed clock
	if EFLAG
		ld a,32
		ld (snddelay),a
	endif
.notWX:
		pop af
		out (MSX_DEVID),a
.MSX2:	
		
		ld hl,palett
		call setpal
		ld a,(MSX_RG9SAV)
		or 2
		ld b,a
		ld c,9
		call MSX_WRTVDP			; forces 50Hz
		
.common:		
		; ld [hl],e
		ld a,(MSX_CHGCPU)
		cp $C3
		ld a,$81
		call z,MSX_CHGCPU		; if turbo available, set it

		; Set up the display if needed
	if QFLAG=0
	
		ld hl,$0101
		ld (MSX_FORCLR+1),hl    ; sets background & border colour to black
		ld a,2
		call MSX_CHGMOD			; set display to screen 2
		
		ld a,(MSX_RG1SAV)
		or 2
		ld b,a
		ld c,1
		call MSX_WRTVDP			; enable 16x16 sprites

		xor a
		ld (MSX_CLIKSW),a       ; disables keyboard click

	endif
		
		ld a,$F1
		ld (clratt),a
	
	if YFLAG
		call music_init
	endif
	if XFLAG
		call sfx_init
	endif
	
		; installs ISR
		call instisr	

	; When ROM, setup of variables with starting value
	if DISTYPE=ROM
		
		xor a
	if EFLAG
		ld hl,sndtyp
		ld (hl),a
	endif
		; ROM mode needs to initialize some vars
		ld hl,score         ; scores.		
		ld de,score+1       ; next byte.
		ld bc,17			; size of score vars.
		ld (hl),'0'        	; write '0'
		ldir
		ld hl,displ0
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		ld (hl),13+128
	if SFLAG
		inc a				; A=1
		ld (scrlyoff),a		; by default, no scrolltext
	endif
	if PFLAG
		ld hl,prosh1
		ld (shrplot),hl
	endif
	if MFLAG
		ld a,$C3
		ld (mod0),a
		ld (mod1),a
		ld (mod2),a
	endif
		ld hl,keytab
		ld de,keys
		ld bc,22
		ldir
	; DATA command initialization
	ifdef DATA00
		ld hl,rdat00
		ld (rptr00),hl
	endif
	ifdef DATA01
		ld hl,rdat01
		ld (rptr01),hl
	endif
	ifdef DATA02
		ld hl,rdat02
		ld (rptr02),hl
	endif
	ifdef DATA03
		ld hl,rdat03
		ld (rptr03),hl
	endif
	ifdef DATA04
		ld hl,rdat04
		ld (rptr04),hl
	endif
	ifdef DATA05
		ld hl,rdat05
		ld (rptr05),hl
	endif
	ifdef DATA06
		ld hl,rdat06
		ld (rptr06),hl
	endif
	ifdef DATA07
		ld hl,rdat07
		ld (rptr07),hl
	endif
	ifdef DATA08
		ld hl,rdat08
		ld (rptr08),hl
	endif
	ifdef DATA09
		ld hl,rdat09
		ld (rptr09),hl
	endif
	ifdef DATA10
		ld hl,rdat10
		ld (rptr10),hl
	endif
	ifdef DATA11
		ld hl,rdat11
		ld (rptr11),hl
	endif
	ifdef DATA12
		ld hl,rdat12
		ld (rptr12),hl
	endif
	ifdef DATA13
		ld hl,rdat13
		ld (rptr13),hl
	endif
	ifdef DATA14
		ld hl,rdat14
		ld (rptr14),hl
	endif
	ifdef DATA15
		ld hl,rdat15
		ld (rptr15),hl
	endif
	ifdef DATA16
		ld hl,rdat16
		ld (rptr16),hl
	endif
	ifdef DATA17
		ld hl,rdat17
		ld (rptr17),hl
	endif
	ifdef DATA18
		ld hl,rdat18
		ld (rptr18),hl
	endif
	ifdef DATA19
		ld hl,rdat19
		ld (rptr19),hl
	endif
	ifdef DATA20
		ld hl,rdat20
		ld (rptr20),hl
	endif
	
	endif

		jp game             ; start the game.

; Don't change the order of these four.  Menu routine relies on winlft following wintop.

wintop db WINDOWTOP		; top of window.
winlft db WINDOWLFT		; left edge.
winhgt db WINDOWHGT		; window height.
winwid db WINDOWWID		; window width.

numob  db NUMOBJ         ; number of objects in game.

; Variables start here.
; Pixel versions of wintop, winlft, winhgt, winwid.

wntopx db (8 * WINDOWTOP) + 1
wnlftx db (8 * WINDOWLFT)
wnbotx db ((WINDOWTOP * 8) + (WINDOWHGT * 8) - 16)
wnrgtx db ((WINDOWLFT * 8) + (WINDOWWID * 8) - 16)


; Make sure pointers are arranged in the same order as the data itself.

frmptr dw frmlst         ; sprite frames.
blkptr dw chgfx          ; block graphics.
proptr dw bprop          ; address of char properties.
scrptr dw scdat          ; address of screens.
nmeptr dw nmedat         ; enemy start positions.


drvmotoff:
		ld a,(MSX_MSLOT)		; motor off entry present?
		ld hl,MSX_MTOFF
		call MSX_RDSLT
		and	a
		ret	z			; no, no way....
		ld iy,(MSX_MSLOT-1)	; we have it! call it now
		ld ix,MSX_MTOFF
		jp MSX_CALSLT

	if MFLAG
	
; Modify for inventory.

minve:
		ld hl,invdis        ; routine address.
		ld (mod0+1),hl      ; set up menu routine.
		ld (mod2+1),hl      ; set up count routine.
		ld hl,fopt          ; find option from available objects.
		ld (mod1+1),hl      ; set up routine.
		jr dbox             ; do menu routine.

; Modify for menu.

mmenu:
		ld hl,always        ; routine address.
		ld (mod0+1),hl      ; set up routine.
		ld (mod2+1),hl      ; set up count routine.
		ld hl,fstd          ; standard option selection.
		ld (mod1+1),hl      ; set up routine.

; Drop through into box routine.

; Work out size of box for message or menu.

dbox:   		
		ld hl,msgdat        ; pointer to messages.
		call getwrd         ; get message number.
		push hl             ; store pointer to message.
		ld d,1              ; height.
		xor a               ; start at object zero.
		ld (combyt),a       ; store number of object in combyt.
		ld e,a              ; maximum width.
dbox5:
		ld b,0              ; this line's width.
;mod2:						 ; auto-modifying code
;		call always
		
		call mod2		
		jr nz,dbox6         ; not in inventory, skip this line. (dbox3?)
		inc d               ; add to tally.
dbox6:
		ld a,(hl)           ; get character.
		inc hl              ; next character.
		cp ','              ; reached end of line?
		jr z,dbox3          ; yes.
		cp 13               ; reached end of line?
		jr z,dbox3          ; yes.
		inc b               ; add to this line's width.
		and a               ; end of message?
		jp m,dbox4          ; yes, end count.
		jr dbox6            ; repeat until we find the end.
dbox3:
		ld a,e              ; maximum line width.
		cp b                ; have we exceeded longest so far?
		jr nc,dbox5         ; no, carry on looking.
		ld e,b              ; make this the widest so far.
		jr dbox5            ; keep looking.
dbox4:
		ld a,e              ; maximum line width.
		cp b                ; have we exceeded longest so far?
		jr nc,dbox8         ; no, carry on looking.
		ld e,b              ; final line is the longest so far.
dbox8:
		dec d               ; decrement items found.
		jp z,dbox15         ; total was zero.
		ld a,e              ; longest line.
		and a               ; was it zero?
		jp z,dbox15         ; total was zero.
		ld (bwid),de        ; set up size.

; That's set up our box size.

		call dissprs

		ld a,(winhgt)       ; window height in characters.
		sub d               ; subtract height of box.
		rra                 ; divide by 2.
		ld hl,wintop        ; top edge of window.
		add a,(hl)          ; add displacement.
		ld (btop),a         ; set up box top.
		ld a,(winwid)       ; window width in characters.
		sub e               ; subtract box width.
		rra                 ; divide by 2.
		inc hl              ; left edge of window.
		add a,(hl)          ; add displacement.
		ld (blft),a         ; box left.

		ld hl,font-256       ; font.
		ld (grbase),hl      ; set up for text display.
		pop hl              ; restore message pointer.
		ld a,(btop)         ; box top.
		ld (dispx),a        ; set display coordinate.
		xor a               ; start at object zero.
		ld (combyt),a       ; store number of object in combyt.
dbox2:
		ld a,(combyt)       ; get object number.
;mod0:						 ; auto-modifying code
;		call always         ; check inventory for display.


		call mod0		
		jp nz,dbox13        ; not in inventory, skip this line.
		ld a,(blft)         ; box left.
		ld (dispy),a        ; set left display position.
		ld a,(bwid)         ; box width.
		ld b,a              ; store width.
	   
dbox0:  
		ld a,(hl)           ; get character.
		cp ','              ; end of line?
		jr z,dbox1          ; yes, next one.
		cp 13               ; end of option?
		jr z,dbox1          ; yes, on to next.
		dec b               ; one less to display.
		and 127             ; remove terminator.

		push bc             ; store characters remaining.
		push hl             ; store address on stack.


		call ptxt           ; display character.		
		
		ld hl,dispy         ; y coordinate.
		inc (hl)            ; move along one.
		
		pop hl              ; retrieve address of next character.
		pop bc              ; chars left for this line.

		ld a,(hl)           ; get character.
		inc hl              ; next character.
		cp 128              ; end of message?
		jp nc,dbox7         ; yes, job done.
		ld a,b              ; chars remaining.
		and a               ; are any left?
		jr nz,dbox0         ; yes, continue.

; Reached limit of characters per line.

dbox9:
		ld a,(hl)           ; get character.
		inc hl              ; next one.
		cp ','              ; another line?
		jr z,dbox10         ; yes, do next line.
		cp 13               ; another line?
		jr z,dbox10         ; yes, on to next.
		cp 128              ; end of message?
		jr nc,dbox11        ; yes, finish message.
		jr dbox9

; Fill box to end of line.

dboxf:
		push hl             ; store address on stack.
		push bc             ; store characters remaining.	   
		ld a,32
		call ptxt           ; display character.		
		
		ld hl,dispy         ; y coordinate.
		inc (hl)            ; move along one.		
		pop bc              ; retrieve character count.
		pop hl              ; retrieve address of next character.
		djnz dboxf          ; repeat for remaining chars on line.
		ret

dbox1:
		inc hl              ; skip character.
		call dboxf          ; fill box out to right side.
dbox10:
		ld a,(dispx)        ; x coordinate.
		inc a               ; down a line.
		ld (dispx),a        ; next position.
		jp dbox2            ; next line.
dbox7:
		ld a,b              ; chars remaining.
		and a               ; are any left?
		jr z,dbox11         ; no, nothing to draw.
		call dboxf          ; fill message to line.

; Drawn the box menu, now select option.

dbox11:
		ld a,(btop)         ; box top.
		ld (dispx),a        ; set bar position.
dbox14:
		call joykey         ; get controls.
		and 31              ; anything pressed?
		jr nz,dbox14        ; yes, debounce it.
		call dbar           ; draw bar.
dbox12:
		call joykey         ; get controls.
		and 28              ; anything pressed?
		jr z,dbox12         ; no, nothing.
		and 16              ; fire button pressed?
;mod1:						 ; auto-modifying code
;		jp nz,fstd          ; yes, job done.

		
		jp nz,mod1
		call dbar           ; delete bar.
		ld a,(joyval)       ; joystick reading.
		and 8               ; going up?
		jr nz,dboxu         ; yes, go up.
		ld a,(dispx)        ; vertical position of bar.
		inc a               ; look down.
		ld hl,btop          ; top of box.
		sub (hl)            ; find distance from top.
		dec hl              ; point to height.
		cp (hl)             ; are we at end?
		jp z,dbox14         ; yes, go no further.
		ld hl,dispx         ; coordinate.
		inc (hl)            ; move bar.
		jr dbox14           ; continue.
dboxu:
		ld a,(dispx)        ; vertical position of bar.
		ld hl,btop          ; top of box.
		cp (hl)             ; are we at the top?
		jp z,dbox14         ; yes, go no further.
		ld hl,dispx         ; coordinate.
		dec (hl)            ; move bar.
		jr dbox14           ; continue.
fstd:
		ld a,(dispx)        ; bar position.
		ld hl,btop          ; top of menu.
		sub (hl)            ; find selected option.
		ld (varopt),a       ; store the option.
		jp redraw           ; redraw the screen.

; Option not available.  Skip this line.

dbox13:
		ld a,(hl)           ; get character.
		inc hl              ; next one.
		cp ','              ; another line?
		jp z,dbox2          ; yes, do next line.
		cp 13               ; another line?
		jp z,dbox2          ; yes, on to next line.
		and a               ; end of message?
		jp m,dbox11         ; yes, finish message.
		jr dbox13
dbox15:
		pop hl              ; pop message pointer from the stack.
		ret

dbar:
		ld a,(blft)         ; box left.
		ld (dispy),a        ; set display coordinate.
		call gprad          ; get printing address.
		ex de,hl            ; flip into hl register pair.
	   
		set 5,h
		ld a,(bwid)         ; box width.
		add a,a
		add a,a
		add a,a
		ld c,a
		ld b,0
		call MSX_RDVRM
		rlca
		rlca
		rlca
		rlca
		jp MSX_FILVRM

invdis:
		push hl             ; store message text pointer.
		push de             ; store de pair for line count.
		ld hl,combyt        ; object number.
		ld a,(hl)           ; get object number.
		inc (hl)            ; ready for next one.
		call gotob          ; check if we have object.
		pop de              ; retrieve de pair from stack.
		pop hl              ; retrieve text pointer.
		ret
		
; Find option selected.

fopt:
		ld a,(dispx)
		ld hl,btop          ; top of menu.
		sub (hl)            ; find selected option.
		inc a               ; object 0 needs one iteration, 1 needs 2 and so on.
		ld b,a              ; option selected in b register.
		ld hl,combyt        ; object number.
		ld (hl),0           ; set to first item.
fopt0:
		push bc             ; store option counter in b register.
		call fobj           ; find next object in inventory.
		pop bc              ; restore option counter.
		djnz fopt0          ; repeat for relevant steps down the list.
		ld a,(combyt)       ; get option.
		dec a               ; one less, due to where we increment combyt.
		ld (varopt),a       ; store the option.
		xor a
		ld (joyval),a
		jp redraw           ; redraw the screen.

fobj:
		ld hl,combyt        ; object number.
		ld a,(hl)           ; get object number.
		inc (hl)            ; ready for next item.
		ret z               ; in case we loop back to zero.
		call gotob          ; do we have this item?
		ret z               ; yes, it's on the list.
		jr fobj             ; repeat until we find next item in pockets.

	endif

;
; installs ISR
;
instisr:
		di
		ld HL,htimi
		ld (MSX_HTIMI+1),HL
		ld A,$C3
		ld (MSX_HTIMI),A
		ei
		ret

;
; ISR
;
htimi:
        ld (MSX_STATFL),a      ;Store this new status
        ld hl,(MSX_JIFFY)
        inc hl
        ld (MSX_JIFFY),hl		
	if (YFLAG or XFLAG)	
		call psgrout
	if YFLAG
		call music_play
	endif
	if XFLAG
		call sfx_play
	endif
	endif
		pop af					; pops out the hook return address		
        pop ix              ;Restore all registers
        pop iy
        pop af
        pop bc
        pop de
        pop hl
        ex  af,af
        exx
        pop af
        pop bc
        pop de
        pop hl
        ei
        ret						; returns from interrupt
		
;
; Wait for keypress.
;	   
chkkey:
		call vsync
		ld b,11
.nokey:
		ld a,b
		dec a
		call MSX_SNSMAT
		cp 255
		ret nz
		djnz .nokey
		jr chkkey

prskey:
		call chkkey
		
; Debounce keypress.
		
debkey:
		call vsync
		ld b,11
.nokey:
		ld a,b
		dec a
		call MSX_SNSMAT
		cp 255
		jr nz,debkey
		djnz .nokey
		ret

; Delay routine.

delay:
		push bc             ; store loop counter.
		call vsync          ; wait for interrupt.
		pop bc              ; restore counter.
		djnz delay          ; repeat.
		ret

; Clear sprite table.

xspr:
		ld hl,sprtab       ; sprite table.
		ld de,sprtab+1
		ld (hl),255
		ld bc,SPRBUF-1     ; length of table.
		ldir
		xor a
		ld (highslot),a		; resets also highest sprite slot number
;
xspr0:
		ld hl,mapspr       ; sprite images map.
		ld de,mapspr+1
		ld (hl),255
		ld bc,127          ; length of table.
		ldir
;
		ld hl,spratr       ; sprite attributes buffer.
		ld de,spratr+1
		ld (hl),0
		ld c,127           ; length of table.
		ldir
		ret
		
	if OFLAG
	
; Initialise all objects.

	if DISTYPE=ROM

iniob:
		ld a,(numob)        ; number of objects in the game.
		ld b,a
		ld hl,objdta        ; objects table.
		ld de,objatr
.loop:
		ld a,OBJSIZ-ODTSIZ  ; distance between objects.
		ld c,a
		ldi
		ldi
		ldi
		ADD_HL_A
		djnz .loop         ; repeat.
		ret

	else
	
iniob:
		ld ix,objdta        ; objects table.
		ld a,(numob)        ; number of objects in the game.
		ld b,a              ; loop counter.
		ld de,OBJSIZ        ; distance between objects.
.loop:
		ld a,(ix+67)        ; start screen.
		ld (ix+64),a        ; set start screen.
		ld a,(ix+68)        ; find start x.
		ld (ix+65),a        ; set start x.
		ld a,(ix+69)        ; get initial y.
		ld (ix+66),a        ; set y coord.
		add ix,de           ; point to next object.
		djnz .loop         ; repeat.
		ret

	endif
	
	endif
	
	
; Screen synchronisation.

vsync:
		ld hl,MSX_JIFFY
		ld a,(hl)

	if SFLAG
		push af
		push hl
		call scrltxt
		pop hl
		pop af
		cp (hl)
		jr z,.novbl0
		call scrly
	if PFLAG
		call proshr
	endif
		call buildspr
	if EFLAG
		call beeper
	endif
		call rdinputs
		jr .nowait
		
.novbl0:		
	endif

	if PFLAG
		
		push af
		push hl
		call proshr
		pop hl
		pop af
		cp (hl)
		jr z,.novbl1
	if SFLAG
		call scrly
	endif
		call buildspr
	if EFLAG
		call beeper
	endif
		call rdinputs
		jr .nowait
		
.novbl1:		
	endif
		
		push af
		push hl
		call buildspr
		pop hl
		pop af
		cp (hl)
		jr z,.novbl2
	if SFLAG
		call scrly
	endif
	if EFLAG
		call beeper
	endif
		call rdinputs
		jr .nowait

.novbl2:
	if EFLAG
		call beeper
	endif
		cp (hl)
		jr z,.novbl3
	if SFLAG
		call scrly
	endif
		call rdinputs
		jr .nowait
		
.novbl3:
		push af
		push hl
		call rdinputs
		pop hl
		pop af
		cp (hl)
		; jr z,.novbl5
		jr z,.wait
	if SFLAG
		call scrly
	endif
		jr .nowait
		
.wait:		
	ifdef DEBUG
		BORDER 13
	endif
		cp (hl)
		jr z,.wait
	if SFLAG
		call scrly
	endif
	
.nowait:
	ifdef DEBUG
		BORDER 14
	endif
		ret

rdinputs:
		ld a,(MSX_JIFFY)
		rrca
		ret c
		jp joykey
		
	if EFLAG
	
beeper:
	ifdef DEBUG
		BORDER 15
	endif
		ld e,a				; keeps JIFFY
		ld a,(sndtyp)       ; sound to play.
		and a               ; any sound?
		jr z,beep1			; no.
		ld b,a              ; outer loop.
		and a               ; test it.
		ld c,14				; first value to write (0)
		jp m,noise          ; play white noise.
.beep2:
		ld a,c              ; (5) get speaker value.
		out (MSX_PPICM),a   ; (12) write to speaker.
		xor 1               ; (7) toggle bit 0.
		ld c,a              ; (5) store value for next time.
		ld d,b              ; (5) store loop counter.
		
		ld a,(snddelay)
		or a
		jr z,.nodelay
		ld b,a
		djnz $
		ld b,d
.nodelay:		
		ld a,e				; (5) restore old JiFFY
.beep3:
		cp (hl)				; (8) next frame?
		jr nz,.beep4		; (8/13) yes, no more processing please.
		djnz .beep3         ; (14/9) loop while frame doesn't changes.
		
		ld b,d              ; (5) restore loop counter.
		djnz .beep2         ; (14/9) continue noise.
							; (87)
.beep4:
		ld a,d              ; where we got to.
vsynca:
		ld (sndtyp),a       ; remember for next time.
beep1:		
		ld a,e

	ifdef DEBUG
		BORDER 14
	endif

		ret

; Play white noise

noise: 
		sub 127
		ld b,a				; outer loop
vsync7:
		ld a,r              ; get random speaker value.
		and 2               ; only retain the speaker/earphone bits.
		rrca
		or c                ; merge with command PPI bit 7.
		out (MSX_PPICM),a   ; write to speaker.
		ld a,e				; restore old JiFFY
		cp (hl)             ; subtract last reading.
		jp nz,vsync8        ; yes, no more processing please.
		ld a,b
		;and 127
		inc a
vsync9:
		dec a
		jr nz,vsync9        ; loop.
		djnz vsync7         ; continue noise.
vsync8:
		xor a
		jr vsynca

	endif
	
; Redraw the screen.

redraw:
		call clrscrmap
		push ix             ; place sprite pointer on stack.
		call droom          ; show screen layout.
	if OFLAG
		call shwob          ; draw objects.
	endif

		HALT2
		
		ld hl,spratr
		ld de,MSX_SPRATR
		ld b,128
		call ram2vram			   
	   
rpblc1:
	if PFLAG
		call dshrp          ; redraw shrapnel.
	endif
	if AFLAG
		call rbloc          ; draw blocks for this screen
	endif
		pop ix              ; retrieve sprite pointer.
		ret

; Clear screen routine.

cls:
		ld a,(clratt)
		ld e,a
		and $F0
		rrca
		rrca
		rrca
		rrca
		ld (MSX_FORCLR),a
		ld a,e
		and $0F
		ld (MSX_BAKCLR),a
		xor a
		call MSX_CLS
		ld hl,0             ; set hl to origin (0, 0).
		ld (charx),hl       ; reset coordinates.
		call clrscrmap
		jp dissprs

; Set palette routine and data.
; Palette.

setpal:
		ld a,(MSX_VDPPRT)	; get first VDP write port
		ld c,a
		inc c      		; prepare to write register data
		xor a      		; from color 0
		out (c),a
		ld a,16+128		; write R#16
		out (c),a
		inc c      		; prepare to write palette data
		ld b,32      	; 16 color * 2 bytes for palette data
		otir
		ret
		
	if (PFLAG or DFLAG)
	
fdchk:
		ld a,(hl)           ; fetch cell.
		cp FODDER           ; is it fodder?
		ret nz              ; no.
		ld (hl),0           ; rewrite block type.
		push hl             ; store pointer to block.
		ld de,MAP           ; address of map.
		and a               ; clear carry flag for subtraction.
		sbc hl,de           ; find simple displacement for block.
		ld a,l              ; low byte is y coordinate.
		and 31              ; column position 0 - 31.
		ld (dispy),a        ; set up y position.
		add hl,hl           ; multiply displacement by 8.
		add hl,hl
		add hl,hl
		ld a,h              ; x coordinate now in h.
		ld (dispx),a        ; set the display coordinate.
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.		
		xor a               ; block to write.
		call pattr          ; write block.
		pop hl              ; restore block pointer.
		ret
		
	endif
	
; Colour a sprite.

cspr:
		ld (ix+5),c
		ret
				
	if PFLAG

; Specialist routines.
; Process shrapnel.
		
proshr:
		call setshr
		
proshrnoset:
		
	ifdef DEBUG
		BORDER 5
	endif

		call proshr0
		call proshr0
		call proshr0
		call proshr0
		call proshr0
		call proshr0
		call proshr0
		call proshr0
		call proshr0
 	
	ifdef DEBUG
		BORDER 14
	endif
	
		ret

setshr:
		ld a,(MSX_JIFFY)
setshr0:
		ld hl,SHRAPN+SHRSIZ        ; table.
		rrca
		jr c,.shrodd
		ld hl,SHRAPN			 ; table.
.shrodd:
		ld (shraddr),hl
		ret
		
proshr0:
		ld ix,(shraddr)
		ld b,NUMSHR/(9*2)
proshloop:
		ld a,(ix+0)         ; on/off marker.
		rla                 ; check its status.
;proshx:						; auto-modifying code

		call nc,proshx      ; on, so process it.
		ld de,SHRSIZ*2      ; distance to next.
		add ix,de           ; point there.
		djnz proshloop      ; round again.
		ld (shraddr),ix
		ret

proshx:
		ld hl,(shrplot)
		jp (hl)

prosh1:
		push bc             ; store counter.
		call plot           ; delete the pixel.
		ld a,(ix+0)         ; restore shrapnel type.
		call prosh2         ; run the routine.
		call chkxy          ; check x and y are good before we redisplay.
		pop bc              ; restore counter.
		ret
prosh2:
		add a,a		
		add a,shrptr&$FF
		ld l,a
		ld h,shrptr>>8
		;ld (addr+1),a			; auto-modifying code
;addr:
		;ld hl,(shrptr)

		jp jumphl
 

; Explosion shrapnel.

/* shrap: ; 220
		ld h,(shrsin >> 8) & $FF    ; Get MSB of table
		ld l,(ix+1)
		
		ld e,(hl)           ; fetch value from table.
		inc hl              ; next byte of table.
		ld d,(hl)           ; fetch value from table.
		
		inc hl              ; next byte of table.
		ld c,(hl)           ; fetch value from table.
		inc hl              ; next byte of table.
		ld b,(hl)           ; fetch value from table.
		
		ld l,(ix+2)         ; x coordinate in hl.
		ld h,(ix+3)
		add hl,de           ; add sine.
		ld (ix+2),l         ; store new coordinate.
		ld (ix+3),h
		
		ld l,(ix+4)         ; y coordinate in hl.
		ld h,(ix+5)
		add hl,bc           ; add cosine.
		ld (ix+4),l         ; store new coordinate.
		ld (ix+5),h
		ret
 */
 ; 182 -> 156
shrap: 
		ld h,shrsin>>8    ; Get MSB of table
		ld a,(ix+1)
		add a,shrsin&$FF	; table offset (saving some bytes)
		ld l,a
		di
		ld (stack),sp
		ld sp,hl
		pop de						; fetch sine
		pop bc						; fetch cosine
		ld sp,ix
		pop hl
		pop hl
		add hl,de
		push hl		
		pop hl
		pop hl
		add hl,bc
		push hl				
		ld sp,(stack)            ;parameter will overwritten
		ei
		ret
		
dotl   dec (ix+5)          ; move left.
       ret
dotr   inc (ix+5)          ; move left.
       ret
dotu   dec (ix+3)          ; move up.
       ret
dotd   inc (ix+3)          ; move down.
       ret

; Check coordinates are good before redrawing at new position.

chkxy:
;		ld (ix+7),255

		ld hl,wntopx        ; window top.
		ld a,(ix+3)         ; fetch shrapnel coordinate.
		cp (hl)             ; compare with top window limit.
		jr c,kilshr         ; out of window, kill shrapnel.
		inc hl              ; left edge.
		ld a,(ix+5)         ; fetch shrapnel coordinate.
		cp (hl)             ; compare with left window limit.
		jr c,kilshr         ; out of window, kill shrapnel.

		inc hl              ; point to bottom.
		ld a,(hl)           ; fetch window limit.
		add a,15            ; add height of sprite.
		cp (ix+3)           ; compare with shrapnel x coordinate.
		jr c,kilshr         ; off screen, kill shrapnel.
		inc hl              ; point to right edge.
		ld a,(hl)           ; fetch shrapnel y coordinate.
		add a,15            ; add width of sprite.
		cp (ix+5)           ; compare with window limit.
		jr nc,plot         ; off screen, kill shrapnel.

kilshr:
		ld (ix+0),128       ; switch off shrapnel.
		; ld (ix+7),255       ; switch off shrapnel.
		
		ret


; Drop through.
; Display shrapnel.

plot:   ; ret

		ld l,(ix+3)         ; x integer.
		ld h,(ix+5)         ; y integer.
		ld (dispx),hl       ; workspace coordinates.
		ld a,(ix+0)         ; type.
		and a               ; is it a laser?
		jr z,plot1          ; yes, draw laser instead.
/*	   
plot0:

		ld a,(ix+7)
		cp 255
		jr z,.initplot

		ld l,(ix+6)
		ld h,a
		SETWRT hl
		ld a,(ix+8)
		out (MSX_VDPDRW),a
		ret

.initplot:
		ld a,h              ; which pixel within byte do we
		and 7               ; want to set first?		
		ld h,dots>>8		; Get MSB of table
		ld l,a		
		ld e,(hl)           ; get value.
		call scadd          ; screen address.		
		SETRD hl
		ld (ix+6),l
		ld (ix+7),h
		in a,(MSX_VDPDRW)
		ld (ix+8),a
		xor e
		ld e,a
		SETWRT hl
		ld a,e
		out (MSX_VDPDRW),a
		ret
*/
plot0:
		ld a,h              ; which pixel within byte do we
		and 7               ; want to set first?		
		ld h,dots>>8		; Get MSB of table
		ld l,a		
		ld e,(hl)           ; get value.			
		call scadd          ; screen address.		
		SETRD hl
		nop
		nop
		in a,(MSX_VDPDRW)
		xor e
		ld e,a
		SETWRT hl
		ld a,e
		out (MSX_VDPDRW),a				
		ret	   
plot1:
		call scadd          ; screen address.
		SETRD hl
		nop
		nop
		in a,(MSX_VDPDRW)
		cpl
		ld e,a
		SETWRT hl
		ld a,e
		out (MSX_VDPDRW),a		
		ret


trail:
		dec (ix+1)          ; time remaining.
		jp z,trailk        ; time to switch it off.
		call qrand          ; get a random number.
		rra                 ; x or y axis?
		jr c,.trailv        ; use x.
		rra                 ; which direction?
		jr c,.traill        ; go left.
		inc (ix+5)          ; go right.
		ret
.traill:
		dec (ix+5)          ; go left.
		ret
.trailv:
		rra                 ; which direction?
		jr c,.trailu        ; go up.
		inc (ix+3)          ; go down.
		ret
.trailu:
		dec (ix+3)          ; go up.
		ret
trailk:
		ld (ix+3),200       ; set off-screen to kill vapour trail.
		ret

laser:
		ld a,(ix+1)         ; direction.
		rra                 ; left or right?
		jr nc,laserl        ; move left.
		ld b,8              ; distance to travel.
		jr laserm           ; move laser.
laserl:
		ld b,248            ; distance to travel.
laserm:
		ld a,(ix+5)         ; y position.
		add a,b             ; add distance.
		ld (ix+5),a         ; set new y coordinate.

; Test new block.

		ld (dispy),a        ; set y for block collision detection purposes.
		ld a,(ix+3)         ; get x.
		ld (dispx),a        ; set coordinate for collision test.
		call tstbl          ; get block type there.
		cp WALL             ; is it solid?
		jr z,trailk         ; yes, it cannot pass.

	if (PFLAG or DFLAG)
		cp FODDER           ; is it fodder?
		jr nz,.exit         ; no, ignore it.
		call fdchk          ; remove fodder block.
		jr trailk           ; destroy laser.
.exit
	endif
		ret

; Plot, preserving de.

plotde:
		push de             ; put de on stack.
		call plot           ; plot pixel.
		pop de              ; restore de from stack.
		ret

; Shoot a laser.

shoot:
		ld c,a              ; store direction in c register.
		ld a,(ix+3)         ; sprite x coordinate.
shoot1:
		add a,7             ; down 7 pixels.
		ld l,a              ; puty x coordinate in l.
		ld h,(ix+4)         ; sprite y coordinate in h.
		push ix             ; store pointer to sprite.
		call fpslot         ; find particle slot.
		jr nc,vapou2        ; failed, restore ix.
		ld (ix+0),0         ; set up a laser.
		ld (ix+1),c         ; set the direction.
		ld (ix+3),l         ; set x coordinate.
		rr c                ; check direction we want.
		jr c,shootr         ; shoot right.
		ld a,h              ; y position.

shoot0:
		and 248             ; align on character boundary.
		ld (ix+5),a         ; set y coordinate.
		jr vapou0           ; draw first image.
shootr:
		ld a,h              ; y position.
		add a,15            ; look right.
		jr shoot0           ; align and continue.

; Create a bit of vapour trail.

vapour:
		push ix             ; store pointer to sprite.
		ld l,(ix+3)         ; x coordinate.
		ld h,(ix+4)         ; y coordinate.
vapou3:
		ld de,7*256+7       ; mid-point of sprite.
		add hl,de           ; point to centre of sprite.
		call fpslot         ; find particle slot.
		jr c,vapou1         ; no, we can use it.
vapou2:
		pop ix              ; restore sprite pointer.
		ret                 ; out of slots, can't generate anything.
vapou1:
		ld (ix+3),l         ; set up x.
		ld (ix+5),h         ; set up y coordinate.
		call qrand          ; get quick random number.
		and 15              ; random time.
		add a,VAPTIM      ; minimum time on screen.
		ld (ix+1),a         ; set time on screen.
		ld (ix+0),1         ; define particle as vapour trail.
vapou0:
		call chkxy          ; plot first position.
		jr vapou2

; Create a user particle.

ptusr:
		ex af,af            ; store timer.
		ld l,(ix+3)         ; x coordinate.
		ld h,(ix+4)         ; y coordinate.
		ld de,7*256+7       ; mid-point of sprite.
		add hl,de           ; point to centre of sprite.
		call fpslot         ; find particle slot.
		jr c,.ptusr1        ; no, we can use it.
		ret                 ; out of slots, can't generate anything.
.ptusr1:
		ld (ix+3),l         ; set up x.
		ld (ix+5),h         ; set up y coordinate.
		ex af,af            ; restore timer.
		ld (ix+1),a         ; set time on screen.
		ld (ix+0),7         ; define particle as user particle.
		jp chkxy            ; plot first position.


; Create a vertical or horizontal star.

star   push ix             ; store pointer to sprite.
       call fpslot         ; find particle slot.
       jp c,star7          ; found one we can use.
star0  pop ix              ; restore sprite pointer.
       ret                 ; out of slots, can't generate anything.

star7  ld a,c              ; direction.
       and 3               ; is it left?
       jr z,star1          ; yes, it's horizontal.
       dec a               ; is it right?
       jr z,star2          ; yes, it's horizontal.
       dec a               ; is it up?
       jr z,star3          ; yes, it's vertical.

       ld a,(wntopx)       ; get edge of screen.
       inc a               ; down one pixel.
star8  ld (ix+3),a         ; set x coord.
       call qrand          ; get quick random number.
star9  ld (ix+5),a         ; set y position.
       ld a,c              ; direction.
       and 3               ; zero to three.
       add a,3             ; 3 to 6 for starfield.
       ld (ix+0),a         ; define particle as star.
       call chkxy          ; plot first position.
       jp star0
star1  call qrand          ; get quick random number.
       ld (ix+3),a         ; set x coord.
       ld a,(wnrgtx)       ; get edge of screen.
       add a,15            ; add width of sprite minus 1.
       jp star9
star2  call qrand          ; get quick random number.
       ld (ix+3),a         ; set x coord.
       ld a,(wnlftx)       ; get edge of screen.
       jp star9
star3  ld a,(wnbotx)       ; get edge of screen.
       add a,15            ; height of sprite minus one pixel.
       jp star8


; Find particle slot for lasers or vapour trail.
; Can't use alternate accumulator.

fpslot:
		ld ix,SHRAPN        ; shrapnel table.
		ld de,SHRSIZ        ; size of each particle.
		ld b,NUMSHR         ; number of pieces in table.
fpslt0:
		ld a,(ix+0)         ; get type.
		rla                 ; is this slot in use?
		ret c               ; no, we can use it.
		add ix,de           ; point to more shrapnel.
		djnz fpslt0         ; repeat for all shrapnel.
		ret                 ; out of slots, can't generate anything.

; Create an explosion at sprite position.

explod:
		ld c,a              ; particles to create.
		push ix             ; store pointer to sprite.
		ld l,(ix+3)         ; y coordinate.
		ld h,(ix+4)         ; x coordinate.
		ld ix,SHRAPN        ; shrapnel table.
		ld de,SHRSIZ        ; size of each particle.
		ld b,NUMSHR         ; number of pieces in table.
expld0:
		ld a,(ix+0)         ; get type.
		rla                 ; is this slot in use?
		jr c,expld1         ; no, we can use it.
expld2:
		add ix,de           ; point to more shrapnel.
		djnz expld0         ; repeat for all shrapnel.
expld3:
		pop ix              ; restore sprite pointer.
		ret                 ; out of slots, can't generate any more.

expld1:
		ld a,c              ; shrapnel counter.
		and 15              ; 0 to 15.
		add a,l             ; add to x.
		ld (ix+3),a         ; x coord.
		ld a,(seed3)        ; crap random number.
		and 15              ; 0 to 15.
		add a,h             ; add to y.
		ld (ix+5),a         ; y coord.
		ld (ix+0),2         ; switch it on.
		exx                 ; store coordinates.
		call chkxy          ; plot first position.
		call qrand          ; quick random angle.
		and 60              ; keep within range.
		ld (ix+1),a         ; angle.
		exx                 ; restore coordinates.
		dec c               ; one less piece of shrapnel to generate.
		jr nz,expld2        ; back to main explosion loop.
		jr expld3           ; restore sprite pointer and exit.
qrand:
		ld a,(seed3)        ; random seed.
		ld l,a              ; low byte.
		ld h,0              ; no high byte.
		ld a,r              ; r register.
		xor (hl)            ; combine with seed.
		ld (seed3),a        ; new seed.
		ret

; Display all shrapnel.

dshrp:
		ld hl,plotde        ; display routine.
		ld (shrplot),hl
		; ld (proshx+1),hl    ; modify routine.		
		
		xor a
		call setshr0
		call proshrnoset    ; process even shrapnel.
		ld a,1
		call setshr0
		call proshrnoset    ; process odd shrapnel.
		
		ld hl,prosh1        ; processing routine.
		ld (shrplot),hl
		; ld (proshx+1),hl    ; modify the call.
		
		ret

; Deletes all shrapnel

delshr: 
		ld ix,SHRAPN        ; table.
		ld b,NUMSHR         ; shrapnel pieces to process.
		; ld d,0				; plot needs this initially
		
.loop:
		ld a,(ix+0)         ; on/off marker.
		rla
		jr c,.noshr
		push bc             ; store counter.
		call plot           ; delete the pixel.
		pop bc              ; restore counter.
.noshr:		
		ld de,SHRSIZ        ; distance to next.
		add ix,de           ; point there.
		djnz .loop         ; round again.
		ret

inishr:	
		ld hl,SHRAPN        ; table.
		ld de,SHRAPN+1        ; distance to next.
		ld (hl),255
		ld bc,(NUMSHR*SHRSIZ)-1         ; shrapnel pieces to process.
		ldir 
		ret
	   
; Check for collision between laser and sprite.

lcol:
		ld hl,SHRAPN        ; shrapnel table.
		ld de,SHRSIZ        ; size of each particle.
		ld b,NUMSHR         ; number of pieces in table.
.loop:
		ld a,(hl)           ; get type.
		and a               ; is this slot a laser?
		jr z,.chkcol          ; yes, check collision.
.nxtshr:
		add hl,de           ; point to more shrapnel.
		djnz .loop          ; repeat for all shrapnel.
		ret                 ; no collision, carry not set.
.chkcol:
		push hl             ; store pointer to laser.
		inc hl              ; direction.
		inc hl              ; not used.
		inc hl              ; x position.
		ld a,(hl)           ; get x.
		sub (ix+X)          ; subtract sprite x.
;lcolh:
		cp 16               ; within range?
		jr nc,.missed         ; no, missed.
		inc hl              ; not used.
		inc hl              ; y position.
		ld a,(hl)           ; get y.
		sub (ix+Y)          ; subtract sprite y.
		cp 16               ; within range?
		jr c,.exit          ; yes, collision occurred.
.missed:
		pop hl              ; restore laser pointer from stack.
		jr .nxtshr
.exit:
		pop hl              ; restore laser pointer.
		ret                 ; return with carry set for collision.

	endif
	
; Main game engine code starts here.

game:

	if PFLAG
		call inishr         ; initialise particle engine.
	endif
evintr:
		call evnt12         ; call intro/menu event.

		ld hl,MAP           ; block properties.
		ld de,MAP+1         ; next byte.
		ld bc,767           ; size of property map.
		ld (hl),WALL        ; write default property.
		ldir
	if OFLAG
		call clrobjlst
	endif
		call clrscrmap

	if OFLAG
		call iniob          ; initialise objects.
	endif
		xor a               ; put zero in accumulator.
		ld (gamwon),a       ; reset game won flag.

		ld hl,score         ; score.
		call inisc          ; init the score.
mapst:
		ld a,(stmap)        ; start position on map.
		ld (roomtb),a       ; set up position in table, if there is one.
inipbl:
	if AFLAG
		ld hl,eop          ; reset blockpointer
		; ld (pbptr+1),hl
		ld (pblkptr),hl
	endif
 
		call initsc         ; set up first screen.
		ld ix,ssprit        ; default to spare sprite in table.
evini:  
		call evnt13         ; initialisation.

; Two restarts.
; First restart - clear all sprites and initialise everything.

rstrt:
		call rsevt          ; restart events.
		call xspr           ; clear sprite table.
		call sprlst         ; fetch pointer to screen sprites.
		call ispr           ; initialise sprite table.
		jr rstrt0

; Second restart - clear all but player, and don't initialise him.

rstrtn:
		call rsevt          ; restart events.
		call nspr           ; clear all non-player sprites.
		call xspr0
		call sprlst         ; fetch pointer to screen sprites.
		call kspr           ; initialise sprite table, no more players.

; Set up the player and/or enemy sprites.

rstrt0: 
		xor a               ; zero in accumulator.
		ld (nexlev),a       ; reset next level flag.
		ld (restfl),a       ; reset restart flag.
		ld (deadf),a        ; reset dead flag.
	if PFLAG
		call delshr			; erases all particles from screen
	endif
	if OFLAG
		call robjs			; removes all present objects from screen
	endif
		call droom          ; show screen layout.
rpblc0: 
	if AFLAG
		call rbloc          ; draw blocks for this screen
	endif
	if PFLAG
		call inishr         ; initialise particle engine.
	endif
	if OFLAG
		call shwob          ; draw objects.
	endif
mloop:
		call vsync          ; synchronise with display.
		call dumpspr
		
	ifdef DEBUG
		BORDER 9
	endif
	   
		ld ix,ssprit        ; point to spare sprite for spawning purposes.
evlp1:  
		call evnt10         ; MAINLOOP1: called once per main loop.
		call pspr           ; process sprites.
		
; Main loop events.
		ld ix,ssprit        ; point to spare sprite for spawning purposes.
evlp2:  
	ifdef DEBUG
		BORDER 8
	endif
		call evnt11         ; MAINLOOP2: called once per main loop.
	ifdef DEBUG
		BORDER 14
	endif
		
		ld ix,sprtab
		call chkimg
		
		ld a,(nexlev)       ; finished level flag.
		and a               ; has it been set?
		jr nz,newlev        ; yes, go to next level.
		ld a,(gamwon)       ; finished game flag.
		and a               ; has it been set?
		jr nz,evwon         ; yes, finish the game.
		ld a,(restfl)       ; finished level flag.
		dec a               ; has it been set?
		jp z,rstrt          ; yes, go to next level.
		dec a               ; has it been set?
		jp z,rstrtn         ; yes, go to next level.
		ld a,(deadf)        ; dead flag.
		and a               ; is it non-zero?
		jr nz,pdead         ; yes, player dead.
		
		ld hl,frmno         ; game frame.
		inc (hl)            ; advance the frame.
; Back to start of main loop.
qoff:	
		jp mloop            ; switched to a jp nz,mloop during test mode.
		
;----------------------------------------------------------
; Read blocks from list and update screen accordingly.
;----------------------------------------------------------

	if AFLAG
	
rbloc:
;pbbuf:
		ld de,eop             ; check for last block
rbloc2:
		; ld hl,(pbptr+1)
		ld hl,(pblkptr)
		or a
		sbc hl,de
		ret z
rbloc1:
		ex de,hl
		ld a,(scno)
		cp (hl)                ;pbbuf
		jr nz,rbloc0
		push hl
		inc hl
		ld de,dispx
		ldi                    ;dispx
		ldi                    ;dispy
		ld a,(hl)
		call pattr2            ; draw block
		pop hl
rbloc0:
		ld de,4
		add hl,de              ; point to next block
		ex de,hl
		jr rbloc2
    
	endif

	
newlev:
		ld a,(scno)         ; current screen.
		ld hl,numsc         ; total number of screens.
		inc a               ; next screen.
		cp (hl)             ; reached the limit?
		jr nc,evwon         ; yes, game finished.
		ld (scno),a         ; set new level number.
		jp rstrt            ; restart, clearing all aliens.
evwon:
		;call dissprs
		call evnt18         ; game completed.
		jp tidyup           ; tidy up and return to BASIC/calling routine.

; Player dead.

pdead:
		xor a               ; zeroise accumulator.
		ld (deadf),a        ; reset dead flag.
evdie:
		call evnt16         ; death subroutine.
		ld a,(numlif)       ; number of lives.
		and a               ; reached zero yet?
		jp nz,rstrt         ; restart game.
evfail:
		call dissprs
		call evnt17         ; failure event.
tidyup: 
		ld hl,hiscor        ; high score.
		ld de,score         ; player's score.
		ld b,6              ; digits to check.
.tidyu2 
		ld a,(de)           ; get score digit.
		cp (hl)             ; are we larger than high score digit?
		jr c,tidyu0         ; high score is bigger.
		jr nz,tidyu1        ; score is greater, record new high score.
		inc hl              ; next digit of high score.
		inc de              ; next digit of score.
		djnz .tidyu2         ; repeat for all digits.
tidyu0:
		jp game
tidyu1:
		ld hl,score         ; score.
		ld de,hiscor        ; high score.
		ld bc,6             ; digits to copy.
		ldir                ; copy score to high score.
evnewh:
		call dissprs
		call evnt19         ; new high score event.
		jr tidyu0           ; tidy up.

; Restart event.

rsevt:
		ld ix,ssprit        ; default to spare element in table.
evrs:
		jp evnt14           ; call restart event.

; Copy number passed in a to string position bc, right-justified.

num2ch ld l,a              ; put accumulator in l.
       ld h,0              ; blank high byte of hl.
       ld a,32             ; leading spaces.
numdg3 ld de,100           ; hundreds column.
       call numdg          ; show digit.
numdg2 ld de,10            ; tens column.
       call numdg          ; show digit.
       or 16               ; last digit is always shown.
       ld de,1             ; units column.
numdg  and 48              ; clear carry, clear digit.
numdg1 sbc hl,de           ; subtract from column.
       jr c,numdg0         ; nothing to show.
       or 16               ; something to show, make it a digit.
       inc a               ; increment digit.
       jr numdg1           ; repeat until column is zero.
numdg0 add hl,de           ; restore total.
       cp 32               ; leading space?
       ret z               ; yes, don't write that.
       ld (bc),a           ; write digit to buffer.
       inc bc              ; next buffer position.
       ret
num2dd ld l,a              ; put accumulator in l.
       ld h,0              ; blank high byte of hl.
       ld a,32             ; leading spaces.
       ld de,100           ; hundreds column.
       call numdg          ; show digit.
       or 16               ; second digit is always shown.
       jr numdg2
num2td ld l,a              ; put accumulator in l.
       ld h,0              ; blank high byte of hl.
       ld a,48             ; leading spaces.
       jr numdg3

inisc  ld b,6              ; digits to initialise.
inisc0 ld (hl),'0'         ; write zero digit.
       inc hl              ; next column.
       djnz inisc0         ; repeat for all digits.
       ret


; Multiply h by d and return in hl.

imul:   
		ld e,d              ; HL = H * D
		ld c,h              ; make c first multiplier.
imul0:
		ld hl,0             ; zeroise total.
		ld d,h              ; zeroise high byte.
		ld b,8              ; repeat 8 times.
.loop:
		rr c                ; rotate rightmost bit into carry.
		jr nc,.imul2         ; wasn't set.
		add hl,de           ; bit was set, so add de.
		and a               ; reset carry.
.imul2:
		rl e                ; shift de 1 bit left.
		rl d
		djnz .loop          ; repeat 8 times.
		ret

; Divide d by e and return in d, remainder in a.

idiv:
		xor a
		ld b,8              ; bits to shift.
.loop:
		sla d               ; multiply d by 2.
		rla                 ; shift carry into remainder.
		cp e                ; test if e is smaller.
		jr c,.nodiv          ; e is greater, no division this time.
		sub e               ; subtract it.
		inc d               ; rotate into d.
.nodiv:
		djnz .loop
		ret

	
	if OFLAG

; Objects handling.
; 64 bytes for image
; 3 for room, x and y
; 3 for starting room, x and y.
; 254 = disabled.
; 255 = object in player's pockets.

; Show items present.

	if DISTYPE=ROM
	
shwob:
		ld hl,objatr        ; objects attribute table.		
		ld a,(numob)        ; number of objects in the game.
		ld b,a              ; loop counter.
.loop0:
		push bc             ; store count.
		push hl             ; store item pointer.
		ld a,(numob)
		sub b				; need to invert object counter
		ld (curobj),a
		ld a,(scno)         ; current location.
		cp (hl)             ; same as an item?
		call z,dobj         ; yes, display object in colour.
		pop hl              ; restore pointer.
		pop bc              ; restore counter.
		ld de,ODTSIZ		; distance to next item.
		add hl,de           ; point to it.
		djnz .loop0         ; repeat for others.
		ret

	else
	
shwob:
		ld hl,objdta        ; objects table.
		ld de,OBJSIZ-ODTSIZ ; distance to room number.
		add hl,de           ; point to room data.
		ld a,(numob)        ; number of objects in the game.
		ld b,a              ; loop counter.
.loop0:
		push bc             ; store count.
		push hl             ; store item pointer.
		ld a,(numob)
		sub b				; need to invert object counter
		ld (curobj),a
		ld a,(scno)         ; current location.
		cp (hl)             ; same as an item?
		call z,dobj         ; yes, display object in colour.
		pop hl              ; restore pointer.
		pop bc              ; restore counter.
		ld de,OBJSIZ        ; distance to next item.
		add hl,de           ; point to it.
		djnz .loop0         ; repeat for others.
		ret

	endif

; Display object.
; hl must point to object's room number.

	if DISTYPE=ROM
	
dobj:   
		inc hl						; point to y.
		ld de,dispx         		; coordinates.
		ld a,(hl)
		cp MSX_MAXCY+1
		ret nc						; don't draw if it's out of boundaries
		ldi                 		; transfer y coord.
		ldi                 		; transfer x too.
		call objimg			; gets object image address in HL
putobj:
		push hl             ; store object graphic address.
		call wobj			; preserves visible object coords in list
		call scadd          ; get screen address in hl.
		SETWRT hl	
		ld c,MSX_VDPDRW		
		ex de,hl            ; switch regs. DE=VRAM
		pop hl              ; restore graphic address. HL=graphics, DE=VRAM
		call putrow0		; 1st pattern row
		inc d				; row increased
		call putrow			; 2nd pattern row
		dec d				; back again to 1st row
		set 5,d				; point to color area
		call putrow			; 1st color row
		inc d				; row increased and process las color row
putrow:
		SETWRT de
putrow0:
		ld b,16
.loop:
		outi
		jp nz,.loop
		ret
;
; Input:
;	A = object number
; Output:
;	HL = object image address
;
objimg:
		; calculates object image address from object number
		ld d,0
		ld a,(curobj)
		ld e,a
		rrca
		rrca
		ld l,a			
		and $3F			
		ld h,a			
		ld a,l			
		and $C0			
		ld l,a			; n * 64
		add hl,de
		ex de,hl		; DE=n*65
		add hl,hl		; HL=n*2
		add hl,de		; HL=n*65 + n*2
		ld de,objdta+3
		add hl,de		; point to image.		
		ret

	else
	
dobj:   
		inc hl						; point to x.
		ld de,dispx         		; coordinates.
		ld a,(hl)
		cp MSX_MAXCY+1
		ret nc						; don't draw if it's out of boundaries
		ldi                 		; transfer y coord.
		ldi                 		; transfer x too.
		ld de,-(OBJSIZ-(ODTSIZ/2))	; distance needed to restore image pointer.
		add hl,de           		; point to image.
putobj:
		push hl             ; store sprite graphic address.
		call wobj			; preserves visible object coords in list
		call scadd          ; get screen address in hl.
		SETWRT hl	
		ld c,MSX_VDPDRW		
		ex de,hl            ; switch regs. DE=VRAM
		pop hl              ; restore graphic address. HL=graphics, DE=VRAM
		call putrow0		; 1st pattern row
		inc d				; row increased
		call putrow			; 2nd pattern row
		dec d				; back again to 1st row
		set 5,d				; point to color area
		call putrow			; 1st color row
		inc d				; row increased and process las color row
putrow:
		SETWRT de
putrow0:
		ld b,16
.loop:
		outi
		jp nz,.loop
		ret

	endif
	
	
; Remove an object (REMOVEOBJECT).

remob:
		ld hl,numob         ; number of objects in game.
		cp (hl)             ; are we checking past the end?
		ret nc              ; yes, can't get non-existent item.
		push af             ; remember object.
		call getob          ; pick it up if we haven't already got it.
		pop af              ; retrieve object number.
		call gotob          ; get its address.
		ld (hl),254         ; remove it.
		ret

; Pick up object number held in the accumulator (GET).

getob:  
		ld (curobj),a		; preserves object number
		ld hl,numob         ; number of objects in game.
		cp (hl)             ; are we checking past the end?
		ret nc              ; yes, can't get non-existent item.
		call gotob          ; check if we already have it.
		ret z               ; we already do.
		ex de,hl            ; object address in de.
		ld hl,scno          ; current screen.
		cp (hl)             ; is it on this screen?
		ex de,hl            ; object address back in hl.
		jr nz,.notinscr        ; not on screen, so nothing to delete.
		ld (hl),255         ; pick it up.
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.		
		jp robj
.notinscr:
		ld (hl),255         ; pick it up.
		ret

;
; Returns pointers over dispx & object coords list
; Input:
;	curobj = object number
; Output:
;	HL = dispx
;	DE = Object's pointer
;
objptr:
		ld a,(curobj)
		add a,a
		ld e,a
		ld d,(objlist >> 8) & $FF
		ld hl,dispx
		ret

;
; Stores current coords in object coords list
; Input:
;	curobj = object number
; Output:
;	None. Object's coords filled with dispx/y
;
wobj:
		call objptr
		ldi
		ldi					; stores dispxy to objects coords list
		ret

;
; Removes object from objects list restoring background		
;		
; Input:
; 	curobj = object number to delete
; Output:
;	None. Object's coords erased with $FF
; Modifies: All
;		
robj:
		call objptr
		ld a,(de)			
		cp 255
		ret z				; if dispx=255, there's no object displayed
		ex de,hl	
		ldi				
		ldi					; restores to dispxy stored objects coords
		dec hl
		dec hl
		ld (hl),255			; clear stored dispx, object deleted
		call gp2tp
		ld de,scrmap
		call pradd
		add hl,de
		ld a,(hl)			; gets old block from screen map buffer
		push hl
		call pchr
		pop hl
		inc hl
		ld a,(hl)
		push hl
		call pchr
		dec (hl)
		dec (hl)
		dec hl
		inc (hl)
		pop hl
		ld de,31
		add hl,de
		ld a,(hl)
		push hl
		call pchr
		pop hl
		inc hl
		ld a,(hl)
		jp pchr

;
; Removes all objects from objects list restoring background		
;		
; Input:
; 	None
; Output:
;	None. All object's dispx in objects list erased with $FF		
		
robjs:
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.
		ld a,(numob)
		ld b,a
.loop:
		push bc
		ld a,b
		dec a
		ld (curobj),a
		call robj			; erase object restoring bg
		pop bc
		djnz .loop
		ret

; Drop object number at (dispx, dispy).

	if DISTYPE=ROM

drpob:
		ld (curobj),a		; preserves object number
		ld hl,numob         ; number of objects in game.
		cp (hl)             ; are we checking past the end?
		ret nc              ; yes, can't drop non-existent item.
		call gotob          ; make sure object is in inventory.
		ld a,(scno)         ; screen number.
		cp (hl)             ; already on this screen?
		ret z               ; yes, nothing to do.
		ld (hl),a           ; bring onto screen.
		inc hl              ; point to x coord.
		
		ld a,(dispx)        ; object y coordinate.
		ld (hl),a           ; set y coord.
		ld c,a
		inc hl              ; point to object x.
		ld a,(dispy)        ; object x coordinate.
		ld (hl),a           ; set the x position.
		ld a,c
		cp MSX_MAXCY+1
		ret nc				; don't draw object if it's out of boundaries

		ld a,(curobj)
		call objimg
		jp putobj           ; draw object.

	else
	
drpob:
		ld (curobj),a		; preserves object number
		ld hl,numob         ; number of objects in game.
		cp (hl)             ; are we checking past the end?
		ret nc              ; yes, can't drop non-existent item.
		call gotob          ; make sure object is in inventory.
		ld a,(scno)         ; screen number.
		cp (hl)             ; already on this screen?
		ret z               ; yes, nothing to do.
		ld (hl),a           ; bring onto screen.
		inc hl              ; point to x coord.
		
		ld a,(dispx)        ; object y coordinate.
		ld (hl),a           ; set y coord.
		ld c,a
		inc hl              ; point to object x.
		ld a,(dispy)        ; object x coordinate.
		ld (hl),a           ; set the x position.
		ld a,c
		cp MSX_MAXCY+1
		ret nc				; don't draw object if it's out of boundaries
		
		ld de,-66           ; minus graphic size.
		add hl,de           ; point to graphics.
		jp putobj           ; draw object.

	endif
	

; Seek objects at sprite position.

	if DISTYPE=ROM
	
skobj:
		ld de,ODTSIZ        ; size of each object.
		ld hl,objatr
		ld a,(numob)        ; number of objects in game.
		ld b,a              ; set up the loop counter.
.sk0: 
		ld a,(scno)         ; current room number.
		cp (hl)             ; is object in here?
		call z,.sk1       	; yes, check coordinates.
		add hl,de           ; point to next object in table.
		djnz .sk0         	; repeat for all objects.
		ld a,255            ; end of list and nothing found, return 255.
		ret
.sk1: 
		inc hl              ; point to y coordinate.
		ld a,(hl)           ; get coordinate.
		sub (ix+3)          ; subtract sprite y.
		add a,MSX_SPRVS-1	; add sprite height minus one.
		cp MSX_SPRVS+16-1   ; within range?
		jp nc,.sk2        	; no, ignore object.
		inc hl              ; point to x coordinate now.
		ld a,(hl)           ; get coordinate.
		sub (ix+4)          ; subtract the sprite x.
		add a,MSX_SPRHS-1   ; add sprite width minus one.
		cp MSX_SPRHS+16-1   ; within range?
		jp nc,.sk3        	; no, ignore object.
		pop de              ; remove return address from stack.
		ld a,(numob)        ; objects in game.
		sub b               ; subtract loop counter.
		ret                 ; accumulator now points to object.
.sk3:
		dec hl              ; back to y position.
.sk2:
		dec hl              ; back to room.
		ret

	else
	
skobj:
		ld hl,objdta        ; pointer to objects.
		ld de,OBJSIZ-ODTSIZ ; distance to room number.
		add hl,de           ; point to room data.
		ld de,OBJSIZ        ; size of each object.
		ld a,(numob)        ; number of objects in game.
		ld b,a              ; set up the loop counter.
.sk0: 
		ld a,(scno)         ; current room number.
		cp (hl)             ; is object in here?
		call z,.sk1       	; yes, check coordinates.
		add hl,de           ; point to next object in table.
		djnz .sk0         	; repeat for all objects.
		ld a,255            ; end of list and nothing found, return 255.
		ret
.sk1: 
		inc hl              ; point to x coordinate.
		ld a,(hl)           ; get coordinate.
		sub (ix+3)          ; subtract sprite x.
		add a,15            ; add sprite height minus one.
		cp 31               ; within range?
		jp nc,.sk2        	; no, ignore object.
		inc hl              ; point to y coordinate now.
		ld a,(hl)           ; get coordinate.
		sub (ix+4)          ; subtract the sprite y.
		add a,15            ; add sprite width minus one.
		cp 31               ; within range?
		jp nc,.sk3        	; no, ignore object.
		pop de              ; remove return address from stack.
		ld a,(numob)        ; objects in game.
		sub b               ; subtract loop counter.
		ret                 ; accumulator now points to object.
.sk3:
		dec hl              ; back to y position.
.sk2:
		dec hl              ; back to room.
		ret

	endif
	
	endif
	
	if (OFLAG or MFLAG)
		
;-----------------------------------------------------------------
; Got object check.
; Call with object in accumulator, returns zero set if in pockets.
;
; Input:
;  A = object number
;-----------------------------------------------------------------

gotob:
		ld hl,numob         ; number of objects in game.
		cp (hl)             ; are we checking past the end?
		jr nc,.gotob0       ; yes, we can't have a non-existent object.
		call findob         ; find the object.
.gotob1:
		cp 255              ; in pockets?
		ret
.gotob0:
		ld a,254            ; missing.
		jr .gotob1

; Find object address

	if DISTYPE=ROM
	
findob:
		ld h,0
		ld l,a
		add hl,hl
		ADD_HL_A
		ld de,objatr
		add hl,de
		ld a,(hl)
		ret

	else
	
findob:
		ld hl,objdta        ; objects.
		ld de,OBJSIZ        ; size of each object (64+6)
		and a               ; is it zero?
		jr z,.fndob1        ; yes, skip loop.
		ld b,a              ; loop counter in b.
.fndob2:
		add hl,de           ; point to next one.
		djnz .fndob2        ; repeat until we find address.
.fndob1:
		ld e,OBJSIZ-ODTSIZ  ; distance to room it's in (0-63 obj.data, 64 room)
		add hl,de           ; point to room.
		ld a,(hl)           ; fetch status.
		ret

	endif
	
	endif


;
; Fills a box of values 255 in screenmap
;
; Input:
;	dispx: y coord (0-191)
;	dispy: x coord (0-255)
;	dirthig: height of the box
;	dirthig+1: width of the box		
; Output:
; 	None. box is filled in scrmap
; Modifies:
;	None
;

/* dirtybox:
		push hl
		push de
		push bc
		ld de,scrmap
		call chradd
		add hl,de
		ld de,32
		ld bc,(dirthig)
		ld a,b
.looprows:	
		push hl
.loopcols:		
		ld (hl),255
		inc hl
		djnz .loopcols
		pop hl		
		add hl,de
		ld b,a		
		dec c
		jr nz,.looprows		
		pop bc
		pop de
		pop hl
		ret
 */	   

; Spawn a new sprite.

spawn:
		ld hl,sprtab        ; sprite table.
numsp1:
		ld a,NUMSPR         ; number of sprites.
		ld de,TABSIZ        ; size of each entry.
.nxtslot:
		ex af,af            ; store loop counter.
		ld a,(hl)           ; get sprite type.
		inc a               ; is it an unused slot?
		jr z,.spaw1         ; yes, we can use this one.
		add hl,de           ; point to next sprite in table.
		ex af,af            ; restore loop counter.
		dec a               ; one less iteration.
		jr nz,.nxtslot      ; keep going until we find a slot.
; Didn't find one but drop through and set up a dummy sprite instead.
.spaw1:
		push ix             ; existing sprite address on stack.
		ld (spptr),hl       ; store spawned sprite address.
		ld (hl),c           ; set the type.
		inc hl              ; point to image.
		ld (hl),b           ; set the image.
		inc hl              ; next byte.

		ld a,b
		call mapsprite

		ld (hl),0           ; frame zero.
		inc hl              ; next byte.
		ld a,(ix+X)         ; x coordinate.
		ld (hl),a           ; set sprite coordinate.
		inc hl              ; next byte.
		ld a,(ix+Y)         ; y coordinate.
		ld (hl),a           ; set sprite coordinate.
		inc hl              ; next byte.

		ld a,(ix+5)         ; color
		ld (hl),a           ; set sprite color.
		inc hl              ; next byte.
		inc hl
		inc hl
		ld a,(ix+X)         ; x coordinate.
		ld (hl),a           ; set sprite coordinate.
		inc hl              ; next byte.
		ld a,(ix+Y)         ; y coordinate.
		ld (hl),a           ; set sprite coordinate.
		inc hl              ; next byte.

		ld a,(ix+10)        ; direction of original.
		ld (hl),a           ; set the direction.
		inc hl              ; next byte.
		ld b,0
		ld (hl),b           ; reset parameter.
		inc hl              ; next byte.
		ld (hl),b           ; reset parameter.
		inc hl              ; next byte.
		ld (hl),b           ; reset parameter.
		inc hl              ; next byte.
		ld (hl),b           ; reset parameter.
rtssp:
		ld ix,(spptr)       ; address of new sprite.
evis1:
		call evnt09         ; call sprite initialisation event.
		pop ix              ; address of original sprite.

;
; Finds the highest used sprite slot
;

hslot:		
		ld a,255
		ld b,NUMSPR
		ld de,-TABSIZ
		ld hl,sprtab+((NUMSPR-1)*TABSIZ)
.nxtslot:
		cp (hl)
		jr nz,.found
		add hl,de
		djnz .nxtslot
.found		
		ld a,b
		ld (highslot),a
		ret

checkx:
		ld a,e              ; x position.
		cp MSX_MAXROWS      ; off screen?
		ret c               ; no, it's okay.
		pop hl              ; remove return address from stack.
		ret

; Displays the current score. (MSX:OK)

dscor:
		call preprt         ; set up font and print position.
		call checkx         ; make sure we're in a printable range.
		ld a,(prtmod)       ; get print mode.
		and a               ; standard size text?
		jp nz,bscor0        ; no, show double-height.
dscor0:
		push bc             ; place counter onto the stack.
		push hl
		ld a,(hl)           ; fetch character.
		call ptxt           ; display character.
		
		ld hl,dispy         ; y coordinate.
		inc (hl)            ; move along one.
		pop hl
		inc hl              ; next score column.
		pop bc              ; retrieve character counter.
		djnz dscor0         ; repeat for all digits.
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.
dscor2:
		ld hl,(dispx)       ; general coordinates.
		ld (charx),hl       ; set up display coordinates.
		ret

; Displays the current score in double-height characters.

bscor0 push bc             ; place counter onto the stack.
       push hl
       ld a,(hl)           ; fetch character.
       call bchar          ; display big char.
       pop hl
       inc hl              ; next score column.
       pop bc              ; retrieve character counter.
       djnz bscor0         ; repeat for all digits.
       jp dscor2           ; tidy up line and column variables.

; Adds number in the hl pair to the score.

addsc  ld de,score+1       ; ten thousands column.
       ld bc,10000         ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; thousands column.
       ld bc,1000          ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; hundreds column.
       ld bc,100           ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; tens column.
       ld bc,10            ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; units column.
       ld bc,1             ; units.
incsc  push hl             ; store amount to add.
       and a               ; clear the carry flag.
       sbc hl,bc           ; subtract from amount to add.
       jr c,incsc0         ; too much, restore value.
       pop af              ; delete the previous amount from the stack.
       push de             ; store column position.
       call incsc2         ; do the increment.
       pop de              ; restore column.
       jp incsc            ; repeat until all added.
incsc0 pop hl              ; restore previous value.
       ret
incsc2 ld a,(de)           ; get amount.
       inc a               ; add one to column.
       ld (de),a           ; write new column total.
       cp '9'+1            ; gone beyond range of digits?
       ret c               ; no, carry on.
       ld a,'0'            ; mae it zero.
       ld (de),a           ; write new column total.
       dec de              ; back one column.
       jr incsc2

; Add bonus to score.

addbo  ld de,score+5       ; last score digit.
       ld hl,bonus+5       ; last bonus digit.
       and a               ; clear carry.
       ld bc,6*256+48      ; 6 digits to add, ASCII '0' in c.
addbo0 ld a,(de)           ; get score.
       adc a,(hl)          ; add bonus.
       sub c               ; 0 to 18.
       ld (hl),c           ; zeroise bonus.
       dec hl              ; next bonus.
       cp 58               ; carried?
       jr c,addbo1         ; no, do next one.
       sub 10              ; subtract 10.
addbo1 ld (de),a           ; write new score.
       dec de              ; next score digit.
       ccf                 ; set carry for next digit.
       djnz addbo0         ; repeat for all 6 digits.
       ret

; Swap score and bonus.

swpsb  ld de,score         ; first score digit.
       ld hl,bonus         ; first bonus digit.
       ld b,6              ; digits to add.
swpsb0 ld a,(de)           ; get score and bonus digits.
       ld c,(hl)
       ex de,hl            ; swap pointers.
       ld (hl),c           ; write bonus and score digits.
       ld (de),a
       inc hl              ; next score and bonus.
       inc de
       djnz swpsb0         ; repeat for all 6 digits.
       ret

; Turns graphic coordinates to text ones
; Input:
;	None
; Output:
; 	dispx & dispy updated
gp2tp:
		ld a,(dispx)
		rrca
		rrca
		rrca
		and $1F			
		ld (dispx),a	; stores y/8
		ld a,(dispy)
		rrca
		rrca
		rrca
		and $1F			
		ld (dispy),a	; stores x/8
		ret
		
; Get print address.returns scr. add. in de (0000-17FF).
; Requires: y(0-23), x(0-31)
; Must NOT modify HL

gprad:
		ld de,(dispx)		; get y coord
		ld a,d				; y*256
		add a,a				; get x coord
		add a,a				; 
		add a,a				; 
		ld d,e				; x*8
		ld e,a				; (y*256)+(x*8)
		ret		
 
; Get property buffer address of char at (dispx, dispy) in hl (0-767).
; Requires: y(0-23), x(0-31)

pradd:
		ld a,(dispx)        ; y coordinate.
		rrca
		rrca
		rrca
		ld l,a			
		and $1F			
		ld h,a			
		ld a,l			
		and $E0			
		ld l,a			; y * 32
		ld a,(dispy)    ; fetch x coordinate.
		and $1F         ; should be in range 0 - 31.
		ADD_HL_A
		ret		

; Get screen buffer address of char at (dispx, dispy) in hl (0-767).
; Requires: y(0-191), x(0-255)

chradd:
		ld a,(dispx)
		rlca                ; multiply char by 4.
		rlca
		ld l,a              ; store shift in e.
		and 3               ; only want high byte bits.
		ld h,a              ; store in d.
		ld a,l              ; restore shifted value.
		and $FC             ; only want low byte bits.
		ld l,a
		ld a,(dispy)
		and $F8
		rrca
		rrca
		rrca
		ADD_HL_A
		ret

; print char pattern (without color) (MSX:OK)
		
ptxt:
		rlca                ; find address for the font char
		rlca
		rlca				; multiply char code by 8.
		ld e,a              ; store shift in e.
		and 7               ; only want high byte bits.
		ld d,a              ; store in d.
		ld a,e              ; restore shifted value.
		and 248             ; only want low byte bits.
		ld e,a              ; that's the low byte. DE=CHAR*8
		ld hl,(grbase)      ; address of graphics.
		add hl,de           ; add displacement.
		call gprad          ; get screen address (in DE)
		SETWRT de
		ld bc,8*256+MSX_VDPDRW
ldirvm0:
		outi				; writes pattern bytes
		jp nz,ldirvm0		
		set 5,d				; DE=VRAM patterns, add $20 and now we're in color table
		SETWRT de
		ld c,8
		ld a,(clratt)
.nxtrow:
		out (MSX_VDPDRW),a	; writes color bytes
		dec c
		jp nz,.nxtrow
		ret
		
; Print block with attributes, properties and pixels.

pattr:
		if AFLAG
		call wbloc          ; save blockinfo	   
		endif
pattr2:
		ld b,a              ; store cell in b register for now.
		ld hl,(proptr)      ; pointer to properties.
		ADD_HL_A
		ld c,(hl)           ; fetch byte.
		ld a,c              ; put into accumulator.
		cp COLECT           ; is it a collectable?
		jp nz,pattr1        ; no, carry on as normal.
		ld a,b              ; restore cell.
		ld (colpat),a       ; store collectable block.
pattr1:
		ld de,MAP
		call pradd          ; get property buffer address.
		push hl
		add hl,de
		ld (hl),c           ; write property.		
		ld de,scrmap
		pop hl
		add hl,de
		ld a,(hl)
		cp b
		jr z, pattrnxt		; skip printing char
 		ld (hl),b		
		ld a,b              ; restore block number.

; Print block.
pchr:
		rlca                ; find address for the block 
		rlca
		rlca
		rlca				; multiply block code by 16
		ld e,a              ; store shift in e.
		and $0F             ; only want high byte bits.
		ld d,a              ; store in d.
		ld a,e              ; restore shifted value.
		and $F0             ; only want low byte bits.
		ld e,a              ; that's the low byte. DE=CHAR*8
		ld hl,(grbase)      ; address of graphics.
		add hl,de           ; add displacement.
		call gprad          ; get screen address (in DE)
		SETWRT de
		ld bc,8*256+MSX_VDPDRW
.ldirvm0:
		outi
		jp nz,.ldirvm0		
		set 5,d				; HL=VRAM patterns, add $20 and now we're in color table
		SETWRT de
		ld b,8
.loop:
		outi
		jp nz,.loop
pattrnxt:		
		ld hl,dispy         ; x coordinate.
		inc (hl)            ; move along one.
		ret

;----------------------------------------------
; Write block
;----------------------------------------------

		if AFLAG
wbloc:
;pbptr:   
		; ld de,0000h
		ld de,(pblkptr)
        ld hl,scno
        ldi                ; write screen.
        ld hl,dispx
        ldi                ; write x position of block.
        ldi                ; write y position of block.
        ld (de),a          ; store block number
        inc de
        ; ld (pbptr+1),de		; auto-modifying code
		
		ld (pblkptr),de
        ret
		endif
	   
; Get room address.

groom:
		ld a,(scno)         ; screen number.
groomx:
		ld de,0             ; start at zero.
		ld hl,(scrptr)      ; pointer to screens.
		and a               ; is it the first one?
groom1:
		jr z,groom0         ; no more screens to skip.
		ld c,(hl)           ; low byte of screen size.
		inc hl              ; point to high byte.
		ld b,(hl)           ; high byte of screen size.
		inc hl              ; next address.
		ex de,hl            ; put total in hl, pointer in de.
		add hl,bc           ; skip a screen.
		ex de,hl            ; put total in de, pointer in hl.
		dec a               ; one less iteration.
		jr groom1           ; loop until we reach the end.
groom0:
		ld hl,(scrptr)      ; pointer to screens.
		add hl,de           ; add displacement.
		ld a,(numsc)        ; number of screens.
		ld d,0              ; zeroise high byte.
		ld e,a              ; displacement in de.
		add hl,de           ; add double displacement to address.
		add hl,de
		ret

; Draw present room.

droom:
		ld a,(wintop)       ; window top.
		ld (dispx),a        ; set x coordinate.
droom2:
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.
		call groom          ; get address of current room.
		xor a               ; zero in accumulator.
		ld (comcnt),a       ; reset compression counter.
		ld a,(winhgt)       ; height of window.
		ld b,a
droom0:
		push bc             ; store row counter.
		ld a,(winlft)       ; window left edge.
		ld (dispy),a        ; set cursor position.
		ld a,(winwid)       ; width of window.
		ld b,a
droom1:
		push bc             ; store column counter.
		ld a,(comcnt)       ; compression counter.
		and a               ; any more to decompress?
		jp nz,flbyt1        ; yes.
		ld a,(hl)           ; fetch next byte.
		inc hl              ; point to next cell.
		cp 255              ; is this byte a control code?
		jp nz,nocom         ; no, this byte is uncompressed.
		ld a,(hl)           ; fetch byte type.
		ld (combyt),a       ; set up the type.
		inc hl              ; point to quantity.
		ld a,(hl)           ; get quantity.
		inc hl              ; point to next byte.
flbyt1:
		dec a               ; one less.
		ld (comcnt),a       ; store new quantity.
		ld a,(combyt)       ; byte to expand.
nocom:		
		push hl             ; store address of cell.
		call pattr2         ; show attributes and block.		
		pop hl              ; restore cell address.
		pop bc              ; restore loop counter.
		djnz droom1
		ld a,(dispx)        ; x coord.
		inc a               ; move down one line.
		ld (dispx),a        ; set new position.
		pop bc              ; restore row counter.
		djnz droom0
		ret

; Decompress bytes on-the-fly.

	if LFLAG
	
; Ladder down check.

laddd:
		ld l,16
		jr ladd

; Ladder up check.

laddu:
		ld l,15
ladd:
		ld a,(ix+3)         ; y coordinate.
		ld h,(ix+4)         ; x coordinate.
		add a,l            ; look 2 pixels above feet.
		ld l,a              ; coords in hl.

laddv:
		ld (dispx),hl       ; set up test coordinates.
		call tstbl          ; get map address.
		call ldchk          ; standard ladder check.
		ret nz              ; no way through.
		inc hl              ; look right one cell.
		call ldchk          ; do the check.
		ret nz              ; impassable.
		ld a,(dispy)        ; y coordinate.
		and 7               ; position straddling block cells.
		ret z               ; no more checks needed.
		inc hl              ; look to third cell.
	
; Check ladder is available.

ldchk:
		ld a,(hl)           ; fetch cell.
		cp LADDER           ; is it a ladder?
		ret                 ; return with zero flag set accordingly.

	endif
	
; Can go up check.

cangu:
		ld a,(ix+3)         ; y coordinate.
		ld h,(ix+4)         ; x coordinate.
		sub 1               ; look up 1 pixels.
		ld l,a              ; coords in hl.
		ld (dispx),hl       ; set up test coordinates.
		call tstbl          ; get map address.
		call lrchk          ; standard left/right check.
		ret nz              ; no way through.
		inc hl              ; look right one cell.
		call lrchk          ; do the check.
		ret nz              ; impassable.
		ld a,(dispy)        ; y coordinate.
		and 7               ; position straddling block cells.
		ret z               ; no more checks needed.
		inc hl              ; look to third cell.
		jp lrchk          ; do the check.

; Can go down check.

cangd:
		ld a,(ix+3)         ; y coordinate.
		ld h,(ix+4)         ; x coordinate.
numsp3:
		add a,16            ; look down 16 pixels.
		ld l,a              ; coords in hl.
		ld (dispx),hl       ; set up test coordinates.
		call tstbl          ; get map address.
		call plchk          ; block, platform check.
		ret nz              ; no way through.
		inc hl              ; look right one cell.
		call plchk          ; block, platform check.
		ret nz              ; impassable.
		ld a,(dispy)        ; y coordinate.
		and 7               ; position straddling block cells.
		ret z               ; no more checks needed.
		inc hl              ; look to third cell.

; Check platform or solid item is not in way.

plchk:
		ld a,(hl)           ; fetch map cell.
		cp WALL             ; is it passable?
		jr z,lrchkx         ; no.
	if (PFLAG or DFLAG)
		cp FODDER           ; fodder has to be dug.
		jr z,lrchkx         ; not passable.
	endif
		cp PLATFM           ; platform is solid.
		jr z,plchkx         ; not passable.
	if LFLAG
		cp LADDER           ; is it a ladder?
		jr z,lrchkx         ; on ladder, deny movement.
	endif
plchk0:
		xor a               ; report it as okay.
		ret
plchkx:
		ld a,(dispx)        ; x coordinate.
		and 7               ; position straddling blocks.
		jr z,lrchkx         ; on platform, deny movement.
		jr plchk0


; Can go left check.

cangl:
		ld l,(ix+3)         ; y coordinate.
		ld a,(ix+4)         ; x coordinate.
		sub 1               ; look left 1 pixels.
		ld h,a              ; coords in hl.
		jr cangh            ; test if we can go there.

; Can go right check.

cangr:
		ld l,(ix+3)         ; y coordinate.
		ld a,(ix+4)         ; x coordinate.
		add a,16            ; look right 16 pixels.
		ld h,a              ; coords in hl.

cangh:
		ld (dispx),hl       ; set up test coordinates.
cangh2:
		ld b,3              ; default rows to write.
		ld a,l              ; x position.
		and 7               ; does x straddle cells?
		jr nz,cangh0        ; yes, loop counter is good.
		dec b               ; one less row to write.
cangh0:
		call tstbl          ; get map address.
		ld de,MSX_MAXCOLS      ; distance to next cell.
cangh1:
		call lrchk          ; standard left/right check.
		ret nz              ; no way through.
		add hl,de           ; look down.
		djnz cangh1
		ret

; Check left/right movement is okay.

lrchk:
		ld a,(hl)           ; fetch map cell.
		cp WALL             ; is it passable?
		jr z,lrchkx         ; no.
		cp FODDER           ; fodder has to be dug.
		jr z,lrchkx         ; not passable.
always:
		xor a               ; report it as okay.
		ret
lrchkx:
		xor a               ; reset all bits.
		inc a
		ret

	
	if CFLAG
	
; Get collectables.

getcol:
		ld b,COLECT         ; collectable blocks.
		call tded           ; test for collectable blocks.
		cp b                ; did we find one?
		ret nz              ; none were found, job done.
		call gtblk          ; get block.
		call evnt20         ; collected block event.
		jr getcol           ; repeat until none left.

; Get collectable block.

gtblk:
		ld (hl),0           ; make it empty now.
		ld de,MAP           ; map address.
		and a               ; clear carry.
		sbc hl,de           ; find cell number.
		ld a,l              ; get low byte of cell number.
		and MSX_MAXCOLS-1   ; 0 - 31 is column.
		ld d,a              ; store y in d register.
		add hl,hl           ; multiply by 8.
		add hl,hl
		add hl,hl           ; x is now in h.
		ld e,h              ; put x in e.
		ld (dispx),de       ; set display coordinates.
		ld hl,(blkptr)      ; blocks.
		ld (grbase),hl      ; set graphics base.
		xor a
		jp pattr2

	endif
	
; Touched deadly block check.
; Returns with DEADLY (must be non-zero) in accumulator if true.

tded:
		ld l,(ix+3)         ; x coordinate.
		ld h,(ix+4)         ; y coordinate.
		ld (dispx),hl       ; set up test coordinates.
		call tstbl          ; get map address.
		ld de,MSX_MAXCOLS-1 ; default distance to next line down.
		cp b                ; is this the required block?
		ret z               ; yes.
		inc hl              ; next cell.
		ld a,(hl)           ; fetch type.
		cp b                ; is this deadly/custom?
		ret z               ; yes.
		ld a,(dispy)        ; horizontal position.
		ld c,a              ; store column in c register.
		and 7               ; is it straddling cells?
		jr z,.tded0          ; no.
		inc hl              ; last cell.
		ld a,(hl)           ; fetch type.
		cp b                ; is this the block?
		ret z               ; yes.
		dec de              ; one less cell to next row down.
.tded0:  
		add hl,de           ; point to next row.
		ld a,(hl)           ; fetch left cell block.
		cp b                ; is this fatal?
		ret z               ; yes.
		inc hl              ; next cell.
		ld a,(hl)           ; fetch type.
		cp b                ; is this fatal?
		ret z               ; yes.
		ld a,c              ; horizontal position.
		and 7               ; is it straddling cells?
		jr z,.tded1          ; no.
		inc hl              ; last cell.
		ld a,(hl)           ; fetch type.
		cp b                ; is this fatal?
		ret z               ; yes.
.tded1:
		ld a,(dispx)        ; vertical position.
		and 7               ; is it straddling cells?
		ret z               ; no, job done.
		add hl,de           ; point to next row.
		ld a,(hl)           ; fetch left cell block.
		cp b                ; is this fatal?
		ret z               ; yes.
		inc hl              ; next cell.
		ld a,(hl)           ; fetch type.
		cp b                ; is this fatal?
		ret z               ; yes.
		ld a,c              ; horizontal position.
		and 7               ; is it straddling cells?
		ret z               ; no.
		inc hl              ; last cell.
		ld a,(hl)           ; fetch final type.
		ret                 ; return with final type in accumulator.


; Fetch block type at (dispx, dispy).
; Input:
; dispx: Y coord (0-191)
; dispy: X coord (0-255)
tstbl:
		ld a,(dispx)        ; fetch y coord.
		rlca                ; divide by 8,
		rlca                ; and multiply by 32.
		ld h,a              ; store in d.
		and $E0             ; mask off high bits.
		ld l,a              ; low byte.
		ld a,h              ; restore shift result.
		and 3               ; high bits.
		add a,MAP>>8
		ld h,a              ; got displacement in de.
		ld a,(dispy)        ; x coord.
		rra                 ; divide by 8.
		rra
		rra
		and 31              ; only want 0 - 31.
		add a,l             ; add to displacement.
		ld l,a              ; displacement in de.
		ld a,(hl)           ; fetch byte there.
		ret


; Jump - if we can.
; Requires initial speed to be set up in accumulator prior to call.

jump:
		neg                 ; switch sign so we jump up.
		ld c,a              ; store in c register.
jump0:
		ld a,(ix+13)        ; jumping flag.
		and a               ; is it set?
		ret nz              ; already in the air.
		inc (ix+13)         ; set it.
		ld (ix+14),c        ; set jump height.
		ret

hop:   
		ld a,(ix+13)        ; jumping flag.
		and a               ; is it set?
		ret nz              ; already in the air.
		ld (ix+13),255      ; set it.
		ld (ix+14),0        ; set jump table displacement.
		ret

; Random numbers code.
; Pseudo-random number generator, 8-bit.

random:
		ld hl,seed          ; set up seed pointer.
		ld a,(hl)           ; get last random number.
		ld b,a              ; copy to b register.
		rrca                ; multiply by 32.
		rrca
		rrca
		xor 31
		add a,b
		sbc a,255
		ld (hl),a           ; store new seed.
		ld (varrnd),a       ; return number in variable.
		ret

; Keyboard test routine. (returns NC if pressed)

/*
ktest  ld c,a              ; key to test in c.
       and 7               ; mask bits d0-d2 for row.
       inc a               ; in range 1-8.
       ld b,a              ; place in b.
       srl c               ; divide c by 8
       srl c               ; to find position within row.
       srl c
       ld a,5              ; only 5 keys per row.
       sub c               ; subtract position.
       ld c,a              ; put in c.
       ld a,254            ; high byte of port to read.
ktest0 rrca                ; rotate into position.
       djnz ktest0         ; repeat until we've found relevant row.
       in a,(254)          ; read port (a=high, 254=low).
ktest1 rra                 ; rotate bit out of result.
       dec c               ; loop counter.
       jp nz,ktest1        ; repeat until bit for position in carry.
       ret
*/

;
; Checks if a key is pressed
;
; Input:	A=row
;			D=key
; Output:	Carry=1 if key not pressed
;			Carry=0 if key is pressed
; Modifies:	A,C
;
ktest:
		call MSX_SNSMAT
		and d
		ret z
		scf					; sets C, key NOT pressed
		ret


/* ktest:
		push hl		
 		ld hl,MSX_NEWKEY
		add a,l
		ld l,a
		ld a,(hl)
		and d
		jr z,pressed
		scf					; sets C, key NOT pressed
pressed:
		pop hl
		ret
 */
;
; Check if STOP key is pressed
;		
chkstop:
		ld bc,$1007
		ld a,c
		call MSX_SNSMAT
		and b
		ret nz
.loop1
		ld a,c
		call MSX_SNSMAT
		and b
		jr z,.loop1

.loop2
		ld a,c
		call MSX_SNSMAT
		and b
		jr nz,.loop2
.loop3
		ld a,c
		call MSX_SNSMAT
		and b
		jr z,.loop3
		ret
	
; Joystick and keyboard reading routines.
; A/E/joyval = result bits: 0,fire3,fire2,fire,up,down,left,right

joykey:
		call chkstop
		ifdef DEBUG
		BORDER 7
		endif
		ld a,(contrl)       ; control flag.
		dec a               ; is it the keyboard?
		jr z,joyjoy1         ; no, it's joystick 1
		dec a               ; joystick 2?
		jr z,joyjoy2         ; read joystick 2
; Keyboard controls (was 0)
		ld hl,keys+13        ; address of last key.
		ld e,0              ; zero reading.
		ld b,7              ; keys to read.
.loop:
		ld d,(hl)           ; get key from table.
		dec hl
		ld a,(hl)			; get row
		dec hl
		call ktest          ; is key pressed (C=0)?
		ccf                 ; complement the result (0=not pressed,1=pressed).
		rl e                ; rotate into reading.
		djnz .loop          ; repeat for all keys.
joyjo1:		
		ld a,e              ; copy e register to accumulator.
joyjo2:	
		ld (joyval),a       ; remember value.
		ifdef DEBUG
		BORDER 14
		endif
		ret

; Joysticks controls
joyjoy2:
		ld a,4				; for joystick 1
		jr joyread

joyjoy1:
		ld a,3				; for joystick 2

joyread:
; triggers check				
		ld e,0
		push af
		ld hl,keys+13        ; address of last key.
		ld d,(hl)           ; get key from table.
		dec hl
		ld a,(hl)			; get row
		call ktest          ; is key pressed (C=1)?
		jr c,.rdjoy
		set 6,e
.rdjoy:		
		pop af
		ld d,a				; save A
		call MSX_GTTRIG		; button B (4 or 3)
		or a
		jr z,notrigb2
setrigb:		
		set 5,e
notrigb2:
		ld a,d
		sub 2 				; button A (2 or 1)
		ld d,a
		call MSX_GTTRIG
		or a
		jr z,joycheck1
setriga:		
		set 4,e
; A/E/joyval = result bits: 0,fire3,fire2,fire,up,down,left,right		
; joysticks check				
joycheck1:
		ld a,d
		push de
		call MSX_GTSTCK
		pop de
		or a
		jr z,joyjo1
		ld b,a
		ld a,e
		djnz noup1
		add a,8
		jr joyjo2
noup1:
		djnz noupright1
		add a,9
		jr joyjo2
noupright1:
		djnz noright1
		inc a
		jr joyjo2
noright1:		
		djnz nodownright1
		add a,5
		jr joyjo2
nodownright1:
		djnz nodown1
		add a,4
		jr joyjo2
nodown1:
		djnz nodownleft1
		add a,6
		jr joyjo2
nodownleft1:
		djnz noleft1
		add a,2
		jr joyjo2
noleft1:
		djnz joyjo2
		add a,10
		jr joyjo2

; Display message.

dmsg:	
		ld hl,msgdat        ; pointer to messages.
		call getwrd         ; get message number.
dmsg3:
		call preprt         ; pre-printing stuff.
		call checkx         ; make sure we're in a printable range.
		
		ex de,hl
		call pradd			; find scrmap pointer from dispx,dispy
		push hl				; preserves buffer pointer
		ex de,hl
		push hl				; preserves start of string
		
		ld a,(prtmod)       ; print mode.
		and a               ; standard size?
		jp nz,bmsg1         ; no, double-height text.
dmsg0:	
		push hl             ; store string pointer.
		ld a,(hl)           ; fetch byte to display.
		and 127             ; remove any end marker.
		cp 13               ; newline character?
		jr z,dmsg1
		call ptxt           ; display character.		
		
		call nexpos         ; display position.
		jr nz,dmsg2         ; not on a new line.
		
		call nexlin         ; next line down.
dmsg2:	
		pop hl				
		ld a,(hl)           ; fetch last character.
		rla                 ; was it the end?
		jp nc,.nxtchr

		pop de				; restores start of string
		or a
		sbc hl,de			
		jr nz,.btzero
		ld hl,scrmap
		pop de				; restores scrmap buffer pointer
		add hl,de			; start of string in scrmap
		ld (hl),255
		jp dscor2
.btzero:

		ld b,h
		ld c,l				; get string lenght in BC
		pop de				; restores scrmap buffer pointer
		add hl,de
		ld a,h
		cp 3				; check if end of string is higher than length of map
		jr nc,.wrapped
.strseg:
		ld hl,scrmap
		add hl,de			; start of string in scrmap
		ld d,h
		ld e,l
		inc e
		ld (hl),255
		ldir		
		jp dscor2         	; job done.
.wrapped:	; half of the message is in the bottom and the rest wraps to coord 0,0
		; upper segment
		ld a,l
		or a
		jr z,.bottom
		push hl
		push de
		push bc
		ld c,l
		ld hl,scrmap
		ld de,scrmap+1
		ld (hl),255
		ldir	
		pop bc
		pop de
		pop hl
.bottom:
		; bottom segment
		ld a,c
		sub l
		ld c,a
		inc e
		dec c
		dec c
		jr .strseg
		
.nxtchr:
		inc hl              ; next character to display.
		jp dmsg0
dmsg1:
		ld hl,dispx         ; y coordinate.
		inc (hl)            ; newline.
		ld a,(hl)           ; fetch position.
		cp MSX_MAXROWS		; past screen edge?
		jr c,dmsg4          ; no, it's okay.
		ld (hl),0           ; restart at top.
dmsg4:	inc hl              ; x coordinate.
		ld (hl),0           ; carriage return.
		jr dmsg2
	   


; Display message in big text.

bmsg1:
		ld a,(hl)           ; get character to display.
		push hl             ; store pointer to message.
		and 127             ; only want 7 bits.
		cp 13               ; newline character?
		jr z,.bmsg2
		call bchar          ; display big char.
.bmsg3:
		pop hl              ; retrieve message pointer.
		ld a,(hl)           ; look at last character.
		inc hl              ; next character in list.
		rla                 ; was terminator flag set?
		jr nc,bmsg1         ; no, keep going.

		pop de				; restores start of string
		or a
		sbc hl,de			
		jr nz,.btzero
		ld hl,scrmap
		pop de				; restores scrmap buffer pointer
		add hl,de			; start of string in scrmap
		ld (hl),255			; 1st half
		ld de,32
		add hl,de
		ld (hl),255			; 2nd half
		ret
.btzero:
		; upper half
		ld b,h
		ld c,l				; get string lenght in BC
		ld hl,scrmap
		pop de				; restores scrmap buffer pointer
		add hl,de			; start of string in scrmap
		ld d,h
		ld e,l
		inc de
		ld (hl),255
		push hl
		push bc
		ldir
		; bottom half
		pop bc
		pop hl
		ld de,32
		add hl,de
		ld d,h
		ld e,l
		inc de
		ld (hl),255
		ldir
		ret
.bmsg2:
		ld hl,charx         ; y coordinate.
		inc (hl)            ; newline.
		inc (hl)            ; newline.
		ld a,(hl)           ; fetch position.
		cp MSX_MAXROWS-1		; past screen edge?
		jr c,.bmsg3          ; no, it's okay.
		ld (hl),0           ; restart at top.
		inc hl              ; y coordinate.
		ld (hl),0           ; carriage return.
		jr .bmsg3


; Big character display.

bchar:
		rlca                ; multiply char by 8.
		rlca
		rlca
		ld e,a              ; store shift in e.
		and 7               ; only want high byte bits.
		ld d,a              ; store in d.
		ld a,e              ; restore shifted value.
		and $F8             ; only want low byte bits.
		ld e,a              ; that's the low byte. DE=CHAR*8
		ld hl,(grbase)      ; address of graphics.
		add hl,de           ; add displacement.
		call gprad          ; get screen address (in DE)
		dec d		
		ld b,2
.nxtchar:		
		inc d
		SETWRT de
		ld c,4
.nxtrow:
		ld a,(hl)
		out (MSX_VDPDRW),a
		inc hl
		dec c
		nop					; VDP slowdown		
		out (MSX_VDPDRW),a
		jr nz,.nxtrow
		djnz .nxtchar
		dec d
		set 5,d				; DE=VRAM patterns, add $20 and now we're in color table
		ld b,2
nxtchar2:		

		ld a,e
        di
        out (MSX_VDPCW),a
        ld a,d
		ld c,8
        or 01000000b       ;for write, set bit 6 high
        out (MSX_VDPCW),a
        ei		

		ld a,(clratt)
nxtfile2:
		out (MSX_VDPDRW),a
		dec c
		jr nz,nxtfile2
		inc d
		djnz nxtchar2				
bchar1 call nexpos         ; display position.
       jp nz,bchar2        ; not on a new line.
bchar3 inc (hl)            ; newline.
       call nexlin         ; next line check.
bchar2 jp dscor2           ; tidy up line and column variables.

; Display a character. (MSX:OK)

achar:
		ld b,a              ; copy to b.
		call preprt         ; get ready to print.
		ld a,(prtmod)       ; print mode.
		and a               ; standard size?
		ld a,b              ; character in accumulator.
		jp nz,bchar         ; no, double-height text.
		call ptxt           ; display character.
	   
		call nexpos         ; display position.
		jp z,bchar3         ; next line down.
		jp bchar2           ; tidy up.

; Get next print column position.(MSX:OK)

nexpos:
		ld hl,dispy         ; X display position.
		ld a,(hl)           ; get coordinate.
		inc a               ; move along one position.
		and MSX_MAXCOLS-1   ; reached edge of screen?
		
		ld (hl),a           ; set new position.
		dec hl              ; point to y now.
		ret                 ; return with status in zero flag.

; Get next print line position. (MSX:OK)

nexlin inc (hl)            ; newline.
       ld a,(hl)           ; vertical position.
       cp MSX_MAXROWS      ; past screen edge?
       ret c               ; no, still okay.
       ld (hl),0           ; restart at top.
       ret

; Pre-print preliminaries.

preprt: 
		ld de,font-256		; font pointer, skipping first 32 ASCII codes
		ld (grbase),de      ; set up graphics base.
prescr:
		ld de,(charx)       ; display coordinates.
		ld (dispx),de       ; set up general coordinates.
		ret

; On entry: hl points to word list
;           a contains word number.
; Modifies: b,a,hl

getwrd:	; (MSX:OK)
		and a               ; first word in list?
		ret z               ; yep, don't search.
		ld b,a
getwd0:
		ld a,(hl)
		inc hl
		cp 128              ; found end?
		jr c,getwd0         ; no, carry on.
		djnz getwd0         ; until we have right number.
		ret

; Process sprites.
		
pspr:
		ld a,(highslot)
		and a
		ret z				; no sprites, nothing to do
		ifdef DEBUG
		BORDER 6
		endif
		ld b,a
		ld ix,sprtab        ; sprite table.
.loop:
		push bc
		ld a,(ix+0)         ; fetch sprite type.
		cp 9                ; within range of sprite types?
		call c,pspr2        ; yes, process this one.
		ld de,TABSIZ        ; distance to next odd/even entry.
		add ix,de           ; next sprite.
		pop bc
		djnz .loop
		ifdef DEBUG
		BORDER 9
		endif
		ret
pspr2:
		ld (ogptr),ix       ; store original sprite pointer.
		call pspr3          ; do the routine.
; rtorg:
		ld ix,(ogptr)       ; restore original pointer to sprite.
; rtorg0:
		ret
pspr3:
		ld hl,evtyp0        ; sprite type events list.
pspr4:
		add a,a             ; double accumulator.
		ADD_HL_A
;
; Makes an indirect jump based on the contents of HL
;
jumphl:		
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a			
		jp (hl)

; Address of each sprite type's routine.

evtyp0:	dw evnt00
evtyp1:	dw evnt01
evtyp2:	dw evnt02
evtyp3:	dw evnt03
evtyp4:	dw evnt04
evtyp5:	dw evnt05
evtyp6:	dw evnt06
evtyp7:	dw evnt07
evtyp8:	dw evnt08

; Look for sprites not mapped yet and map them
; Input:
;	None
; Output:
;	None. Sprites mapped
;
chkimg:
		ld a,(highslot)
		and a
		ret z				; no sprites, nothing to do
		ifdef DEBUG
		BORDER 3
		endif
		ld b,a
		ld de,TABSIZ				
.loop:		
		ld a,(ix+0)			; get sprite type
		inc a
		jr z,.nxtspr		; is the sprite active?		
		ld a,(ix+1)		
 		ld c,a
		call gfrm
		ld l,(hl)
		ld h,mapspr>>8		
		ld a,(hl)
		inc a				; has already been mapped?
		jr nz,.nxtspr
		ld a,c
		ex de,hl
 		call mapsprite		; the sprite has not been mapped ($FF), do it now
		ex de,hl
.nxtspr:		
		add ix,de           ; next sprite.
		djnz .loop          ; repeat for remaining sprites.
		ifdef DEBUG
		BORDER 14
		endif
		ret
 
dissprs:
		ld a,208			; disable all sprites
		ld hl,MSX_SPRATR
		jp MSX_WRTVRM

;
; Copy data from RAM to VRAM
; Input:
; 	HL: Source in RAM
; 	DE: VRAM address to copy to
;	B: bytes to copy (0-255, 0 is 256 bytes)
; Output:
;	None. 
;		 
ram2vram:
		ld c,MSX_VDPCW
        di
        out (c),e
        set 6,d			; high byte set for write
        out (c),d
        ei	
		dec c 
.loop:		
		[8] outi
		jp nz,.loop
		ret

;
; Copy data from RAM to VRAM
; Input:
; 	HL: Source in RAM
; 	DE: VRAM address to copy to
;	B: bytes to copy (0-255, 0 is 256 bytes)
; Output:
;	None. 
;
		 
ram2vram_slow:
		ld c,MSX_VDPCW
        di
        out (c),e
        set 6,d			; high byte set for write
        out (c),d
        ei	
		dec c 
.loop:		
		outi
		jp nz,.loop
		ret

 
buildspr:
		ld a,(highslot)		; max number of sprites being instantiated
		and a
		ret z				; no sprites, nothing to do
		ifdef DEBUG
		BORDER 12
		endif
		ld ix,sprtab
		ld b,a
		ld hl,spratr
		ld (sprptr),hl
.loop:		
		ld a,(ix+0)			; get sprite type
		inc a
		jr nz,.ison			; is the sprite active?
		ld a,$D1			; not active
		ld (hl),a			; Y
		inc l
		inc l
		inc l
		jr .nxtspr		
.ison:		
		ld a,(ix+3)			
		dec a				; corrects y MSX sprite coordinate		
		ld (hl),a			; Y
		inc l		
		
		ld a,(ix+4)				
		ld (hl),a			; X	
		inc l

		ex de,hl
		ld a,(ix+1)
		call gfrm
		ld l,(hl)
		ld h,(mapspr>>8)&$FF				
		ld a,(hl)			; gets real frame from mapspr table
		add a,(ix+2)
		add a,a
		add a,a
		ex de,hl
		ld (hl),a			; image number * 4
		inc l
		
		ld a,(ix+5)
		ld (hl),a
.nxtspr:
		inc l		
		ld de,TABSIZ		
		add ix,de           ; next sprite.
		djnz .loop          ; repeat for remaining sprites.
		ld a,$D0			; no more sprite from here
		ld (hl),a

; ----------------------------------

sprflick:	
		ld hl,spratr
		ld a,(MSX_STATFL)
		bit 6,a
		jr nz,.flick
		ld a,colltab&$FF
		ld (offset),a
		jr .no5th
.flick:
		; sort sprites into two separate lists (aligned with 5th & not aligned)
		and 31
		ld de,spratr2		; not aligned list
		push de
		ld d,h
		ld e,l
		add a,a
		add a,a
		add a,e
		ld e,a
		ld a,(highslot)
		ld b,a				; number of sprites to check
		ld a,(de)			
		ld c,a				; get C=Y-coord of 5th sprite
		ld de,colltab		; aligned with 5th list
.lp:
		ld a,(hl)
		sub c
		jr nc,.bottom
		neg
.bottom:		
		cp MSX_SPRVS		; compare with sprite vertical size
		jr nc,.noovlp
		push bc
		ldi
		ldi
		ldi
		ldi
		pop bc
		jr .nxt
.noovlp:
		EX_SP_DE
		push bc
		ldi
		ldi
		ldi
		ldi
		pop bc
		EX_SP_DE
.nxt:
		djnz .lp
		; rotate SAT segments (only 5th related sprites)
		ld c,e
		ld a,(offset)
		add a,16
		cp c
		jr c,.noreset 
		ld a,colltab&$FF
		ld (offset),a		; store offset to split SAT
		ld a,e
		pop de
		jr .fullsat			; SAT is not splitted, only one copy needed		
.noreset:		
		ld (offset),a		; store offset to split SAT
		ld h,d
		ld l,a
		ld a,c
		sub l
		ld c,a
		pop de
		ldir				; copy first half 
		ld a,(offset)
.fullsat:
		sub colltab&$FF
		ld c,a
		ld hl,colltab
		ldir				; copy 2nd half
		ld a,$D0			; no more sprite from here
		ld (de),a
		ld hl,spratr2
.no5th:
		ld (sprptr),hl

		ifdef DEBUG
		BORDER 14
		endif

		ret


/*
 ; Could be reworked
		ld hl,spratr
		ld a,(MSX_STATFL)
		bit 6,a
		jp z,.NO5TH
		
		ld e,a
		ld a,(offset)
		or a
		jr z,.NOLDIR
		cp 255
		jr nz,.NOINIT
		ld a,e
		and $3C
		add a,a
		add a,a		
.NOINIT:	
		ld b,0
		ld c,a
		ld de,spratr2
		ldir
.NOLDIR:	
		add a,16
		and $3F
		jp .NORESET
		
.NO5TH:	
		ld a,255
.NORESET:	
		ld (offset),a
		ld (sprptr),hl
*/

dumpspr:
		ld a,(highslot)
		and a
		ret z				; no sprites, nothing to do
		ifdef DEBUG
		BORDER 10
		endif		
		add a,a
		add a,a		
		add a,8
		and $F8				; only send to VRAM multiples of 8 
		ld b,a
		ld hl,(sprptr)
		ld de,MSX_SPRATR
		ifdef FASTVRAMDUMP
		call ram2vram
		else
		call ram2vram_slow
		endif
		ifdef DEBUG
		BORDER 14
		endif
		ret
		
; Drop into screen address routine. (MSX:OK)
; This routine returns in HL a screen address for (dispx, dispy) in hl. Must not modify DE

scadd:
		ld a,(dispx)
		ld l,a
		and $F8
		rrca
		rrca
		rrca
		ld h,a
		ld a,l
		and $07
		ld l,a			; HL= ((y/8)*256+y%8)
		ld a,(dispy)
		and $F8			; A = (x/8)*8
		ADD_HL_A
		ret	
		
; Animates a sprite.

animsp:
		ld hl,frmno         ; game frame.
		and (hl)            ; is it time to change the frame?
		ret nz              ; not this frame.
		ld a,(ix+1)         ; sprite image.
		call gfrm           ; get frame data.
		inc hl              ; point to frames.
		ld a,(ix+2)         ; sprite frame.
		inc a               ; next one along.
		cp (hl)             ; reached the last frame?
		jr c,anims0         ; no, not yet.
		xor a               ; start at first frame.
anims0:
		ld (ix+2),a         ; new frame.
		ret
animbk:
		ld hl,frmno         ; game frame.
		and (hl)            ; is it time to change the frame?
		ret nz              ; not this frame.
		ld a,(ix+1)         ; sprite image.
		call gfrm           ; get frame data.
		inc hl              ; point to frames.
		ld a,(ix+2)         ; sprite frame.
		and a               ; first one?
		jr nz,.rtanb0        ; yes, start at end.
		ld a,(hl)           ; last sprite.
.rtanb0:
		dec a               ; next one along.
		jr anims0           ; set new frame.

; Check for collision with other sprite, strict enforcement.
; Input:
;	B = NUmber of sprite to check for collision
sktyp:  
		ld a,(highslot)
		and a
		ret z				; no sprites, nothing to do
		ifdef DEBUG
		BORDER 4
		endif
		ld a,(MSX_STATFL)
		and 00100000b		; check hardware sprites collision
		jr z,.nocoll		; no collisions, skip routine
							; There's a collision, find it
		ld hl,sprtab        ; sprite table.
.loop: 
		ex af,af            ; store loop counter.
		ld (skptr),hl       ; store pointer to sprite.
		ld a,(hl)           ; get sprite type.
		cp b                ; is it the type we seek?
		jr z,coltyp         ; yes, we can use this one.
.sktyp1: 
		ld hl,(skptr)       ; retrieve sprite pointer.
		
		ld de,TABSIZ        ; size of each entry.
		add hl,de           ; point to next sprite in table.
		
		ex af,af           ; restore loop counter.
		dec a               ; one less iteration.
		jp nz,.loop        ; keep going until we find a slot.
		
		ld hl,0             ; default to ROM address - no sprite.
		ld (skptr),hl       ; store pointer to sprite.
		or h                ; don't return with zero flag set.
.nocoll:
		ifdef DEBUG
		BORDER 6
		endif
		ret                 ; didn't find one.

coltyp:
		ld a,(ix+0)         ; current sprite type.
		cp b                ; seeking sprite of same type?
		jr z,.colty1         ; yes, need to check we're not detecting ourselves.
.colty0:
		ld de,X             ; distance to x position in table.
		add hl,de           ; point to coords.
		
		ld e,(hl)           ; fetch x coordinate.
		inc hl              ; now point to y.
		ld d,(hl)           ; that's y coordinate.
; Drop into collision detection.
;colc16:
		ld a,(ix+X)         ; x coord.
		sub e               ; subtract x.
		jr nc,.colc1a        ; result is positive.
		neg                 ; make negative positive.
.colc1a:
		cp 16               ; within x range?
		jr nc,sktyp.sktyp1        ; no - they've missed.
		ld c,a              ; store difference.
		ld a,(ix+Y)         ; y coord.
		sub d               ; subtract y.
		jr nc,.colc1b        ; result is positive.
		neg                 ; make negative positive.
.colc1b:
		cp 16               ; within y range?
		jr nc,sktyp.sktyp1        ; no - they've missed.
		add a,c             ; add x difference.
		cp 26               ; only 5 corner pixels touching?
		ret c               ; carry set if there's a collision.
		jp sktyp.sktyp1           ; try next sprite in table.
.colty1:
		push ix             ; base sprite address onto stack.
		pop de              ; pop it into de.
		ex de,hl            ; flip hl into de.
		sbc hl,de           ; compare the two.
		ex de,hl            ; restore hl.
		jr z,sktyp.sktyp1   ; addresses are identical.
		jp .colty0

; Display number.
;
disply:
		ld bc,displ0        ; display workspace.
		call num2ch         ; convert accumulator to string.
displ1:
		dec bc              ; back one character.
		ld a,(bc)           ; fetch digit.
		or 128              ; insert end marker.
		ld (bc),a           ; new value.
		ld hl,displ0        ; display space.
		jp dmsg3            ; display the string.

; Initialise screen.
;
initsc:
		ld a,(roomtb)       ; whereabouts in the map are we?
		call tstsc          ; find displacement.
		cp 255              ; is it valid?
		ret z               ; no, it's rubbish.
		ld (scno),a         ; store new room number.
		ret

; Test screen.
;
tstsc  ld hl,mapdat-MAPWID ; start of map data, subtract width for negative.
       ld b,a              ; store room in b for now.
       add a,MAPWID        ; add width in case we're negative.
       ld e,a              ; screen into e.
       ld d,0              ; zeroise d.
       add hl,de           ; add displacement to map data.
       ld a,(hl)           ; find room number there.
       ret

; Screen left.
;
scrl:
		ld a,(roomtb)       ; present room table pointer.
		dec a               ; room left.
scrl0:
		call tstsc          ; test screen.
		inc a               ; is there a screen this way?
		ret z               ; no, return to loop.
		ld a,b              ; restore room displacement.
		ld (roomtb),a       ; new room table position.
scrl1:
		call initsc         ; set new screen.
		ld hl,restfl        ; restart screen flag.
		ld (hl),2           ; set it.
		ret
scrr:
		ld a,(roomtb)       ; room table pointer.
		inc a               ; room right.
		jr scrl0
scru:
		ld a,(roomtb)       ; room table pointer.
		sub MAPWID          ; room up.
		jr scrl0
scrd:
		ld a,(roomtb)       ; room table pointer.
		add a,MAPWID        ; room down.
		jr scrl0
		
; Jump to new screen.
;
nwscr:
		ld hl,mapdat        ; start of map data.
		ld bc,256*80        ; zero room count, 80 to search.
nwscr0:
		cp (hl)             ; have we found a match for screen?
		jr z,nwscr1         ; yes, set new point in map.
		inc hl              ; next room.
		inc c               ; count rooms.
		djnz nwscr0         ; keep looking.
		ret
nwscr1:
		ld a,c              ; room displacement.
		ld (roomtb),a       ; set the map position.
		jr scrl1            ; draw new room.


; Gravity processing.
;
grav:
 		ld a,(frmno)
		rrca
		ret c				; only 1/2 of frames		
		ld a,(ix+13)        ; in-air flag.
		and a               ; are we in the air?
		ret z               ; no we are not.
		inc a               ; increment it.
		jp z,ogrv           ; set to 255, use old gravity.
		ld (ix+13),a        ; write new setting.
		rra                 ; every other frame.
		jr nc,grav0         ; don't apply gravity this time.
		ld a,(ix+14)        ; pixels to move.
		cp 16               ; reached maximum?
		jr z,grav0          ; yes, continue.
		inc (ix+14)         ; slow down ascent/speed up fall.
grav0:
		ld a,(ix+14)        ; get distance to move.
		sra a               ; divide by 2.
		and a               ; any movement required?
		ret z               ; no, not this time.
		cp 128              ; is it up or down?
		jr nc,gravu         ; it's up.
gravd:
		ld b,a              ; set pixels to move.
gravd0:
		call cangd          ; can we go down?
		jr nz,gravst        ; can't move down, so stop.
		inc (ix+3)          ; adjust new x coord.
		djnz gravd0
		ret
gravu:
		neg                 ; flip the sign so it's positive.
		ld b,a              ; set pixels to move.
gravu0:
		call cangu          ; can we go up?
		jp nz,ifalls        ; can't move up, go down next.
		dec (ix+3)          ; adjust new x coord.
		djnz gravu0
		ret
gravst:
		ld a,(ix+14)        ; jump pointer high.
		ld (ix+13),0        ; reset falling flag.
		ld (ix+14),0        ; store new speed.
		cp 8                ; was speed the maximum?
evftf:
		jp z,evnt15         ; yes, fallen too far.
		ret

; Old gravity processing for compatibility with 4.6 and 4.7.
;
ogrv:   
		ld e,(ix+14)        ; get index to table.
		ld d,0              ; no high byte.
		ld hl,jtab          ; jump table.
		add hl,de           ; hl points to jump value.
		ld a,(hl)           ; pixels to move.
		cp 99               ; reached the end?
		jr nz,ogrv0         ; no, continue.
		dec hl              ; go back to previous value.
		ld a,(hl)           ; fetch that from table.
		jr ogrv1
ogrv0  inc (ix+14)         ; point to next table entry.
ogrv1  and a               ; any movement required?
       ret z               ; no, not this time.
       cp 128              ; is it up or down?
       jr nc,ogrvu         ; bigger than 128, it's up.	   
ogrvd  ld b,a              ; less than 128, go down. Set pixels to move.
ogrvd0 call cangd          ; can we go down?
       jr nz,ogrvst        ; can't move down, so stop.
       inc (ix+3)          ; adjust new x coord.
       djnz ogrvd0
       ret	   
ogrvu  neg                 ; flip the sign so it's positive.
       ld b,a              ; set pixels to move.
ogrvu0 call cangu          ; can we go up?
       jr nz,ogrv2         ; can't move up, go down next.
       dec (ix+3)          ; adjust new x coord.
       djnz ogrvu0
       ret	   
ogrvst ld e,(ix+14)        ; get index to table.
       ld d,0              ; no high byte.
       ld hl,jtab          ; jump table.
       add hl,de           ; hl points to jump value.
       ld a,(hl)           ; fetch byte from table.
       cp 99               ; is it the end marker?
       ld (ix+13),0        ; reset jump flag.
       ld (ix+14),0        ; reset pointer.
       jp evftf	   
ogrv2  ld hl,jtab          ; jump table.
       ld b,0              ; offset into table.
ogrv4  ld a,(hl)           ; fetch table byte.
       cp 100              ; hit end or downward move?
       jr c,ogrv3          ; yes.
       inc hl              ; next byte of table.
       inc b               ; next offset.
       jr ogrv4            ; keep going until we find crest/end of table.
ogrv3  ld (ix+14),b        ; set next table offset.
       ret

; Initiate fall check.
;
ifall:
		ld a,(ix+13)        ; jump pointer flag.
		and a               ; are we in the air?
		ret nz              ; if set, we're already in the air.
		ld h,(ix+4)         ; y coordinate.
		ld a,16             ; look down 16 pixels.
		add a,(ix+3)        ; add x coordinate.
		ld l,a              ; coords in hl.
		ld (dispx),hl       ; set up test coordinates.
		call tstbl          ; get map address.
		call plchk          ; block, platform check.
		ret nz              ; it's solid, don't fall.
		inc hl              ; look right one cell.
		call plchk          ; block, platform check.
		ret nz              ; it's solid, don't fall.
		ld a,(dispy)        ; x coordinate.
		and 7               ; position straddling block cells.
		jr z,ifalls         ; no more checks needed.
		inc hl              ; look to third cell.
		call plchk          ; block, platform check.
		ret nz              ; it's solid, don't fall.
ifalls:
		inc (ix+13)         ; set in air flag.
		ld (ix+14),0        ; initial speed = 0.
		ret

tfall:
		ld a,(ix+13)        ; jump pointer flag.
		and a               ; are we in the air?
		ret nz              ; if set, we're already in the air.
		call ifall          ; do fall test.
		ld a,(ix+13)        ; get falling flag.
		and a               ; is it set?
		ret z               ; no.
		ld (ix+13),255      ; we're using the table.
		jr ogrv2            ; find position in table.


; Get frame data for a particular sprite.
;
gfrm:
		rlca                ; multiple of 2.
		ld hl,(frmptr)      ; frames used by game.
		ADD_HL_A
		ret

; Find sprite list for current room.
;
sprlst:
		ld a,(scno)         ; screen number.
		ld hl,(nmeptr)      ; pointer to enemies.
		ld b,a              ; loop counter in b register.
		and a               ; is it the first screen?
		ret z               ; yes, don't need to search data.
		ld de,NMESIZ        ; bytes to skip.
.loop:
		ld a,(hl)           ; fetch type of sprite.
		inc a               ; is it an end marker?
		jr z,.nxtscr        ; yes, end of this room.
		add hl,de           ; point to next sprite in list.
		jr .loop            ; continue until end of room.
.nxtscr:
		inc hl              ; point to start of next screen.
		djnz .loop          ; continue until room found.
		ret

; Clear all but a single player sprite.
;
nspr:
		ld b,NUMSPR         ; sprite slots in table.
		ld ix,sprtab        ; sprite table.
		ld de,TABSIZ        ; distance to next odd/even entry.
.loop:
		ld a,(ix+0)         ; fetch sprite type.
		and a               ; is it a player?
		jr z,.loop1         ; yes, keep this one.
		ld (ix+0),255       ; remove next type.
.loop1:
		add ix,de           ; next sprite.
		djnz .loop          ; one less space in the table.
		ret
		
; Two initialisation routines.

; HL is already pointing to start of sprites for this screen (nmedat)
; Initialise sprites - copy everything from list to table.
;
ispr:	
		xor a
		ld (nsprite),a		; reset first sprite frame number in VRAM
		ld b,NUMSPR         ; sprite slots in table.
		ld ix,sprtab        ; sprite table.
.loop2:
		ld a,(hl)
		inc a
		jr z,.exit
.loop1:  
		ld a,(ix+0)         ; next type.
		inc a
		jr z,.copyspr       ; no, process this one.
		ld de,TABSIZ        ; distance to next odd/even entry.
		add ix,de           ; next sprite.
		djnz .loop1         ; repeat for remaining sprites.
		jr .exit
.copyspr:
		call cpsp           ; initialise a sprite.
		djnz .loop2         ; one less space in the table.
.exit:
		jp hslot

; HL is already pointing to start of sprites for this screen (nmedat)		
; Initialise sprites - but not player, we're keeping the old one.
;
kspr:	
		xor a
		ld (nsprite),a		; reset first sprite frame number in VRAM		
		ex de,hl
		call dissprs		; disable all sprites to mask them
		ex de,hl		
		ld b,NUMSPR         ; sprite slots in table.
		ld ix,sprtab        ; sprite table.
.loop2:  
		ld a,(hl)           ; fetch byte.
		cp 255              ; is it an end marker?
		jr z,.exit          ; yes, no more to do.
		and a               ; is it a player sprite?
		jr nz,.loop1        ; no, add to table as normal.		
		inc hl
		call mapsprite		; no player set but sprite pattern mapped to VRAM
		dec hl		
		ld de,NMESIZ        ; distance to next item in list.
		add hl,de           ; point to next one.
		jr .loop2
.loop1:
		ld a,(ix+0)         ; next type.
		inc a               ; is it enabled yet?
		jr z,.copyspr       ; no, process this one.
		ld de,TABSIZ        ; distance to next odd/even entry.
		add ix,de           ; next sprite.
		djnz .loop1         ; repeat for remaining sprites.
		jr .exit            ; no more room in table.
.copyspr:
		call cpsp           ; copy sprite to table.
		djnz .loop2         ; one less space in the table.
.exit:
		jp hslot

; Copy sprite from list to table.

cpsp:
		ld a,(hl)           ; fetch byte from table.
		ld (ix+0),a         ; set up type.
		inc hl              ; move to next byte.
		ld a,(hl)           ; fetch byte from table.
		ld (ix+1),a         ; set up sprite number.		
		inc hl              ; move to next byte.
		call mapsprite		; remaps RAM sprite number in A to a new VRAM sprite
		ld a,(hl)           ; fetch byte from table (color).
		ld (ix+5),a         ; set up color.
		inc hl              ; move to next byte.
		ld a,(hl)           ; fetch byte from table.
		ld (ix+3),a         ; set up coordinate.
		inc hl              ; move to next byte.
		ld a,(hl)           ; fetch byte from table.
		ld (ix+4),a         ; set up coordinate.
		inc hl		
		xor a               ; zeroes in accumulator.
		ld (ix+2),a         ; reset frame number.
		ld (ix+10),a        ; reset direction.
		ld (ix+13),a        ; reset jump pointer low.
		ld (ix+14),a        ; reset jump pointer high.
		ld (ix+16),255      ; reset data pointer to auto-restore.
		push ix             ; store ix pair.
		push hl             ; store hl pair.
		push bc
		call evnt09         ; perform event.
		pop bc
		pop hl              ; restore hl.
		pop ix              ; restore ix.
		ld de,TABSIZ        ; distance to next odd/even entry.
		add ix,de           ; next sprite.
		ret

		; A=image number from SPRITEPOSITION
mapsprite:					; initialize mapspr table
		push hl
		push bc
		call gfrm
		ld a,(hl)			; get real frame in RAM
		and 127				; maximum 128 frames in RAM (correct?)
		ld e,a
		ld d,mapspr>>8		
		ld a,(de)
		inc a
		jr nz,nomap
		ld a,(nsprite)		; gets available sprite frame pointer
		ld (de),a			; maps this to the old image from SPRITEPOSITION
		inc hl
		add a,(hl)			; next sprite frame available after adding frames size
		ld (nsprite),a		; stores it as new available sprite frame
		dec hl				; restore HL pointer to start of frmlst
		call spradr			; HL = sprite frame list position, DE = pointer to actual sprite frame in VRAM, BC = lenght of data		
		call MSX_SETWRT
		ex de,hl			; HL = sprite RAM data address, DE = spriVte RAM data address, BC = lenght of data
nxtsprbyt:		
		ld a,(hl)
		out (MSX_VDPDRW),a
		cpi					; 18
		jp pe,nxtsprbyt		; 11 = 29
nomap:		
		pop bc
		pop hl
		ret
		
; Inputs
; HL = sprite frame list position
; DE = pointer to actual sprite frame in VRAM
spradr:
		ld a,(hl)			; get initial image frame in RAM
		call mult32			; BC= A * 32
		inc hl				; next frmlst position (num framesS)
		ld a,(hl)			; get num frames		
		ex af,af			; saves num frames
		ld hl,sprgfx
		add hl,bc			; HL = sprite RAM data address
		ld a,(de)			; gets destination VRAM sprite frame
		ex de,hl			; DE = now sprite RAM source data address
		call mult32		
		ld hl,MSX_SPRTBL
		add hl,bc			; HL = sprite VRAM destination data address
		ex af,af			; restore num frames		
mult32:		
		rrca                
		rrca
		rrca
		ld c,a              
		and 31              
		ld b,a              
		ld a,c              
		and 224             
		ld c,a				; BC = A * 32		
		ret

	if OFLAG
	
clrobjlst:
		ld hl,objlist
		ld c,1     
		ld a,255
		jp fastfill
	
	endif
		
clrscrmap:
		ld hl,scrmap
		ld c,3     
		ld a,255
;
; fast fills RAM areas starting in addresses multiple of 4 
; Input:	C=number of 256 bytes blocks to fill
;			HL=starting address
;			A=byte for fill			
;
fastfill:
		ld b,64              ;set B to 64 (64 * 4 sets = 256 bytes initiaized)
.loop1:
		ld (hl), a           ;set byte to 255
		inc l                ;move to the next byte
		ld (hl), a
		inc l
		ld (hl), a
		inc l
		ld (hl), a
		inc hl               ;this time we are not sure that inc l will not cause overflow
		djnz .loop1          ;repeat for next 4 bytes
		dec c
		jr nz,fastfill       ;outer loop. repeat for next c*256 bytes.
		ret		
		 
; Clear the play area window.

clw:
		ld hl,(wintop)
		ld (dispx),hl
		call gprad          ; get print address in DE.
		ex de,hl
		ld a,(winhgt)       ; height of window.
		ld b,a
		ld a,(winwid)
		add a,a
		add a,a
		add a,a
		ld c,a
.loop3   
		call MSX_SETWRT
		push bc
		xor a
.loop1:
		out (MSX_VDPDRW),a
		dec c
		jr nz,.loop1
		set 5,h
		call MSX_SETWRT
		pop bc
		push bc
		ld a,(clratt)
.loop2:
		out (MSX_VDPDRW),a
		dec c
		jr nz,.loop2
		pop bc
		res 5,h
		inc h
		djnz .loop3
		ld hl,(wintop)      ; get coordinates of window.
		ld (charx),hl       ; put into display position.
		call clrscrmap
		jp dissprs


	if SFLAG
	
; Effects code.
; Ticker routine is called 25 times per second (MSX:50fps).

scrly:
 	ifdef DEBUG
		BORDER 7
	endif
		ld a,(scrlyoff)
		or a
		ret nz
		ld hl,scrbuf
		ld de,(txtbeg)         ; get screen address.
		ld a,(txtwid)       
		add a,a
		add a,a
		add a,a					; characters*8 wide.
		ld b,a
		ifdef FASTVRAMDUMP
		call ram2vram
		else
		call ram2vram_slow
		endif
 	ifdef DEBUG
		BORDER 14
	endif
		ret
		
scrltxt:
 	ifdef DEBUG
		BORDER 2
	endif
		ld a,(scrlyoff)
		or a
		ret nz
		
		ld a,(txtbit)
		rlca
		jr nc,.nonewchr
		
		ld hl,(txtpos)      ; get text pointer.
		ld a,(hl)           ; find character we're displaying.
		push hl
		and 127             ; remove end marker bit if applicable.
		cp 13               ; is it newline?
		jr nz,.scrly5       ; no, it's okay.
		ld a,32             ; convert to a space instead.
.scrly5:
		rlca
		rlca
		rlca                ; multiply by 8 to find char.
		ld b,a              ; store shift in b.
		and 3               ; keep within 768-byte range of font.
		ld d,a              ; that's our high byte.
		ld a,b              ; restore the shift.
		and 248
		ld e,a
		ld hl,font-256      ; font.
		add hl,de           ; point to image of character.
		ld de,(txtend)
		ld bc,8
		ldir
		pop hl
		ld a,(hl)
		inc hl
		rla
		jr nc,.scrly6        ; not yet - continue.
.scrly4:
		ld hl,(txtini)      ; start of scrolling message.		
.scrly6:
		ld (txtpos),hl      ; new text pointer position.
		ld a,1
.nonewchr:
		ld (txtbit),a

		; Scroll a char row
		ld hl,(txtend)
		ld d,254
		ld c,8
		ld a,(txtwid)       ; characters wide.
		inc a
		ld b,a              ; put into the loop counter.
.rowloop:
		push bc
		push hl
		ld c,0
.colloop:	   
		ld a,(hl)
		rlca
		ld e,a
		and d
		or c
		ld (hl),a
		ld a,e
		and 1
		ld c,a
		
		ld a,l
		sub 8
		jr nc,$+3
		dec	h
		ld l,a

		djnz .colloop
		pop hl
		inc l
		pop bc
		dec c
		jr nz,.rowloop
		
 		ifdef DEBUG
		BORDER 14
		endif
		ret


				
	   ; bc= width*256+msg.number
iscrly: 
		call prescr         ; set up display position.
		ld a,b              ; width.
		dec a               ; subtract one.
		cp MSX_MAXCOLS      ; is it between 1 and 32?
		ret nc              ; TODO:no, disable messages.
		ld d,b
		ld a,c              ; message number.
		ld hl,msgdat        ; text messages.
		call getwrd         ; find message start.
		ld (txtini),hl      ; set initial text position.
		ld (txtpos),hl      ; set initial text position.
		ld a,d
		ld (txtwid),a
		add a,a
		add a,a
		add a,a				; *8
		ld c,a
		ld b,0
		jr nc,.nocarry
		inc b
.nocarry:		
		call gprad          ; get hires print address in DE.
		ld (txtbeg),de
		ld hl,scrbuf
		ex de,hl
		call MSX_LDIRMV
		ld (txtend),de      ; set text screen address.
        ld a,128
        ld (txtbit),a
		xor a	
		ld (scrlyoff),a 
        ret

	endif


	if DFLAG

dig:
       and 3
       jr z,digl
       dec a
       jr z,digr
       dec a
       jr z,digu
       ld h,(ix+4)
       ld a,16
       add a,(ix+3)
       ld l,a
       jr digv
digu   ld a,(ix+3)
       ld h,(ix+4)
       sub 2
       ld l,a
digv   ld (dispx),hl
       call tstbl
       call fdchk
       inc hl
       call fdchk
       ld a,(dispy)
       and 7
       ret z
       inc hl
       jp fdchk
digl   ld l,(ix+3)
       ld a,(ix+4)
       sub 2
       ld h,a
digh   ld (dispx),hl
       ld a,l
       and 7
       ld a,3
       jr nz,digh1
       dec a
digh1  ld b,a
       call tstbl
digh0  push bc
       call fdchk
       ld de,MSX_MAXCOLS
       add hl,de
       pop bc
       djnz digh0
       ret
digr   ld l,(ix+3)
       ld a,(ix+4)
       add a,16
       ld h,a
       jr digh 

	endif


	; include "PT3SFX.asm"
	include "PT3-ROM.asm"
	include "ayFX-ROM.asm"


	if XFLAG
	
sfxbank:	incbin "..\resources\sfx.afb"
	
	endif
	
	if PFLAG

; some aligned data

	   ALIGN 256

dots:		db 128,64,32,16,8,4,2,1   
shrptr:		dw laser          ; laser.
			dw trail          ; vapour trail.
			dw shrap          ; shrapnel from explosion.
			dw dotl           ; horizontal starfield left.
			dw dotr           ; horizontal starfield right.
			dw dotu           ; vertical starfield up.
			dw dotd           ; vertical starfield down.
			dw ptcusr         ; user particle.			
shrsin: 	dw 0,1024,391,946,724,724,946,391
			dw 1024,0,946,65144,724,64811,391,64589
			dw 0,64512,65144,64589,64811,64811,64589,65144
			dw 64512,0,64589,391,64811,724,65144,946


	endif


; User routine.  Put your own code in here to be called with USER instruction.
; if USER has an argument it will be passed in the accumulator.

user:
		ret

; Game-specific data and events code generated by the compiler ------------------

; ======================================================================================
;
; BEGINNING OF RAM AREA: The following data needs to be located in RAM!!!
;
; ======================================================================================

; Variables that NEED to be initialized when in RAM mode can be autoinitialized for free

	if DISTYPE!=ROM

score:		db "000000" 		; player's score  000000 .
hiscor:		db "000000" 		; high score  000000 .
bonus:		db "000000" 		; bonus  000000 .
displ0:		db 0,0,0,13+128

	if EFLAG

sndtyp:		db 0

	endif

	if PFLAG

shrplot:	dw prosh1

	endif

	if SFLAG
	
scrlyoff:	db 1
	
	endif
	
	if MFLAG
	
mod0:	db $C3,0,0
mod1:	db $C3,0,0
mod2:	db $C3,0,0

	endif

	ifdef DATA00
rptr00:		dw rdat00
	endif
	ifdef DATA01
rptr01:		dw rdat01
	endif
	ifdef DATA02
rptr02:		dw rdat02
	endif
	ifdef DATA03
rptr03:		dw rdat03
	endif
	ifdef DATA04
rptr04:		dw rdat04
	endif
	ifdef DATA05
rptr05:		dw rdat05
	endif
	ifdef DATA06
rptr06:		dw rdat06
	endif
	ifdef DATA07
rptr07:		dw rdat07
	endif
	ifdef DATA08
rptr08:		dw rdat08
	endif
	ifdef DATA09
rptr09:		dw rdat09
	endif
	ifdef DATA10
rptr10:		dw rdat10
	endif
	ifdef DATA11
rptr11:		dw rdat11
	endif
	ifdef DATA12
rptr12:		dw rdat12
	endif
	ifdef DATA13
rptr13:		dw rdat13
	endif
	ifdef DATA14
rptr14:		dw rdat14
	endif
	ifdef DATA15
rptr15:		dw rdat15
	endif
	ifdef DATA16
rptr16:		dw rdat16
	endif
	ifdef DATA17
rptr17:		dw rdat17
	endif
	ifdef DATA18
rptr18:		dw rdat18
	endif
	ifdef DATA19
rptr19:		dw rdat19
	endif
	ifdef DATA20
rptr20:		dw rdat20
	endif


	
	endif
	
 ; clock  db 0              ; last clock reading.

endmain:	equ $

; Fill the rest of the page

	if DISTYPE=ROM

	output rom_filler.bin

	org endmain
	
		if ($ & $8000)!=0
			block $4000-($-8000h),255
		else
			block $4000-($-4000h),255
		endif
		
	endif
;
;
;
		output main_vars.tmp

	if DISTYPE=ROM
	
		org $E000

varbegin: equ $

score:		ds 6		; player's score  000000 .
hiscor:		ds 6		; high score  000000 .
bonus:		ds 6		; bonus  000000 .
displ0:		ds 4

	if EFLAG

sndtyp:		ds 1		; sound type. don't move!

	endif

	if PFLAG

shrplot:	ds 2

	endif

	if SFLAG
	
scrlyoff:	ds 1
	
	endif

	if MFLAG
	
mod0:	ds 3
mod1:	ds 3
mod2:	ds 3

	endif

	ifdef DATA00
rptr00:		ds 2
	endif
	ifdef DATA01
rptr01:		ds 2
	endif
	ifdef DATA02
rptr02:		ds 2
	endif
	ifdef DATA03
rptr03:		ds 2
	endif
	ifdef DATA04
rptr04:		ds 2
	endif
	ifdef DATA05
rptr05:		ds 2
	endif
	ifdef DATA06
rptr06:		ds 2
	endif
	ifdef DATA07
rptr07:		ds 2
	endif
	ifdef DATA08
rptr08:		ds 2
	endif
	ifdef DATA09
rptr09:		ds 2
	endif
	ifdef DATA10
rptr10:		ds 2
	endif
	ifdef DATA11
rptr11:		ds 2
	endif
	ifdef DATA12
rptr12:		ds 2
	endif
	ifdef DATA13
rptr13:		ds 2
	endif
	ifdef DATA14
rptr14:		ds 2
	endif
	ifdef DATA15
rptr15:		ds 2
	endif
	ifdef DATA16
rptr16:		ds 2
	endif
	ifdef DATA17
rptr17:		ds 2
	endif
ifdef DATA18
rptr18:		ds 2
	endif
	ifdef DATA19
rptr19:		ds 2
	endif
	ifdef DATA20
rptr20:		ds 2
	endif
	
	else			; RAM model variables	
		
		org endmain

varbegin: equ $

	endif
	
loopa:		ds 1			; loop counter system variable. (23681)
loopb:		ds 1			; loop counter system variable. (23728)
loopc:		ds 1			; loop counter system variable. (23729)	
vara:		ds 1			;   ds 1              general-purpose variable.
varb:		ds 1			;   ds 1              general-purpose variable.
varc:		ds 1			;   ds 1              general-purpose variable.
vard:		ds 1			;   ds 1              general-purpose variable.
vare:		ds 1			;   ds 1              general-purpose variable.
varf:		ds 1			;   ds 1              general-purpose variable.
varg:		ds 1			;   ds 1              general-purpose variable.
varh:		ds 1			;   ds 1              general-purpose variable.
vari:		ds 1			;   ds 1              general-purpose variable.
varj:		ds 1			;   ds 1              general-purpose variable.
vark:		ds 1			;   ds 1              general-purpose variable.
varl:		ds 1			;   ds 1              general-purpose variable.
varm:		ds 1			;   ds 1              general-purpose variable.
varn:		ds 1			;   ds 1              general-purpose variable.
varo:		ds 1			;   ds 1              general-purpose variable.
varp:		ds 1			;   ds 1              general-purpose variable.
varq:		ds 1			;   ds 1              general-purpose variable.
varr:		ds 1			;   ds 1              general-purpose variable.
vars:		ds 1			;   ds 1              general-purpose variable.
vart:		ds 1			;   ds 1              general-purpose variable.
varu:		ds 1			;   ds 1              general-purpose variable.
varv:		ds 1			;   ds 1              general-purpose variable.
varw:		ds 1			;   ds 1              general-purpose variable.
varz:		ds 1			;   ds 1              general-purpose variable.
contrl:		ds 1              ; control, 0 = keyboard, 1 = Kempston, 2 = Sinclair, 3 = Mouse.
charx:		ds 1              ; cursor y position.
chary:		ds 1              ; cursor x position.
colpat:		ds 1	
prtmod:		ds 1		; print mode, 0 = standard, 1 = double-height.	
clratt:		ds 1
	
; Scrolly text and puzzle variables.

	if SFLAG
txtbit:		ds 1			; db 128             bit to write.
txtwid:		ds 1			; db 16             width of ticker message.
txtpos:		ds 2			; dw msgdat
txtini:		ds 2			; dw msgdat
txtend:		ds 2			; dw 0
txtbeg:		ds 2			; dw 0
	endif

; beeper variable
	if EFLAG
snddelay:	ds 1
	endif
	
spptr:		ds 2			; spawned sprite pointer.
seed:		ds 1			; seed for random numbers.
grbase:		ds 2			; graphics base address.
joyval:		ds 1			; joystick reading.		
scno:		ds 1            ; present screen number.
ogptr:		ds 2            ; original sprite pointer.
nsprite:	ds 1
numlif:		ds 1            ; number of lives.
curobj:		ds 1
dirthig:	ds 2		
skptr:  	ds 2            ; search pointer.
highslot:	ds 1
roomtb:		ds 1 			; room number.

	if MFLAG
bwid:		ds 1            ; box/menu width.
blen:		ds 1            ; box/menu height.
btop:		ds 1            ; box coordinates.
blft:		ds 1
	endif
	
frmno:		ds 1            ; current game frame.
combyt:		ds 1			; byte type compressed.
comcnt: 	ds 1            ; compression counter.
seed3:		ds 1
nexlev:		ds 1			; db 0               next level flag.
restfl:		ds 1			; db 0               restart screen flag.
deadf:		ds 1			; db 0              dead flag.
gamwon:		ds 1			; db 0               game won flag.
dispx:		ds 1			; db 0              cursor y position.
dispy:		ds 1			; db 0              cursor x position.
varrnd:		ds 1			; db 255             last random number.
varobj:		ds 1			; db 254             last object number.
varopt:		ds 1			; db 255             last option chosen from menu.
varblk:		ds 1			; db 255             block type.
offset:		ds 1

varend:		equ $

	include "PT3-RAM.asm"
	include "ayFX-RAM.asm"

; Sprite table.
; ix+0  = type.
; ix+1  = sprite image number.
; ix+2  = frame.
; ix+3  = x coord.
; ix+4  = y coord.

; ix+5  = new type.
; ix+6  = new image number.
; ix+7  = new frame.
; ix+8  = new x coord.
; ix+9  = new y coord.

; ix+10 = direction.
; ix+11 = parameter 1.
; ix+12 = parameter 2.
; ix+13 = jump pointer low.
; ix+14 = jump pointer high.
; ix+15 = data pointer low.
; ix+16 = data pointer high.

sprtab:		ds SPRBUF	   
ssprit:		ds TABSIZ

colltab:	ds 15*4			; Support till 16 Y-aligned sprites.
sprptr:		ds 2
pblkptr:	ds 2
stack:		ds 2

	if DISTYPE=ROM

keys:		ds 22

	endif
	
; 2 bytes free for variables here (in ROM mode)

;
; aligned tables
;
; move wisely!
;
		ALIGN 256

MAP:		ds 768			; main attributes map. Stores tile attributes		
spratr:		ds 128			; full sprite attribute table. Cannot cross a 256 byte boundary
spratr2:	ds 128			; secondary sprite attribute table
	
	if OFLAG
objlist:	ds 256			; Objects list. Needs exact 256 alignment
	endif

scrmap:		ds 768			; Blocks map. Keeps tile codes

mapspr:		ds 128			; Sprite mapping list. Needs exact 256 alignment		

	if SFLAG
scrbuf:		ds 256+8
	endif
	
	if PFLAG
shraddr:	ds 2
SHRAPN:		ds NUMSHR*SHRSIZ
	endif
		
	if (OFLAG and DISTYPE=ROM)
objatr:		ds NUMOBJ*3
	endif
	
eop:		equ $

;
; Extra binary. Loaders for disk/tape versions
;

	if DISTYPE=DISK
	
		output loader.bin

		db $FE
		dw slots
		dw endslots-1
		dw slots

		org $F41F		

slots:  
		di
		call bakslots
		call enap1
		ld hl,$8080
		ld de,$4000
		ld bc,$4000
		ldir 
		call oldslots
		ei
		ret

run:
		di
		call enap1
		ei
		jp $4000
		
		; enable RAM page 1 as MAP points up
enap1: 
		ld a,(MSX_EXPTBL+3)
		ld b,a                 ;check if slot is expanded
		and a
		jp z,enaram2
		ld a,(MSX_SSSREG)           ;if so, read subslot value first
		cpl                        ;complement value
		and 11000000b
		rrca                       ;shift subslot bits to bits 2-3
		rrca
		rrca
		rrca
		or b
		ld b,a
enaram2: 
		in a,(MSX_RAMIO)             ;read slot value
		and 11000000b           ;shift slot bits to bits 0-1
		rlca
		rlca
		or b
		ld h,0x40               ;select slot
		jp MSX_ENASLT		
		
bakslots:
		in a,(MSX_RAMIO)
		ld (slta),a
		ld a,(MSX_SSSREG)
		cpl
		ld (sltb),a
		ret

oldslots:
		ld a,(sltb)
		ld (MSX_SSSREG),a
		ld a,(slta)
		out (MSX_RAMIO),a
		ret

endslots:	equ $
		
		output loader_vars.tmp

		org endslots
		
slta:	ds 1
sltb:	ds 1		

	endif
	
