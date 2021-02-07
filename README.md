


# MSX AGD Suite
AGD suite for converting, compiling and running AGD games on an MSX machine. Right now, the generated games will work in all MSX machine types; but only MSX1 features are supported (except color palettes to some extent).

## Installation
Simply copy the files into a directory and make sure you have a couple of environment variables initialized:

**MSXEMUPATH** = Absolute directory path of your chosen emulator.

**EMU** = Name of the chosen emulator executable.

MPAGD for MSX supports the following emulators: OpenMSX, BlueMSX and fMSX (being their respective executables openmsx.exe, bluemsx.exe and fMSX.exe).
If you use OpenMSX by default, you can tune up the build.bat script to setup in the first lines which ones are your favorite MSX models used to launch games.

## ZX Spectrum AGD programs conversion
The use of **MPAGD suite v0.7.10** (https://jonathan-cauldwell.itch.io/multi-platform-arcade-game-designer) is recommended. There's also a convert tool in this suite but; right now it's not in a working status or supported.


## Building AGD programs
Usage: build \<AGD file> [-?|-h] [-a] [-m] [-c] [-l] [-s \<PSG channel>] [-f \<Hz>] [-t \<SC2 file>] [-q \<SC2 file>] [-r \<KB Size>|-d \<KB size>|-k \<KB size>] [-x \<MSX type>]

Where:

   \<AGD file>  AGD source file without .agd extension (1)

   -?|-h         This help
   -a	  Enables adventure mode (default: off)
   -m  Enables metablocks mode (default: off)
   -c   Enables HW sprite collisions (default: off, standard AGD routine)
   -b   Enables "Pacman mode" collectable blocks (default: off, standard AGD behaviour, collectables are redrawn after a screen restart)
   -l    Enables SFX relative volume mode (default: off)
   -y   Enables SFX dynamic channel mode output (default: off, fixed PSG channel used)
   -s \<channel>  PSG output channel when dynamic mode is off. Valid values are: 1 (C), 2 (B) or 3 (C) (default:1)
   -f \<Hz>       Force TV refresh Hz in MSX2 or higher machines: Valid values are: 0 (machine default), 50 (50Hz), 60 (60Hz) (default:0)
   -t \<SC2 file> Loads a title screen (only disk based)
   -q \<SC2 file> Loads a marquee screen to be used by te game (only disk based. No video initialization at boot)
   -r \<size>  Cartridge (ROM) distribution. Valid KB sizes are: 16,32,48 (default size:16)
   -d \<size>  Disk (RAM) distribution. Valid KB sizes are: 32,48,64 (default size:32)
   -k \<size>  Tape (RAM) distribution. Valid KB sizes are: 32,48,64 (default size:32)
   -x \<MSX type> Launch <MSX type> emulation after successful build

                 MSX types (-x)
                 ------------------
                 0: None
                 1: MSX1 (Default)
                 2: MSX2 
                 3: MSX2+ 
                 4: TurboR 

(1) With no parameters, compiler defaults are:

      * Disk (DSK) distribution
      * 32KB setup
      * Default MSX model TV freq (eg: 60Hz for japanese models or
        50Hz for european ones)
      * All flags off except emulation running set for MSX1

Examples: 

    >build dodgy
                
Builds dodgy.agd, creates a DSK and launches a MSX1 emulation.


    >build dodgy -r
                
Builds dodgy.agd, creates a ROM and launches a MSX1 emulation.

    >build testbasicdig -a -x 2 

Builds test.agd, enables adventure mode, creates a DSK and launches a MSX2 emulation.

    >build dodgy -t TITLE.SC2 -x 4 

Builds dodgy.agd, adds a loading screen, creates a DSK and launches a TurboR emulation).

The distribution files (DSK, CAS or ROM files), once built, are located in the home directory of the AGD suite.

### About MSX CAS files and OpenMSX

CAS tape distribution is supported but to execute these CAS files using "-x" command and OpenMSX, you must probably configure some facilities offered by this emulator: autorun and fast loading.
To enable autorun you must type in the OpenMSX console:
    
    >set autoruncassettes on 
 
Not doing this means that you'll need to type in by yourself the classic "RUN"CAS:" MSX-BASIC command.

To enable fast loading you must type in the OpenMSX console:
    
    >set fullspeedwhenloading on 
 
Not doing this means that you'll need to wait until the game loads from tape, old school gaming!.

Note that TurboR machines doesn't support cassette loading; so you won't be able to specifying this machine to execute a tape game.
  

## Differences between ZX & MSX compilers

The AGD language as MPAGD v0.7.10 defined it is fully supported but to benefit from MSX features some changes have been made to the language syntax.
The following table shows the new or modified commands:

| COMMAND | HOW IT CHANGED |
|--|--|
| BORDER | Colour between 0-15 |
| COLOUR | Format changed |
| CRUMBLE | New command |
| DEFINEOBJECT | Format changed |
| DEFINEBLOCK | Format changed |
| DEFINECONTROLS | Default keys changed |
| DEFINEMUSIC | New command |
| DEFINEPALETTE | Format changed |
| DEFINESPRITE | Format changed |
| INK | Colour between 0-15 |
| MUSIC | New command |
| PALETTE | Format changed |
| PAPER | Colour between 0-15 |
| SCREENOFF | New command |
| SCREENON | New command |
| SOUND | New command |
| SPRITEINK | Colour between 0-15 |
| SPRITEPOSITION | Format changed |
| SPRITESOFF | New command |
| THRUST | New command |

Now some brief explanations of every command above:


    DEFINEBLOCK

Now 16 values are needed (excluding the block type) to define the shape of a block: first 8 values are the pattern, the next 8 are color attribute values, one for each row.

    DEFINESPRITE

No changes to the amount of bytes used; but the arrangement is different to the one found in the ZX. The first value is the number of sprite frames; about the patterns, if you think in a 16x16 sprite divided in 8x8 areas:

AB
CD

The values must be defined following order ACBD, first the 8 bytes from area A, next the 8 bytes from C and so on for each sprite and sprite frame...

    DEFINEOBJECT

They're not sprites now!. In the MSX engine, objects are like block characters but with 16x16 size and can only be placed in coordinates multiple of 8 (they'll shown garbage if not). This is reflected in the attribute bytes that they're only 3 now: room, Y coordinate, X coordinate, they loose the ZX color attribute:

DEFINEOBJECT \<room> \<y> \<x>

Given that, the bytes used are 64 and following the above sprite example they're ordered as ABCD, the first 32 bytes being the pattern bytes and the next 32 bytes the color attributes of each 8x8 area.

    SPRITEPOSITION

One attribute is added: color of the sprite. The syntax is: 

SPRITEPOSITION \<type> \<image> \<color> \<y> \<x>

    COLOUR

The only parameter accepted is used to define both foreground and background color. You can use the formula FG*256+BG to calculate the value or use the more straightforward hexadecimal numbers (as suggested in the following section).

    SPRITEINK, INK, PAPER & BORDER

Now the value can be 0..15. Remember that 0 is transparent!.

    DEFINEPALETTE

If the MSX machine supports color palettes this feature is enabled. The default palette if you don't use the DEFINEPALETTE command is the following:

0x000,0x000,0x611,0x733,0x117,0x327,0x151,0x627
0x171,0x373,0x661,0x664,0x411,0x265,0x555,0x777

The 16 values (one color palette definition each) are defined using the GRB scheme. 

An example of use is the following:

DEFINEPALETTE	$000 $000 $611 $733 $117 $327 $151 $627 $171 $373 $661 $664 $411 $265 $555 $777

    PALETTE

As the above function, it'll only work in MSX2 or higher machines (as a matter of fact, a MSX1 machine with a V9938 can also work). It's used as follows: 

PALETTE \<color number> \<color byte definition 1> \<color definition byte 2> 

Where:

color byte definition 1: 0 R2 R1 R0 0 B2 B1 B0 (defines red and blue color values).
color byte definition 2: 0 0 0 0 0 G2 G1 G0 (defines green value).

    DEFINEMUSIC

The MSX AGD parser has an integrated music & sfx framework based in the well-known PT3 song format and ayFX sounds. You can create or use a existing PT3 file in your program doing the following:

1) Prepare the PT3 archive trimming their first 100 bytes (this kind of PT3 files are also called "extreme" and you can also find them as .p3x, they're used by the [Cold Snap audio routine](https://sourcesolutions.itch.io/coldsnap "Check Cold Snap audio page"). 
You can accomplish the above this with the provided "trim" tool: 

    trim myfavesong.pt3 100

2) Include the resulting file using DEFINEMUSIC command: 

	DEFINEMUSIC "myfavesong.pt3"

You can define until 10 different musics or jingles, numbered from 1 to 10 in the same order they're being added.

    MUSIC

Once included in your program with the define command, you can invoke the replayer using MUSIC command: 

MUSIC <0|1-10> <0|1>

The first argument plays the nth defined music from 1 to 10. Value 0 stops the playing. The second argument mean if you want to endlessly loop the music (1) or play it only once (0), eg.: a "Game Over" jingle.

    SOUND

Works the same as the already existing in AGD. It's used as follows: 

SOUND \<sound number> [\<sound priority (0-15)>]

The sound number represents the sound position inside an ayFX soundbank minus one; so if the bank has sounds 1-5, you'll use number from 0 to 4 to play them.
The sound priority is a number from 0 to 15 being 0 the highest priority and 15 the lowest one. If no priority is given, a default value of 0 is assigned (the maximum priority). 
When a sound with high priority is being played, a new one with lower priority won't be played. If the new one has higher priority will mute the first one and will be played instead.

Only one soundbank is used, named "sfx.afb" that must be located in "resources" directory. As for now, this can't be changed; but of course you can replace this sfx.afb file with your own created sound bank.

This ready-made sound bank has the following sounds:
1) Jumping
2) Explosion
3) Shoot
4) Pickup 
5) Event
6) Laser
7) Jet

ayFXEdit (https://shiru.untergrund.net/software.shtml) can be used to edit and create these banks (including the default one, of course). It's recommended to save it without sound names, you'll save some useless bytes.

    DEFINECONTROLS

Now they're the following as default (note that "default" means no DEFINECONTROLS is added to the agd source): 

 - Movement: Cursor keys 
 - Fire 1: Space 
 - Fire 2: "M" 
 - Fire 3: "N" 
 - Option 1:   "1" 
 - Option 2: "2" 
 - Option 3: "3" 
 - Option 4: "4"

When a joystick is used (1 or 2), both fire buttons are used and the third button is still mapped to the keyboard (joymega is still not supported).

    SPRITESOFF

Hides all sprites, no parameters are used. They'll remain hidden until their coordinates were updated again (as it happens every game frame, this command is only really useful when a MENU, INV or WAITKEY commands are used). 

    CRUMBLE

Crumbling blocks are supported. You must add the CRUMBLE keyword at start of event 0 (PLAYER) routine if you want crumbling blocks. There's only a block shape and its animation must be defined using blocks 9-16; so, the block frames are always 8 and can't be changed. The crumbling animation speed is also fixed, it happens every 8 frames.
Once defined its shape, you only need to use a block 9 in your map. By the way, you must assign a PLATFORMBLOCK attribute to all blocks to work as intented, clever, isn't it?.
You can find a good example in "testjump.agd" source.

    THRUST

A sprite can be moved using a rotational pattern, you can set the direction with DIRECTION variable and give it a constant impulse in pixels with this THRUST command. The direction needs a value between 0-256 that is roughly mapped to 0-360 degrees following this scheme (every 90º):

 - DIRECTION  = 0 = 180º
 - DIRECTION  = 64 = 90º
 - DIRECTION  = 128 = 0º
 - DIRECTION  = 192 = 270º
 
You can find a good example in "testthrust.agd" source.


    SCREENOFF

Disables the screen display. If you want to hide what's going on, use it. 

    SCREENON

Enables back the screen displaying. 

    METABLOCKS

And last but not least, Metablocks. This is not a keyword, what's that?. The so called metablocks are 2x2 blocks sized tiles used to build maps. Every metablock uses 4 blocks; so 64 can be defined with the full 256 blocks supported by AGD. 
Using metablocks you can save quite some RAM if your maps doesn't need the high detail when using standard blocks, a full screen (16x12 metablocks) need only 192 bytes without taking account of the compression level. 
Maps are defined referencing the first block of every metablock so right now, the known AGD map editors can't be used as they are, you must to be creative to design your map!.
Note that you can combine blocks and metablocks because only screen maps are built from metablocks, the standard blocks are still used as always by commands like PUTBLOCK.

## In-game hotkeys

    STOP key

It can't be programatically controlled; but it always works pausing the game (music still plays) until a new STOP key press releases the pause.


    SELECT key

Used to swap between 50Hz/60Hz TV refresh when available. This means that only MSX2 or higher machines will have this feature. Remember that if you change the frequency to 60Hz, the game will play a bit faster, the same goes for the music.

## TIPS & BITS

### Color conversion
When converting a ZX AGD source file, start looking for attribute color uses. You must adapt them to MSX color scheme.

Remember that a ZX color attribute byte always comes as follows:

    7 6  5  4  3  2  1  0
    F B P2 P2 P1 I0 I1 I0

- Bit 7 if set indicates the colour flashes between the foreground (ink) and background (paper) colours.
- Bit 6 if set indicates the colours are rendered bright.
- Bits 5 to 3 contain the paper (background) colour 0..7
- Bits 2 to 0 contain the ink (foreground) colour 0..7

The MSX one must be represented as follows:

     7  6  5  4  3  2  1  0
    I3 I2 I1 I0 P3 P2 P1 P0

- Bits 0 to 3 contain the paper (background) colour 0..15
- Bits 4 to 7 contain the ink (foreground) colour 0..15

Hexadecimal numbers are supported so it's usually the easiest way to represent a color attribute, eg.: COLOUR $F1 (ink 15 & paper 1)

### Engine FPS 
The FPS (frames per second not first person shooter :-P) of the MSX engine double the number of the generated by the ZX engine (50fps against 25fps); so you must be extremely careful with variables used as timers (to animate sprites or timed actions) that are increment every "loop" or frame. You can usually find them in events MAINLOOP1 and MAINLOOP2 and once identified you must probably double it's values. Of course you need also to look for them in the rest of the source (usually as "IF variable = value" expressions) and evaluate if they need to be adapted.
As the ZX engine moved the sprites 2px at a time, now they're only moved 1px every executed move command so the action is smoother. As an undesired effect, now it's hard to place a sprite in position (eg.: a main character under a stair).

### Sprite colors
SPRITEINK commands are not needed...or mostly not. Sprites now have a color attribute defined in SPRITEPOSITION commands so they don't need to dinamically being assigned. They could be useful if you want to change sprite colors during the game or color a newly created sprite with SPAWN.

### Text colors
Use COLOUR instead INK & PAPER when possible. It's faster and uses less RAM.

### Locating cursor
Use AT command instead LINE & COLUMN. It's faster and uses less RAM. After a printing command has been executed, the COLUMN is always updated but the LINE remains the same (if you haven't reached the rightmost edge of the screen) so if you want to print more texts think if it's enough to update only a variable, LINE or COLUMN, this way you can keep saving more bytes and gaining again a little speed.

### Beware MAINLOOPs
AVOID use of printing commands in MAINLOOP events (eg.: scoreboards). Of course you must need to print something; but look for alternatives or ways to reduce its use to a minimum, don't keep printing every frame the same text over and over again. The MSX texts color printing is heavy.

### Waiting for a key
WAITKEY right now doesn't returns the key pressed.

### TICKER routine workaround
TICKER routine only updates every frame when a loop is completed. If you're in an infinite loop (eg.: in a WHILE/ENDWHILE conditional loop) and you want to see the TICKER being updated, you'll need to invoke a DELAY inside the loop. Use "DELAY 1" and it's enough...

### TICKER with colors
TICKER routine doesn't update at all the color table; but you can setup the scrolling area before the ticker routine starts. Print anything you want with the same size of the scroll area and the desired colors, the scroll will be automagically colored!. Use blocks and you can even get some nice multicolor scrolling. 

### MSX Turbo CPUs
The MSX turbo enabled machines, some MSX2+ and MSX2 machines, automatically activate this feature. The TurboR machines also use the R800 ROM mode by default and thus are the fastest machines (all the events code is processed much faster), this can have influence over the pitch of the beeper commands.

### MSX color palettes
In MSX2 and higher machines, the palette routine works so you can define your own color palette.

### Sprite planes priorities
The order used when defining the screen sprites also determines the priority plane it uses. First SPRITEPOSITIONS are placed in higher priority planes than the last ones, this can change if you use REMOVE & SPAWN commands.

### Particles
Try to not to abuse also of particles, several particle sources can easily overhead the frame process time causing slowdowns to some extent. The dynamic v-syncing will help to minimize this but definitely, use them wisely.

## Advanced Topics

### AGD Flow Chart

Here's a simplified AGD events flow chart. Try to understand it works and you'll get a useful understanding on how AGD works:

![enter image description here](https://github.com/jltursan/AGD-MSX-Suite/blob/master/Suite%20MSX/docs/AGD%20Flow%20Chart.png)

## Extra tools
The MSX suite comes with some extra tools I've added:

- FontConverter; Java executable that allows to convert a 64c font file (Commodore 64) to a chr AGD loadable font.
- ZXAttributeConverter: Simple tool to convert a ZX color attribute value to its MSX1 equivalent.
- trim: Script to trim ending bytes of a file. Already explained above.

## Acknowledgements
Sjasm - XL2S Entertainment (http://www.xl2s.tk/)
ONEDRIVE v1.0 - Adriano Camargo Rodrigues da Cunha (http://www.alsoftware.com.br/adrianpage/), sadly his page is not available anymore...

wrdsk v1.6 - Arnold Metselaar (http://www.math.utwente.nl/~metselaa/msx/diskutil.html). Also not available but you can find a mirror here: (https://github.com/clach04/msx_diskutil)

split - from CoreUtils for Windows suite (http://gnuwin32.sourceforge.net/packages/coreutils.htm)

mcp v0.2.0 - Álvaro Polo "Apoloval" (https://github.com/apoloval/mcp)
