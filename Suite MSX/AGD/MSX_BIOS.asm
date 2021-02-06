bios_start:

BIOS_SNSMAT:  
		ld c,a
        di
        in a,(MSX_PPIC)
        and $F0
        add a,c
        out (MSX_PPIC),a
        in a,(MSX_PPIB)
        ei
        ret
		
BIOS_INIGRP:  
		call BIOS_DISSCR		; DISSCR
        ld hl,MSX_NAMTBL
        call BIOS_SETWRT		; SETWRT
        xor a
        ld b,3
.nxtblk:  
		out ($98),a
        inc a
        jr nz,.nxtblk
        djnz .nxtblk			; erases patterns name table		
        call BIOS_CLS			; erases screen with BAKCLR
        call vdpinit			; set VDP registers
		; falls through ENASCR
		
BIOS_ENASCR:
		ld a,(MSX_RG1SAV)	; ENASCR
        or $40
        jr wrtreg1

BIOS_DISSCR:
		ld a,(MSX_RG1SAV)	; DISSCR
        and $BF
wrtreg1:  
		ld b,a
        ld c,1
		; falls through WRTVDP

BIOS_WRTVDP:  
		ld a,b				; data
        di
        out (MSX_VDPCW),a
        ld a,c				; register
        or $80
        out (MSX_VDPCW),a
        ei
        push hl		
        ld hl,MSX_RG0SAV
		ld a,c
		cp 8
		jr c,.msx1
        ld hl,MSX_RG8SAV-8
.msx1:
		add a,l			
		ld l,a			
		adc a,h			
		sub l			
		ld h,a			
		ld (hl),b
		pop hl
        ret

BIOS_SETRD:
		ld a,l
		di
		out (MSX_VDPCW),a
		ld a,h
		and $3F
		out (MSX_VDPCW),a
		ei
        ret	
		
BIOS_SETWRT:
		ld a,l
		di
		out (MSX_VDPCW),a
		ld a,h
		or $40
		out (MSX_VDPCW),a
		ei		
        ret	
			
BIOS_WRTVRM:  
		push af
        call BIOS_SETWRT
        pop af
        out (MSX_VDPDRW),a
        ret
		
BIOS_RDVRM:
		call BIOS_SETRD
        in a,(MSX_VDPDRW)
        ret
		
BIOS_CHBDCLR:  
		ld a,(MSX_BDRCLR)
		ld b,a
        ld c,7
        jp BIOS_WRTVDP	
	
BIOS_LDIRMV:
		call BIOS_SETRD
		ex de,hl
.nxtbyte:  
		in a,(MSX_VDPDRW)
        ld (hl),a
		cpi
        jp pe,.nxtbyte
		ex de,hl
        ret		

BIOS_LDIRVM:
		ex de,hl
		call BIOS_SETWRT
		ex de,hl
.nxtbyte:
		ld a,(hl)
		out (MSX_VDPDRW),a
		cpi
        jp pe,.nxtbyte
        ret		
		
BIOS_CLS:  
		call BIOS_CHBDCLR		; change border colour       
		ld bc,256/8*192
        push bc
        ld hl,MSX_CLRTBL
        ld a,(MSX_BAKCLR)
        call BIOS_FILVRM		; FILVRM (fills with BAKCLR $2000-$37FF)		
        ld hl,MSX_CHRTBL
        pop bc
        xor a
		
		; HL = start
		; BC = length
		; A = fill value
BIOS_FILVRM:
		push af
        call BIOS_SETWRT
		pop af
.loopfill:  
        out (MSX_VDPDRW),a
		cpi
        jp pe,.loopfill
        ret	

vdpinit:  
		ld a,(MSX_RG0SAV)		;SETGRP
        or 2
        ld b,a
        ld c,0
        call BIOS_WRTVDP		; WRTVDP
        ld a,(MSX_RG1SAV)
        and $E7
        ld b,a
        inc c
        call BIOS_WRTVDP		; WRTVDP
        ld hl,MSX_GRPNAM
        ld de,$7F03
		; initialize VDP registers 2,3,4,5,6
		ld bc,$0602		
        call .wrtzero
        ld b,$0A
        ld a,d
        call .wrtpair
        ld b,$05
        ld a,e
        call .wrtpair
        ld b,$09
        call .wrtzero
        ld b,$05
.wrtzero:  
		xor a
.wrtpair:
		push hl
        push af
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
        xor a
.shift:  
		add hl,hl
        adc a,a
        djnz .shift
        ld l,a
        pop af
        or l
        ld b,a
        call BIOS_WRTVDP		; WRTVDP
        pop hl
        inc hl
        inc hl
        inc c
        ret
		
;
; ------------------------------ ENASLT ------------------------------
;
; Selects the appropriate slot according to the value given
; through registers, and permanently enables the slot.
;
; Input parameters:
;
; A  - FxxxSSPP
;      |   ||||
;      |   ||++-- primary slot # (0-3)
;      |   ++---- secondary slot # (0-3)
;      +--------- 1 if secondary slot # specified
;
; HL - address of target memory
;
; Note: Interrupts are disabled automatically but never enabled
;       by this routine.
;
BIOS_ENASLT:
        call    selprm          ;calculate bit pattern and mask code
        jp      m,eneslt        ;expanded slot specified
        in      a,(MSX_PPIA)
        and     c               ;cancel current setting for target address
        or      b               ;add new setting
        out     (MSX_PPIA),a
        ret
eneslt:
        push    hl              ;save target address
        call    selexp          ;select secondary slot
        ld      c,a             ;move primary slot # to [bc]
        ld      b,0
        ld      a,l             ;re-calculate what is currently output
        and     h               ;to expansion slot register
        or      d
        ld      hl,MSX_SLTTBL       ;calculate address into slttbl
        add     hl,bc
        ld      (hl),a          ;set current value output to expansion slot register
        pop     hl              ;restore target address
        ld      a,c             ;restore primary slot # to [acc]
        jr      BIOS_ENASLT          ;enable by primary slot register
selprm:
        di
        push    af              ;save slot address
        ld      a,h             ;extract upper 2 bits
        rlca
        rlca
        and     00000011b
        ld      e,a
        ld      a,0c0h          ;format mask pat, correspond to address
slprm1:
        rlca
        rlca
        dec     e
        jp      p,slprm1
		;save mask pattern
        ;       00000011    0000-3fff             
        ;       00001100    4000-7fff                        
        ;       00110000    8000-bfff                        
        ;       11000000    c000-ffff                        
        ld      e,a                        
        cpl
		;save mask pattern
        ;       11111100    0000-3fff             
        ;       11110011    4000-7fff                        
        ;       11001111    8000-bfff                        
        ;       00111111    c000-ffff                        
        ld      c,a                       
        pop     af              ;restore slot address
        push    af
        and     00000011b       ;extract primary slot #
        inc     a
        ld      b,a
        ld      a,10101011b     ;convert slot # to proper bit pattern
slprm2:
        add     a,01010101b
        djnz    slprm2
		;save bit pattern for primary slot #
		;       00000000    slot #0
		;       01010101    slot #1
		;       10101010    slot #2
		;       11111111    slot #3
        ld      d,a             
        and     e               ;extract significant bits
        ld      b,a             ;set it to [b]
        pop     af              ;expanded slot specified?
        and     a               ;set sign flag if so
        ret
selexp:
        push    af              ;save target slot
        ld      a,d             ;get bit pattern for primary slot
        and     1000000b        ;extract slot # for 0c000h..0ffffh
        ld      c,a             ;save it
        pop     af              ;restore target slot
        push    af              ;save target slot
        ld      d,a             ;load [d] with specified slot address
        in      a,(MSX_PPIA)
        ld      b,a             ;save current setting
        and     00111111b       ;cancel current setting for 0c000h..0ffffh
        or      c
        out     (MSX_PPIA),a      ;enable 0c000h..0ffffh or target bank
        ld      a,d             ;load slot information
        rrca
        rrca
        and     00000011b       ;extract secondary slot #
        ld      d,a
        ld      a,10101011b     ;convert secondary slot # to proper
slexp1:
        add     a,01010101b     ;bit pattern
        dec     d
		;       00000000    slot #0
		;       01010101    slot #1
		;       10101010    slot #2
		;       11111111    slot #3
        jp      p,slexp1        
        and     e               ;make bit pattern to be added
        ld      d,a             ;save this
        ld      a,e             ;make bit pattern to strip off old value
        cpl
        ld      h,a             ;save this
        ld  a,(MSX_SSSREG)          ;read expanded slot register
        cpl
        ld      l,a             ;save current setting
        and     h               ;strip off old bits
        or      d               ;and set new bits
        ld      (MSX_SSSREG),a      ;set secondary slot register
        ld      a,b
        out     (MSX_PPIA),a      ;restore original primary port
        pop     af              ;restore target slot
        and     00000011b       ;fake read from primary slot
        ret	

BIOS_GTSTCK:
;
        dec     a
        jp      m,kystck        ;stick(0) - read cursor keys
        call    slstck          ;read joystick
        ld      hl,stktbl
stick1:
        and     $0f
        ld      e,a
        ld      d,0
        add     hl,de
        ld      a,(hl)
        ret
kystck:
;
        call    gtrow8          ;read keyboard
        rrca                    ;move cursor status to lower four bits
        rrca
        rrca
        rrca
        ld      hl,kstktb
        jr      stick1
		

BIOS_GTTRIG:
;
        dec     a
        jp      m,keytrg        ;strig(0), use keyboard
        push    af
        and     1
        call    slstck          ;read joystick
        pop     bc
        dec     b
        dec     b
        ld      b,$10           ;prepare mask pattern for trigger a
        jp      m,trig1
        ld      b,' '           ;prepare mask pattern for trigger b
trig1:
        and     b               ;extract trigger status
trig2:
        sub     1               ;return 255 if [acc]=0, 0 if non-0
        sbc     a,a
        ret
keytrg:
;
        call    gtrow8          ;read keyboard
        and     1               ;extract space status
        jr      trig2
		
slstck:
;
; select proper joystick and read from it
;
        ld      b,a
        ld      a,MSX_PSGPB
        di
        call    rdpsg           ;read what is currently output to port b
        djnz    slstc1          ;stick(1)
        and     $df            ;make sure p8 is low state
        or      $4c             ;select joystick 2, enable p6,p7
        jr      slstc2
slstc1:
;
        and     $af            ;select joystick 1, make sure p8 is low state
        or      3               ;enable p6,p7
slstc2:
        out     (MSX_PSGDW),a
        call    ingi            ;read status of joystick port
        ei
        ret
		
ingi:
;
; input data from pad
;
        ld      a,MSX_PSGPA
rdpsg:
        out     (MSX_PSGLW),a
        in      a,(MSX_PSGDR)
        ret
		
gtrow8:
;
; get keyboard's 8th row, bit assignments are as follows.
;
; rdulxxxs
; ||||   |
; ||||   +- space
; |||+----- left
; ||+------ up
; |+------- down
; +-------- right
;
        di
        in      a,(MSX_PPIC)
        and     $f0
        add     a,8
        out     (MSX_PPIC),a
        in      a,(MSX_PPIB)
        ei
        ret

stktbl:
        db      0               ;rlbf
        db      5               ;rlb
        db      1               ;rl f
        db      0               ;rl
        db      3               ;r bf
        db      4               ;r b
        db      2               ;r f
        db      3               ;r
        db      7               ; lbf
        db      6               ; lb
        db      8               ; l f
        db      7               ; l
        db      0               ; bf
        db      5               ; b
        db      1               ;  f
        db      0               ;
;
kstktb:
        db      0               ;rbfl,
        db      3               ;rbf
        db      5               ;rb l
        db      4               ;rb
        db      1               ;r fl
        db      2               ;r f
        db      0               ;r l
        db      3               ;r
        db      7               ;  bfl
        db      0               ; bf
        db      6               ; b l
        db      5               ; b
        db      8               ; fl
        db      1               ; f
        db      7               ;  l
        db      0               ;
		
bios_end:
