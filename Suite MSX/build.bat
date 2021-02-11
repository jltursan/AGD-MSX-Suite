@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set WD=%cd%

REM Configure and uncomment the selected pair of variables 
REM OpenMSX setup
REM set MSXEMUPATH=
REM set EMU=openmsx.exe
REM fMSX setup
REM set MSXEMUPATH=<PATH TO fMSX>\fMSX
REM set EMU=fMSX.exe
REM blueMSX setup
REM set MSXEMUPATH=<PATH TO blueMSX>\blueMSX
REM set EMU=blueMSX.exe

set AGDPATH=%WD%\AGD
set SOURCES=%WD%\AGDsources
set TOOLSPATH=%WD%\tools
set ASMPATH=%WD%\sjasm
set MEDIAPATH=%WD%\resources

set WRDSK=%TOOLSPATH%\wrdsk.exe
set MCP=%TOOLSPATH%\mcp.exe
set ASM=%ASMPATH%\sjasm.exe
set COMPILER=%AGDPATH%\CompilerMSX.exe
set BUILD=%0

REM OpenMSX DEFAULT MACHINES and EXTENSIONS
REM ---------------------------------------
set MSX1MACHINE=Sony_HB-75P
set MSX2MACHINE=Philips_NMS_8245
set MSX2PMACHINE=Panasonic_FS-A1WX
set MSXTRMACHINE=Panasonic_FS-A1GT
set MSXFDI=Sony_HBD-F1

set "HEXA=0123456789ABCDEF"

REM (always $E000)
set RAMSTART=57344
REM (MSX 64KB without disk drives = $F380)
set CASHIMEM=62336
REM (MSX 64KB with at least 1 drive = $E470)
set DSKHIMEM=58480

set MAXOBJECTS=128	REM safe objects buffer number size when adventure mode is on (real size=objects*2)
set STACK=128
set BASSIZE=128
set BIOSVARS=56

set NAME=
set MACHINE=
set DIST=
set DEVICE=

REM MANUAL FLAGS 
set AFLAG=
set BFLAG=
set DFLAG=
set KFLAG=
set MBFLAG=
set HCFLAG=
set CBFLAG=
set QFLAG=
set RFLAG=
set TFLAG=
set TVFLAG=
set FXRFLAG=
set FXDFLAG=
set FXCFLAG=

echo.
echo MPAGD v0.7.10 - MSX Builder 1.0 -----------------------------------------------------------
echo.

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
) else if "%OPT%"=="-m" (
	set MBFLAG= -m
) else if "%OPT%"=="-c" (
	set HCFLAG= -c
) else if "%OPT%"=="-b" (
	set CBFLAG= -b
) else if "%OPT%"=="-l" (
	set FXRFLAG= -l
) else if "%OPT%"=="-y" (
	set FXDFLAG= -y
) else if "%OPT%"=="-s" (
	if NOT "%FXDFLAG%"=="" (
		echo Error: Can't set a fixed channel while in dynamic mode.
		goto :eof
	)
	if "%2"=="" (
		echo No PSG output channel specified. Setting default PSG output channel to C...
		set CHANNEL=1
		set FXCFLAG= -s !CHANNEL!
		goto next
	) else if "%2"=="1" (
		set CHANNEL=1
	) else if "%2"=="2" (
		set CHANNEL=2
	) else if "%2"=="3" (
		set CHANNEL=3
	) else (
		echo Error: Wrong PSG output channel, try with 1, 2 or 3
		goto :eof
	)
	set FXCFLAG= -s !CHANNEL!
	shift
) else if "%OPT%"=="-f" (
	if "%2"=="" (
		echo No TV mode specified. Setting default TV refresh to 'machine default'...
		set TVMODE=50
		set TVFLAG=-f !TVMODE!
		goto next
	) else if "%2"=="0" (
		set TVMODE=0
	) else if "%2"=="50" (
		set TVMODE=50
	) else if "%2"=="60" (
		set TVMODE=60
	) else (
		echo Error: TV refresh not supported, try with 0, 50 or 60
		goto :eof
	)
	set TVFLAG=-f !TVMODE!
	shift
) else if "%OPT%"=="-r" (
	if NOT "%DFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -r ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	if NOT "%QFLAG%%TFLAG%"=="" (
		echo Error: ROM cartridge distribution is not compatible with Marquee or Title options^^!
		goto :eof
	)
	set DIST=ROM
	set HIMEM=%CASHIMEM%	
	if "%2"=="" (
		echo Setting default mode to ROM cartridge with 16K...
		set MEMORY=16
		set RFLAG=-r !MEMORY!
		goto next
	) else if "%2"=="16" (
		set MEMORY=16
	) else if "%2"=="32" (
		set MEMORY=32
	) else if "%2"=="48" (
		set MEMORY=48
	) else (
		echo Error: %2K size model not supported for ROM cartridges, try with 16, 32 or 48
		goto :eof
	)
	set RFLAG=-r !MEMORY!
	shift
) else if "%OPT%"=="-d" (
	if NOT "%RFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -r ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	set DIST=RAM
	set HIMEM=%DSKHIMEM%
	if "%2"=="" (
		echo Setting default mode to RAM, disk and 32K...
		set MEMORY=32
		set DFLAG=-d !MEMORY!
		set /a BSTART=32768 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
		goto next
	) else if "%2"=="16" (
		set MEMORY=16
		set /a BSTART=49152 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="32" (
		set MEMORY=32
		set /a BSTART=32768 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="48" (
		set MEMORY=48
		set BSTART=16384
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="64" (
		set MEMORY=64
		set BSTART=0
		set /a SZLIMIT=HIMEM - STACK - BIOSVARS
		set /a MAXRAM=SZLIMIT
	) else (
		echo Error: %2K size model not supported for disk binaries, try with 16, 32, 48 or 64
		goto :eof
	)
	set DFLAG=-d !MEMORY!
	shift
) else if "%OPT%"=="-k" (
	if NOT "%RFLAG%"=="" (
		echo Error: Duplicate distribution flag^^!. Only one -r ^(ROM^) or -d/-k ^(DSK/CAS^) flag can be selected at the same time
		goto :eof
	)
	set DIST=RAM
	set HIMEM=%CASHIMEM%
	if "%2"=="" (
		echo Setting default mode to RAM, tape and 32K...
		set MEMORY=32
		set DFLAG=-k !MEMORY!
		set /a BSTART=32768 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
		goto next
	) else if "%2"=="16" (
		set MEMORY=16
		set /a BSTART=49152 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="32" (
		set MEMORY=32
		set /a BSTART=32768 + BASSIZE
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="48" (
		set MEMORY=48
		set BSTART=16384
		set /a SZLIMIT=HIMEM - STACK - BSTART
		set /a MAXRAM=HIMEM - STACK - BIOSVARS
	) else if "%2"=="64" (
		set MEMORY=64
		set BSTART=0
		set /a SZLIMIT=HIMEM - STACK - BIOSVARS
		set /a MAXRAM=SZLIMIT
	) else (
		echo Error: %2K size model not supported for tape binaries, try with 16, 32, 48 or 64
		goto :eof
	)
	set KFLAG=-k !MEMORY!
	set DEVICE=CAS:
	shift
) else if "%OPT%"=="-q" (
	if NOT "%RFLAG%"=="" (
		echo Error: Marquee option is not compatible with ROM cartridge distribution^^!
		goto :eof
	)
	if NOT "%KFLAG%"=="" (
		echo Error: Marquee option is not compatible with Tape file distribution^^!
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
	if NOT "%RFLAG%"=="" (
		echo Error: Title option is not compatible with ROM cartridge distribution^^!
		goto :eof
	)
	if NOT "%KFLAG%"=="" (
		echo Error: Title option is not compatible with Tape file distribution^^!
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

if "%MSXEMUPATH%"=="" (
	if exist "%WD%\openmsx\openmsx.exe" (
		echo OpenMSX emulator set to default...
		set MSXEMUPATH=%WD%\openmsx
		set EMU=openmsx.exe
	) else if exist "%WD%\fMSX\fMSX.exe" (
		echo fMSX emulator set to default...
		set MSXEMUPATH=%WD%\fMSX
		set EMU=fMSX.exe
	) else (
		echo Warning: No MSX emulator found, you can't run the compiled programs
	)
)

if %MACHINE%.==. (
	set MACHINE=1
	echo Setting default MSX emulation to MSX1...
)
if "%NAME%"=="" (
	echo Error: No name specified
	goto help
)
if "%DFLAG%%RFLAG%%KFLAG%"=="" (
	echo Setting default distribution to RAM, disk and 32K...
	set DIST=RAM
	set MEMORY=32
	set HIMEM=%DSKHIMEM%
	set DFLAG=-d !MEMORY!
	set /a BSTART=32768 + BASSIZE
	set /a SZLIMIT=HIMEM - STACK - BSTART
	set /a MAXRAM=HIMEM - STACK - BIOSVARS
)

if not "%AFLAG%"=="" (
	set /a MAXRAM=MAXRAM-MAXOBJECTS*2 
	set /a SZLIMIT=SZLIMIT-MAXOBJECTS*2
)
set /a MAXRAM=MAXRAM-(65536-MEMORY*1024)

set COMPILERFLAGS=%BFLAG%%AFLAG%%MBFLAG%%HCFLAG%%CBFLAG%%TVFLAG%%FXRFLAG%%FXDFLAG%%FXCFLAG%%QFLAG%

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

	mkdir mediadir
	
REM	del sjasm.log *.bin %NAME%.dsk >NUL 2>&1
	set ERRFOUND=0
	
	copy "%SOURCES%\%NAME%.agd" . >NUL 2>&1
	copy "%AGDPATH%\*.asm" . >NUL 2>&1

	"%COMPILER%" %NAME% %DFLAG%%RFLAG%%KFLAG% %COMPILERFLAGS%
	if ERRORLEVEL 1 (
		echo Error: Errors ^(%ERRORLEVEL%^) detected while compiling AGD source...
		goto :eof
	)
	"%ASM%" -s %NAME%.asm 1>sjasm.log
	if ERRORLEVEL 1 (
		find /C "out of range" sjasm.log >NUL 2>&1
		if ERRORLEVEL 1 (
			set ERRFOUND=1
			echo Error: Errors detected while compiling asm source.
		) else (
			set ERRFOUND=2
		)
	) 	
	
	if %ERRFOUND% equ 1 (
		if exist sjasm.log ( 
			type sjasm.log
		)
		goto :eof
	) 
	
	call :filesize ram_vars.tmp
	set /a DSIZE = FSIZE
	call :filesize %NAME%.bin
	set /a BSIZE = FSIZE
	set /a TSIZE = BSIZE + DSIZE

	if %TSIZE% gtr %SZLIMIT% (
		echo Game is too big to fit in %MEMORY%KB RAM. Enabling a new RAM page...
		set /a MEMORY = MEMORY + 16
		cd %WD%
		if NOT "%DFLAG%"=="" (
			call %BUILD% %NAME% -d !MEMORY! %COMPILERFLAGS% %TFLAG% -x %MACHINE%
		) else (
			call %BUILD% %NAME% -k !MEMORY! %COMPILERFLAGS% %TFLAG% -x %MACHINE%
		)
		goto :eof
	) else (
		echo File compiled successfully^^!
	)
	
	set /a BEND = BSTART + BSIZE - 1
	set /a TEND = BSTART + TSIZE - 1
	set /a FREEMEM = MAXRAM - TSIZE 
	call :DECTOHEX BSTART
	call :DECTOHEX BEND
	call :DECTOHEX TEND

	echo.
	echo Binary stats
	echo ------------------------	
	echo Binary size:%BSIZE%
	echo Program binary:$%BSTART%-$%BEND%
	echo Variables area size:%DSIZE% 
	echo Total size (binary+variables):%TSIZE%
	echo Total memory range used:$%BSTART%-$%TEND%
	echo Free RAM:%FREEMEM% bytes 

	REM call :codeAnalysis
	
	REM Generate Title screen
	if not "%TFLAG%"=="" (
		set IMAGES=BLOAD"!DEVICE!IT.BIN",S:A$=INPUT$^(1^):
		copy "%MEDIAPATH%\!TITLE!" mediadir\IT.BIN >NUL 2>&1
	)
	REM Generate Marquee screen
	if not "%QFLAG%"=="" (
		set IMAGES=!IMAGES!BLOAD"!DEVICE!IQ.BIN",S:
		copy "%MEDIAPATH%\!MARQUEE!" mediadir\IQ.BIN >NUL 2>&1
	)
	if not "!IMAGES!"=="" (
		set IMAGES=SCREEN2,2,0:COLOR15,1,1:CLS:!IMAGES!
	)

	REM Generate binaries
	if %MEMORY% equ 64 (
		echo Splitting file and creating loader for a 64KB binary...
		REM Split file
		"%TOOLSPATH%\split.exe" -b 16k %NAME%.bin
		if exist xad (
			copy /b xac + xad xzz >NUL 2>&1
			move xzz xac >NUL 2>&1
			del xad xzz >NUL 2>&1
		)
		REM Create binaries
		call :createbin xab P1.BIN 8080 F42F
		call :createbin xaa P2.BIN 8080 F41F
		call :createbin xac P3.BIN 8000 F448
		move P1.BIN mediadir >NUL 2>&1
		move P2.BIN mediadir >NUL 2>&1
		move P3.BIN mediadir >NUL 2>&1
		copy loader.bin mediadir\LDR.BIN >NUL 2>&1
		copy data\*.* mediadir >NUL 2>&1 >NUL 2>&1
		set LOADER=GAME.ASC
		if NOT "%DFLAG%"=="" (
			copy "%TOOLSPATH%\ONEDRIVE.COM" mediadir\ONEDRIVE.COM >NUL 2>&1
			echo 1 BLOAD"ONEDRIVE.COM":A=PEEK^(-833^)+256*PEEK^(-832^):DEFUSR=A:A=USR^("RUN.BAS"^) >mediadir\AUTOEXEC.BAS
			set LOADER=RUN.BAS
		) 
		echo 1 CLEAR1,%HIMEM%:BLOAD"!DEVICE!LDR.BIN":!IMAGES!BLOAD"!DEVICE!P1.BIN",R:BLOAD"!DEVICE!P2.BIN",R:BLOAD"!DEVICE!P3.BIN",R >mediadir\!LOADER!
	) else if %MEMORY% equ 48 (
		echo Splitting file and creating loader for a 48KB binary...
		REM Split file
		"%TOOLSPATH%\split.exe" -b 16k %NAME%.bin
		if exist xac (
			copy /b xab + xac xzz >NUL 2>&1
			move xzz xab >NUL 2>&1
			del xac xzz >NUL 2>&1
		)
		REM Create binaries
		call :createbin xaa P1.BIN 8080 F42F
		call :createbin xab P2.BIN 8000 F44B
		move P1.BIN mediadir >NUL 2>&1
		move P2.BIN mediadir >NUL 2>&1
		copy loader.bin mediadir\LDR.BIN >NUL 2>&1
		copy data\*.* mediadir >NUL 2>&1 >NUL 2>&1
		set LOADER=GAME.ASC
		if NOT "%DFLAG%"=="" (
			copy "%TOOLSPATH%\ONEDRIVE.COM" mediadir\ONEDRIVE.COM >NUL 2>&1
			echo 1 BLOAD"ONEDRIVE.COM":A=PEEK^(-833^)+256*PEEK^(-832^):DEFUSR=A:A=USR^("RUN.BAS"^) >mediadir\AUTOEXEC.BAS
			set LOADER=RUN.BAS
		)
		echo 1 CLEAR1,%HIMEM%:BLOAD"!DEVICE!LDR.BIN":!IMAGES!BLOAD"!DEVICE!P1.BIN",R:BLOAD"!DEVICE!P2.BIN",R >mediadir\!LOADER!
	) else (
		echo Binary fits in BASIC RAM...
		REM Create binaries
		call :createbin %NAME%.bin P1.BIN %BSTART% %BSTART%
		move P1.BIN mediadir >NUL 2>&1
		copy data\*.* mediadir >NUL 2>&1 >NUL 2>&1
		set LOADER=GAME.ASC
		if NOT "%DFLAG%"=="" (
			copy "%TOOLSPATH%\ONEDRIVE.COM" mediadir\ONEDRIVE.COM >NUL 2>&1
			echo 1 BLOAD"ONEDRIVE.COM":A=PEEK^(-833^)+256*PEEK^(-832^):DEFUSR=A:A=USR^("RUN.BAS"^) >mediadir\AUTOEXEC.BAS
			set LOADER=RUN.BAS
		)
		echo 1 CLEAR1,%HIMEM%:!IMAGES!BLOAD"!DEVICE!P1.BIN",R >mediadir\!LOADER!
	)

	if NOT "%DFLAG%"=="" (
		call :createdsk mediadir
		if exist %NAME%.dsk (
			move %NAME%.dsk "%WD%" >NUL 2>&1
			move %NAME%.sym "%ASMPATH%" >NUL 2>&1
		)
	) else if NOT "%KFLAG%"=="" (
		call :createcas mediadir
		if exist %NAME%.cas (
			move %NAME%.cas "%WD%" >NUL 2>&1
			move %NAME%.sym "%ASMPATH%" >NUL 2>&1
		)
	)

	cd %WD%

	echo =======================================================================================
	
	if not "%MSXEMUPATH%"=="" (
		if %MACHINE% gtr 0 (
			call :execemu %MACHINE%
		)
	) else (
		echo No OpenMSX emulator found. Can't execute^^!
	)

	REM Delete all temp files
	REM rmdir /S /Q tmp >NUL 2>&1

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

	"%COMPILER%" %NAME% %DFLAG%%RFLAG% %COMPILERFLAGS%
	if ERRORLEVEL 1 (
		echo Error: Errors detected while compiling AGD source...
		goto :eof
	)
	
	"%ASM%" -s %NAME%.asm 1>sjasm.log
	if ERRORLEVEL 1 (
		find /C "does not fit" sjasm.log >NUL 2>&1
		if ERRORLEVEL 1 (
			set ERRFOUND=1
			echo Error: Errors detected while compiling asm source.
		) else (
			set ERRFOUND=2
			echo Warning: Binary too big. 
		)
	)
	
	if %ERRFOUND% equ 1 (
		if exist sjasm.log ( 
			type sjasm.log
		)
		goto :eof
	) else if %ERRFOUND% equ 2 (
		if %MEMORY% equ 16 (
			echo Game is too big to fit a 16KB ROM page. Enabling two page ROM cart and retrying...
			cd %WD%
			call %BUILD% %NAME% -r 32 %COMPILERFLAGS% %TFLAG% -x %MACHINE% 
			goto :eof
		) else if %MEMORY% equ 32 (
			echo Game is too big to fit a 32KB ROM page. Enabling three page ROM cart and retrying...
			cd %WD%
			call %BUILD% %NAME% -r 48 %COMPILERFLAGS% %TFLAG% -x %MACHINE% 
			goto :eof
		) else if %MEMORY% equ 48 (
			echo Error: Game is too big to fit in 49152 bytes of ROM. Try to reduce it^^!
			goto :eof
		)
	) else (
		echo File compiled successfully^^!
	)
	
	for /f "tokens=1 delims=:" %%a in ('findstr /N /C:"%NAME%.rom" %NAME%.lst') do set lastline=%%a
	more +%lastline% %NAME%.lst > %NAME%.txt
	set firstline=1
	for /f "tokens=1 delims=:" %%a in ('findstr /N /C:"ram_vars.tmp" %NAME%.txt') do set lastline=%%a
	del %NAME%_sizes.txt >NUL 2>&1	
	for /f "tokens=1* delims=:" %%a in ('findstr /N /C:" " %NAME%.txt') do (
		if %%a geq %firstline% ( 
			if %%a lss %lastline% ( echo %%b >>%NAME%_sizes.txt )
		)
	) 
	for /f "tokens=1,2 delims= " %%a in ('findstr /C:"empty" %NAME%_sizes.txt') do set BEND=%%a & set FREEROM=%%b
	set BEND=%BEND:~4%
	call :HEXTODEC BEND
	for /f "tokens=2" %%a in ('findstr /C:"score" %NAME%.txt') do set DSIZE=%%a	
	
	REM Generating stats
	if %MEMORY% equ 48 (
		set BSTART=56
	) else (
		set BSTART=16384
	)
	set /a BSIZE = BEND - BSTART
	set /a VSTART = RAMSTART
	set /a VEND = 57344 + DSIZE
	set /a FREERAM = HIMEM - RAMSTART - DSIZE
	call :DECTOHEX BSTART
	call :DECTOHEX BEND
	call :DECTOHEX VSTART
	call :DECTOHEX VEND

	echo.
	echo ROM stats
	echo ------------------------	
	echo ROM size: %MEMORY%KB
	echo Binary size:%BSIZE%
	echo Program binary: $%BSTART%-$%BEND%
	echo Free ROM: %FREEROM% bytes
	echo RAM area used: $%VSTART%-$%VEND% 
	echo RAM used size: %DSIZE% 
	echo Free RAM: %FREERAM% bytes

	REM call :codeAnalysis
	
	if exist %NAME%.rom (
		REM if exist rom_filler.bin (
		REM 	copy /b %NAME%.rom + rom_filler.bin %NAME%.rom >NUL 2>&1
		REM )
		move %NAME%.rom "%WD%" >NUL 2>&1
		move %NAME%.sym "%ASMPATH%" >NUL 2>&1
	)

	cd %WD%

	echo =======================================================================================
	if not "%MSXEMUPATH%"=="" (
		if %MACHINE% gtr 0 (
			call :execemu %MACHINE%
		)
	) else (
		echo No OpenMSX emulator found. Can't execute^^!
	)

	REM Delete all temp files
	REM rmdir /S /Q tmp >NUL 2>&1

	echo Process finished^^!^^!
	goto :eof
	
:execemu
	cd /d "%MSXEMUPATH%"
	if NOT "%RFLAG%"=="" (
		if "%EMU%"=="fMSX.exe" (
			set MEDIA=^"%WD%\%NAME%.rom^"
		) else if "%EMU%"=="openmsx.exe" (
			set MEDIA=-carta ^"%WD%\%NAME%.rom^"
		) else if "%EMU%"=="blueMSX.exe" (
			set MEDIA=-rom1 ^"%WD%\%NAME%.rom^"
		)
	) else if NOT "%DFLAG%"=="" (
		set MEDIA=-diska ^"%WD%\%NAME%.dsk^"
	) else if NOT "%KFLAG%"=="" (
		if "%EMU%"=="fMSX.exe" (
			set MEDIA=-tape ^"%WD%\%NAME%.cas^"
		) else if "%EMU%"=="openmsx.exe" (
			set MEDIA=-cassetteplayer ^"%WD%\%NAME%.cas^"
		) else if "%EMU%"=="blueMSX.exe" (
			set MEDIA=-cas ^"%WD%\%NAME%.cas^"
		)
	) 
	if %1 equ 1 (
		if "%EMU%"=="fMSX.exe" (
			set HW=-msx1
		) else if "%EMU%"=="openmsx.exe" (
			if NOT "%DFLAG%"=="" (
				set HW=-machine %MSX1MACHINE% -ext %MSXFDI%
			) else if NOT "%KFLAG%"=="" (
				set HW=-machine %MSX1MACHINE%
			) else (
				set HW=-machine %MSX1MACHINE%
			)
		) else if "%EMU%"=="blueMSX.exe" (
			set HW=-machine MSX
		)
	) else if %1 equ 4 (
		if NOT "%KFLAG%"=="" (
			echo Error: MSX TurboR machines can't execute a tape. Try with lower models...
			exit /b 1
		)
		if "%EMU%"=="fMSX.exe" (
			echo Error: MSX TurboR machines aren't supported in fMSX...
			exit /b 1
		) else if "%EMU%"=="openmsx.exe" (
			set HW=-machine %MSXTRMACHINE%
		) else if "%EMU%"=="blueMSX.exe" (
			set HW=-machine MSXTurboR
		)
	) else ( 
		if NOT "%KFLAG%"=="" (
			echo Remember to keep pressed SHIFT until MSX BASIC appears to disable all disk drives^!^!
			pause
		)
		if %1 equ 2 (
			if "%EMU%"=="fMSX.exe" (
				set HW=-msx2
			) else if "%EMU%"=="openmsx.exe" (
				set HW=-machine %MSX2MACHINE%
			) else if "%EMU%"=="blueMSX.exe" (
				set HW=-machine MSX2
			)
		) else if %1 equ 3 (
			if "%EMU%"=="fMSX.exe" (
				set HW=-msx2+
			) else if "%EMU%"=="openmsx.exe" (
				set HW=-machine %MSX2PMACHINE%
			) else if "%EMU%"=="blueMSX.exe" (
				set HW=-machine MSX2+
			)
		) else (
			echo Error: Unknown MSX model^!. Can't execute...
			exit /b 1
		) 
	) 
	start "" /B "%MSXEMUPATH%\%EMU%" !HW! !MEDIA!
	exit /b 0
	
:createbin
	echo 	output %2 >mediadir\HEADER.ASM
	echo 	db $FE >>mediadir\HEADER.ASM
	echo 	dw main >>mediadir\HEADER.ASM
	echo 	dw endprogram-1 >>mediadir\HEADER.ASM
	echo 	dw $%4 >>mediadir\HEADER.ASM
	echo 	org $%3 >>mediadir\HEADER.ASM
	echo main: incbin "..\%1" >>mediadir\HEADER.ASM
	echo endprogram: equ $ >>mediadir\HEADER.ASM
	"%ASM%" mediadir\HEADER.ASM >NUL 2>&1
	del mediadir\HEADER.ASM mediadir\HEADER.LST >NUL 2>&1
	exit /b 0

:createdsk
	cd %1
	for /r %%f in (*) do "%WRDSK%" "..\%NAME%.dsk" %%~nxf >NUL
	cd ..
	REM rmdir /S /Q %1 >NUL 2>&1
	exit /b 0

:createcas
	cd %1
	for /r %%f in (*) do @"%MCP%" -a %NAME%.cas %%~nxf 
	copy %NAME%.cas .. >NUL 2>&1
	cd ..
	REM rmdir /S /Q %1 >NUL 2>&1
	exit /b 0

:getsymbol var
	set "OUT1="
	set "OUT2="
	for /f "tokens=2" %%a in ('type %NAME%.lst ^| findstr /C:"  %1:"') do set OUT1=%%a
	for /f "tokens=2 delims=:" %%b in ("%OUT1%") do set OUT2=%%b
	set "%1=%OUT2%"
	exit /b 0

:getsymbols
	call :getsymbol mapedge
	set hex_mapedge=%mapedge%
	call :HEXTODEC mapedge

	call :getsymbol mapdat
	set hex_mapdat=%mapdat%
	call :HEXTODEC mapdat

	REM call :getsymbol init
	REM set hex_init=%main%
	REM call :HEXTODEC init
	
	call :getsymbol evnt00
	set hex_evnt00=%evnt00%
	call :HEXTODEC evnt00
	
	call :getsymbol msgdat
	set hex_msgdat=%msgdat%
	call :HEXTODEC msgdat
	
	call :getsymbol scdat
	set hex_scdat=%scdat%
	call :HEXTODEC scdat

	call :getsymbol chgfx
	set hex_chgfx=%chgfx%
	call :HEXTODEC chgfx

	call :getsymbol sprgfx
	set hex_sprgfx=%sprgfx%
	call :HEXTODEC sprgfx

	call :getsymbol objdta
	set hex_objdta=%objdta%
	call :HEXTODEC objdta

	call :getsymbol palett
	set hex_palett=%palett%
	call :HEXTODEC palett

	call :getsymbol font
	set hex_font=%font%
	call :HEXTODEC font

	call :getsymbol jtab
	set hex_jtab=%jtab%
	call :HEXTODEC jtab

	if NOT "%RFLAG%"=="" (
		call :getsymbol keytab
		set hex_keytab=%keytab%
		call :HEXTODEC keytab
	) else (
		call :getsymbol keys
		set hex_keys=%keys%
		call :HEXTODEC keys
	)

	call :getsymbol CHECKLP
	if NOT "%CHECKLP%"=="" (
		set hex_CHECKLP=%CHECKLP%
		call :HEXTODEC CHECKLP
	)
	
	call :getsymbol songaddr0
	if NOT "%songaddr0%"=="" (
		set hex_songaddr0=%songaddr0%
		call :HEXTODEC songaddr0
	)

	call :getsymbol sfx_init
	if NOT "%sfx_init%"=="" (
		set hex_sfx_init=%sfx_init%
		call :HEXTODEC sfx_init
	)

	call :getsymbol start
	set hex_start=%start%
	call :HEXTODEC start

	call :getsymbol score
	set hex_score=%score%
	call :HEXTODEC score
	
	call :getsymbol varbegin
	set hex_varbegin=%varbegin%
	call :HEXTODEC varbegin

	call :getsymbol endprogram
	set hex_endprogram=%endprogram%
	call :HEXTODEC endprogram

	call :getsymbol eop
	set hex_eop=%eop%
	call :HEXTODEC eop


	exit /b 0

:codeAnalysis
	call :getsymbols
	set /a MAPWIDTH = mapdat - mapedge
	set /a MAPSIZE = evnt00 - mapdat + MAPWIDTH
	set /a GAME = msgdat - evnt00
	set /a MESSAGES = scdat - msgdat
	set /a SCREENS = chgfx - scdat	
	set /a BLOCKS = sprgfx - chgfx	
	set /a SPRITES = objdta - sprgfx
	set /a SPRITES = objdta - sprgfx
	set /a OBJECTS = palett - objdta
	set /a PALETTES = font - palett
	set /a FONT = jtab - font	
	if "%RFLAG%"=="" (
		set /a JUMPTABLE = keys - jtab
	) else (
		set /a JUMPTABLE = keytab - jtab
	)	
	if NOT "%songaddr0%"=="" (
		set /a KEYTABLE = songaddr0 - jtab - JUMPTABLE
		set /a SONGS = start - songaddr0
	) else (
		set /a KEYTABLE = start - jtab - JUMPTABLE
	)
	if NOT "%sfx_init%"=="" (
		set /a SFX = endprogram - sfx_init
		set /a ENGINE = sfx_init - start
		if NOT "%CHECKLP%"=="" (
			set /a MUSIC = sfx_init - CHECKLP
		)
	) else (
		set /a ENGINE = endprogram - start
		if NOT "%CHECKLP%"=="" (
			if "%RFLAG%"=="" (
				set /a MUSIC = score - CHECKLP
			) else (
				set /a MUSIC = endprogram - CHECKLP
			)			
		)
	)	
	set /a VARIABLES = eop - varbegin

	
	echo.
	echo RAM use results (aprox.)
	echo -------------------------------
	echo Events game logic: %GAME% bytes
	echo Map size: %MAPSIZE% bytes
	echo Map screens: %SCREENS% bytes
	echo Messages: %MESSAGES% bytes
	echo Blocks ^& properties: %BLOCKS% bytes
	echo Sprites ^& positions: %SPRITES% bytes
	echo Objects: %OBJECTS% bytes
	echo Palettes: %PALETTES% bytes
	echo Font: %FONT% bytes
	echo Jumptable: %JUMPTABLE% byte/s
	echo Keytable: %KEYTABLE% bytes
	if NOT "%CHECKLP%"=="" (
		echo Music ^(code^): %MUSIC% bytes
	)
	if NOT "%songaddr0%"=="" (
		echo Songs: %SONGS% bytes
	)
	if NOT "%sfx_init%"=="" (
		echo SFX ^(code ^& sfxbank^): %SFX% bytes
	)
	echo AGD engine: %ENGINE% bytes
	echo RAM Variables: %VARIABLES% bytes
	echo.
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

:HEXTODEC VAR
	set "HEX=!%1!"
	set /A DEC=0x%HEX%
	set "%1=%DEC%"
	exit /b
	
:help
echo.
echo Description: ^"build^" batch script builds the MSX distribution for an AGD source.
echo.
echo Usage: build ^<AGD file^> [-?^|-h] [-a] [-m] [-c] [-b] [-l] [-s ^<PSG channel^>] [-f ^<Hz^>] [-t ^<SC2 file^>] [-q ^<SC2 file^>] [-r ^<KB Size^>^|-d ^<KB size^>^|-k ^<KB size^>] [-x ^<MSX type^>]
echo. 
echo    ^<AGD source^>  AGD source file without .agd extension (*1)
echo. 
echo    -?^|-h         This help
echo    -a            Enables adventure mode (default: off)
echo    -m            Enables metablocks mode (default: off)
echo    -c            Enables HW sprite collisions (default: off, standard AGD routine)
echo    -b            Enables ^"Pacman mode^" collectable blocks (default: off, standard AGD behaviour)
echo    -l            Enables SFX relative volume mode (default: off)
echo    -y            Enables SFX dynamic channel mode output (default: off, fixed PSG channel used)
echo    -s ^<channel^>  PSG output channel when dynamic mode is off: 1 (C), 2 (B) or 3 (C) (default:1)
echo    -f ^<Hz^>       Force TV refresh Hz in MSX2 or higher machines: 0 (machine default), 50 (50Hz), 60 (60Hz) (default mode:0)
echo    -t ^<SC2 file^> Loads a title screen (only disk based)
echo    -q ^<SC2 file^> Loads a marquee screen to be used by the game (only disk based. No video initialization at boot)
echo    -r ^<KB size^>  Cartridge (ROM) distribution. Valid KB sizes are: 16,32,48 (default size:16)
echo    -d ^<KB size^>  Disk (RAM) distribution. Valid KB sizes are: 32,48,64 (default size:32)
echo    -k ^<KB size^>  Tape (RAM) distribution. Valid KB sizes are: 32,48,64 (default size:32)
echo    -x ^<MSX type^> Launch ^<MSX type^> emulation after successful build
echo.
echo       MSX types (-x)
echo       ------------------
echo       0: None (no emulator is launched)
echo       1: MSX1 (%MSX1MACHINE%) (Default)
echo       2: MSX2 (%MSX2MACHINE%)
echo       3: MSX2+ (%MSX2PMACHINE%)
echo       4: TurboR (%MSXTRMACHINE%)
echo.
echo (*1) With no parameters, compiler defaults are:
echo.
echo       * Disk (DSK) distribution
echo       * 32KB setup
echo       * Default MSX model TV mode (eg: NTSC for japanese models or PAL for european ones) 
echo       * All flags off except emulation running set for MSX1
echo.
echo Examples: ^>build dodgy                   (builds program, creates a DSK and launches a MSX1 emulation)
echo           ^>build testbasicdig -a -x 2    (enables adventure mode, builds, creates a DSK and launches a MSX2 emulation)
echo           ^>build dodgy -t TITLE.SC2 -x 4 (builds program, adds a loading screen, creates a DSK and launches a TurboR emulation)
echo.
goto :eof

:end
