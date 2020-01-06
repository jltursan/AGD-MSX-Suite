		; --- ayFX REPLAYER v1.31 ---

		; --- THIS FILE MUST BE COMPILED IN RAM ---
	if XFLAG
	
ayFX_MODE:		ds 1			; ayFX mode
ayFX_BANK:		ds 2			; Current ayFX Bank
ayFX_PRIORITY:	ds 1			; Current ayFX stream priotity
ayFX_POINTER:	ds 2			; Pointer to the current ayFX stream
ayFX_TONE:		ds 2			; Current tone of the ayFX stream
ayFX_NOISE:		ds 1			; Current noise of the ayFX stream
ayFX_VOLUME:	ds 1			; Current volume of the ayFX stream
ayFX_CHANNEL:	ds 1			; PSG channel to play the ayFX stream

 	if AYFXRELATIVE

ayFX_VT:		ds 2			; ayFX relative volume table pointer

	endif

	if ( YFLAG = 0 )	
		
AYREGS:			ds 14

	endif
	
	endif
