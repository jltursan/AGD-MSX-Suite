		; --- ayFX REPLAYER v1.31 ---

		; --- v1.31	Fixed bug on previous version, only PSG channel C worked
		; --- v1.3	Fixed volume and Relative volume versions on the same file, conditional compilation
		; ---		Support for dynamic or fixed channel allocation
		; --- v1.2f/r	ayFX bank support
		; --- v1.11f/r	If a frame volume is zero then no AYREGS update
		; --- v1.1f/r	Fixed volume for all ayFX streams
		; --- v1.1	Explicit priority (as suggested by AR)
		; --- v1.0f	Bug fixed (error when using noise)
		; --- v1.0	Initial release

		; --- DEFINE AYFXRELATIVE AS 0 FOR FIXED VOLUME VERSION ---
		; --- DEFINE AYFXRELATIVE AS 1 FOR RELATIVE VOLUME VERSION ---
		if XFLAG

;
; WARNING: This routine must always exist
; Setups the SFX playing routine (if needed)
;					
sfx_init:
		ld hl,sfxbank
		call ayFX_SETUP
		jp mixeroff

;
; WARNING: This routine must always exist
; Stops & mute a SFX playing
;					
sfx_mute:
		ld	a,255				; Lowest ayFX priority		
		ld	[ayFX_PRIORITY],a		; Priority saved (not playing ayFX stream)		
		ld hl,AYREGS
		ld a,(ayFX_CHANNEL)
		inc a
		and 3
		add a,8
		add a,l
		ld l,a
		adc a,h
		sub l
		ld h,a			; y * 32 + x		
		ld (hl),0
		ret

;
; WARNING: This routine must always exist
; Initialize a SFX for playing
;			
sfx_set:
		ld c,0
		jp ayFX_INIT

;
; WARNING: This routine must always exist
; Plays a frame of an ayFX stream. To be called from interrupt
;			
sfx_play:
		jp ayFX_PLAY
		
;
; core routines
;
ayFX_SETUP:	; ---          ayFX replayer setup          ---
		; --- INPUT: HL -> pointer to the ayFX bank ---
		ld	[ayFX_BANK],hl			; Current ayFX bank
		xor	a				; a:=0
		ld	[ayFX_MODE],a			; Initial mode: fixed channel
		inc	a				; Starting channel (=1)
		ld	[ayFX_CHANNEL],a		; Updated
ayFX_END:	; --- End of an ayFX stream ---
		jp sfx_mute

ayFX_INIT:	; ---     INIT A NEW ayFX STREAM     ---
		; --- INPUT: A -> sound to be played ---
		; ---        C -> sound priority     ---
		push	bc				; Store bc in stack
		push	de				; Store de in stack
		push	hl				; Store hl in stack
		; --- Check if the index is in the bank ---
		ld	b,a				; b:=a (new ayFX stream index)
		ld	hl,[ayFX_BANK]			; Current ayFX BANK
		ld	a,[hl]				; Number of samples in the bank
		or	a				; If zero (means 256 samples)...
		jr	z,.CHECK_PRI			; ...goto .CHECK_PRI
		; The bank has less than 256 samples
		ld	a,b				; a:=b (new ayFX stream index)
		cp	[hl]				; If new index is not in the bank...
		ld	a,2				; a:=2 (error 2: Sample not in the bank)
		jr	nc,.INIT_END			; ...we can't init it
.CHECK_PRI:	; --- Check if the new priority is lower than the current one ---
		; ---   Remember: 0 = highest priority, 15 = lowest priority  ---
		ld	a,b				; a:=b (new ayFX stream index)
		ld	a,[ayFX_PRIORITY]		; a:=Current ayFX stream priority
		cp	c				; If new ayFX stream priority is lower than current one...
		ld	a,1				; a:=1 (error 1: A sample with higher priority is being played)
		jr	c,.INIT_END			; ...we don't start the new ayFX stream
		; --- Set new priority ---
		ld	a,c				; a:=New priority
		and	$0F				; We mask the priority
		ld	[ayFX_PRIORITY],a		; new ayFX stream priority saved in RAM

 	if AYFXRELATIVE			   
		; --- Volume adjust using PT3 volume table ---
		ld	c,a				; c:=New priority (fixed)
		ld	a,15				; a:=15
		sub	c				; a:=15-New priority = relative volume
		jr	z,.INIT_NOSOUND		; If priority is 15 -> no sound output (volume is zero)
		add	a,a				; a:=a*2
		add	a,a				; a:=a*4
		add	a,a				; a:=a*8
		add	a,a				; a:=a*16
		ld	e,a				; e:=a
		ld	d,0				; de:=a
		ld	hl,VT_				; hl:=PT3 volume table
		add	hl,de				; hl is a pointer to the relative volume table
		ld	[ayFX_VT],hl			; Save pointer
	endif

		; --- Calculate the pointer to the new ayFX stream ---
		ld	de,[ayFX_BANK]			; de:=Current ayFX bank
		inc	de				; de points to the increments table of the bank
		ld	l,b				; l:=b (new ayFX stream index)
		ld	h,0				; hl:=b (new ayFX stream index)
		add	hl,hl				; hl:=hl*2
		add	hl,de				; hl:=hl+de (hl points to the correct increment)
		ld	e,[hl]				; e:=lower byte of the increment
		inc	hl				; hl points to the higher byte of the correct increment
		ld	d,[hl]				; de:=increment
		add	hl,de				; hl:=hl+de (hl points to the new ayFX stream)		
		ld	[ayFX_POINTER],hl		; Pointer saved in RAM
		xor	a				; a:=0 (no errors)
.INIT_END:	pop	hl				; Retrieve hl from stack
		pop	de				; Retrieve de from stack
		pop	bc				; Retrieve bc from stack
		ret					; Return

 	if AYFXRELATIVE			   
.INIT_NOSOUND:	; --- Init a sample with relative volume zero -> no sound output ---
		ld	a,255				; Lowest ayFX priority
		ld	[ayFX_PRIORITY],a		; Priority saved (not playing ayFX stream)
		jr	.INIT_END			; Jumps to .INIT_END
	endif

ayFX_PLAY:	; --- PLAY A FRAME OF AN ayFX STREAM ---
		ld	a,[ayFX_PRIORITY]		; a:=Current ayFX stream priority
		or	a				; If priority has bit 7 on...
		ret	m				; ...return
		; --- Calculate next ayFX channel (if needed) ---
		ld	a,[ayFX_MODE]			; ayFX mode
		and	1				; If bit0=0 (fixed channel)...
		jr	z,.TAKECB			; ...skip channel changing
		ld	hl,ayFX_CHANNEL			; Old ayFX playing channel
		dec	[hl]				; New ayFX playing channel
		jr	nz,.TAKECB			; If not zero jump to .TAKECB
		ld	[hl],3				; If zero -> set channel 3
.TAKECB:	; --- Extract control byte from stream ---
		ld	hl,[ayFX_POINTER]		; Pointer to the current ayFX stream
		ld	c,[hl]				; c:=Control byte
		inc	hl				; Increment pointer
		; --- Check if there's new tone on stream ---
		bit	5,c				; If bit 5 c is off...
		jr	z,.CHECK_NN			; ...jump to .CHECK_NN (no new tone)
		; --- Extract new tone from stream ---
		ld	e,[hl]				; e:=lower byte of new tone
		inc	hl				; Increment pointer
		ld	d,[hl]				; d:=higher byte of new tone
		inc	hl				; Increment pointer
		ld	[ayFX_TONE],de			; ayFX tone updated
.CHECK_NN:	; --- Check if there's new noise on stream ---
		bit	6,c				; if bit 6 c is off...
		jr	z,.SETPOINTER			; ...jump to .SETPOINTER (no new noise)
		; --- Extract new noise from stream ---
		ld	a,[hl]				; a:=New noise
		inc	hl				; Increment pointer
		cp	$20				; If it's an illegal value of noise (used to mark end of stream)...
		jp	z,ayFX_END			; ...jump to ayFX_END
		ld	[ayFX_NOISE],a			; ayFX noise updated
.SETPOINTER:	; --- Update ayFX pointer ---
		ld	[ayFX_POINTER],hl		; Update ayFX stream pointer
		; --- Extract volume ---
		ld	a,c				; a:=Control byte
		and	$0F				; lower nibble

 	if AYFXRELATIVE
		; --- Fix the volume using PT3 Volume Table ---
		ld	hl,[ayFX_VT]			; hl:=Pointer to relative volume table
		ld	e,a				; e:=a (ayFX volume)
		ld	d,0				; d:=0
		add	hl,de				; hl:=hl+de (hl points to the relative volume of this frame
		ld	a,[hl]				; a:=ayFX relative volume
		or	a				; If relative volume is zero...
	endif

		ld	[ayFX_VOLUME],a			; ayFX volume updated
		ret	z				; ...return (don't copy ayFX values in to AYREGS)
		; -------------------------------------
		; --- COPY ayFX VALUES IN TO AYREGS ---
		; -------------------------------------
		; --- Set noise channel ---
		bit	7,c				; If noise is off...
		jr	nz,.SETMASKS			; ...jump to .SETMASKS
		ld	a,[ayFX_NOISE]			; ayFX noise value
		ld	[AYREGS+6],a			; copied in to AYREGS (noise channel)
.SETMASKS:	; --- Set mixer masks ---
		ld	a,c				; a:=Control byte
		and	$90				; Only bits 7 and 4 (noise and tone mask for psg reg 7)
		cp	$90				; If no noise and no tone...
		ret	z				; ...return (don't copy ayFX values in to AYREGS)
		; --- Copy ayFX values in to ARYREGS ---
		rrca					; Rotate a to the right (1 TIME)
		rrca					; Rotate a to the right (2 TIMES) (OR mask)
		ld	d,$DB				; d:=Mask for psg mixer (AND mask)
		; --- Dump to correct channel ---
		ld	hl,ayFX_CHANNEL			; Next ayFX playing channel
		ld	b,[hl]				; Channel counter
.CHK1:		; --- Check if playing channel was 1 ---
		djnz	.CHK2				; Decrement and jump if channel was not 1
.PLAY_C:	; --- Play ayFX stream on channel C ---
		call	.SETMIXER			; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
		ld	[AYREGS+10],a			; Volume copied in to AYREGS (channel C volume)
		bit	2,c				; If tone is off...
		ret	nz				; ...return
		ld	[AYREGS+4],hl			; copied in to AYREGS (channel C tone)
		ret					; Return
.CHK2:		; --- Check if playing channel was 2 ---
		rrc	d				; Rotate right AND mask
		rrca					; Rotate right OR mask
		djnz	.CHK3				; Decrement and jump if channel was not 2
.PLAY_B:	; --- Play ayFX stream on channel B ---
		call .SETMIXER			; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
		ld	[AYREGS+9],a			; Volume copied in to AYREGS (channel B volume)
		bit	1,c				; If tone is off...
		ret	nz				; ...return
		ld [AYREGS+2],hl			; copied in to AYREGS (channel B tone)
		ret					; Return
.CHK3:		; --- Check if playing channel was 3 ---
		rrc	d				; Rotate right AND mask
		rrca					; Rotate right OR mask
.PLAY_A:	; --- Play ayFX stream on channel A ---
		call .SETMIXER			; Set PSG mixer value (returning a=ayFX volume and hl=ayFX tone)
		ld	[AYREGS+8],a			; Volume copied in to AYREGS (channel A volume)
		bit	0,c				; If tone is off...
		ret	nz				; ...return
		ld	[AYREGS+0],hl			; copied in to AYREGS (channel A tone)
		ret					; Return
.SETMIXER:	; --- Set PSG mixer value ---
		ld	c,a				; c:=OR mask
		ld	a,[AYREGS+7]			; a:=PSG mixer value
		and	d				; AND mask
		or	c				; OR mask
		ld	[AYREGS+7],a			; PSG mixer value updated
		ld	a,[ayFX_VOLUME]			; a:=ayFX volume value
		ld	hl,[ayFX_TONE]			; ayFX tone value
		ret					; Return


	if ( YFLAG = 0 )	

	; If there's no PSG player we need to provide these routines
mixeroff:
		xor a
		ld h,a
		ld l,a
		ld (AYREGS+AR_AmplA),a
		ld (AYREGS+AR_AmplB),hl
		jp psgrout

psgrout:
		xor a 
		ld hl,AYREGS+AR_Mixer
		set 7,(hl)
		res 6,(hl)
		ld c,MSX_PSGDW
		ld hl,AYREGS
.sfxloop:
		out (MSX_PSGLW),a
		inc a
		outi
		cp 13
		jr nz,.sfxloop	
		ret
	;
	
	if AYFXRELATIVE

		; --- UNCOMMENT THIS BLOCK if YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---
VT_:	db 000h,000h,000h,000h,000h,000h,000h,000h,001h,001h,001h,001h,001h,001h,001h,001h
		db 000h,000h,000h,000h,001h,001h,001h,001h,001h,001h,001h,001h,002h,002h,002h,002h
		db 000h,000h,000h,001h,001h,001h,001h,001h,002h,002h,002h,002h,002h,003h,003h,003h
		db 000h,000h,001h,001h,001h,001h,002h,002h,002h,002h,003h,003h,003h,003h,004h,004h
		db 000h,000h,001h,001h,001h,002h,002h,002h,003h,003h,003h,004h,004h,004h,005h,005h
		db 000h,000h,001h,001h,002h,002h,002h,003h,003h,004h,004h,004h,005h,005h,006h,006h
		db 000h,000h,001h,001h,002h,002h,003h,003h,004h,004h,005h,005h,006h,006h,007h,007h
		db 000h,001h,001h,002h,002h,003h,003h,004h,004h,005h,005h,006h,006h,007h,007h,008h
		db 000h,001h,001h,002h,002h,003h,004h,004h,005h,005h,006h,007h,007h,008h,008h,009h
		db 000h,001h,001h,002h,003h,003h,004h,005h,005h,006h,007h,007h,008h,009h,009h,00Ah
		db 000h,001h,001h,002h,003h,004h,004h,005h,006h,007h,007h,008h,009h,00Ah,00Ah,00Bh
		db 000h,001h,002h,002h,003h,004h,005h,006h,006h,007h,008h,009h,00Ah,00Ah,00Bh,00Ch
		db 000h,001h,002h,003h,003h,004h,005h,006h,007h,008h,009h,00Ah,00Ah,00Bh,00Ch,00Dh
		db 000h,001h,002h,003h,004h,005h,006h,007h,007h,008h,009h,00Ah,00Bh,00Ch,00Dh,00Eh
		db 000h,001h,002h,003h,004h,005h,006h,007h,008h,009h,00Ah,00Bh,00Ch,00Dh,00Eh,00Fh 
		; --- UNCOMMENT THIS if YOU DON'T USE THIS REPLAYER WITH PT3 REPLAYER ---

	endif
	
	endif

	endif
		