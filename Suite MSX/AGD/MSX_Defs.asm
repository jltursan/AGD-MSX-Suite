; All MSX 1 BIOS calls ===========================================
	if (DISSIZE!=48)

MSX_CHKRAM	equ $0000
MSX_CHRGTR	equ $0010
MSX_WRSLT	equ $0014
MSX_OUTDO	equ $0018
MSX_DCOMPR	equ $0020
MSX_GETYPR	equ $0028
MSX_CALLF	equ $0030
MSX_KEYINT	equ $0038
MSX_INITIO	equ $003B
MSX_INIFNK	equ $003E
MSX_CHGMOD	equ $005F
MSX_CHGCLR	equ $0062
MSX_NMI		equ $0066
MSX_CLRSPR	equ $0069
MSX_INITXT	equ $006C
MSX_INIT32	equ $006F
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
MSX_POSIT	equ $00C6
MSX_FNKSB	equ $00C9
MSX_ERAFNK	equ $00CC
MSX_DSPFNK	equ $00CF
MSX_TOTEXT	equ $00D2
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
MSX_WSLREG	equ $013B
MSX_RDVDP	equ $013E
MSX_PHYDIO	equ $0144
MSX_FORMAT	equ $0147
MSX_ISFLIO	equ $014A
MSX_OUTDLP	equ $014D
MSX_GETVCP	equ $0150
MSX_GETVC2	equ $0153
MSX_KILBUF	equ $0156
MSX_CALBAS	equ $0159
	
	endif

MSX_RDSLT	equ $000C
MSX_CALSLT	equ $001C
MSX_RSLREG	equ $0138

; --- end of all MSX 1 BIOS calls ---
; BIOS routine - Turbo-R computers only!
MSX_CHGCPU	equ $0180

; Diskrom motor off entry point
MSX_MTOFF	equ	$4029

; VRAM addresses =================================================

MSX_CHRTBL	equ $0000 ; (GRPCGP)
MSX_NAMTBL	equ $1800 ; (GRPNAM)
MSX_CLRTBL	equ $2000 ; (GRPCOL)
MSX_SPRTBL	equ $3800 ; (GRPPAT)
MSX_SPRATR	equ $1B00 ; (GRPATR)

; BIOS constants =================================================
MSX_VDPPRT	equ	$0007	; VDP port 0
MSX_MSXVER	equ $002D

; System variables addresses =====================================
MSX_MSLOT	equ	$F348
MSX_GRPNAM  equ $F3C7
MSX_GRPCOL  equ $F3C9
MSX_GRPCGP  equ $F3CB
MSX_GRPATR  equ $F3CD
MSX_GRPPAT  equ $F3CF
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
MSX_RG8SAV	equ	$FFE7	; Mirror of VDP register 9 (Basic: VDP(9))
MSX_RG9SAV	equ	$FFE8	; Mirror of VDP register 9 (Basic: VDP(9))
MSX_STATFL	equ	$F3E7 	; 	Mirror of VDP(8) status register (S#0)
MSX_SCNCNT  equ $F3F6
MSX_REPCNT  equ $F3F7
MSX_FNKSTR	equ	$F87F	; Ubicacion textos teclas funcion (se reaprovecha como RAM, 160 bytes)
MSX_NEWKEY	equ	$FBE5
MSX_HIMEM	equ $FC4A	; Highest available RAM
MSX_JIFFY	equ	$FC9E
MSX_INTCNT  equ $FCA2
MSX_EXPTBL	equ	$FCC1	; Bios Slot / Expansion Slot	
MSX_SLTTBL	equ	$FCC5
MSX_HKEYI	equ $FD9A	 
MSX_HTIMI   equ $FD9F
MSX_SSSREG	equ $FFFF	; secondary slot select register

; ================================================================

; Maximum stack address
MSX_STACK	equ $F380

; I/O PORTS ================================================================
MSX_DEVID	equ	$40
MSX_SWTIO	equ $41

; PSG PORTS
MSX_PSGLW	equ $A0 ;A0H    latch address for PSG
MSX_PSGDW	equ $A1 ;A1H    write data to PSG
MSX_PSGDR	equ $A2 ;A2H    read data from PSG
;
MSX_PSGPA	equ 14  ;Port A of PSG
MSX_PSGPB	equ 15  ;Port B of PSG


; VDP PORTS
MSX_VDPDRW	equ	$98	;98H    Read/write data VDP
MSX_VDPCW	equ	$99	;99H    write command to VDP
MSX_VDPSR	equ	$99	;99H    read status from VDP
MSX_VDPPAL	equ	$9B     ; palette register (only MSX2)

; PPI / Programmable Peripheral Interface / 8255 I/O ports
MSX_PPIA	equ $A8 ; PPI- register A. Primary slot select register
MSX_PPIB	equ $A9 ; PPI- register B. Keyboard matrix row input register (read only)
MSX_PPIC	equ $AA ; PPI- register C. Keyboard and cassette interface
MSX_PPICM	equ $AB ; PPI- Command register (write only)

MSX_MMAP0	equ	$FC
MSX_MMAP1	equ	$FD
MSX_MMAP2	equ	$FE
MSX_MMAP3	equ	$FF

; ================================================================

; Disable sprites magic numbers
MSX_HIDE_SPRITES	equ	208
MSX_HIDE_SPRITE		equ	209

; clock variable
clock	equ MSX_JIFFY

; Replaced BIOS calls

	ifdef NOBIOS

		include "MSX_BIOS.asm"
		
MSX_SNSMAT	equ BIOS_SNSMAT  
MSX_INIGRP	equ	BIOS_INIGRP  
MSX_ENASCR	equ	BIOS_ENASCR  
MSX_DISSCR	equ	BIOS_DISSCR  
MSX_WRTVDP	equ	BIOS_WRTVDP
MSX_SETRD	equ	BIOS_SETRD
MSX_SETWRT	equ	BIOS_SETWRT
MSX_WRTVRM	equ	BIOS_WRTVRM 
MSX_RDVRM	equ	BIOS_RDVRM
MSX_LDIRMV	equ	BIOS_LDIRMV
MSX_LDIRVM	equ	BIOS_LDIRVM
MSX_CLS		equ	BIOS_CLS
MSX_FILVRM	equ	BIOS_FILVRM
MSX_ENASLT	equ	BIOS_ENASLT
MSX_GTSTCK	equ	BIOS_GTSTCK
MSX_GTTRIG	equ	BIOS_GTTRIG

	else

MSX_ENASLT	equ	$0024
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
MSX_INIGRP	equ $0072
MSX_CLS		equ $00C3
MSX_GTSTCK	equ $00D5
MSX_GTTRIG	equ $00D8
MSX_SNSMAT	equ $0141
		
	endif

