@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set WD=%cd%

set AGDPATH=%WD%\AGD
set SOURCES=%WD%\AGDsources
set TOOLSPATH=%WD%\tools
set ASMPATH=%WD%\sjasm
set MEDIAPATH=%WD%\resources

set WRDSK=%TOOLSPATH%\wrdsk.exe
set ASM=%ASMPATH%\sjasm.exe
set COMPILER=%AGDPATH%\CompilerMSX.exe
set EMU=openmsx.exe
set BUILD=%0

if "%MSXEMUPATH%"=="" (
	if exist "%WD%\openmsx\%EMU%" (
		echo OpenMSX home directory set to default...
		set MSXEMUPATH=%WD%\openmsx
	) else (
		echo Warning: No OpenMSX emulator found, you can't run the compiled programs
	)
)

SET "HEXA=0123456789ABCDEF"

REM HIMEM=E100 (MSX 64KB with at least 1 drive)
REM How much bytes fit in RAM without switching pages (aprox. HIMEM-$80-$8080-$DAC)
set SZLIMIT=24576
REM (aprox. (HIMEM-$80-$8000-$DAC)+$4000)
set MAXRAM=41088

set NAME=
set MACHINE=
set DIST=

REM MANUAL FLAGS 
set AFLAG=
set BFLAG=
set CFLAG=
set DFLAG=
set KFLAG=
set QFLAG=
set TFLAG=

:getopt
set OPT=%~1
if "%OPT%"=="" (
	goto endopt
) else if not "%OPT:~0,1%"=="-" (
	set NAME=%OPT%
) else if "%OPT%"=="-?" (
	goto help
) else if "%OPT%"=="-h" (
	goto help
) else if "%OPT%"=="-a" (
	set AFLAG= -a
) else if "%OPT%"=="-c" (
	if NOT "%DFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -c ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	if NOT "%QFLAG%%TFLAG%"=="" (
		echo Error: ROM cartridge distribution is not compatible with Marquee or Title options^^!
		goto :eof
	)
	set DIST=ROM
	if "%2"=="16" (
		set MEMORY=16
	) else if "%2"=="32" (
		set MEMORY=32
	) else (
		echo Setting default mode to ROM cartridge with 32K...
		set MEMORY=32
		set CFLAG=-c !MEMORY!
		goto next
	)
	set CFLAG=-c !MEMORY!
	shift
) else if "%OPT%"=="-d" (
	if NOT "%CFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -c ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	set DIST=RAM
	if "%2"=="32" (
		set MEMORY=32
	) else if "%2"=="48" (
		set MEMORY=48
	) else (
		echo Setting default mode to RAM, disk and 32K...
		set MEMORY=32
		set DFLAG=-d !MEMORY!
		goto next
	)
	set DFLAG=-d !MEMORY!
	shift
) else if "%OPT%"=="-k" (
	if NOT "%CFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -c ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	set DIST=RAM
	if "%2"=="32" (
		set MEMORY=32
	) else if "%2"=="48" (
		set MEMORY=48
	) else (
		echo Setting default mode to RAM, tape and 32K...
		set MEMORY=32
		set KFLAG=-k !MEMORY!
		goto next
	)
	set KFLAG=-k !MEMORY!
	shift
) else if "%OPT%"=="-q" (
	if NOT "%CFLAG%"=="" (
		echo Error: Marquee option is not compatible with ROM cartridge distribution^^!
		goto :eof
	)
	set MARQUEE=%2
	if not exist "%MEDIAPATH%\!MARQUEE!" (
		echo Error: Marquee file "!MARQUEE!" doesn't exists in resources path
		goto :eof
	)
	set QFLAG= -q !MARQUEE!
	shift
) else if "%OPT%"=="-t" (
	if NOT "%CFLAG%"=="" (
		echo Error: Title option is not compatible with ROM cartridge distribution^^!
		goto :eof
	)
	set TITLE=%2
	if not exist "%MEDIAPATH%\!TITLE!" (
		echo Error: Title file "!TITLE!" doesn't exists in resources path
		goto :eof
	)
	set TFLAG= -t !TITLE!
	shift
) else if "%OPT%"=="-b" (
	set BFLAG= -b
) else if "%OPT%"=="-x" (	
	set MACHINE=%2
	if !MACHINE! gtr 4 (
		echo Error: Invalid argument "%1 !MACHINE!". Unknown MSX model
		goto :eof
	)
	shift
) else (
	echo Error: Can't parse arguments. Unknown %OPT% argument. 
	goto :eof
)
:next
shift
goto getopt
:endopt

if %MACHINE%.==. (
	set MACHINE=1
	echo Setting default MSX emulation to MSX1...
)
if "%NAME%"=="" (
	echo Error: No name specified
	goto :eof
)
if "%DFLAG%"=="" (
	if "%CFLAG%"=="" (
		echo Setting default distribution to RAM, disk and 32K...
		set DIST=RAM
		set MEMORY=32
		set DFLAG=-d !MEMORY!
	)
)

set COMPILERFLAGS=%BFLAG%%AFLAG%%QFLAG%

:main
if not exist "%SOURCES%\%NAME%.agd" (
	echo Error: Source %SOURCES%\%NAME%.agd doesn't exists...
	goto :eof
)

if /I "%DIST%"=="RAM" (
	goto createram
) else if /I "%DIST%"=="ROM" (
	goto createrom	
) else (
	echo Error: No distribution mode set^^!
	goto :eof
)

:createram
	echo ========= Creating RAM distribution ===================================================
	rmdir /S /Q tmp >NUL 2>&1
	mkdir tmp

	cd tmp
	mkdir dskdir
	
	set ERRFOUND=0
	
	copy "%SOURCES%\%NAME%.agd" . >NUL 2>&1
	copy "%AGDPATH%\*.asm" . >NUL 2>&1

	"%COMPILER%" %NAME% %DFLAG%%CFLAG%%COMPILERFLAGS%
	if ERRORLEVEL 1 (
		echo Error: Errors detected while compiling AGD source...
		goto :eof
	)
	
	"%ASM%" -s %NAME%.asm 1>sjasm.log
	if ERRORLEVEL 1 (
		set ERRFOUND=1
		echo Error: Errors detected while compiling asm source...
	)

	call :filesize main_vars.tmp
	set /a DSIZE = FSIZE
	call :filesize %NAME%.bin
	set /a BSIZE = FSIZE
	set /a TSIZE = BSIZE + DSIZE
	if %TSIZE% gtr %MAXRAM% (
		echo Error: Game is too big to fit in %MAXRAM% bytes of RAM. Try to reduce it^^!
		goto :eof
	)

	if %ERRFOUND% equ 1 (
		if %MEMORY% equ 32 (
			if %TSIZE% gtr %SZLIMIT% (
				echo Game is too big to fit RAM in pages 2-3. Enabling RAM in page 1...
				cd %WD%
				call %BUILD% %NAME% -d 48 %COMPILERFLAGS% %TFLAG% -x %MACHINE% 
			) else (
				echo There must be errors...
			)			
		)
		if exist sjasm.log ( 
			type sjasm.log
		)
		goto :eof
	) else (
		echo File compiled successfully^^!
	)

	if %MEMORY% equ 48 (
		set BSTART=16384
	) else (
		if %MEMORY% equ 32 (
			if %TSIZE% gtr %SZLIMIT% (
				echo Game is too big to fit in RAM. Retrying with 48K mode...
				cd %WD%
				call %BUILD% %NAME% -d 48 %COMPILERFLAGS% %TFLAG% -x %MACHINE%
				goto :eof
			) else (
				set BSTART=32896
			)
		)
	) 	
	
	set /a BEND = BSTART + BSIZE - 1
	set /a TEND = BSTART + TSIZE - 1
	call :DECTOHEX BSTART
	call :DECTOHEX BEND
	call :DECTOHEX TEND

	echo Binary size:%BSIZE%
	echo Program binary:%BSTART%-%BEND%
	echo Variables area size:%DSIZE% 
	echo Total size:%TSIZE%
	echo Total memory range:%BSTART%-%TEND%

	REM Generate Title and Marquee screens
	if not "%TFLAG%"=="" (
		set IMAGES=BLOAD"TI.SC2",S:A$=INPUT$^(1^):
		copy "%MEDIAPATH%\!TITLE!" dskdir\TI.SC2 >NUL 2>&1
	)
	if not "%QFLAG%"=="" (
		set IMAGES=!IMAGES!BLOAD"MQ.SC2",S:
		copy "%MEDIAPATH%\!MARQUEE!" dskdir\MQ.SC2 >NUL 2>&1
	)
	if not "!IMAGES!"=="" (
		set IMAGES=SCREEN2,2,0:COLOR15,1,1:CLS:!IMAGES!
	)

	REM Generate binaries
	if %TSIZE% gtr %SZLIMIT% (
		echo Total size is bigger than %SZLIMIT% bytes, splitting file and creating loader...
		REM Split file
		"%TOOLSPATH%\split.exe" -b 16k %NAME%.bin
		if exist xac (
			copy /b xab + xac xzz >NUL 2>&1
			move xzz xab >NUL 2>&1
			del xac xzz >NUL 2>&1
		)
		REM Create binaries
		call :createbin xaa P1.BIN 8080 F41F
		call :createbin xab P2.BIN 8000 F436
		move P1.BIN dskdir >NUL 2>&1
		move P2.BIN dskdir >NUL 2>&1
		copy loader.bin dskdir\LDR.BIN >NUL 2>&1
		copy "%TOOLSPATH%\ONEDRIVE.COM" dskdir\ONEDRIVE.COM >NUL 2>&1
		copy data\*.* dskdir >NUL 2>&1 >NUL 2>&1
		echo 1 BLOAD"ONEDRIVE.COM":A=PEEK^(-833^)+256*PEEK^(-832^):DEFUSR=A:A=USR^("RUN.BAS"^) >dskdir\AUTOEXEC.BAS
		echo 1 CLEAR1,57600:!IMAGES!BLOAD"LDR.BIN":BLOAD"P1.BIN",R:BLOAD"P2.BIN",R >dskdir\RUN.BAS
	) else (
		echo Total size is less than %SZLIMIT% bytes. Fits in BASIC RAM...
		REM Create binaries
		call :createbin %NAME%.bin P1.BIN %BSTART% %BSTART%
		move P1.BIN dskdir >NUL 2>&1
		copy "%TOOLSPATH%\ONEDRIVE.COM" dskdir\ONEDRIVE.COM >NUL 2>&1
		copy data\*.* dskdir >NUL 2>&1 >NUL 2>&1
		echo 1 BLOAD"ONEDRIVE.COM":A=PEEK^(-833^)+256*PEEK^(-832^):DEFUSR=A:A=USR^("RUN.BAS"^) >dskdir\AUTOEXEC.BAS
		echo 1 CLEAR1,57600:!IMAGES!BLOAD"P1.BIN",R >dskdir\RUN.BAS
	)

	call :createdsk dskdir

	if exist %NAME%.dsk (
		if not "%MSXEMUPATH%"=="" (
			move %NAME%.dsk "%MSXEMUPATH%" >NUL 2>&1
		) else (
			move %NAME%.dsk "%WD%" >NUL 2>&1
		)
		move %NAME%.sym "%ASMPATH%" >NUL 2>&1
	)

	cd %WD%
	REM Delete all temp files
	rmdir /S /Q tmp >NUL 2>&1

	echo =======================================================================================
	
	if not "%MSXEMUPATH%"=="" (
		if %MACHINE% gtr 0 (
			call :execemu %MACHINE%
		)
	) else (
		echo No OpenMSX emulator found. Can't execute^^!
	)

	echo Process finished^^!^^!
	goto :eof

:createrom
	echo ========= Creating ROM distribution ===================================================
	rmdir /S /Q tmp >NUL 2>&1
	mkdir tmp

	cd tmp
	
	set ERRFOUND=0
	
	copy "%SOURCES%\%NAME%.agd" . >NUL 2>&1
	copy "%AGDPATH%\*.asm" . >NUL 2>&1

	"%COMPILER%" %NAME% %DFLAG%%CFLAG%%COMPILERFLAGS%
	if ERRORLEVEL 1 (
		echo Error: Errors detected while compiling AGD source...
		goto :eof
	)
	
	"%ASM%" -s %NAME%.asm 1>sjasm.log
	if ERRORLEVEL 1 (
		set ERRFOUND=1
		echo Error: Errors detected while compiling asm source...
	)

	call :filesize main_vars.tmp
	set /a DSIZE = FSIZE
	call :filesize %NAME%.rom
	set /a BSIZE = FSIZE
	if %BSIZE% gtr 32768 (
		echo Error: Game is too big to fit in 32768 bytes of ROM. Try to reduce it^^!
		goto :eof
	)

	if %ERRFOUND% equ 1 (
		if exist sjasm.log ( 
			type sjasm.log
		)
		goto :eof
	) else (
		echo File compiled successfully^^!
	)

	REM type testmsx.lst | findstr /R /C:"endmain:"
	REM for /F "tokens=2" %a in ("    6250   00:6059  (00:6059)           endmain:    equ $") DO ( echo %a )
	REM for /F "tokens=2 delims=:" %a in ("00:6059") DO ( echo %a )
	
	set BSTART=16384
	set /a BEND = BSTART + BSIZE - 1
	call :DECTOHEX BSTART
	call :DECTOHEX BEND

	echo Binary size:%BSIZE%
	echo Program binary:%BSTART%-%BEND%
	echo Variables area size:%DSIZE% 

	if exist %NAME%.rom (
		if exist rom_filler.bin (
			copy /b %NAME%.rom + rom_filler.bin %NAME%.rom >NUL 2>&1
		)
		if not "%MSXEMUPATH%"=="" (
			move %NAME%.rom "%MSXEMUPATH%" >NUL 2>&1
		) else (
			move %NAME%.rom "%WD%" >NUL 2>&1
		)
		move %NAME%.sym "%ASMPATH%" >NUL 2>&1
	)

	cd %WD%
	REM Delete all temp files
	rmdir /S /Q tmp >NUL 2>&1

	echo =======================================================================================
	if not "%MSXEMUPATH%"=="" (
		if %MACHINE% gtr 0 (
			call :execemu %MACHINE%
		)
	) else (
		echo No OpenMSX emulator found. Can't execute^^!
	)

	echo Process finished^^!^^!
	goto :eof
	
:execemu
	cd /d "%MSXEMUPATH%"
	if NOT "%CFLAG%"=="" (
		set MEDIA=-carta %NAME%.rom
	) else if NOT "%DFLAG%"=="" (
		set MEDIA=-diska %NAME%.dsk
	) else if NOT "%KFLAG%"=="" (
		set MEDIA=-cassetteplayer insert %NAME%.cas
	)
	if %1 equ 1 (
		if NOT "%DFLAG%"=="" (
			set MEDIA=-ext Sony_HBD-F1 !MEDIA!
		)
		start /B %EMU% -machine Sony_HB-75P !MEDIA!
	) else if %1 equ 2 (
		start /B %EMU% -machine Philips_NMS_8245 %MEDIA%
	) else if %1 equ 3 (
		start /B %EMU% -machine Panasonic_FS-A1WX %MEDIA%
	) else if %1 equ 4 (
		start /B %EMU% -machine Panasonic_FS-A1GT %MEDIA%
	) else (
		echo Error: Unknown MSX model^!. Can't play game...
		exit /b 1
	)
	exit /b 0
	
:createbin
	echo 	output %2 >dskdir\HEADER.ASM
	echo 	db $FE >>dskdir\HEADER.ASM
	echo 	dw main >>dskdir\HEADER.ASM
	echo 	dw endmain-1 >>dskdir\HEADER.ASM
	echo 	dw $%4 >>dskdir\HEADER.ASM
	echo 	org $%3 >>dskdir\HEADER.ASM
	echo main: incbin "..\%1" >>dskdir\HEADER.ASM
	echo endmain: equ $ >>dskdir\HEADER.ASM
	"%ASM%" dskdir\HEADER.ASM >NUL 2>&1
	del dskdir\HEADER.ASM dskdir\HEADER.LST >NUL 2>&1
	exit /b 0

:createdsk
	cd %1
	for /r %%f in (*) do @"%WRDSK%" %NAME%.dsk %%~nxf >NUL
	copy %NAME%.dsk .. >NUL 2>&1
	cd ..
	REM rmdir /S /Q %1 >NUL 2>&1
	exit /b 0
	
:filesize
	set FSIZE=%~z1
	exit /b 0

:DECTOHEX VAR
SET "DEC=!%1!"
SET "HEX="
:loop
    SET /A DIGIT=DEC%%16, DEC/=16
    SET "HEX=!HEXA:~%DIGIT%,1!%HEX%"
IF %DEC% NEQ 0 GOTO loop
SET "%1=%HEX%"
EXIT /B

:help
echo.
echo Description: ^"build^" batch builds the MSX distribution for an AGD source
echo.
echo Usage: build ^<AGD file^> [-?^|-h] [-a] [-t ^<SC2 file^>] [-q ^<SC2 file^>] [-c ^<KB Size^>^|-d ^<KB size^>] [-x ^<MSX type^>]
echo. 
echo    ^<AGD source^>  AGD source file without .agd extension (1)
echo. 
echo    -?^|-h         This help
echo    -a            Enables adventure mode
echo    -t ^<SC2 file^> Loads a title screen
echo    -q ^<SC2 file^> Loads a marquee screen to be used by te game (no video initialization at boot)
echo    -d ^<KB size^>  Disk (RAM) distribution: Valid KB sizes are: 16,32,48 (default:32)
echo    -c ^<KB size^>  Cartridge (ROM) distribution: Valid KB sizes are: 16,32 (default:32)
echo    -x ^<MSX type^> Launch ^<MSX type^> emulation after successful build
echo.
echo                  MSX types (-x)
echo                  ------------------
echo                  0: None
echo                  1: MSX1 (Sony HB-75P) (Default)
echo                  2: MSX2 (Philips NMS-8245)
echo                  3: MSX2+ (Panasonic FS-A1WX)
echo                  4: TurboR (Panasonic FS-A1GT)
echo.
echo (1) Default are disk (DSK) distribution, 32KB setup and all flags disables except emulation set for MSX1
echo.
echo Examples: ^>build oceano                  (builds oceano.agd, creates a DSK and launches a MSX1 emulation)
echo           ^>build foggy -a -x 2           (builds foggy.agd, enables adventure mode, creates a DSK and launches a MSX2 emulation)
echo           ^>build dcr11 -t TITLE.SC2 -x 4 (builds dcr11.agd, adds a loading screen, creates a DSK and launches a TurboR emulation)
echo.
goto :eof

:end
