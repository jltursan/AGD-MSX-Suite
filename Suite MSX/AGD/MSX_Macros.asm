; MSX MACROS

	macro BORDER clr
		push af
        ld a,clr             ;Get data to set
        di
        out (MSX_VDPCW),a
        ld a,$87             ;Set register #
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
		or $40
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

	/*
	macro HALT1
		ld hl,clock         ; previous clock setting.		
		inc (hl)
.wait:
		ld a,(MSX_JIFFY)        ; current clock setting.
		cp (hl)             ; subtract last reading.
		jp z,.wait        ; yes, no more processing please.
		ld (hl),a
	endmacro 
	*/

	macro WAITFRAME
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
		add a,l			; 5
		ld l,a			; 5
		adc a,h			; 5
		sub l			; 5
		ld h,a			; 5
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
	