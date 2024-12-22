	.TITLE	Spare Time Gizmos VIS1802 Video Terminal Firmware
	.SBTTL	Bob Armstrong [24-APR-2024]



;   888     888 8888888 .d8888b.   d888   .d8888b.   .d8888b.   .d8888b.  
;   888     888   888  d88P  Y88b d8888  d88P  Y88b d88P  Y88b d88P  Y88b 
;   888     888   888  Y88b.        888  Y88b. d88P 888    888        888 
;   Y88b   d88P   888   "Y888b.     888   "Y88888"  888    888      .d88P 
;    Y88b d88P    888      "Y88b.   888  .d8P""Y8b. 888    888  .od888P"  
;     Y88o88P     888        "888   888  888    888 888    888 d88P"      
;      Y888P      888  Y88b  d88P   888  Y88b  d88P Y88b  d88P 888"       
;       Y8P     8888888 "Y8888P"  8888888 "Y8888P"   "Y8888P"  888888888  
;
;          Copyright (C) 2024 By Spare Time Gizmos, Milpitas CA.

;++
;   This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
; for more details.
;
;   You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;--
;0000000001111111111222222222233333333334444444444555555555566666666667777777777
;1234567890123456789012345678901234567890123456789012345678901234567890123456789

	.MSFIRST \ .PAGE \ .CODES

	.NOLIST
	.LIST
	
	.SBTTL	VIS1802 Overview

;++
;   The VIS1802 is a stand alone serial ASCII terminal based on the CDP1802
; CPU and the RCA CDP1869/1870/1876 VIS chip set.  The VIS generates a 40x24
; character text display or an 240x192 pixel graphics display with up to eight
; colors.  The display scan rate is 15750Hz horizontal and 60Hz vertical with
; either NTSC/PAL color encoding (using the CDP1870 chip) or RGB TTL colors
; (using the CDP1876 chip).
;
;   The VIS text font uses a 6x8 pixel glyph with either 64 upper case only,
; or 128 upper and lower case characters.  The font is contained in RAM and is
; loaded from EPROM at startup, and custom font glyphs may be downloaded later.
; The 64 character font can display two different text colors simultaneously,
; but the 128 character font can display only one.  The background color may be
; selected from a palette of eight colors independently of the foreground
; color(s).  The 128 character font also contains 32 special graphics
; characters which may be selected with the appropriate escape sequence.
;
;   The VIS1802 uses a CDP1854 UART and a CDP1861 baud rate generator.  It can
; operate at all standard rates from 110 to 9600bps, and can use either CTS/DTR
; hardware flow control or XON/XOFF software flow control.  A PS/2 keyboard is
; used for input, and an AT89C4051 auxiliary processor decodes the PS/2
; prototocol to generate ASCII key codes.  The VIS chipset contains a sound
; generator that can play simple musical tunes.
;
;   The VIS1802 firmware also contains a copy of the RCA BASIC3 interpreter and
; can operate in local mode as a stand alone BASIC computer.  Up to 28K of RAM
; is available to BASIC for storing programs and data, and programs can be
; uploaded to or downloaded from a host computer over the serial port using the
; XMODEM protocol.  The VIS1802 BASIC has been extended to include functions
; that allow input and output to be redirected to either the serial port or to
; the PS/2 keyboard and VIS display.
;
;   BASIC has also been extended with graphics functions to plot points and
; draw lines.  A BASIC PLAY statement allows playing of simple music using the
; VIS sound generator, and the BASIC TIME and WAIT functions keep track of the
; time of day using VRTC interrupts.   And lastly, a BASIC KEY function allows
; for non-blocking console input from either the serial port or PS/2 keyboard.
;--
	.SBTTL	Revision History

;++
; 001	-- Start by stealing from the SBC1802 project!
;
; 002	-- Implement basic POST for EPROM, RAM and SLU.
;
; 003	-- Implement interrupt driven buffered I/O for serial port.
;
; 004	-- Can't use OUTI() in an ISR!   (because P != R3)
;
; 005	-- Add basic console I/O functions stolen from SBC1802.
;
; 006	-- Add 16 bit multiply and divide routines.
;
; 007	-- Add basic command scanner and examine/deposit commands.
;
; 008	-- Add basic help.
;
; 009	-- Add blinking cursor, cursor functions and basic cursor motions.
;
; 010	-- Add screen/line erase functions.
;
; 011	-- Add scrolling functions.
;
; 012	-- Add advanced cursor motions and control character dispatch.
;
; 013	-- Add escape sequence state machine.
;
; 014	-- Normal character output.
;
; 015	-- Fix up LDFONT to support colors.
;
; 016	-- Add COLORS table and <ESC>b to set foreground colors.
;
; 017	-- Add <ESC>b to set the foreground colors.
;
; 018	-- ERASE screws up the colors (because it resets the COLB0/1 bits!)
;
; 019	-- Add <ESC>c to set background color.
;
; 020	-- BELL needs to call SELIO0!
;
; 021	-- Make SERGET and SERPUT preserve T1 (trashing it breaks several
;	   things, including DELETE/BACKSPACE and ^U in READLN).
;
; 022	-- Change P1 ro RE and AUX to RF, and use AUX.1 (not AUX.0) to save
;	   and restore D in SCRT and other places.  This is for compatibility
;	   with RCA BASIC!
;
; 023	-- Fix up TFCHAR to let <CR> pass unmolested.
;
; 024	-- Add keyboard interrupt service and circular buffer.
;
; 025	-- Add extended key code to VT52 escape sequence translation.
;
; 026	-- SERPUT screws up the stack if the buffer is full!
;
; 027	-- Add SERINI to initialize the serial port according to the switches.
;
; 028	-- Add VISINI to initialize the VIS (steal the code from the current
;	   startup).
;
; 029	-- Add splash screen display for startup.
;
; 030	-- Change around startup messages to fit a 40 column screen.
;	   Change EXAMINE to only show 8 bytes per line (for 40 columns!).
;
; 031	-- Add <ESC> = and <ESC> > (select alternate/numeric keypad).
;
; 032	-- Remove unused code - TVERSN, TDEC16, MUL16, DIV16.
;
; 033	-- Add <ESC> lower case letter for non-standard (i.e. non-VT52) escape
;	   sequences.  Add hide cursor/show cursor sequences.
;
; 034	-- Add CONGET/CONPUT/CONECHO/CONBRK vectors in RAM.  Add SIN/SOUT/TIN
;	   /TOUT and RSTIO routines to set the console input/output vectors.
;
; 035	-- Change TFCHAR to TFECHO and use it just for echoing user input.  Add
;	   TECHO to call CONECHO rather than CONPUT. All this so that user input
;	   will echo to a sensible place.
;
; 036	-- Make TFECHO echo <CR> as <CRLF> and <BS> literally.
;
; 037	-- SELIO1/0 needs to preserve T1 so that RSTIO can be called directly
;	   from BASIC.  Add entry point for "DEFCON" to restore the console 
;	   redirection to the default.
;
; 038	-- Add XMODEM code from SBC1802, along with XSAVE/XLOAD commands.
;
; 039	-- XWRITE shouldn't do INC P3 - bug from ERAM replacement!
;
; 040	-- Add conditionals to make BASIC optional.
;
; 041	-- Change TFECHO back to echo <CR> as just <CR>.  BASIC needs it!
;
; 042	-- Add PLAY, PNOTE, et all to play simple music w/CDP1869.
;
; 043	-- Add ODE command to play a demo tune.
;
; 044	-- Add GERASE, XYTORC and PLOT for really basic graphics.
;
; 045	-- Add HLINE and VLINE for those two (easy) special cases.
;
; 046	-- Finally add LINE1, LINE2 and LINE for arbitrary lines!
;
; 047	-- LINE1/LINE2 needs to be more careful about checking for D < 0.
;
; 048	-- Make LTRIM return on <CR>, <LF> or <ESC> for BASIC.
;
; 049	-- Add BASIC callbacks for GMODE, PLOT, LINE and PLAY.
;
; 050	-- ENACURS/DSACURS needs to save T2 for BASIC ...
;
; 051	-- GMODE should always set HMA to zero, and TMODE needs to call
;	    UPDTOS to reset HMA according to the text scrolling.
;
; 052	-- Remove BRSTIO - the regular RSTIO works fine.
;
; 053	-- If the UART receives a character and the RXBUF is full, the SLUISR
;	    still needs to read the SLUBUF.  Otherwise DA never clears and the
;	    IRQ never goes away!
;
; 054	-- Add UPTIME 32 bit counter to count total VRTC ticks since reset.
;
; 055	-- Add BASIC BKEY, BWAIT, and BTIME callbacks.
;
; 056	-- Changes for rev 1B PCBs - eliminate video mode register, add PCB
;	    and CTS bits to flags register.
;
; 057	-- Add hardware (CTS) flow control.  Note that this works only for
;	    receiving data from the host - we still don't support flow control
;	    for transmitting to the host (RTS) !
;
; 058	-- In GERASE, set each byte to the default foreground color, not $00.
;
; 059	-- Add XON/XOFF flow control.  Like CTS flow control, this only works
;	    for receiving data from the host.
;
; 060	-- Change SERINI so that SW4 ON selects 7E1 format, SW4 OFF selects
;	    8N1.  SW5 ON selects XON/XOFF flow control, and SW5 OFF selects CTS.
;
; 061	-- VTPUTC needs to return with DF=0 (otherwise CONPUT will loop!).
;
; 062	-- Implement <ESC>g (graphics screen), <ESC>t (text screen), and
;	    <ESC>e (erase graphics screen).
;
; 063	-- Make VTPUTC trim all characters, EXCEPT the subsequent bytes of
; 	    escape sequences, to 7 bits.
;
; 064	-- Firmware crashes when we receive a null!  There's a missing
;	    "SEX SP" in VTPUTC.
;
; 065	-- Clear graphics memory on startup too
;
; 066	-- Always set the HMA register to zero when entering grpahics mode,
;	   and reset HMA to TOPLIN when switching back to text mode.
;
; 067	-- Switch back to text mode when any character is output via VTPUTC,
;	   EXCEPT for escape sequences (so that we can have escape sequences
;	   that draw graphics!).
;
; 068	-- Clear graphics memory on startup.
;
; 069	-- Re-order the ISR code to check for video interrupts last.
;
; 070	-- Since any VTPUTC switches back to text mode, make the GRAPHICS and
;	   GTEST commands wait for input before returning (otherwise the ">>>"
;	   prompt immediately switches up back to text!).
;
; 071	-- Make FONTSIZE a Makefile parameter.  Add CPUCLOCK assembly option
;	   to the Makefile also.  Add option for 3.579545MHz CPU clock.
;
; 072	-- Add NOTES table for 5.579545MHz clock.
;--
VERMAJ	.EQU	1	; major version number
VEREDT	.EQU	72	; and the edit level

; TODO LIST!
;  * Add graphics functions via serial port - <ESC>e, g, l, and p
;  * support for setting colors in graphics mode
;  * play music via escape sequences
;  * really slow (the effective baud rate is about 300!)
;  * Add auto newline <ESC>v and w.
;  * Distinguish between auto new line and auto line wrap?
;    Auto newline means that whenever the terminal receives a <CR> it
;      automatically adds an <LF> as well.  Unfortunately, if we receive <CRLF>
;      then the text is double spaced!
;    Auto line wrap means that when receiving text and the cursor hits the
;      right edge of the screen, the cursor automatically wraps around to the
;      left edge of the next line.   If auto line wrap is disabled then the
;      cursor "sticks" at the right edge and subsequent characters just
;      overwrite until a <CRLF> is received.
;    Currently the code DOES auto line wrap and DOES NOT do auto new line!
;  * Add keyboard shortcuts (function keys?) to flip between text and graphics
;  * Put BOTH 64 and 128 character fonts in ROM and add escape sequences to
;    switch between them
;  * downloadable fonts, sprites, etc
;  * Use the second PMEM page as the BASIC text display.  Now we can have BOTH
;    the remote terminal AND BASIC in local mode active at the same time.  Add
;    Keyboard shortcut to switch between BASIC and terminal modes.
;  * The set color sequences need to hide/show the cursor.
;  * Expect an 1805 CPU and try to speed up the code by replacing the macros
;    with built-in 1805 instructions, especially RLDI, SCAL, SRET, etc.
;  * See if we can't improve performance by queueing up simple screen updates
;    (e.g. ones which only increment the cursor) during the VBI.

	.SBTTL	Hardware Definitions

; Memory layout ...
ROMBASE	 .EQU $0000	   	; EPROM starts at $0000
ROMSIZE  .EQU $8000	   	;  ... and the EPROM is 32K bytes
ROMEND	 .EQU ROMBASE+ROMSIZE-1	;  ... address of the last byte in EPROM
CHKSUM	 .EQU ROMBASE+ROMSIZE-2	; EPROM checksum tored in the last two bytes
BASIC	 .EQU $4000		; BASIC interpreter start address
HLPTXT	 .EQU $7800		; help text stored here in EPROM
RAMBASE	 .EQU $8000	   	; RAM starts at $8000
RAMSIZE  .EQU $7000	   	;  ... RAM is only 28K (because of the VIS!)
RAMEND   .EQU RAMBASE+RAMSIZE-1	;  ... address of the last byte in RAM
DPBASE   .EQU RAMEND-512+1   	; our data occupies the last two pages in RAM
PAGEMEM	 .EQU $F800		; start of VIS text buffer memory
CHARMEM  .EQU $F400		; start of the VIS font memory 

; I/O ports implemented on the VIS1802 ...
;   Note that the FLAGS port works the same in either I/O group 0 or 1, the
; VISIRQR port is in group 0, and all other ports are in I/O group 1.
FLAGS	.EQU	1	; flags register
VISIRQR	.EQU	2	; reset VIS interrupt request
SLUBUF	.EQU	2	; CDP1854 UART data register
SLUCTL	.EQU	3	; CDP1854 UART control register
SLUSTS	.EQU	SLUCTL	; CDP1854 UART status register
DIPSW	.EQU	4	; DIP switches
KEYDATA	.EQU	5	; PS/2 keyboard data buffer
SLUBAUD	.EQU	6	; CDP1863 baud rate generator

; Standard EF flag assignments for the VIS1802 ...
#define  B_KEYIRQ  B1	; branch on keyboard interrupt
#define BN_KEYIRQ  BN1	;  ...
#define  B_DISPLAY B2	; branch on VIS PREDISPLAY interrupt
#define BN_DISPLAY BN2	;  ...
#define  B_SLUIRQ  B3	; branch on SLU interrupt
#define BN_SLUIRQ  BN3	;  ...
#define  B_GROUP1  B4	; branch if I/O group 1 selected
#define  B_GROUP0  BN4	;   "    "   "    "   0   "  "

; Turn the Q "POST OK" LED on or off ...
#define LED_ON  SEQ	; ...
#define LED_OFF REQ	; ...

; FLAGS register definitions ...
;   The FLAGS register is two 73HC73 flip flops that implement four control
; bits - I/O GROUP, GRAPHICS MODE, CTS, and PCB.  Since these are J-K flip
; flops, any bit can be set, reset, or toggled independently of the others.
FL.IO1	.EQU	$01	; select I/O group 0
FL.IO0	.EQU	$02	;   "     "    "   1
FL.GRAP	.EQU	$04	; select graphics mode
FL.TEXT	.EQU	$08	;   "    text      "
FL.CCTS	.EQU	$10	; deassert RS-232 clear to send
FL.SCTS	.EQU	$20	; assert     "      "    "   "
FL.PCB1	.EQU	$40	; set the CDP1870 page color bit
FL.PCB0	.EQU	$80	; clear "    "     "     "    "

	.SBTTL	VIS Chipset Defintions

; VIS CDP1870/76 color/control port ...
;   Note that, unlike all the other VIS registers, this one is only 8 bits ...
VISCOLR	.EQU	3	; standard VIS port address
VC.HRES   .EQU	  $80	;   1 -> 40 characters/row, 0 -> 20 characters/row
VC.COLBG  .EQU	  $40	;   CCB0/1 controls BLUE/GREEN
VC.COLRG  .EQU	  $20	;   CCB0/1 controls RED/GREEN
VC.COLRB  .EQU	  $00	;   CCB0/1 controls RED/BLUE
VC.DOFF   .EQU	  $10	;   1 -> display OFF, 0 -> display ON
VC.CFC    .EQU	  $08	;   color format control
VC.BKGR   .EQU	  $04	;   background color RED bit
VC.BKGB   .EQU	  $02	;    "     "     "   BLUE
VC.BKGG   .EQU	  $01	;    "     "     "   GREEN 

; VIS CDP1869 tone generator port ...
;   Note that this register is 16 bits!!
VISTONE	.EQU	4	; standard VIS port address
VT.AMPL   .EQU    $000F	;   tone amplitude control
VT.FSEL   .EQU	  $0070	;   frequency (octave) divider
VT.TOFF   .EQU	  $0080	;   1 -> tone off
VT.TDIV   .EQU	  $7F00	;   tone divisor mask
VT.BELL   .EQU	  $313F	;   440Hz, full volume

; VIS CDP1869 noise/configuration port ...  16 bits!
VISCONF	.EQU	5	; standard VIS port address
VN.NOFF   .EQU	  $8000	;   1 -> noise off
VN.FSEL   .EQU	  $7000	;   frequency (octave) divider
VN.AMPL   .EQU	  $0F00	;   noise amplitude control
VN.VRES   .EQU	  $0080	;   1 -> 24 rows/screen, 0 -> 12 rows/screen
VN.DPAG   .EQU	  $0040	;   1 -> 2K PMEM, 0 -> 1K PMEM
VN.16LF   .EQU	  $0020	;   1 -> 16 scan lines per font glyph
;   Note that the datasheet calls this next bit "9-line" but that's misleading
; because it's active low.  SETTING this bit gets you 8 lines per font glyph!
VN.8LF    .EQU	  $0008	;   1 -> 8 lines per glyph, 0 -> 9 lines/glyph
VN.CMEM   .EQU	  $0001	;   1 -> enable CMEM access mode, 0 -> normal
; Our default configuration is noise off, 24 rows, SINGLE page, 8 line fonts...
;   Yes, we only use a single page even though the VIS1802 board has 2K memory
; for the PMEM.  The extra 1K doesn't do us any good for a 40x24 display, and
; it just makes the scrolling computations more complicated.
VN.MODE	.EQU	VN.NOFF+VN.VRES+VN.8LF

; VIS CDP1869 PMA and HMA ports ...  16 bits each!
VISPMA	.EQU	6	; page memory address register
VISHMA	.EQU	7	; home memory address register

	.SBTTL	CDP1854 and CDP1863 Definitions
	
; CDP1863 baud rate generator definitions ...
;   The CDP1863 is a simple 8 bit programmable "divide by N" counter.  It's
; clocked by a 2.4576Mhz oscillator, and has an built in divide by 16 prescaler.
; Remember that the CDP1854 requires a 16x baud rate clock, so that gives us
; the simple formula DIVISOR = 9600/BAUD - 1 ...
#define BAUD_DIVISOR(b)	((9600/b)-1)

; CDP1854 status register bits ...
SL.THRE	.EQU	$80	; transmitter holding register empty
SL.TSRE	.EQU	$40	; transmitter buffer register empty
SL.PSI	.EQU	$20	; peripheral status interrupt
SL.ES	.EQU	$10	; extra status (RTS on the SBC1802)
SL.FE	.EQU	$08	; framing error
SL.PE	.EQU	$04	; parity error
SL.OE	.EQU	$02	; overrun error
SL.DA	.EQU	$01	; received data available

; CDP1854 control register bits ...
SL.TR	.EQU	$80	; transmit request (unused on SBC1802)
SL.BRK	.EQU	$40	; set to force transmit break
SL.IE	.EQU	$20	; interrupt enable
SL.WL2	.EQU	$10	; select number of data bits (5..8)
SL.WL1	.EQU	$08	;   "      "     "   "    "
SL.SBS	.EQU	$04	; set to select 1.5/2 stop bits
SL.EPE	.EQU	$02	; set for even parity
SL.PI	.EQU	$01	; set to inhibit parity
SL.8N1	.EQU	SL.WL2+SL.WL1+SL.PI	; select 8N1 format
SL.7E1	.EQU	SL.WL2+SL.EPE		; select 7E1 format

; Special ASCII control characters that get used here and there...
CH.NUL	.EQU	$00	; control-shift-@
CH.CTC	.EQU	$03	; control-C (abort command)
CH.BEL	.EQU	$07	; control-G (ring bell)
CH.BSP	.EQU	$08	; control-H (backspace)
CH.TAB	.EQU	$09	; control-I (horizontal tab)
CH.LFD	.EQU	$0A	; control-J (line feed)
CH.FFD	.EQU	$0C	; control-L (form feed)
CH.CRT	.EQU	$0D	; control-M (carriage return)
CH.CTO	.EQU	$0F	; control-O (suppress output)
CH.XON	.EQU	$11	; control-Q (resume output)
CH.CTR	.EQU	$12	; control-R (retype input)
CH.XOF	.EQU	$13	; control-S (pause output
CH.CTU	.EQU	$15	; control-U (erase input)
CH.ESC	.EQU	$1B	; control-[ (escape)
CH.DEL	.EQU	$7F	; rubout (delete)

; XMODEM protocol special characters ...
CH.SOH	.EQU	$01	; start of a data block
CH.EOT	.EQU	$04	; end of file
CH.ACK	.EQU	$06	; packet received OK
CH.NAK	.EQU	$15	; packet not OK - retransmit
CH.SUB	.EQU	$1A	; filler for partial data blocks

	.SBTTL	Software Configuration

; Configuration options ...
MAXCOL	  .EQU	40		; characters displayed per row
MAXROW	  .EQU	24		; rows displayed per screen
PAGESIZE  .EQU  MAXCOL*MAXROW	; number of characters in the page RAM
PAGEEND	  .EQU	PAGEMEM+PAGESIZE; end of screen RAM
HERTZ	  .EQU	60		; VISISR interrupt frequency
SCANLINES .EQU	 8		; scan lines per font glyph
CMDMAX	  .EQU	64		; maximum command line length
BELLTIME  .EQU  HERTZ/2		; delay (in VISISR ticks) for ^G bell
BLINKTIME .EQU	250		; delay in milliseconds when blinking the LED
DEFFORCLR .EQU  $C0		; default CCB1/0 for forground font
DEFALTCLR .EQU  $00		; default CCB1/0 for alternate font
DEFBCKCLR .EQU  $00		; default screen background color


; Primary and alternate (graphics) character set definitions ...
;   For a 64 character font, we store four copies of the character set.  The
; first two are the primary character set, and the second two are the alternate
; set.  And in each pair, the first one is normal and the second is reverse
; video.
;
;   For the 128 character font, there's only the normal and reverse video set.
; The alternate character set is implemented in the code by using the glyphs
; from 0..0x1F in the character set.
	.IF (FONTSIZE == 64)
BLANK	  .EQU	0	; character code used for blank spaces
RVVBIT    .EQU $80	; bit we set for reverse video
ACSBIT    .EQU $40	; bit we set for the alternate character set
	.ENDIF
	.IF (FONTSIZE == 128)
BLANK	  .EQU	' '	; character code used for blank spaces
RVVBIT	  .EQU $80	; bit we set for reverse video
ACSBIT	  .EQU $FF	; this is just a flag, not a bit mask
	.ENDIF
; And in either event, the cursor just toggles the reverse video bit ...
CURSBIT	  .EQU RVVBIT	; bit we toggle for the cursor
RVVMASK	  .EQU $3F	; mask for inverting all font bits


; Buffer size definitions ...
;   Be sure to read the comments in the circular buffer routines and on the
; page where the buffers are allocated before you change these!  They aren't
; arbitrary values!
RXBUFSZ	 .EQU	 64	; serial port receiver buffer size
RXSTOP	 .EQU	 48	;  ... send XOFF/clear CTS when RXBUF has .GE. 48 chars
RXSTART	 .EQU	 16	;  ... send XON/assert CTS when RXBUF has .LE. 16 chars
TXBUFSZ	 .EQU	 32	; serial port transmitter buffer size
KEYBUFSZ .EQU    16	; PS/2 keyboard buffer size

; XMODEM protocol constants ..
XDATSZ	.EQU	128	; data (payload) size in XMODEM record
XPKTSZ	.EQU	XDATSZ+5; overall XMODEM packet size (header+data)
XTIMEO	.EQU	5000	; protocol timeout, in 2ms units (10s)

;   Special key codes sent by the PS/2 APU whenever function, arrow, keypad,
; or other special keys are pressed.  There are actually a lot of these, but
; most are just translated to VT52 escape sequences.  These are just the ones
; we handle specially.
KEYBREAK .EQU	$80	; PAUSE/BREAK key
KEYMENU	 .EQU	$95	; MENU key
KEYUP	 .EQU	$90	; UP ARROW key
KEYDOWN	 .EQU	$91	; DOWN ARROW key
KPENTER	 .EQU	$AF	; KEYPAD ENTER key
KEYVERS  .EQU	$C0	; mask for APU version number

; Standard register mnemonics ...
PC0	.EQU	0	; PC register for initialization
DMAPTR	.EQU	0	; register used for DMA
INTPC	.EQU	1	; PC register for interrupt service
SP	.EQU	2	; stack pointer
PC	.EQU	3	; normal PC register after startup
CALLPC	.EQU	4	; PC register dedicated to the CALL routine
RETPC	.EQU	5	; PC register dedicated to the RETURN routine
A	.EQU	6	; call linkage register
;   Note that the registers BASIC does NOT need preserved are RA, RC, RD
; and RE.  The assignments below are selected so that those correspond to
; our T1, P1, P2 and P3 (although not necessarily in that order!) ...
T1	.EQU	$A	; the first of 4 temporary registers
T2	.EQU	8	;  "  second " "   "   "     "   "  
T3	.EQU	9	;  "  third  " "   "   "     "   "  
T4	.EQU	7	;  "  fourth " "   "   "     "   "
P1	.EQU	$E	; first of 3 parameter/permanant registers
P2	.EQU	$D	; second " "	"		"
P3	.EQU	$C	; third  " "	"		"
P4	.EQU	$B	; and fourth...
AUX	.EQU	$F	; used by SCRT to preserve D

	.SBTTL	General Macros

; Advance the current origin to the next page...
#define PAGE		.ORG ($ + $FF) & $FF00

; Return the high and/or low bytes of a 16 bit value...
#define HIGH(X)		(((X)>>8) & $FF)
#define LOW(X)		( (X)     & $FF)

; Make a 16 bit word out of two 8 bit bytes ...
#define WORD(x)		((x) & $FFFF)
#define MKWORD(H,L)	((H)<<8) | (L))

; Macros for some common BIOS functions...
#define OUTSTR(pstr)	RLDI(P1,pstr)\ CALL(TSTR)
#define OUTCHR(c)	LDI c\ CALL(TCHAR)

;   INLMES() simply prints out an ASCII string "in line", which saves us the
; trouble of defining a label and a .TEXT constant for OUTSTR().  The catch
; is that TASM HAS A 16 CHARACTER LIMIT ON THE LENGTH OF A MACRO ARGUMENT!
; That's not many when it comes to messages, so use INLMES with caution...
#define	INLMES(str)	CALL(TMSG)\ .TEXT str \ .BYTE 0

;   Annoyingly, the 1802 has no instructions to explicitly set or clear the
; DF flag which, since we often use that as a way to return a true/false result,
; would have been really handy!  To fix that, we'll invent our own.  Note that
; these do not actually change the current contents of D!
#define CDF	ADI 0
#define SDF	SMI 0

;   The standard assembler defines the mnemonics BL (branch if less), BGE
; (branch if greater or equal), etc.  These all simply test the DF flag and
; are normally used after a subtract operation.  These are all short branches
; however, and while there are equivalent long branch instructions that also
; test DF, those don't have these same mnemonics.  Let's fix that...
#define LBPZ	LBDF
#define LBGE	LBDF
#define LSGE	LSDF
#define LBM	LBNF
#define LBL	LBNF
#define LSL	LSNF

;   This delay macro is calculated based on a 2.835MHz clock frequency.  Each
; major cycle (8 clocks) requires 2.821us, and a two millisecond delay needs
; exactly 708.75 major cycles.  The following loop uses 4 major cycles per
; iteration, so a count of 176 gives 704 clocks.  Adding in two more for the
; LDI and three more for the final NOP gives us a grand total of 709.  That's
; as close as we're gonna get!
;
;  There's an alternative constant here calculated for a 3.579545MHz CPU 
; crystal instead.  That gives a major cycle of 2.235us, so a two millisecond
; delay needs 894.89 major cycles.  That gives a loop count of 223 for 892
; cycles, and the final NOP gives 3 more for a total of 895 cycles.  That's
; pretty close!
	.IF	CPUCLOCK == 2835000
DLYCONS	.EQU	176		; magic constant for 2mS at 2.835MHz
	.ENDIF
	.IF	CPUCLOCK == 3579545
DLYCONS	.EQU	223		; magic constant for 2ms at 3.579545MHz
	.ENDIF
#define DLY2MS	LDI DLYCONS\ SMI 1\ BNZ $-2\ NOP

; Enable and disable interrupts (P = PC) ...
#define ION	SEX PC\ RET\ .BYTE (SP<<4) | PC
#define IOFF	SEX PC\ DIS\ .BYTE (SP<<4) | PC

;   This macro does the equivalent of an "OUT immediate" instruction with the
; specified port and data.  It assumes the P register is set to the PC.
#define	OUTI(p,n)	SEX PC\ OUT p\ .BYTE n

; Standard subroutine call and return macros...
#define CALL(ADDR)	SEP CALLPC\ .WORD ADDR
#define RETURN		SEP RETPC

;   Push or pop the D register from the stack.  Note that POPD assumes the SP
; is in the usual position (pointing to a free byte on the TOS) and it does the
; IRX for you!  That's because 1802 stack operations are BOTH pre-increment AND
; pre-decrement, which doesn't work out so well. 
#define PUSHD		STXD
#define POPD		IRX\ LDX

	.SBTTL	16 Bit Register Operations

;   Register load immedate.  RLDI is exactly equivalent to the 1805 instruction
; by the same name.
#define RLDI(R,V)	LDI HIGH(V)\ PHI R\ LDI LOW(V)\ PLO R
#define RLDI2(R,H,L)	LDI (H)\ PHI R\ LDI (L)\ PLO R

; Clear a register...
#define RCLR(R)		LDI $00\ PHI R\ PLO R

;   Register load via pointer.   RLXA is exactly equivalent to the 1805
; instruction by the same name, but there is no equivalent for RLDA.
#define RLDA(R,N)	LDA N\ PHI R\ LDA N\ PLO R
#define RLXA(R)		LDXA \ PHI R\ LDXA \ PLO R

;   Copy the 16 bit source register to the destination. Note that the closest
; equivalent 1805 operation would be RNX - copy register N to register X.
; Unfortunately the 1802 has no "PLO X" or "PHI X" operation, so there's no way
; to emulate that exactly.
#define RCOPY(D,S)	GHI S\ PHI D\ GLO S\ PLO D

;   Push a 16 bit register on the stack.  Note that RSXD and PUSHR are exactly
; the same - the PUSHR mnemonic is just for convenience.
#define RSXD(R)		GLO R\ STXD\ GHI R\ STXD
#define PUSHR(R)	RSXD(R)

;   Pop a 16 bit register from the stack.  Note that POPR is exactly the same
; as RLXA - the POPR mnemonic is just for convenience.  Unfortunately the 1802
; stack operations are BOTH pre-increment and pre-decrement, which doesn't work
; out so well.  POPR/RLXA always needs to be preceeded by an IRX, and also the
; LAST pop operation needs to do an LDX rather than LDXA (or else you need to
; stick a DEC SP in there somewhere).  That's why POPRL exists.
#define POPR(R)		RLXA(R)
#define POPRL(R)	LDXA\ PHI R\ LDX\ PLO R

; Decrement register and branch if not zero ...
#define DBNZ(R,A)	DEC R\ GLO R\ LBNZ A\ GHI R\ LBNZ A

; Shift a sixteen bit register left 1 bit (with or w/o carry in) ...
#define RSHL(R)		GLO R\ SHL\  PLO R\ GHI R\ SHLC\ PHI R
#define RSHLC(R)	GLO R\ SHLC\ PLO R\ GHI R\ SHLC\ PHI R

; Shift a sixteen bit register right 1 bit (with or w/o carry in) ...
#define RSHR(R)		GHI R\ SHR\  PHI R\ GLO R\ SHRC\ PLO R
#define RSHRC(R)	GHI R\ SHRC\ PHI R\ GLO R\ SHRC\ PLO R

; Double precision add register S to register D (i.e. D = D + S) ...
#define DADD(D,S)	GLO D\ STR SP\ GLO S\ ADD\ PLO D\ GHI D\ STR SP\ GHI S\ ADC\ PHI D

; Double precision subtract register S from register D (i.e. D = D - S) ...
#define DSUB(D,S)	GLO S\ STR SP\ GLO D\ SM\  PLO D\ GHI S\ STR SP\ GHI D\ SMB\ PHI D

	.SBTTL	RAM Storage Map

;++
;   This page defines all the RAM locations we use.  It's important that the
; only thing you put here are .BLOCK statements and not any actual code or
; data, because the .HEX file generated by assembling this file gets programmed
; into the EPROM and any RAM addresses would be outside that.  If you want any
; RAM locations initialized to non-zero values then you'll have to put code
; in SYSINI to do that.
;
;   Even though we have a full 32K RAM available to us, we really only need
; a small chunk of that.  We'd like to jam our memory up against the top end
; of RAM so that the part from $8000 and up can be used by BASIC or whatever
; other interesting things we have in EPROM.
;--
	.ORG	DPBASE

; Other random VT52 emulator context variables...
;   WARNING!! DO NOT CHANGE THE ORDER OF TOPLIN, CURSX and CURSY!  The code
; DEPENDS on these three bytes being in this particular order!!!
TOPLIN: .BLOCK	1	; the number of the top line on the screen
CURSX:	.BLOCK	1	; the column number of the cursor
CURSY:	.BLOCK	1	; the row number of the cursor
; DON'T CHANGE THE GROUPING of CURSOFF, CURSADR and CURSCHR!
CURSOFF:.BLOCK	1	; 0xFF to hide the cursor, 0x00 to display
CURSADR:.BLOCK	2	; frame buffer address of current cursor
CURSCHR:.BLOCK	1	; original character at the cursor
; DON'T CHANGE THE GROUPING OF ESCSTA, CURCHR and SAVCHR!!
ESCSTA:	.BLOCK	1	; current ESCape state machine state
CURCHR:	.BLOCK	1	; character we're trying to output
SAVCHR:	.BLOCK	1	; save one character for escape sequences
; DON'T CHANGE THE GROUPING OF ACSFLG AND RVVFLG!!
ACSFLG:	.BLOCK	1	; != 0 for graphics character set mode
RVVFLG:	.BLOCK	1	; != 0 for reverse video mode
; Other variables ...
CURGRP:	.BLOCK	1	; current I/O group selection
FRAME:	.BLOCK	1	; incremented by the end of frame ISR
TTIMER:	.BLOCK	1	; timer for tones and ^G bell beeper
CURCLR:	.BLOCK	1	; current COLB1/0 and background color
SERBRK:	.BLOCK	1	; serial port break flag
GMODEF:	.BLOCK	1	; 0xFF if in graphics mode, 0x00 for text mode
UPTIME:	.BLOCK	4	; total time (in VRTC ticks) since power on
SLUFMT:	.BLOCK	1	; serial port format (8N1 or 7E1)

; Flags from the keyboard input routine ...
; DON'T CHANGE THE ORDER OR GROUPING OF THESE!!
KEYVER:	.BLOCK	1	; keyboard APU firmware version
KEYBRK:	.BLOCK	1	; non-zero if the BREAK key was pressed
KEYMNU:	.BLOCK	1	; non-zero if the MENU key was pressed
KPDALT:	.BLOCK	1	; 0 for numeric keypad, 0xFF for application
KEYPBK:	.BLOCK	2	; "push back" buffer for escape sequences

;   These two locations are used for (gasp!) self modifying code.  The first
; byte gets either an INP or OUT instruction, and the second a "SEP PC".  The
; entire fragment runs with T1 as the program counter and is used so that
; we can compute an I/O instruction to a variable port address...
IOT:	.BLOCK	3

;   These are temporary locations used by the XMODEM transmit and receive
; routines, and in order to save RAM space we share them with the TIMBUF
; above.  Note that the order of these four locations is critical, so don't
; change that!
XINIT:	.BLOCK	1	; send initial ACK or NAK for XRDBLK
XBLOCK:	.BLOCK	1	; current XMODEM block number
XCOUNT:	.BLOCK	1	; current XMODEM buffer byte count
XDONE:	.BLOCK	1	; non-zero when we receive EOT from the host

;   These are the GET and PUT pointer pairs for each of the circular buffers.
; Remember - don't separate the GET and PUT pairs, and the GET pointer must
; always be first, followed by the PUT.
TXGETP:	.BLOCK	1	; serial port transmitter buffer pointers 
TXPUTP:	.BLOCK	1	; ...
RXGETP:	.BLOCK	1	; serial port receiver buffer pointers
RXPUTP:	.BLOCK	1	; ...
KEYGETP:.BLOCK	1	; and keyboard buffer pointers
KEYPUTP:.BLOCK	1	; ...

;   These bytes are used for the receiver flow control.  RXBUFC counts the
; number of bytes in the buffer, FLOCTL controls whether flow control is
; enabled, and TXONOF is used for XON/XOFF flow control.  All these bytes 
; MUST BE TOGETHER and in this order!
RXBUFC:	.BLOCK	1	; count of bytes in RX buffer for flow control
FLOCTL:	.BLOCK	1	; flow control mode: $01->CTS, $FF->XON/XOFF, 0->none
TXONOF:	.BLOCK	1	; $00 -> receiving normally, $01 -> transmit XON
			; $FF -> transmit XOFF, $FE -> XOFF transmitted

;   These locations are used by the TRAP routine to save the current context.
; Note that the order of these bytes is critical - you can't change 'em without
; also changing the code at TRAP:...
SAVEXP:	.BLOCK	1	; saved state of the user's X register
SAVED:	.BLOCK	1	;   "    "    "   "    "    D    "
SAVEDF:	.BLOCK	1	;   "    "    "   "    "    DF   "
REGS:	.BLOCK	16*2	; All user registers after a breakpoint

; These locations are used by the VIS music player ...
; DON'T CHANGE THE ORDER OR GROUPING OF THESE!!
OCTVOL:	.BLOCK	1	; current octave and volume
TEMPO:	.BLOCK	1	; duration (in ticks) of a quarter note
NOTIME:	.BLOCK	1	; current note duration

;   The CONGET and CONPUT locations contain an LBR to either the SERGET/PUT 
; or VTPUTC/GETKEY routines.  Likewise, CONBRK tests the console break flag
; and should point to either the ISSBRK or ISKBRK routines.  Lastly, CONECHO
; is used by the CONGET routine to echo user input.  These vectors are used
; by this monitor for all console I/O, and storing them in RAM allow us to
; redirect the console to either the serial port or the PS/2 keyboard and
; VIS display.  
;
; DON'T CHANGE THE ORDER OR GROUPING OF THESE!!
CONGET:	.BLOCK	3	; contains an LBR to SERGET or GETKEY
CONECHO:.BLOCK	3	; contains an LBR to the input echo routine
CONBRK:	.BLOCK	3	; contains an LBR to ISSBRK or ISKBRK
CONPUT:	.BLOCK	3	; contains an LBR to SERPUT or VTPUTC

; Command line buffer...
CMDBUF:	.BLOCK	CMDMAX+1; buffer for a line of text read from the terminal

;++
;   We place our stack at the end of this RAM page and then let it grow
; downward from there.  Whatever you do, it's important that we leave here
; exactly page aligned, so that the buffers on the next page can start on a
; power of two address.  Read the buffer comments to see why!
;
;   We then figure out how many bytes are left between the last variable and
; the end of this page, and that's the stack size.  Double check that it's
; enough. What's enough? That's pretty arbitrary but we make an educated guess.
;--
STACK	.EQU	(($+$FF) & $FF00) - 1	; top of this firmware's stack
STKSIZE	.EQU	STACK-$			; space allocated for that stack
	.ECHO	"STACK SIZE "\ .ECHO STKSIZE\ .ECHO " BYTES\n"
	.IF (STKSIZE < 64)
	.ECHO	"**** NOT ENOUGH ROOM FOR THE STACK! *****\n"
	.ENDIF
	.ORG	STACK+1


;++
;   Thexe are the circular buffers used by the interrupt service routines.
; All in all, there are three such buffers -
;
;	TXBUF	- characters waiting to be transmitted via the serial port
;	RXBUF	- characters received from the serial port
;	KEYBUF	- data received from the PS/2 keyboard
;
;   One might ask why we need a KEYBUF, because a) data received from the
; keyboard goes directly to the serial port TXBUF, and b) the PS/2 APU chip has
; a built in buffer anyway.  It's because we want to be able to "look ahead"
; and detect keys like MENU, SETUP or BREAK when running BASIC (or perhaps when
; the UART is transmitting at a slow baud rate).
;
;   It's not currently implemented, but it would also be a good idea to add
; a VIS buffer too.  That's because we can only update the display during the
; vertical blanking time.  Instead of spinning waiting for a VBI every time
; we have a character to display, we could buffer them and process them all in
; a batch at the end of the frame.  That'd make BASIC programs that do a lot
; of printing run a lot faster.
;
;   IMPORTANT!   To make life and coding easier, and faster for the ISRs, on
; the 1802 (which is not the smartest MCU around, after all) these buffers
; have several restrictions!
;
;   1) The ??GETP and ??PUTP pointers are indices, relative to the buffer
;      base, of the next character for the GET and PUT routines, respectively.
;      If the GETP equals the PUTP before a GET then the buffer is empty, and
;      if after incrementing the PUTP it would equal the GETP for a GET, then
;      the buffer is full!
;
;   2) Buffer sizes must always be a power of two, and not more than 256.  So
;      16, 32, 64, 128 or 256 are the only practical and reasonable sizes.
;      This allows us to handle GETP/PUTP wrap around with a simple AND.
;
;   3) The actual buffers must be aligned on a natural boundary; for example,
;      a 64 byte buffer must be aligned on a 64 byte boundary (i.e. such that
;      the lower 6 bits of the buffer address are zeros).  This allows us to
;      index into the buffer without having to worry about carry operations.
;
;   4) The order of the GETP/PUTP pointers for each buffer can't change.
;      It's always GET pointer first, then PUT pointer.
;
;   5) The RAM initialization code in the startup sets all these values to
;      zero.  For the GET/PUT pointers, that's an empty buffer (perfect!).
;--
	.IF (($ & $FF) != 0)
	.ECHO	"***** CIRCULAR BUFFERS NOT PAGE ALIGNED! *****\n"
	.ENDIF
RXBUF:	.BLOCK	RXBUFSZ		; then RXBUF (64 bytes) is next
TXBUF:	.BLOCK	TXBUFSZ		; and finally TXBUF (32 bytes)
KEYBUF:	.BLOCK	KEYBUFSZ	; and KEYBUF (32 bytes)


;++
;   This is the buffer used by the XMODEM protocol and is always 128 bytes
; of payload plus 4 overhead bytes (three header bytes and a checksum).
; Unlike the circular buffers above it doesn't require any special kind of
; alignment, however we are careful to arrange the total size of this buffer
; plus the circular buffers so that they'll all fit in one 256 byte page.
;
;   BTW, needless to say, this part of RAM CANNOT BE UPLOADED OR DOWNLOADED!
;--
XHDR1:	.BLOCK	1		; received SOH or EOT
XHDR2:	.BLOCK	1		; received block number
XHDR3:	.BLOCK	1		; received "inverse" block number
XBUFFER:.BLOCK	XDATSZ		; 128 bytes of received data
XHDR4:	.BLOCK	1		; received checksum

	.IF ($ > RAMEND)
	.ECHO	"**** TOO MANY RAM BYTES - ADJUST DPBASE *****\n"
	.ENDIF

	.SBTTL	Startup, Copyright and Vectors

;++
;   This code gets control immediately after a hardware reset, and contains
; the initial startup code and copyright notice.  We just disable interrupts,
; turn the LED OFF, load the PC (R3) with the address of the SYSINI code, and
; branch there.
;--
	.ORG	ROMBASE		; the VIS1802 EPROM is mapped here
	DIS\ .BYTE $00		; disable interrupts (just in case!)
	RLDI(PC, SYSINI)	; switch to P=3
	SEP	PC		; and go start the self test/initialization


;++
;   Address $000F in the EPROM contains a count (always negative) of the
; number of entry vectors defined, and then the table of entry vectors starts
; at address $0010.  Every vector is three bytes and contains an LBR to
; the appropriate routine.  This table is used by BASIC, or whatever other
; code is stored in the EPROM, to call terminal routines.
;--
	.ORG	ROMBASE+$000F
	.BYTE	-23		; number of entry vectors
	LBR	SCALL		;  0 - our standard call routine
	LBR	SRETURN		;  1 - our standard return routine
	LBR	TRAP		;  2 - breakpoint trap
	LBR	TCHAR		;  3 - send characters to the console
	LBR	INCHRW		;  4 - read keystrokes from the keyboard
	LBR	CONBRK		;  5 - check for console BREAK key
	LBR	SERPUT		;  6 - get character from serial port
	LBR	SERGET		;  7 - send character to serial port
	LBR	ISSBRK		;  8 - test for serial framing error
	LBR	TIN		;  9 - redirect console input to PS/2 keyboard
	LBR	TOUT		; 10 - redirect console output to VIS display
	LBR	SIN		; 11 - redirect console input to serial port
	LBR	SOUT		; 12 - redirect console output to serial port
	.IF (BASIC != 0)
	LBR	RSTIO		; 13 - restore console redirection
	LBR	BSAVE		; 14 - save BASIC program/data with XMODEM
	LBR	BLOAD		; 15 - load BASIC program/data with XMODEM
	LBR	BEXIT		; 16 - re-enter monitor
	LBR	BGMODE		; 17 - switch between text and graphics modes
	LBR	BPLOT		; 18 - plot a single point in graphics mode
	LBR	BLINE		; 19 - draw a line in graphics mode
	LBR	BPLAY		; 20 - play music
	LBR	BKEY		; 21 - test for a keypress
	LBR	BWAIT		; 22 - delay for a number of ticks
	LBR	BTIME		; 23 - return current UPTIME
	.ENDIF

;++
;   And lastly the firmware version, name, copyright notice and date all live
; at the end of the vector table.  These strings should appear at or near to
; the beginning of the EPROM, because we don't want them to be hard to find,
; after all!
;--
SYSNAM:	.TEXT	"SPARE TIME GIZMOS VIS1802 V"
	.BYTE	'0'+VERMAJ, '('
	.BYTE	'0'+(VEREDT/100)
	.BYTE	'0'+((VEREDT/10)%10)
	.BYTE	'0'+(VEREDT%10)
	.BYTE	')', 0
	.INCLUDE "sysdat.asm"
RIGHTS1:.TEXT	"Copyright (C) 2024 Spare Time Gizmos\000"
RIGHTS2:.TEXT	"All rights reserved\000"
	.IF (BASIC != 0)
BRIGHTS:.TEXT	"RCA BASIC3 V1.1 BY Ron Cenker\000"
	.ENDIF

	.SBTTL	Hardware Initializtion

;++
;   This is the hardware initialization after a power up or reset.  The first
; thing is to initialize the RAM contents, and then set up the stack and
; SCRT registers to we can call subroutines.  After that we initialize the
; CDP1854 UART, CDP1863 baud rate generator, PS/2 keyboard, and finally the
; VIS chip set.
;
;   Notice that we turn the LED off at the start of initialization and then
; on at the end.  If anything goes wrong during initialization (i.e. if there
; is some hardware failure) then we'll hang up with the LED off forever ...
;--
SYSINI:	LED_OFF

; Zero everything in RAM ...
	RLDI(T1,RAMEND)\ SEX T1	; start from the top of RAM and work down
RAMIN1:	LDI 0\ STXD\ GHI T1	; zero another byte
	XRI	HIGH(RAMBASE)-1	; have we done everything down to $8000?
	LBNZ	RAMIN1		; loop until we roll over from $8000 -> $7FFF

; Initialize the standard call/return technique ...
	RLDI(SP,STACK)
	RLDI(CALLPC,SCALL)	; initialize the CALLPC and ...
	RLDI(RETPC,SRETURN)	;  ... RETPC registers ...

; Initialize the hardware ...
	CALL(SERINI)		; initialize the CDP1854 and CDP1863
	CALL(VISINI)		; initialize the VIS chipset 
	CALL(ERASE)		; clear text memory to blanks
	RLDI(INTPC,ISR)		; set up the interrupt PC
	ION			; and enable interrupts
	CALL(GERASE)		; and clear graphics memory also
	CALL(TMODE)		; switch back to text mode
	LED_ON			; turn the "CPU OK" LED on
	CALL(BELL)		; and sound the bell

				; fall into the software startup next

	.SBTTL	Software Initialization

;++
;--
	CALL(RSTIO)		; select the correct console device

; Display the splash screen if requested ...
	SEX SP\ INP DIPSW	; read the switches
	SHL\ LBNF SYSIN2	; skip this if no splash screen requested

;  Display the splash screen.  Note that this routine will return whenever any
; input is received from either the keyboard or the serial port!
	CALL(SPLASH)		; ...

; Now figure out whether we start in BASIC or terminal mode ...
SYSIN2:	SEX SP\ INP DIPSW	; read the switches again
	SHL\ SHL\ LBDF SYSIN3	; SW7 selects BASIC startup
	LBR	TERM		; startup the terminal emulator instead ...

; Print the system name, firmware and BIOS versions, and checksum...
SYSIN3:	CALL(TCRLF)		; ...
	OUTSTR(SYSNAM)		; "VIS1802 FIRMWARE"
	CALL(TCRLF)\ CALL(TCRLF); ...
	OUTSTR(SYSDAT)		; print the build date
	INLMES(" CHECKSUM ")	; and the EPROM checksum
	RLDI(P1,CHKSUM)		; stored here by the romcksum program
	SEX P1\ RLXA(P2)	; ...
	CALL(THEX4)		; type that in HEX
	CALL(TCRLF)		; that's all for this line
	OUTSTR(RIGHTS1)		; then print the copyright notice
	CALL(TCRLF)		; ...
	.IF (BASIC != 0)
	OUTSTR(BRIGHTS)		; and the BASIC copyright
	CALL(TCRLF)		; ...
	.ENDIF
	OUTSTR(RIGHTS2)		; ...
	CALL(TCRLF)\ CALL(TCRLF); ...

; If BASIC isn't installed, then just fall into the command scanner!
	.IF	(BASIC != 0)
	LBR	BASIC		; start up BASIC and we're done
	.ENDIF

	.SBTTL	Command Scanner

;++
;   This is the monitor main loop - it prints a prompt, scans a command,
; looks up the command name, and then dispatches to the appropriate routine.
;--
MAIN:	RLDI(CALLPC,SCALL)	; reset our SCRT pointers, just in case
	RLDI(RETPC,SRETURN)	; ...
	RLDI(SP,STACK)\ SEX SP	; reset the stack pointer to the TOS

; Print the prompt and scan a command line...
	INLMES(">>>")		; print our prompt
	RLDI(P1,CMDBUF)		; address of the command line buffer
	RLDI(P3,CMDMAX)		; and the length of the same
	CALL(READLN)		; read a command line
	LBDF	MAIN		; branch if the line was terminated by ^C

;   Parse the command name, look it up, and execute it.  By convention while
; we're parsing the command line (which occupies a good bit of code, as you
; might imagine), P1 is always used as a command line pointer...
	RLDI(P1,CMDBUF)		; P1 always points to the command line
	CALL(ISEOL)		; is the line blank???
	LBDF	MAIN		; yes - just go read another
	RLDI(P2,CMDTBL)		; table of top level commands
	CALL(COMND)		; parse and execute the command
	LBR	MAIN		; and the do it all over again


;   This routine will echo a question mark, then all the characters from
; the start of the command buffer up to the location addressed by P1, and
; then another question mark and a CRLF.  After that it does a LBR to MAIN
; to restart the command scanner.  It's used to report syntax errors; for
; example, if the user types "BASEBALL" instead of "BASIC", he will see
; "?BASE?"...
CMDERR:	LDI	$00		; terminate the string in the command buffer
	INC	P1		; ...
	STR	P1		; at the location currently addressed by P1
;   Enter here (again with an LBR) to do the same thing, except at this
; point we'll echo the entire command line regardless of P1...
ERRALL:	CALL(TQUEST)		; print a question mark
	OUTSTR(CMDBUF)		; and whatever's in the command buffer
	CALL(TQUEST)		; and another question mark
	CALL(TCRLF)		; end the line
	LBR	MAIN		; and go read a new command

	.SBTTL	Lookup and Dispatch Command Verbs

;++
;   This routine is called with P1 pointing to the first letter of a command
; (usually the first thing in the command buffer) and P2 pointing to a table
; of commands.  It searches the command table for a command that matches the
; command line and, if it finds one, dispatches to the correct action routine.
;
;   Commands can be any number of characters (not necessarily even letters)
; and may be abbreviated to a minimum length specified in the command table.
; For example, "BA", "BAS", "BASI" and "BASIC" are all valid for the "BASIC"
; command, however "BASEBALL" is not.
;
;   See the code at CMDTBL: for an example of how this table is formatted.
;--
COMND:	PUSHR(P3)\ PUSHR(P4)	; save registers P3 and P4
	CALL(LTRIM)		; ignore any leading spaves
	RCOPY(P3,P1)		; save the pointer so we can back up
COMND1:	RCOPY(P1,P3)		; reset the to the start of the command
	LDA P2\ PLO P4		; get the minimum match for the next command
	LBZ	ERRALL		; end of command table if it's zero

;   Compare characters on the command line with those in the command table
; and, as long as they match, advance both pointers....
COMND2:	LDN	P2		; take a peek at the next command table byte
	LBZ	COMN3A		; branch if it's the end of this command
	LDN P1\ CALL(FOLD)	; get the next command character
	SEX P2\ SM		; does the command line match the table?
	LBNZ	COMND3		; nope - skip over this command
	INC P2\ INC P1\ DEC P4	; increment table pointers and decrement count
	LBR	COMND2		; keep comparing characters

;   Here when we find something that doesn't match.  If enough characters
; DID match, then this is the command; otherwise move on to the next table
; entry...
COMND3:	SEX P2\ LDXA		; be sure P2 is at the end of this command
	LBNZ	COMND3		; keep going until we're there
	SKP			; skip over the INC
COMN3A:	INC	P2		; skip to the dispatch address
	GLO	P4		; how many characters matched?
	LBZ	COMND4		; branch if an exact match
	SHL			; test the sign bit of P4.0
	LBDF	COMND4		; more than an exact match

; This command doesn't match.  Skip it and move on to the next...
	INC P2\ INC P2		; skip two bytes for the dispatch address
	LBR	COMND1		; and then start over again

; This command matches!
COMND4:	SEX SP\ IRX		; restore P3 and P4
	POPR(P4)\ POPRL(P3)	; ...
	RLDI(T1,COMND5)		; switch the PC temporarily
	SEP	T1		; ...
COMND5:	SEX	P2		; ...
	POPR(PC)		; load the dispatch address into the PC
	LDI	0		; always return with D cleared!
	SEX SP\ SEP PC		; branch to the action routine

	.SBTTL	Primary Command Table

;++
;   This table contains a list of all the firmware command names and the
; addresses of the routines that execute them.  Each table entry is formatted
; like this -
;
;	.BYTE	2, "BASIC", 0
;	.WORD	BASIC
;
; The first byte, 2 in this case, is the minimum number of characters that must
; match the command name ("BA" for "BASIC" in this case).  The next bytes are
; the full name of the command, terminated by a zero byte, and the last two
; bytes are the address of the routine that processes this command.
;--

; This macro makes it easy to create a command table entry ...
#define CMD(len,name,routine)	.BYTE len, name, 0\ .WORD routine

; And here's the actual table of commands ...
CMDTBL:	CMD(2, "INPUT",      INPUT)	; test input port
	CMD(3, "OUTPUT",     OUTPUT)	;  "   output  "
	.IF (BASIC != 0)
	CMD(3, "BASIC",	     RBASIC)	; run BASIC
	.ENDIF
	CMD(1, "EXAMINE",    EXAM)	; examine/dump memory bytes
	CMD(1, "DEPOSIT",    DEPOSIT)	; deposit data in memory
	CMD(3, "REGISTERS",  SHOREG)	; show registers
	CMD(3, "GRAPHICS",   GRAPH)	; select graphics mode
	CMD(3, "TEXT",       TEXT)	; select text mode
	CMD(4, "GCLR",       GERASE)	; temporary - clear graphics screen
	CMD(3, "VIS",	     VISCMD)	; issue VIS commands
	CMD(2, "XSAVE",	     XSAVE)	; save memory via XMODEM
	CMD(2, "XLOAD",	     XLOAD)	; load memory via XMODEM
	CMD(3, "TEST",	     TPATTN)	; display a test pattern
	CMD(4, "GTEST",	     GTEST)	; graphics test
	CMD(2, "HELP",	     PHELP)	; print help text
	CMD(3, "SPLASH",     SPLASH)	; display the startup splash screen
	CMD(4, "TERM",	     TTERM)	; terminal mode
	CMD(3, "TIN",	     TIN)	; select PS/2 keyboard for input
	CMD(3, "SIN",	     SIN)	; select serial port for input
	CMD(4, "TOUT",	     TOUT)	; select VIS display for output
	CMD(4, "SOUT",	     SOUT)	; select serial port for output
	CMD(2, "PLAY",       PLAY)	; play a melody
	CMD(3, "ODE", 	     PDEMO)	; play demo tune
	CMD(1, ":",          IHEX)	; load Intel .HEX format files
	CMD(1, ";",	     MAIN)	; a comment
; The table always ends with a zero byte...
	.BYTE	0

	.SBTTL	Examine Memory Command

;++
;  The E[XAMINE] command allows you to examine one or more bytes of memory in
; both hexadecimal and ASCII. This command accepts two formats of operands -
;
;	>>>E xxxx yyyy
;	- or -
;	>>>E xxxx
;
;   The first one will print the contents of all locations from xxxx to yyyy,
; printing 16 bytes per line.  The second format will print the contents of
; location xxxx only.  All addresses are in hex, of course.
;--
EXAM:	CALL(HEXNW)		; scan the first parameter and put it in P2
	RCOPY(P3,P2)		; save that in a safe place
	CALL(ISEOL)		; is there more?
	LBDF	EXAM1		; no - examine with one operand
	CALL(HEXNW)		; otherwise scan a second parameter
	RCOPY(P4,P2)		; and save it in P4 for a while
	CALL(CHKEOL)		; now there had better be no more
	CALL(P3LEP4)		; are the parameters in the right order??
	LBNF	CMDERR		; error if not
	CALL(MEMDMP)		; go print in the memory dump format
	RETURN			; and then on to the next command

; Here for the one address form of the command...
EXAM1:	RCOPY(P2,P3)		; copy the address
	CALL(THEX4)		; and type it out
	INLMES("> ")		; ...
	B_DISPLAY $
	LDN	P3		; fetch the contents of that byte
	CALL(THEX2)		; and type that too
	CALL(TCRLF)		; type a CRLF and we're done
	RETURN			; ...

	.SBTTL	Generic Memory Dump

;++
;   This routine will dump, in both hexadecimal and ASCII, the block of memory
; between P3 and P4.  It's used by the EXAMINE command, but it can also be
; called from other random places, such as the dump disk sector command, and
; can be especially handy for chasing down bugs...
;
;CALL:
;	P3/ starting RAM address
;	P4/ ending RAM address
;	CALL(MEMDMP)
;--
MEMDMP:	GLO P3\ ANI $F8\ PLO P3	; round P3 off to $xxx0/$xxx8
	GLO P4\ ORI $07\ PLO P4	; and round P4 off to $xxx7/$xxxF
	CALL(TMSG)		; print column headers
	.TEXT	"       0  1  2  3  4  5  6  7\r\n\000"

; Print the address of this line (the first of a row of 8 bytes)...
MEMDM2:	RCOPY(P2,P3)		; copy the address of this byte
	CALL(THEX4)		; and then type it in hex
	INLMES("> ")		; type a > character after the address
	SKP			; skip the INC P3 the first time around

; Now print a row of 8 bytes in hexadecimal...
MEMDM3:	INC	P3		; on to the next byte...
	CALL(TSPACE)		; leave some room between bytes
	B_DISPLAY $
	LDN	P3		; get the next byte from memory
	CALL(THEX2)		; and type the data in two hex digits

; Here to advance to the next data byte...
MEMDM4:	GLO P3\ ANI $07\ XRI $07; have we done eight bytes??
	LBNZ	MEMDM3		; no - on to the next address

; Print all sixteen bytes again, put this time in ASCII...
MEMDM5:	CALL(TSPACE)		; leave a few blanks
	GLO P3\ ANI $F8\ PLO P3	; restore the address back to the beginning
	LBR	MEMD61		; skip the INC P3 the first time around

; If the next byte is a printing ASCII character, $20..$7E, then print it.
MEMDM6:	INC	P3
MEMD61:	B_DISPLAY $
	LDN	P3		; on to the next byte
	PHI	AUX		; save the original byte
	ANI	$60		; is it a control character??
	LBZ	MEMDM7		; yep - print a dot
	GHI	AUX		; no - get the byte again
	ANI $7F\ XRI $7F	; is it a delete (rubout) ??
	LBZ	MEMDM7		; yep - print a dot
	XRI $7F\ CALL(TCHAR)	; no - restore the original byte and type
	LBR	MEMDM8		; on to the next byte

; Here if the character isn't printing - print a "." instead...
MEMDM7:	OUTCHR('.')		; do just that
MEMDM8:	GLO P3\ ANI $07\ XRI $07; have we done sixteen bytes?
	LBNZ	MEMDM6		; nope - keep printing

; We're done with this line of sixteen bytes....
	CALL(TCRLF)		; finish the line
	CALL(CONBRK)		; does the user want to stop early?
	LBDF	MEMDM9		; branch if yes
	INC	P3		; on to the next byte
	GHI P3\ STR SP		; did we roll over from $FFFF to $0000?
	GLO P3\ OR		; check both bytes for zero
	LBZ	MEMDM9		; return now if we rolled over
	CALL(P3LEP4)		; have we done all of them?
	LBDF	MEMDM2		; nope, keep going
MEMDM9:	RETURN			; yep - all done

	.SBTTL	Deposit Memory Command

;++
;   The D[EPOSIT] stores bytes in memory, and it accepts an address and a list
; of data bytes as operands:
;
;	>>>D xxxx dd dd dd dd dd dd dd dd ....
;
; This command would deposit the bytes dd ... into memory addresses beginning
; at xxxx.  Any number of data bytes may be specified; they are deposited into
; sequential addresses...
;--
DEPOSIT:CALL(HEXNW) 		; scan the address first
	RCOPY(P3,P2)		; then save the address where it is safe
	CALL(ISSPAC)		; we'd better have found a space
	LBNF	CMDERR		; error if not

; This loop will read and store bytes...
DEP1:	CALL(HEXNW)		; read another parameter
	CALL(ISSPAC)		; and we'd better have found a space or EOL
	LBNF	CMDERR		; error if not
	B_DISPLAY $
	GLO P2\ STR P3		; store it in memory at (P3)
	LDN P3\ PHI P2		; verify that memory was changed
	STR SP\	GLO P2\ XOR	; compare what we read with what we wrote
	LBNZ	MEMERR		; branch if error
	INC	P3		; on to the next address
	CALL(ISEOL)		; end of line?
	LBNF	DEP1		; nope - keep scanning
	RETURN			; yes - all done now

; Here if memory can't be written ...
MEMERR:	INLMES("?MEM ERR @")
	PUSHR(P2)		; save the good/bad data
	RCOPY(P2,P3)		; print the address first
	CALL(THEX4)		; ...
	INLMES(" RD=")
	POPD\ CALL(THEX2);
	INLMES(" WR=")
	POPD\ CALL(THEX2)
	LBR	TCRLF

;++
; This routine will zero P2 bytes of RAM starting from location P1.
;--
CLRMEM:	LDI 0\ STR P1\ INC P1	; write one byte with zeros
	DBNZ(P2,CLRMEM)		; and loop until they're all done
	RETURN			; ...

	.SBTTL	INPUT Command

;++
;   The IN[put] command reads the specified I/O port, 1..7, and prints the
; byte received in hexadecimal.  Note that this ALWAYS ACCESSES PORTS IN
; I/O GROUP 1!  Those are all the "generic" (i.e. non-VIS) ports in the
; system.  To access the VIS chipset ports in group 0, use the V[is] command.
;
;	>>>INP <port>
;--
INPUT:	CALL(HEXNW)		; read the port number
	CALL(CHKEOL)		; and that had better be all
	RLDI(P4,IOT)		; point P4 at the IOT buffer
	GLO P2\ ANI 7		; get the port address
	LBZ	CMDERR		; error if port 0 selected
	ORI $68\ STR P4		; turn it into an input instruction
	INC	P4		; point to IOT+1
	LDI $D0+PC\ STR P4	; load a "SEP PC" instruction
	DEC	P4		; back to IOT:

; Execute the I/O instruction and type the result...
	INLMES("Port ")
	LDN P4\ ANI 7\ ORI '0'	; convert the port number to ASCII
	CALL(TCHAR)		; ...
	INLMES(" = ")		; ...
	CALL(SELIO1)		; select I/O group 1
	SEP	P4		; execute the input and hold your breath!
	CALL(THEX2)		; type that in hex
	LBR	TCRLF		; finish the line and we're done here!

	.SBTTL	OUTPUT Command

;++
;   The OUT[put] command writes the specified byte to the specified I/O port.
; For example
;
;	>>>OUT <port> <byte>
;
; Like INPUT, this command always accesses ports in I/O group 1.  If you want
; to access the VIS chip set, then use the VIS command instead.
;--
OUTPUT:	CALL(HEXNW2)		; read the port number and the byte
	CALL(CHKEOL)		; there should be no more
	RLDI(P4,IOT)		; point P4 at the IOT buffer
	GLO P3\ ANI 7		; get the port address
	LBZ	CMDERR		; error if port 0 selected
	ORI $60\ STR P4\ INC P4	; turn it into an output instruction
	GLO P2\ STR P4\ INC P4	; store the data byte inline
	LDI $D0+PC\ STR P4	; store a "SEP PC" instruction
	DEC P4\ DEC P4		; back to IOT:
	CALL(SELIO1)		; select I/O group 1
	SEX	P4		; set X=P for IOT
	SEP	P4		; now call the output routine
	RETURN			; and we're done

	.SBTTL	XMODEM Load and Save

;++
;   The XSAVE command uploads a chunk of memory to the host as a binary "file"
; using the XMODEM protocol, and the XLOAD command downloads the same to RAM.
; XMODEM does have flow control, checksums, error detection and (best of all)
; error correction, which are all good.  Unlike Intel HEX files however, it
; does NOT have any kind of address information so it's up to you to make sure
; that any binary file is loaded into RAM at the right address!
;
;	>>>XSAVE bbbb eeee
; 	- or -
;	>>>XLOAD bbbb eeee
;
; where "bbbb" and "eeee" are the addresses of the first and last bytes to be
; saved or loaded (similar to the EXAMINE command).
;
;   XMODEM always saves data in 128 byte blocks so for XSAVE if the size of the
; block to be saved is not a multiple of 128, then the last record will be
; padded with SUB ($1A, Control-Z) bytes.  That's the XMODEM tradition.  For
; XLOAD, if the host sends more data than the specified address range allows,
; the extra data will be ignored.  That means that as long as XSAVE and XLOAD
; have the same parameters, the extra SUB bytes will be ignored.
;--
XLOAD:	CALL(HEXNW2)		; we always have two parameters
	CALL(CHKEOL)		; and then that should be everything
	CALL(P3LEP4)		; make sure "bbbb" .LE. "eeee"
	LBNF	CMDERR		; abort if they aren't
	RCOPY(P1,P3)		; save the starting address temporarily
	CALL(P4SBP3)		; and then compute eeee-bbbb -> P3
	CALL(XOPENR)		; open an XMODEM channel with the host
	RCOPY(P2,P3)		; put the byte count in P2
	RCOPY(P3,P1)		; and the start address in P3
	CALL(XREAD)		; read the data with XMODEM
	LBR	XCLOSER		; close the XMODEM connection and we're done

; Here to upload RAM via XMODEM ...
XSAVE:	CALL(HEXNW2)		; we always have two parameters
	CALL(CHKEOL)		; and then that should be everything
	CALL(P3LEP4)		; make sure "bbbb" .LE. "eeee"
	LBNF	CMDERR		; abort if they aren't
	RCOPY(P1,P3)		; save the starting address
	CALL(P4SBP3)		; compute the byte count
	CALL(XOPENW)		; open an XMODEM upload channel
	LBDF	XTOERR		; timeout error
	RCOPY(P2,P3)		; put the byte count in P2
	RCOPY(P3,P1)		; and the RAM address in P3
	CALL(XWRITE)		; send the data with XMODEM
	LBR	XCLOSEW		; close the connection and we're done

; Here for timeout ...
XTOERR:	OUTSTR(XTOMSG)		; print "?TIMEOUT"
	LBR	MAIN		; and abort
XTOMSG:	.BYTE	"?TIMEOUT\r\n", 0

	.SBTTL	Load Intel HEX Records

;   This routine will parse an Intel .HEX file record from the command line and,
; if the record is valid, deposit it in memory.  All Intel .HEX records start
; with a ":", and the command scanner just funnels all lines that start that
; way to here.  This means you can just send a .HEX file to the SBC1802 thru
; your terminal emulator, and there's no need for a special command to download
; it.  And since each Intel .HEX record ends with a checksum, error checking
; is automatic.
;
;   Intel .HEX records look like this -
;
;	>>>:bbaaaattdddddddddddd......ddcc
;
; Where
;
;	bb   is the count of data bytes in this record
;	aaaa is the memory address for the first data byte
;	tt   is the record type (00 -> data, 01 -> EOF)
;	dd   is zero or more bytes of data
;	cc   is the record checksum
;
;   All values are either two, or in the case of the address, four hex digits.
; All fields are fixed length and no spaces or characters other than hex digits
; (excepting the ":" of course) are allowed.
;
;   While this code is running, the following registers are used -
;
;	P1   - pointer to CMDBUF (contains the HEX record)
;	P2   - hex byte/word returned by GHEX2/GHEX4
;	P3   - memory address (from the aaaa field in the record)
;	T1.0 - record length (from the bb field)
;	T1.1 - record type (from the tt field)
;	T2.0 - checksum accumulator (8 bits only!)
;	T2.1 - temporary used by GHEX2/GHEX4
;
;   Lastly, note that when we get here the ":" has already been parsed, and
; P1 points to the first character of the "bb" field.
;
IHEX:	CALL(GHEX2)\ PLO T1	; record length -> T1.0
	LBNF	CMDERR		; syntax error
	CALL(GHEX4)		; out the load address in P3
	LBNF	CMDERR		; syntax error
	CALL(GHEX2)\ PHI T1	; record type -> T1.1
	LBNF	CMDERR		; syntax error

; The only allowed record types are 0 (data) and 1 (EOF)....
	LBZ	IHEX1		; branch if a data record
	SMI	1		; is it one?
	LBZ	IHEX4		; yes - EOF record

; Here for an unknown hex record type...
	OUTSTR(URCMSG)\	RETURN

;   Here for a data record - begin by accumulating the checksum.  Remember
; that the record checksum includes the four bytes (length, type and address)
; we've already read, although we can safely skip the record type since we know
; it's zero!
IHEX1:	GHI P3\ STR SP		; add the two address bytes
	GLO P3\ ADD\ STR SP	; ...
	GLO T1\ ADD		; and add the record length
	PLO	T2		; accumulate the checksum here

; Read the number of data bytes specified by T1.0...
IHEX2:	GLO	T1		; any more bytes to read???
	LBZ	IHEX3		; nope - test the checksum
	CALL(GHEX2)		; yes - get another data value
	LBNF	CMDERR		; syntax error
	STR SP\ SEX SP		; save the byte on the stack for a minute
	GLO T2\ ADD\ PLO T2	; and accumulate the checksum
	LDN SP\ STR P3		; store the byte in memory at (P3)
	LBDF	MEMERR		; memory error
	INC P3\ DEC T1		; increment the address and count the bytes
	LBR	IHEX2		; and keep going

; Here when we've read all the data - verify the checksum byte...
IHEX3:	CALL(GHEX2)		; one more time
	LBNF	CMDERR		; syntax error
	STR SP\ GLO T2\ ADD	; add the checksum byte to the total so far
	LBNZ	IHEX6		; the result should be zero
	INLMES("OK")		; successful (believe it or not!!)
	LBR	TCRLF		; ...

;  Here for an EOF record.  Note that we carelessly ignore everything on the
; EOF record, including any data AND the checksum.  Strictly speaking we're
; not supposed to do that, but EOF records never have any data.
IHEX4:	INLMES("EOF")
	LBR	TCRLF

;   And here if the record checksum doesn't add up.  Ideally we should just
; ignore this entire record, but unfortunatley we've already stuffed all or
; part of it into memory.  It's too late now!
IHEX6:	OUTSTR(HCKMSG)
	RETURN

; HEX file parsing messages ...
HCKMSG:	.TEXT	"?CHECKSUM ERROR\r\n\000"
URCMSG:	.TEXT	"?UNKNOWN RECORD\r\n\000"

	.SBTTL	Scan Two and Four Digit Hex Values

;   These routines are used specifically to read Intel .HEX records.  We can't
; call the usual HEXNW, et al, functions here since they need a delimiter to
; stop scanning.  Calling HEXNW would just eat the entire remainder of the
; .HEX record and return only the last 16 bits!  So instead we have two special
; functions, GHEX2 and GHEX4, that scan fixed length fields.

;   This routine will read a four digit hex number pointed to by P1 and return
; its value in P3.  Other than a doubling of precision, it's exactly the same
; as GHEX2...
GHEX4:	CALL(GHEX2)\ PHI P3	; get the first two digits
	LBNF	GHEX40		; quit if we don't find them
	CALL(GHEX2)\ PLO P3	; then the next two digits
	LBNF	GHEX40		; not there
	SDF			; and return with DF set
GHEX40:	RETURN			; all done


;   This routine will scan a two hex number pointed to by P1 and return its
; value in D.  Unlike F_HEXIN, which will scan an arbitrary number of digits,
; in this case the number must contain exactly two digits - no more, and no
; less.  If we don't find two hex digits in the string addressed by P1, the
; DF bit will be cleared on return and P1 left pointing to the non-hex char.
GHEX2:	LDN	P1		; get the first character
	CALL(ISHEX)		; is it a hex digit???
	LBNF	GHEX40		; nope - quit now
	SHL\ SHL\ SHL\ SHL	; shift the first nibble left 4 bits
	PHI	T2		; and save it temporarily
	INC P1\	LDN P1		; then get the next character
	CALL(ISHEX)		; is it a hex digit?
	LBNF	GHEX20		; not there - quit now
	STR SP\ GHI T2\ OR	; put the two digits together
	INC P1\ SDF		; success!
GHEX20:	RETURN			; and we're all done

	.SBTTL	GRAPHICS and TEXT Commands

;++
;   The GR[aphics] command selects graphics mode for the VIS chipset.  There
; are no arguments ...
;--
GRAPH:	CALL(CHKEOL)		; there are no arguments
	CALL(GMODE)		; select graphics mode 

;   Mega kludge here - if output is to the screen and we just return, then
; we'll immediately print another ">>>" prompt and that will instantly switch
; us back to text mode!  Instead, just spin here until the user types something
; (anything!) and then continue processing commands.
GWAIT:	RLDI(T1,CONPUT+2)	; get the current console output routine
	LDN T1\ XRI LOW(VTPUTC)	; is it to the screen ?
	LBNZ	GRAPH2		; no - just return now
GRAPH1:	RLDI(T1,KEYGETP)\ LDA T1; yes - test the keyboard buffer
	SEX T1\ XOR		; GETP == PUTP ??
	LBZ	GRAPH1		; yes - buffer empty, wait here
GRAPH2:	RETURN			; no - continue with the next command


;++
;   The TE[xt] command selects text mode for the VIS chipset.  There are no
; arguments ...
;--
TEXT:	CALL(CHKEOL)		; no arguments allowed
	LBR	TMODE		; select text mode and we're done

	.SBTTL	VIS Command

;++
;   The VIS command issues commands to the VIS chipset.  It needs two arguments,
; a port number and the command/data.   Ports 4..7 reference the CDP1869 chip,
; and port 3 references the CDP1870/76 chip.  Ports 1..2 aren't allowed here.
;
;	>>>VIS port data
;
;   The CDP1869 VIS chip is a weird beast - it's connected to the address bus,
; but not to the data bus at all.  That means issuing a command to this chip
; requires us to put the command bits on the ADDRESS bus, so it's the address
; referenced by the OUT istruction that matters.  The contents of the data
; bus are ignored here, and so the contents of the location referenced are
; unimportant.  This is actually fairly convenient on the 1802, if a bit odd.
; Just load the 16 bit command word into a regster, SEX that register, and
; execute the OUT.  The OUT will trash the register by incrementing it, but
; that doesn't matter here.
;
;   The CDP1870/76 chip, OTOH, is completely conventional and in this case
; it wants to see its command on the data bus and the address doesn't matter.
; The CDP1869 can actually accept a 16 bit command word, but the 1870/76 is
; limited to 8 bits, of course.
;
;   Lastly, note that commands to both chips are issued with OUT instructions.;
; Neither has any read back capability, and both chips are strictly write
; only.
;--
VISCMD:	CALL(HEXNW2)		; read two parameters into P2 and P3
	CALL(CHKEOL)		; then check for the end of line
	CALL(SELIO0)		; the VIS chips are in group 0
	RLDI(P4,IOT)		; point to the IOT work area
	GLO P3\ ANI 7		; get the port number
	SMI 3\ LBL CMDERR	; port number must be .GE. 3
	LBZ	VISCM1		; branch if port 3 was selected

; Here to access the CDP1869 chip ...
	ADI 3\ ORI $60		; make an OUT instruction
	STR P4\ INC P4		; store that in the work area
	LDI $D0+PC\ STR P4	; and store a "SEP PC" next
	SEX	P2		; the second argument is the data for the 1869
	DEC P4\ SEP P4		; execute the OUT instruction
	LBR	SELIO1		; select I/O group 1 again and we're done

; Here to access the CDP1870 chip ...
VISCM1:	LDI $63\ STR P4\ INC P4	; store an OUT 3 instruction
	GLO P2\ STR P4\ INC P4	; the data for the 1870 is inline
	LDI $D0+PC\ STR P4	; and store a "SEP PC" last
	DEC P4\ DEC P4		; backup to the start of work area
	SEX P4\ SEP P4		; execute the OUT ...
	LBR	SELIO1		; reselect group 1 and we're done

	.SBTTL	HELP Command

;++
;   The HELP command prints a canned help file, which is stored in EPROM in
; plain ASCII. 
;--
PHELP:	CALL(CHKEOL)		; HELP has no arguments
	RLDI(P1,HLPTXT)		; nope - just print the whole text
	LBR	TSTR		; ... print it and return

	.SBTTL	Terminal Emulator

;++
;   This is your basic terminal emulator.  It simply copies characters from
; the serial port to the screen, and from the keyboard to the serial port.
; Notice that this routine loops forever, however you can get to the command
; scanner by pressing either the MENU key on the PS/2 keyboard or sending a
; long break on the serial port.
;
;   TTERM is an alternate entry used by the TERM command.
;--
TTERM:	CALL(CHKEOL)
	OUTSTR(TTMSG)

TERM:	RLDI(T1,KEYBRK)\ SEX T1	; clear both the KEYMNU and KEYBRK flags
	LDI 0\ STXD\ STXD	; ...
	RLDI(T1,SERBRK)		; and clear the serial break flag too
	LDI 0\ STR T1		; ...

TERM1:	CALL(ISKMNU)		; was the menu key pressed ?
	LBDF	TERM4		; yes - start the command scanner
	CALL(ISSBRK)		; was a break received on the serial port?
;;	LBDF	TERM1		; yes - ignore it

; Check the serial port for input first ...
	CALL(SERGET)		; anything in the buffer
	LBDF	TERM2		; no - check the PS/2 keyboard
	CALL(VTPUTC)		; yes - send this character to the screen

; Check the PS/2 keyboard for input ...
TERM2:	CALL(ISKBRK)		; was the BREAK key pressed ?
	LBDF	TERM3		; yes - send a break on the serial port
	CALL(GETKEY)		; anything waiting from the keyboard?
	LBDF	TERM1		; no - back to checking the serial port
	CALL(SERPUT)		; yes - send it to the serial port
	LBR	TERM1		; and keep going

; Here when the PS/2 keyboard BREAK key is pressed ...
TERM3:	CALL(TXSBRK)		; send a break on the serial port
	LBR	TERM1		; and then continue

; Here when the PS/2 keyboard MENU key is pressed ...
TERM4:	OUTSTR(TEMSG)		; print a message
	LBR	MAIN		; and start up the command scanner

; Messages ...
TTMSG:	.TEXT	"[TERMINAL MODE]\r\n\000"
TEMSG:	.TEXT	"\r\n\n[COMMAND MODE]\r\n\000"

	.SBTTL	Graphics and Terminal Test Commands

;++
;   The TEST command displays a "test pattern" (if you want to call it that)
; screen full of text ...
;
;	>>>TEST
;--
TPATTN:	CALL(CHKEOL)
	CALL(DSACURS)
	RLDI(T1,PAGEMEM)
	RLDI(T2,PAGESIZE)
	RLDI(T3,'A'-$20)
	RLDI(T4,0)
TPATT1:	B_DISPLAY $
	GLO T3\ STR T1\ INC T1
	INC T4\ GLO T4
	SMI MAXCOL\ LBL TPATT2
	INC T3\ RCLR(T4)
TPATT2:	DBNZ(T2,TPATT1)
	CALL(ENACURS)
	RETURN

;++
;   The GTEST command displays a graphics test pattern with lines drawn in
; all four quadrants with slopes both .GT. 1 and .LE. 1...
;
;	>>>GTEST
;--
GTEST:	CALL(CHKEOL)
	RLDI(P1,$0000)\ RLDI(P2,$EF00)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$EF00)\ RLDI(P2,$EFBF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$EFBF)\ RLDI(P2,$00BF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$00BF)\ RLDI(P2,$0000)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$7800)\ RLDI(P2,$78BF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$0060)\ RLDI(P2,$EF60)\ CALL(LINE)\ LBDF CMDERR

	RLDI(P2,$0000)\ RLDI(P1,$EFBF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P2,$EF00)\ RLDI(P1,$00BF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$3C00)\ RLDI(P2,$B4BF)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$3CBF)\ RLDI(P2,$B400)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$EF90)\ RLDI(P2,$0030)\ CALL(LINE)\ LBDF CMDERR
	RLDI(P1,$0090)\ RLDI(P2,$EF30)\ CALL(LINE)\ LBDF CMDERR
GTEST9:	LBR	GWAIT

	.SBTTL	Start BASIC Interpreter

	.IF (BASIC != 0)
;++
;   The BASIC command runs BASIC from ROM.  The BASIC we is the BASIC3 v1.1
; from the RCA Microboard COSMAC Development System (aka the MCDS, not to be
; confused with the earlier COSMAC Development System, CDS).  This BASIC 
; takes 12K of ROM and was written for a "ROM high, RAM low" configuration.
; Better yet, it was also written to work with the UT62 ROM for the console
; I/O, which is compatible with the UT71 ROM that we emulate for MicroDOS.
;
;   BASIC runs using the ROM0 memory map and all we have to do is jump to
; it's starting address using R0 as the PC.  The rest takes care of itself.
;--
RBASIC:	CALL(CHKEOL)		; no arguments for this command
	LBR	BASIC		; load the BASIC entry point


;++
;   This routine is called by BASIC for the BYE command.  It will reinitialize
; everything, including SCRT and the console terminal, and then restarts the
; monitor.
;--
BEXIT:	RLDI(SP,STACK)		; reset the stack pointer
	RLDI(CALLPC,SCALL)	;  ... and re-initialize the CALLPC and
	RLDI(RETPC,SRETURN)	;  ... RETPC just to be safe
	CALL(RSTIO)		; reset the console I/O pointers
	LBR	MAIN		; and return to MAIN
	.ENDIF

	.SBTTL	BASIC LOAD/SAVE Support

	.IF (BASIC != 0)
;++
;   BASIC calls this routine to save either program or data using XMODEM.  When
; we get here, BASIC has already switched the SCRT routines to our own BIOS
; versions, so we're free to call any XMODEM or BIOS functions so long as we
; preserve all registers.  When BASIC calls us we have
;
;	RA (aka T4) = start address
;	RC (aka P3) = byte count
;
;   One thing - when somebody eventually tries to load this data back into
; BASIC, there's nothing to tell us how many bytes we should load nor where
; (in RAM) we should put it.  BASIC just assumes we know, and of course XMODEM
; doesn't save this information.  That means we have to save it, so we add four
; bytes to the start of the data to save the address and byte count.  We do
; this by pushing those registers onto the stack and then saving four bytes
; directly from the stack area, which is slightly clever but works great.
;
; Note that P2 (aka RD) is critical to BASIC and we have to preserve it!
;--
BSAVE:	CALL(XOPENW)		; open the XMODEM channel to the host
	LBDF	BASTMO		; branch if failure
	PUSHR($D)		; save BASIC's RD (aka P2)
	PUSHR($C)		; put the byte count on the stack first
	PUSHR($A)		; ... and then the RAM address
	RCOPY(P3,SP)\ INC P3	; point to the first of these four bytes
	RLDI(P2,4)		; ... and save four bytes
	CALL(XWRITE)		; ...
	IRX\ POPR(P3)		; now put the actual RAM address in P3
	POPRL(P2)		;  ... and the actual byte count in P2
	CALL(XWRITE)		; save the BASIC data
	IRX\ POPRL($D)		; restore BASIC's RD
	LBR	XCLOSEW		; close XMODEM and return


;++
;   And this routine will load a BASIC program or data via XMODEM and it's
; essentially the reverse of BSAVE, above.  Remember that BASIC doesn't tell
; us how many bytes to load nor where in RAM to put them - we have to get all
; that from the four byte header that BSAVE wrote.
;--
BLOAD:	CALL(XOPENR)		; open the XMODEM channel to the host
	PUSHR($D)		; save BASIC's RD (aka P2)
	DEC SP\ DEC SP\ DEC SP	; make some space on the stack
	RCOPY(P3,SP)\ DEC SP	; and set P3 to the address of this space
	RLDI(P2,4)		; ... it's always four bytes
	CALL(XREAD)		; read the header information first
	IRX\ POPR(P3)		; put the RAM address from the image in P3
	POPRL(P2)		; and the byte count in P2
	CALL(XREAD)		; load the BASIC data
	IRX\ POPRL($D)		; restore BASIC's  RD
	LBR	XCLOSER		; close XMODEM and return


; Here for BASIC SAVE/LOAD XMODEM time out ...
BASTMO:	OUTSTR(XTOMSG)		; say "?TIMEOUT"
	RETURN			; and give up
	.ENDIF

	.SBTTL	BASIC Graphics Support

	.IF (BASIC != 0)
;++
;   This routine is called by the BASIC GRAPHICS statement.  GRAPHICS takes
; one argument, as follows
;
;	GRAPHICS 0 -> switch to text display
;	GRAPHICS 1 -> switch to graphics display
;	GRAPHICS 3 -> switch to graphics and clear graphics display
;
; Note that GRAPHICS 3 can be used if you're already in graphics mode; in that
; case it just clears the display and stays in graphics mode.  BASIC passes
; the GRAPHICS argument to us in RA.0.  Normally we're responsible for saving
; registers, however GMODE, TMODE and GERASE already save all registers, so
; we're good there.
;--
BGMODE:	GLO $A\ LBZ TMODE	; GMODE 0 -> switch to text mode
	GLO $A\ XRI 1		; GMODE 1 -> switch to graphics mode
	LBZ	GMODE		; ...
	GLO $A\ XRI 3		; GMODE 3 -> switch to graphics and clear
	LBZ	GERASE		; ...
	RETURN			; and ingore everything else


;++
;   This routine is called by the BASIC PLOT statement.  PLOT draws a single
; point on the screen, and takes two arguments giving the X and Y coordinates
; of that pixel.
;
;	PLOT(X,Y) 	-> 0 <= X <= 239 and 0 <= Y <= 191
;
;   The BASIC code already sets up the X and Y values in RE for us, and since
; RE is our P1 that's all we need.  We just have to preserve any additional
; registers and then call PLOT.
;
;   Note that if the coordinates are invalid (out of the range specified above)
; then PLOT returns with DF=1.  We need to pass that all the way back to BASIC,
; and BASIC will issue an error in that case.
;--
BPLOT:	PUSHR(T2)		; T2 is the only other thing used by PLOT
	CALL(PLOT)		; draw the point
	IRX\ POPRL(T2)		; restore T2
	RETURN			; and return


;++
;   And this routine is called by the BASIC LINE statement.  LINE draws an
; arbitrary line between any two points on the screen, and it requires four
; arguments - the X and Y coordinates of each end point.
;
;	LINE(X0,Y0,X1,Y1)	-> draw line from (X0,Y0) to (X1,Y1)
;
;   The BASIC code sets up (X0,Y0) in RA and (X1,Y1) in RE before we get here.
; RE is our P1 so we can leave that alone, but we need to save P2 (and other
; registers too) and then transfer RA to P2.  That actually draws a line from
; (X1,Y1) to (X0,Y0) in the reverse direction, but that doesn't matter.
;
;   Like PLOT, LINE returns DF=1 if any of the coordinates is invalid, and we
; need to pass that back to BASIC.
;--
BLINE:	PUSHR(T2)\ PUSHR(T3)	; LINE uses pretty much ALL registers!
	PUSHR(T4)\ PUSHR(P2)	; ...
	PUSHR(P3)\ PUSHR(P4)	; ...
	RCOPY(P2,$A)		; transfer RA to P2 (P1 is already set up)
	CALL(LINE)		; draw the line
	IRX\ POPR(P4)		; and then restore everything
	POPR(P3)\ POPR(P2)	; ...
	POPR(T4)\ POPR(T3)	; ...
	POPRL(T2)\ RETURN	; ...
	.ENDIF

	.SBTTL	BASIC PLAY and KEY Support

	.IF (BASIC != 0)
;++
;   This routine is called by the BASIC PLAY statement, which plays tunes using
; the CDP1869 sound hardware.  
;
;	PLAY string
;
;   The argument to PLAY is a string of characters which specify the pitch, 
; duration, octave, volume, etc of the notes to be played according to rules
; documented in the PLAY routine later in this file.  
;
;   Syntactically BASIC treats PLAY like a REM statement and just completely
; ignores the remainder of the line.  Spaces are ignored, but otherwise the
; remainder of the line will be "played", and in particular, quotation marks
; around the string are NOT required (and should NOT be used).  And sadly,
; this also means that the string has to be a constant in the BASIC program;
; there's no way to use string variables or string functions to generate the
; music string.
;
;   BASIC passes us a pointer to the source line in RB, which we transfer to
; P1 for PLAY.  On return PLAY leaves P1 pointing to the first character that
; it could NOT interpret as a musical note, and we transfer that pointer back
; to RB before returning.  BASIC will check that this points to an end of line
; and will issue an error if it doesn't.
;--
BPLAY:	PUSHR(T2)		; need to save T2 for BASIC
	RCOPY(P1,$B)		; put the line pointer in P1
	CALL(PLAY1)		; and play music!
	RCOPY($B,P1)		; let BASIC know where we stopped
	IRX\ POPRL(T2)		; restore T2 and ...
	RETURN			;  ... we're done


;++
;   The KEY function in BASIC tests the current console for any input pending
; and, if there is something there, returns the ASCII value of that character.
; If the input buffer is empty the zero is returned.
;
;	LET K = KEY
;  or
;	IF KEY != 0 ...
;
;   Note that there are no parenthesis after the KEY - that's a quirk of the
; way BASIC3 works.
;
;   KEY respects the current TIN/SINP console assignment, and any input read
; by KEY is NOT echoed!   We return the result in R8.0.
;--
BKEY:	CALL(CONGET)		; then poll the console input device
	LSNF			; if DF=1 ...
	 LDI	 0		;  ... return zero
	PLO	R8		; save the result
	RETURN			; and that's it!
	.ENDIF

	.SBTTL	BASIC TIME and WAIT Support

	.IF (BASIC != 0)
;++
;   The BASIC TIME function returns the number of VRTC interrupts since the
; system was powered up.  This is a 32 bit value that only increases as time
; goes on.  It doesn't give you the actual time of day, but it does give a 
; convenient way to measure time in real units.
;
;	LET T = TIME
;
;   Note that, like KEY, there can be no parenthesis after TIME.  That's just
; a BASIC3 quirk.  The 32 bit result is returned in R8 (low 16 bits) and RA
; (high 16 bits).
;
;   BTW, it's critical to turn off interrupts while doing this.  It's always
; possible that the count might roll over from 0xFF, 0xFFFF, or even 0xFFFFFF
; while we're here, and if that happens while we're here then we could return
; a massively wrong result.
BTIME:	PUSHR(P1)		; save a working register (note T1 == R8!)
	RLDI(P1,UPTIME)		; and point to the current uptime count
	IOFF			; make sure the count DOESN'T change!
	LDA P1\ PLO $8		; return the result in R8 ...
	LDA P1\ PHI $8		;  ...
	LDA P1\ PLO $A		;  ... and RA ...
	LDA P1\ PHI $A		;  ...
	ION			; interrupts are safe again
	IRX\ POPRL(P1)		; restore P1
	RETURN			; and we're done here


;++
;   The BASIC WAIT statement delays execution for a number of VRTC interrupt
; "ticks".  
;
;	WAIT value
;
;   BASIC treats the argument as a 16 bit unsigned value and passes that to
; us in RA.  We add that value (which requires a 32 bit quad precision addition
; unfortunately!) to the current UPTIME and then just spin here until UPTIME
; counts past that value.
;
;   One complication - we call CONBRK repeatedly while we're waiting and if
; a BREAK is found we abort the wait and return immediately!
;--
BWAIT:	PUSHR(P1)\ PUSHR(T2)	; save some working room (T1 == RA!!)
	PUSHR(T3)		; ...
	RLDI(P1,UPTIME)		; point to the current uptime
	IOFF\ SEX P1		; don't allow UPTIME to change
	GLO $A\ ADD\ PLO T2\ IRX ; add WAIT argument to current time
	GHI $A\ ADC\ PHI T2\ IRX ;  ... store the result in T2 (low)
	LDXA\ ADCI 0\ PLO T3	;  ... and T3 (high)
	LDXA\ ADCI 0\ PHI T3	;  ...
	ION			; interrupts are safe again

; Now start waiting ...
BWAIT1:	CALL(CONBRK)		; test for a break
	LBDF	BWAIT2		; quit now if a break was found
	RLDI(P1,UPTIME)		; compare T3:T2 to UPTIME
	IOFF\ SEX P1		; again, don't allow UPTIME to change
	GLO T2\ SM\ IRX		; compute <end time> - <uptime>
	GHI T2\ SMB\ IRX	;  ... but don't store the result!
	GLO T3\ SMB\ IRX	;  ...
	GHI T3\ SMB		;  ...
	ION			; interrupts are safe again
	LBGE	BWAIT1		; keep waiting until <end time> - <uptime> < 0

; All done ...
BWAIT2:	SEX SP\ IRX\ POPR(T3)	; restore saved registers
	POPR(T2)\ POPRL(P1)	; ...
	RETURN			; and we're done waiting
	.ENDIF

	.SBTTL	Trap and Save Context

;++
; BREAKPOINT TRAPS
;   You can put an LBR to TRAP anywhere (say, in BASIC while you're debugging
; it!) and this routine will save the user registers, re-initialize the stack
; and SCRT, and then branch to MAIN to start the command scanner.  It uses R0
; to save the registers (remember that R1 is reserved for interrupts, which
; we need!) and assumes the PC is R3 and that R2 points to some kind of valid
; stack.
;--

;   Save (X,P) to the stack (the current P is moot, but it's useful to know
; what X is), and the current D and DF to the stack (assuming that there's a
; valid stack pointer in R2).
TRAP:	MARK			; save (X,P)
	SEX R2\ STXD		; save D on the user's stack
	LDI 0\ SHLC\ STR R2	; and save DF on the stack too

; Save registers RF thru R3 in memory at REGS:...
	RLDI(R0,REGS+32-1)\ SEX R0
	PUSHR(RF)
	PUSHR(RE)
	PUSHR(RD)
	PUSHR(RC)
	PUSHR(RB)
	PUSHR(RA)
	PUSHR(R9)
	PUSHR(R8)
	PUSHR(R7)
	PUSHR(R6)
	PUSHR(R5)
	PUSHR(R4)
	PUSHR(R3)
	DEC R0\ DEC R0		; skip over R2 (we'll fix that later)

;   The next two registers, R1 and R0, don't really contain useful data but
; we need to skip over those before we can save D, DF and X...
	PUSHR(R1)		; R1 is the ISR, but save it anyway
	LDI 0\ STXD\ STXD	; save R0 as all zeros

; Recover DF, D and X from the user's stack and save them in our memory...
	LDN	R2		; get the user's DF
	STXD			; store that at SAVEDF:
	INC R2\ LDN R2		; then get the user's D
	STXD			; and store that at SAVED:
	INC R2\ LDN R2		; and lastly get the user's (X,P)
	STXD			; and store it at SAVEXP:

;   Finally, update the value of register 2 that we saved so that it shows the
; current (and correct) value, before we pushed three bytes onto the stack...
	RLDI(R0,REGS+5)
	PUSHR(R2)

;   We're all done saving stuff.  Reset our stack pointer and the SCRT pointers
; (just in case) and then dump the breakpoint data.
	RLDI(CALLPC,SCALL)	; reset our SCRT pointers
	RLDI(RETPC,SRETURN)	; ...
	RLDI(SP,STACK)\ SEX SP	; and reset the stack pointer to the TOS
	CALL(SHOBPT)		; print the registers 
	LBR	MAIN		; go start up the command scanner

	.SBTTL	Display User Context

;++
;   This routine will display the user registers that were saved after the last
; breakpoint trap.   It's used by the "REGISTERS" command, and is also called
; directly whenever a breakpoint trap occurs.
;--

; Here to display the registers after a breakpoint trap ...
SHOBPT:	OUTSTR(BPTMSG)		; print "BREAKPOINT ..."
	LBR	SHORE1		; thenn go dump all the registers

; Here for the "REGisters" command...
SHOREG:	CALL(CHKEOL)		; should be the end of the line
				; Fall into SHORE1 ....

; Print a couple of CRLFs and then display X, D and DF...
SHORE1:	RLDI(T1,SAVEXP)		; point T1 at the user's context info
	INLMES("XP=")		; ...
	SEX T1\ LDXA		; get the saved value of (X,P)
	CALL(THEX2)		;  ... and print it in hex
	INLMES(" D=")		; ...
	SEX T1\ LDXA		; now get the saved value of D
	CALL(THEX2)		; ...
	INLMES(" DF=")		; ...
	SEX T1\ LDXA\ ADI '0'	; and lastly get the saved DF
	CALL(TCHAR)		; ... it's just one bit!
	CALL(TCRLF)		; finish that line

;   Print the registers R(0) thru R(F) (remembering, of course, that R0 and R3
; aren't really meaningful, on four lines four registers per line...
	LDI 0\ PLO P3		; count the registers here
SHORE2:	OUTCHR('R')		; type "Rn="
	GLO P3\ CALL(THEX1)	; ...
	OUTCHR('=')		; ...
	SEX T1\ POPR(P2)	; now load the register contents from REGS:
	CALL(THEX4)		; type that as 4 hex digits
	CALL(TTABC)		; and finish with a tab
	INC	P3		; on to the next register
	GLO	P3		; get the register number
	ANI	$3		; have we done a multiple of four?
	LBNZ	SHORE2		; nope - keep going

; Here to end the line...
	CALL(TCRLF)		; finish off this line
	GLO	P3		; and get the register number again
	ANI	$F		; have we done all sixteen??
	LBNZ	SHORE2		; nope - not yet
	LBR	TCRLF		; yes - print another CRLF and return

; Messages...
BPTMSG:	.TEXT	"\r\nBREAK AT \000"

	.SBTTL	Output Characters to the Screen

;++
;   This routine is called whenever we want to send a character to the video
; terminal.  It checks to see whether we are in the middle of processing an
; escape sequence and, if we are, then it advances the state machine for that.
; If its not an escape sequence then we next check for a control character and
; handle those as needed.  And lastly, if it's just a plain ordinary printing
; character then we branch off to NORMAL to handle the alternate character set
; and reverse video.
;
;   One note - this routine can be called directly from BASIC and as such it's
; important that we preserve all registers used AND that we return the original
; character in D.
;--
VTPUTC:	PHI AUX\ SEX SP		; save character in a safe place
	PUSHR(T1)		; save the registers that we use 
	PUSHR(T2)		; ...
	PUSHR(P1)		; ...
	RLDI(T1,CURCHR)\ SEX T1	; point to our local storage
	GHI AUX\ STXD		; move the character to CURCHR
	LDN T1\ LBNZ VTPUT2	; jump if ESCStA is not zero

; This character is not part of an escape sequence...
VTPUT3:	INC T1\ LDN T1\ ANI $7F	; trim character to 7 bits
	PHI AUX\ LBZ VTPUT9	;  ... and ignore null characters
	XRI $7F\ LBZ VTPUT9	;  ... ignore RUBOUTs too
	GHI AUX\ SMI ' '	; is this a control character ?
	LBL	VTPUT1		; branch if yes

; This character is a normal, printing, character...
	GHI AUX\ CALL(NORMAL)	; display it as a normal character

;   And return...  It's a bit of extra work, but it's really important that
; we return the same value in D that we were originally called with.  Some
; code depends on this!
VTPUT9:	RLDI(T1,CURCHR)		; gotta get back the original data
	LDN T1\ PHI AUX		; save it for a moment
	SEX SP\ IRX\ POPR(P1)	; restore the registers we saved
	POPR(T2)		; ...
	POPRL(T1)		; ...
;  It's critical the we return with DF=0 for compatibility with SERPUT.  If
; we don't we risk CONPUT calling us multiple times for the same character!
	CDF\ GHI AUX\ RETURN	; and we're done!

; Here if this character is a control character...
VTPUT1:	GHI	AUX		; restore the original character
	CALL(LBRI)		; and dispatch to the correct routine
	 .WORD	 CTLTAB		; ...
	LBR	VTPUT9		; then return normally

; Here if this character is part of an escape sequence...
VTPUT2:	CALL(LBRI)		; branch to the next state in escape processing
	 .WORD	 ESTATE		; table of escape states
	LBR	VTPUT9		; and return

	.SBTTL	Write Normal Characters to the Screen

;++
;   This routine is called whenever a printing character is received.  This
; character will be written to the screen at the current cusror location and
; after that the cursor will move right one character.  If the cursor is at
; the right edge of the screen, then it WILL 'wrap around' to the next line.
; The character to be written should be passed in D.
;
;   Like the VT52, we have both a "normal" mode and an alternate (graphics)
; character set mode, but the implementation of the alternate character set
; depends on whether a 128 or 64 character font is in use.
;
; Uses T1 ...
;--
NORMAL:	PUSHD			; save the character for a minute
;   Be sure we're in text mode before sending anything to the screen.  Note
; that this test is done AFTER checking for an escape sequence - that means
; escape sequences that affect the text screen need to check separately, but
; checking first makes graphics escape sequences impossible!
	CALL(TMODE)		; be sure we're in text mode
	POPD\ PHI AUX		; save the character to display
	RLDI(T1,ACSFLG)		; and point T1 at the ACS/RVV flag

	.IF (FONTSIZE == 64)
;++
;   With the 64 character font, the alternate character set is an entire
; alternate font.  All we have to is to OR in the ACSBIT left by ENAACS
; or DSAACS.   However, remember that this font only has upper case letters,
; we first need to fold lower case input to upper.   BTW, note that this
; "fold" is different from the usual because we fold EVERYTHING from 0x60
; to 0x7F, not just letters!
;--
	GHI AUX\ SMI $60	; is this character 0x60..0x7F?
	LBL	NORMA1		;  ... branch if not
	GHI AUX\ SMI $20\ SKP	; fold 0x60..0x7F to 0x40..0x5F
NORMA1:	GHI AUX\ SMI $20	; move ' ' (0x20) down to 0x00 for this font
	SEX T1\ OR		; OR in the ACS flag
	.ENDIF

	.IF (FONTSIZE == 128)
;   With the 128 character font, the alternate character set is stored in fonts
; 0x00..0x1F (i.e. what would be the ASCII control characters).  If the ACS is
; enabled then weneed to fold the lower case range 0x60..0x7F down to that range
; and we're done.  Note that unlike the VT52 we can display both altenate and
; lower case characters at the same time.
;--
	GHI AUX\ SMI $60	; is this even a lower case letter anyway?
	LBL	NORMA1		; nope - just continue normally
	LDN T1\ LBZ NORMA1	; continue normally if ACS is not enabled
	GHI AUX\ SMI $60\ SKP	; fold 0x60..0x7F down to 0x00..0x1F
NORMA1:	GHI	AUX		; use the original character as-is
	.ENDIF

; Apply the reverse video flag and then store this character under the cursor.
	INC T1\ SEX T1\  OR	; and then OR in the reverse video flag
	CALL(UPDCCHR)		; store this character under the cursor

;   After storing the character we want to move the cursor right.  This could
; be as simple as just calling RIGHT:, but but that will stop moving the cursor
; at the right margin.  We'd prefer to have autowrap, which means that we need
; to start a new line if we just wrote the 80th character on this line...
	RLDI(T1,CURSX)\ LDN T1	; get the cursor X location
	XRI	MAXCOL-1	; are we at the right edge?
	LBNZ	RIGHT1		; nope - just move right and return
	LBR	AUTONL		; yes - do an automatic new line

	.SBTTL	Interpret Escape Sequences

;++
;   This routine is called whenever an escape character is detected and what
; happens depends, of course, on what comes next.  Unfortunately, that's
; something of a problem in this case - in a real terminal we could simply
; wait for the next character to arrive, but in this case nothing's going
; to happen until we return control to the application. 
;
;   The only solution is to keep a "flag" which lets us know that the last
; character was an ESCape, and then the next time we're called we process
; the current character differently.  Since many escape sequences interpret
; more than one character after the ESCape, we actually need a little state
; machine to keep track of what we shold do with the current character.
;--
ESCAPE:	LDI	EFIRST		; next state is EFIRST (ESCAP1)
ESCNXT:	STR	SP		; save that for a second
	RLDI(T1,ESCSTA)		; point to the escape state
	LDN SP\ STR T1		; update the next escape state
ESCRET:	RETURN			; and then wait for another character

;   Here for the first character after the <ESC> - this alone is enough
; for most (but not all!) escape sequences.  To that end, we start off by
; setting the next state to zero, so if this isn't changed by the action
; routine this byte will by default be the last one in the escape sequence.
ESCAP1:	LDI 0\ CALL(ESCNXT)	; set the next state to zero
	RLDI(T1,CURCHR)\ LDN T1	; get the current character back again
	SMI 'A'\ LBL ESCAP4	; is it less than 'A' ?
	SMI	'Z'-'A'+1	; check the other end of the sequence
	LBGE	ESCAP3		; ...
	LDN T1\ SMI 'A'		; convert the character to a zero based index
	CALL(LBRI)		; and dispatch to the right routine
	 .WORD	 ESCCHRU	;  ... VT52 standard escape sequences
	RETURN			; just return

;   All our extended, non-standard escape sequences consist of <ESC> followed
; by a lower case letter.  If this isn't a standard VT52 escape sequence, then
; check for that next.
ESCAP3:	LDN	T1		; get the character after the <ESC> again
	SMI 'a'\ LBL ESCRET	; see if it's a lower case letter
	SMI	'z'-'a'+1	; ...
	LBGE	ESCRET		; just ignore it if it's not lower case letters
	LDN T1\ SMI 'a'		; convert to a zero based index
	CALL(LBRI)		; dispatch to the right routine
	 .WORD	 ESCCHRL	;  ... extended escape sequences
	RETURN			; and we're done here

;   A real VT52 has two escape sequences where the <ESC> is NOT followed by
; a letter - <ESC> = (select alternate keypad mode) and <ESC> > (select
; numeric keypad mode).  They don't fit into our table scheme, so we just
; special case these ...
ESCAP4:	LDN T1\ SMI '='		; check for alternate keypad mode
	LBZ	ALTKPD		; select alternate keypad mode
	LDN T1\ SMI '>'		; and normal (numeric) keypad mode
	LBZ	NUMKPD		; ...
	LBZ	ESCRET		; just ignore anything else

	.SBTTL	Direct Cursor Addressing

;++
;   This routine implements the direct cursor addressing escape sequence.  The
; <ESC>Y sequence is followed by two data bytes which indicate the line and
; column (in that order) that the cursor is to move to. Both values are biased
; by 32 so that they are appear as printing ASCII characters.  The line number
; character should be in the range 32 to 55 (decimal), and the column number
; character may range from 32 to 71 (decimal).  If either byte is out of range,
; then the cursor will only move as far as the margin.
;
;   This is identical to the VT52 direct cursor addressing sequence, but the
; column number is limited to 40 rather than 80.
;
;   For example:
;	<ESC>Y<SP><SP>	- move to (0,0) (i.e. home)
;	<ESC>Y7G	- move to (39,23) (i.e. lower right)
;--

; Here for part 1 - <ESC>Y has been received so far...
DIRECT:	LDI EYNEXT\ LBR ESCNXT	; next state is get Y

; Part 2 - the current character is Y, save it and wait for X...
DIRECY:	RLDI(T1,CURCHR)\ LDA T1	; get the current character
	STR	T1		; and save CURCHR in SAVCHR
	LDI EXNEXT\ LBR ESCNXT	; next state is "get X"

; Part 3 - CURCHR is X and SAVCHR is Y.
DIRECX:	RLDI(T1,CURCHR)		; point T1 at CURCHR/SAVCHR
	RLDI(T2,CURSX)		; and T2 at CURSX/CURSY

;  First handle the X coordinate.  Remember that the cursor moves to the
; corresponding margin if the coordinate give is less than 0 or greater than
; MAXCOL-1!
	LDN T1\ SMI ' '		; get X and adjust for the ASCII bias
	LBGE	DIREC1		; branch if greater than zero
	LDI 0\ LBR DIRE12	; less than zero - use zero instead
DIREC1:	SMI MAXCOL\ LBNF DIRE11	; would it be greater than MAXCOL-1?
	LDI MAXCOL-1\ LBR DIRE12; yes - just use MAXCOL-1 instead
DIRE11:	LDN T1\ SMI ' '		; the original coordinate is OK
DIRE12:	STR	T2		; and update CURSX

; Now handle the Y coordinate (in SAVCHR) the same way...
	INC T1\ INC T2		; point to SAVCHR and CURSY
	LDN T1\ SMI ' '		; pretty much the same as before
	LBGE	DIREC2		; branch if greater than zero
	LDI 0\ LBR DIRE22	; nope - use zero instead
DIREC2:	SMI MAXROW\ LBNF DIRE21	; is it too big for the screen?
	LDI MAXROW-1\ LBR DIRE22; yes - use the bottom margin instead
DIRE21:	LDN T1\ SMI ' '		; the value is OK - get it back again
DIRE22:	STR	T2		; and update CURSY

;   Finally, update the cursor on the screen and we're done.  DON'T FORGET to
; change the next state (ESCSTA) to zero to mark the end of this sequence!
	CALL(UPDCURS)		; move the cursor
	LDI 0\ LBR ESCNXT	; next state is zero (back to normal)

	.SBTTL	Select Graphics, Reverse Video and Alternate Keypad

;++
;   On the VT52, the <ESC>F command selects the alternate graphics character
; set, and the <ESC>G command deselects it.  The SI (Shift In) and SO (Shift
; Out) control characters do the same...
;--

; Enable the graphics character set...
ENAACS:	RLDI(T1,ACSFLG)		; point to the ACS mode flag
	LDI ACSBIT\ STR T1	; set it to non-zero to enable
	RETURN			; and we're done

; Disable the graphics character set...
DSAACS:	RLDI(T1,ACSFLG)		; same as before
	LDI 0\ STR T1		; but set the ACS flag to zero
	RETURN			; ...


;++
;   A real VT52 doesn't have reverse video, but we do and we implement two
; additional escape sequences, <ESC>R to select reverse video and <ESC>N to
; select normal video.
;--

; Enable reverse video for all subsequent characters ...
ENARVV:	RLDI(T1,RVVFLG)		; point to the reverse video flag
	LDI RVVBIT\ STR T1	; set it to non-zero to enable
	RETURN			; and we're done

; Return to normal video for all subsequent characters ...
DSARVV:	RLDI(T1,RVVFLG)		; same as above
	LDI 0\ STR T1		; but clear the reverse video flag
	RETURN			; ...


;++
;   The sequence <ESC> = slects alternate keypad mode, and <ESC> > selects
; normal (numeric) keypad mode ...
;--

; Select alternate keypad mode ...
ALTKPD:	RLDI(T1,KPDALT)		; point to the alternate keypad mode flag
	LDI $FF\ STR T1		; and make it non-zero for alternate mode
	RETURN			; ...

; Select numeric keypad mode ...
NUMKPD:	RLDI(T1,KPDALT)		; same as above!
	LDI $00\ STR T1		; but set it to zero for numeric keypad mode
	RETURN			; ...

	.SBTTL	Select Background Color

;++
;   The <ESC>c command selects the background color for the screen.  This
; escape sequence needs a single argument, an ASCII character '0' .. '7'
; and that specifies the background color code.  Any character outside that
; range is ignored.
;--
ESCP:	LDI EPNEXT\ LBR ESCNXT	; wait for the color code

; Here when we get the next byte...
ESCP1:	LDI 0\ CALL(ESCNXT)	; set ESCSTA to zero for next time
	RLDI(T1,CURCHR)\ LDN T1	; get the argument character
	SMI '0'\ LBL ESCRET	; ignore if .LT. '0'
	SMI  8 \ LBGE ESCRET	;  ... or if .GT. '7'
	LDN T1\ SMI '0'\ STR SP	; save the new background color
	RLDI(T1,CURCLR)\ LDN T1	; get the current color mode settings
	ANI $F8\ SEX SP\ OR	; combine the new background
	STR T1\ LBR DSPON	; DSPON will update the VISCOLR register

	.SBTTL	Select Foreground Colors

;++
;   The <ESC>b command selects the color for the primary and alternate fonts.
; The escape sequence should be followed by a single character in the range
; 0x20 to 0x5F, the lower six bits of which select the colors.  The lowest
; three bits are the alternate font color, and the upper three bits are the
; primary font color.  If the 128 character font is in use then there's only
; a primary font, and the secondary font color bits are ignore.
;
;   The COLORS table on the next page gives a nice summary of the ASCII code
; and the corresponding character needed for each color combination!
;--
ESCO:	LDI EONEXT\ LBR ESCNXT	; wait for the color code

; Here when we receive the next byte...
ESCO1:	LDI 0\ CALL(ESCNXT)	; first, set ESCSTA to zero
	RLDI(T1,CURCHR)\ LDN T1	; and then get the current character
	SMI $20\ LBL ESCRET	; ignore if .LT. 0x20
	SMI $40\ LBGE ESCRET	;  ... or if .GT 0x5F
	PUSHR(P2)\ PUSHR(P3)	; we need a couple more working registers

;   Compute an index into the COLORS table.  Note that if the table entry is
; 0xFF, then this color combination is impossible!
	LDN T1\ SMI $20		; get the <ESC>b argument again
	ADI LOW(COLORS)\ PLO P3	; and index into the COLORS table
	LDI 0\ ADCI HIGH(COLORS); ...
	PHI P3\ LDN P3\ XRI $FF	; is this combination impossible?
	LBZ	ESCO12		; yes - ignore it

; Turn the display off until the color change is finished!
	CALL(DSPOFF)

;   Now we need to reload the fonts, both normal and reverse video forms.
; The upper two bits of the COLORS table gives us the CCB bits for the primary
; font, and the next two bits of COLORS are the CCB bits for the alternate
; font.  With the 128 character font we only use the primary colors and ignore
; the alternate.
	RLDI(P1,FONT)		; point to the font table
	.IF (FONTSIZE == 64)
	LDI 0\ PHI P2		; clear the reverse video bits
	LDN P3\ ANI $C0\ PLO P2	; set the primary font color
	LDI 0\ CALL(LDFONT)	; load font characters 0..63
	LDI RVVMASK\ PHI P2	; now select reverse video
	LDI 128\ CALL(LDFONT)	; and load characters 128..191
	LDN P3\ ANI $30		; get the alternate font colors
	SHL\ SHL\ PLO P2	; ...
	LDI 192\ CALL(LDFONT)	; load the alternate reverse video font
	LDI 0\ PHI P2		; ...
	LDI 64\ CALL(LDFONT)	; load the alternate normal video font
	.ENDIF
	.IF (FONTSIZE == 128)
	LDI 0\ PHI P2		; clear the reverse video bits
	LDN P3\ ANI $C0\ PLO P2	; load the primary font color
	LDI 0\ CALL(LDFONT)	; load characters 0..127
	LDI RVVMASK\ PHI P2	; select reverse video
	LDI 128\ CALL(LDFONT)	; and load the reverse video font
	.ENDIF

; Finally, set the PCB and COLB1/0 bits for the CDP1870/76 ...
	CALL(SELIO1)		; VIDMODE is in I/O group 1
	LDN P3\ ANI 1		; is the PCB bit set in COLORS?
	LBZ	ESCO11		; skip if not
	LDI FL.PCB1\ LSKP	; yes, set PCB=1
ESCO11:	LDI FL.PCB0		; no, set PCB=0
	STR	SP		; store on the stack for OUT
	OUT FLAGS\ DEC SP	; set/clear the PCB bit
	RLDI(T1,CURCLR)\ LDN T1	; current COLB0/1 are stored here
	ANI $9F\ STR SP		; clear the current COLB0/1 bits
	LDN P3\ ANI $0C		; get just the COLB0/1 bits from COLORS
	SHL\ SHL\ SHL\ OR	; position them correctly and combine
	STR T1\ CALL(DSPON)	; display on and set the color map bits

; All done here!!
ESCO12:	IRX\ POPR(P3)		; restore the extra registers we saved
	POPRL(P2)\ RETURN	; and we're done

	.SBTTL	Color Tables

;++
;   The VIS chipset has three different fields, seven bits total, that we can
; control to give us a selection from just eight colors!  First, there are the
; two color control bits, CCB1/0, stored in each font glyph.  And next there
; are the two color mapping bits, COLB1/0, stored in the CDP1870/76 that 
; control how the CCB bits are mapped to the RGB outputs.  And lastly there's
; the page color bit, PCB, that supplies an extra color mapping selection.
; Whew!
;
;   This table tells us how to set those seven bits for any combination of
; two foreground colors, one for the primary font and one for the alternate
; font.  Note that certain combinations are just not possible, for example,
; there's no combination of settings that will give you blue and yellow on
; screen at the same time.  Those are indicated by a $FF in the table.
;
;				FONT CCB1/0
;  PCB	COLB1/0		00	01	10	11
;  ---	-------		------- -------	-------	------
;   0      00		BLACK	RED	BLUE	MAGENTA
;   0	   01		BLACK	RED	GREEN	YELLOW
;   0	   1x		BLACK	BLUE	GREEN	CYAN
;   1	   00		GREEN	YELLOW	CYAN	WHITE
;   1	   01		BLUE	MAGENTA	CYAN	WHITE
;   1	   1x		RED	MAGENTA	YELLOW	WHITE
;--
#define COLOR(pcb,colb,ccb1,ccb2)	.BYTE (ccb1<<6)+(ccb2<<4)+(colb<<2)+pcb

;	color code	 <ESC>b arg	primary	alternate
;					font1	font2
;	-------------	 ----------	-------	---------
COLORS:	COLOR(0,0,0,0)	; 0x20	sp	BLACK	BLACK
	COLOR(0,0,0,2)	; 0x21	!	BLACK	BLUE
	COLOR(0,0,0,1)	; 0x22	"	BLACK	RED
	COLOR(0,0,0,3)	; 0x23	#	BLACK	MAGENTA
	COLOR(0,2,0,2)	; 0x24	$	BLACK	GREEN
	COLOR(0,2,0,3)	; 0x25	%	BLACK	CYAN
	COLOR(0,1,0,3)	; 0x26	&	BLACK	YELLOW
	.BYTE	$FF 	; 0x27	'	BLACK	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,0,2,0)	; 0x28	(	BLUE	BLACK
	COLOR(0,0,2,2)	; 0x29	)	BLUE	BLUE
	COLOR(0,0,2,1)	; 0x2A	*	BLUE	RED
	COLOR(0,0,2,3)	; 0x2B	+	BLUE	MAGENTA
	COLOR(0,2,1,2)	; 0x2C	,	BLUE	GREEN
	COLOR(0,2,1,3)	; 0x2D	-	BLUE	CYAN
	.BYTE	$FF	; 0x2E	.	BLUE	YELLOW
	COLOR(1,1,0,3)	; 0x2F	/	BLUE	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,0,1,0)	; 0x30	0	RED	BLACK
	COLOR(0,0,1,2)	; 0x31	1	RED	BLUE
	COLOR(0,0,1,1)	; 0x32	2	RED	RED
	COLOR(0,0,1,3)	; 0x33	3	RED	MAGENTA
	COLOR(0,1,1,2)	; 0x34	4	RED	GREEN
	.BYTE	$FF 	; 0x35	5	RED	CYAN
	COLOR(1,2,0,2)	; 0x36	6	RED	YELLOW
	COLOR(1,2,0,3)	; 0x37	7	RED	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,0,3,0)	; 0x38	8	MAGENTA	BLACK
	COLOR(0,0,3,2)	; 0x39	9	MAGENTA	BLUE
	COLOR(0,0,3,1)	; 0x3A	:	MAGENTA	RED
	COLOR(0,0,3,3)	; 0x3B	;	MAGENTA	MAGENTA
	.BYTE	$FF	; 0x3C	<	MAGENTA	GREEN
	COLOR(1,1,1,2)	; 0x3D	=	MAGENTA	CYAN
	COLOR(1,2,1,2)	; 0x3E	>	MAGENTA	YELLOW
	COLOR(1,2,1,3)	; 0x3F	?	MAGENTA	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,1,2,0)	; 0x40	@	GREEN	BLACK
	COLOR(0,2,2,1)	; 0x41	A	GREEN	BLUE
	COLOR(0,1,2,1)	; 0x42	B	GREEN	RED
	.BYTE	$FF	; 0x43	C	GREEN	MAGENTA
	COLOR(1,0,0,0)	; 0x44	D	GREEN	GREEN
	COLOR(1,0,0,2)	; 0x45	E	GREEN	CYAN
	COLOR(1,0,0,1)	; 0x46	F	GREEN	YELLOW
	COLOR(1,0,0,3)	; 0x47	G	GREEN	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,2,3,0)	; 0x48	H	CYAN	BLACK
	COLOR(0,2,3,1)	; 0x49	I	CYAN	BLUE
	.BYTE	$FF	; 0x4A	J	CYAN	RED
	COLOR(1,1,2,1)	; 0x4B	K	CYAN	MAGENTA
	COLOR(1,0,2,0)	; 0x4C	L	CYAN	GREEN
	COLOR(1,0,2,2)	; 0x4D	M	CYAN	CYAN
	COLOR(1,0,2,1)	; 0x4E	N	CYAN	YELLOW
	COLOR(1,0,2,3)	; 0x4F	O	CYAN	WHITE

;     pcb,colb,ccb1,ccb2
	COLOR(0,1,3,0)	; 0x50	P	YELLOW	BLACK
	.BYTE	$FF	; 0x51	Q	YELLOW	BLUE
	COLOR(0,1,3,1)	; 0x52	R	YELLOW	RED
	COLOR(1,2,2,1)	; 0x53	S	YELLOW	MAGENTA
	COLOR(1,0,1,0)	; 0x54	T	YELLOW	GREEN
	COLOR(1,0,1,2)	; 0x55	U	YELLOW	CYAN
	COLOR(1,0,1,1)	; 0x56	V	YELLOW	YELLOW
	COLOR(1,0,1,3)	; 0x57	W	YELLOW	WHITE

;     pcb,colb,ccb1,ccb2
	.BYTE	$FF	; 0x58	X	WHITE	BLACK
	COLOR(1,1,3,0)	; 0x59	Y	WHITE	BLUE
	COLOR(1,2,3,0)	; 0x5A	Z	WHITE	RED
	COLOR(1,2,3,1)	; 0x5B	[	WHITE	MAGENTA
	COLOR(1,0,3,0)	; 0x5C	\	WHITE	GREEN
	COLOR(1,0,3,2)	; 0x5D	]	WHITE	CYAN
	COLOR(1,0,3,1)	; 0x5E	^	WHITE	YELLOW
	COLOR(1,0,3,3)	; 0x5F	_	WHITE	WHITE

	.SBTTL	Identify (Answerback) Function

;++
;   If we receive the escape sequence <ESC>Z (identify) then we respond by
; sending <ESC>/K (VT52 without copier).  If we receive a Control-E (ENQ) then
; we respond the same.  Not sure if a real VT52 did the latter, but it's the
; standard ASR-33 answerback code.   FWIW, I believe this is the only case
; where we send a reply back to the host!
;--
IDENT:	LDI	CH.ESC		; send <ESC>
IDENT1:	CALL(SERPUT)		; ...
	 LBDF	 IDENT1		; ... loop if the buffer is full
	LDI	'/'		; ...
IDENT2:	CALL(SERPUT)		; ...
	 LBDF	 IDENT2		; ...
	LDI	'K'		; and the last byte
IDENT3:	CALL(SERPUT)		; ...
	 LBDF	 IDENT3		; ...
	RETURN

	.SBTTL	Indirect Table Jump

;++
;   This routine will take a table of two byte addresses, add the index passed
; in the D register, and then jump to the selected routine.  It's used to
; dispatch control characters, escape characters, and the next state for the
; escape sequence state machine.
;
; CALL:
;	 <put the jump index, 0..n, in D>
;	 CALL(LBRI)
;	 .WORD	TABLE
;  	 .....
; TABLE: .WORD	fptr0	; address of routine 0
;	 .WORD	fptr1	;  "   "  "   "   "  1
;	 ....
;
;   Notice that the index starts with zero, not one, and that it's actually
; an index rather than a table offset.  The difference is that the former 
; is multiplied by two (since every table entry is a byte) and the latter
; wouldn't be!
;
;   Since this function is called by a CALL() and it actually jumps to the
; destination routine, that routine can simply execute a RETURN to return
; back to the original caller.  The inline table address will be automatically
; skipped.
;
; Uses T1 and T2 ...
;--
LBRI:	SHL\ STR SP		; multiply the jump index by 2
	LDA A\ PHI T1		; get the high byte of the table address
	LDA A\ ADD\ PLO T1	; add the index to the table address
	GHI T1\ ADCI 0\ PHI T1	; then propagate the carry bit
	RLDI(T2,LBRI1)\ SEP T2	; then switch the PC to T2

; Load the address pointed to by T1 into the PC and continue
LBRI1:	LDA T1\ PHI PC		; get the high byte of the address
	LDA T1\ PLO PC		; and then the low byte
	SEP	PC		; and away we go!

	.SBTTL	Control Character Dispatch Table

;++
;   This table is used by LBRI and VTPUTC to dispatch to the correct function
; for any ASCII code .LT. 32.  Any unused control characters should just
; point to NOOP, which simply executes a RETURN instruction.  Note that the
; ASCII NUL code is trapped in VTPUTC and never gets here, but its table
; entry is required anyway to make the rest of the offsets correct.
;--
CTLTAB:	.WORD	NOOP		; 0x00 ^@ NUL
	.WORD	NOOP		; 0x01 ^A SOH
	.WORD	NOOP		; 0x02 ^B STX
	.WORD	NOOP		; 0x03 ^C ETX
	.WORD	NOOP		; 0x04 ^D EOT
	.WORD	IDENT		; 0x05 ^E ENQ - identify (send answerback)
	.WORD	NOOP		; 0x06 ^F ACK
	.WORD	BELL		; 0x07 ^G BEL - ring the "bell" on the CDP1869
	.WORD	LEFT		; 0x08 ^H BS  - cursor left (backspace)
	.WORD	TAB		; 0x09 ^I HT  - move right to next tab stop
	.WORD	LINEFD		; 0x0A ^J LF  - cursor down and scroll up
	.WORD	LINEFD		; 0x0B ^K VT  - vertical tab is the same as LF
	.WORD	ERASE		; 0x0C ^L FF  - form feed erases the screen
	.WORD	CRET		; 0x0D ^M CR  - move cursor to left margin
	.WORD	DSAACS		; 0x0E ^N SO  - select normal character set
	.WORD	ENAACS		; 0x0F ^O SI  - select graphics character set
	.WORD	NOOP		; 0x10 ^P DLE
	.WORD	NOOP		; 0x11 ^Q DC1
	.WORD	NOOP		; 0x12 ^R DC2
	.WORD	NOOP		; 0x13 ^S DC3
	.WORD	NOOP		; 0x14 ^T DC4
	.WORD	NOOP		; 0x15 ^U NAK
	.WORD	NOOP		; 0x16 ^V SYN
	.WORD	NOOP		; 0x17 ^W ETB
	.WORD	NOOP		; 0x18 ^X CAN
	.WORD	NOOP		; 0x19 ^Y EM
	.WORD	NOOP		; 0x1A ^Z SUB
	.WORD	ESCAPE		; 0x1B ^[ ESC - introducer for escape sequences
	.WORD	NOOP		; 0x1C ^\
	.WORD	NOOP		; 0x1D ^] GS
	.WORD	NOOP		; 0x1E ^^ RS
	.WORD	NOOP		; 0x1F ^_ US

NOOP:	RETURN

	.SBTTL	Escape Sequence State Table

;++
;   Whenever we're processing an escape sequence, the index of the next
; state is stored in location ESCSTA.  When the next character arrives
; that value is used as an index into this table to call the next state.
;--
#define XX(n,r)	.WORD r\n .EQU ($-ESTATE-2)/2

ESTATE:	.WORD	0		; 0 - never used
	XX(EFIRST,ESCAP1)	; 1 - first character after <ESC>
	XX(EYNEXT,DIRECY)	; 2 - <ESC>Y, get first byte (Y)
	XX(EXNEXT,DIRECX)	; 3 - <ESC>Y, get second byte (X)
	XX(EONEXT,ESCO1)	; 4 - <ESC>b, select foreground colors
	XX(EPNEXT,ESCP1)	; 5 - <ESC>c, select background color

	.SBTTL	Escape Sequence Dispatch Table

;++
;  All the standard VT52 escape sequences use <ESC> followed by an upper case
; letter (with the exception of the application/numeric keypad, but that's
; handled separately).  This table is used to decode the first character in a
; standard VT52 escape sequence.  Our own custom escape sequences use lower
; case letters, which are handled in the next table.
;--
ESCCHRU:.WORD	UP		; <ESC>A -- cursor up
	.WORD	DOWN		; <ESC>B -- cursor down
	.WORD	RIGHT		; <ESC>C -- cursor right
	.WORD	LEFT		; <ESC>D -- cursor left
	.WORD	ERASE		; <ESC>E -- erase screen
	.WORD	ENAACS		; <ESC>F -- select alternate character set
	.WORD	DSAACS		; <ESC>G -- select normal character set
	.WORD	HOME		; <ESC>H -- cursor home
	.WORD	RLF		; <ESC>I -- reverse line feed
	.WORD	EEOS		; <ESC>J -- erase to end of screen
	.WORD	EEOL		; <ESC>K -- erase to end of line
	.WORD	NOOP		; <ESC>L -- Unimplemented
	.WORD	NOOP		; <ESC>M -- unimplemented
	.WORD	NOOP		; <ESC>N -- unimplemented
	.WORD	NOOP		; <ESC>O -- unimplemented
	.WORD	NOOP		; <ESC>P -- unimplemented
	.WORD	NOOP		; <ESC>Q -- unimplemented
	.WORD	NOOP		; <ESC>R -- unimplemented
	.WORD	NOOP		; <ESC>S -- unimplemented
	.WORD	NOOP		; <ESC>T -- unimplemented
	.WORD	NOOP		; <ESC>U -- unimplemented
	.WORD	NOOP		; <ESC>V -- unimplemented
	.WORD	NOOP		; <ESC>W -- unimplemented
	.WORD	NOOP		; <ESC>X -- unimplemented
	.WORD	DIRECT		; <ESC>Y -- direct cursor addressing
	.WORD	IDENT		; <ESC>Z -- identify


;++
;   And this table decodes escape sequences where the next character after
; the <ESC> is a lower case letter.  These are our own VIS1802 custom sequences.
;--
ESCCHRL:.WORD	NOOP		; <ESC>a -- unimplemented
	.WORD	ESCO		; <ESC>b -- select foreground colors
	.WORD	ESCP		; <ESC>c -- select background color
	.WORD	ENACURS		; <ESC>d -- display cursor
	.WORD	GERASE		; <ESC>e -- erase graphics screen
	.WORD	NOOP		; <ESC>f -- unimplemented
	.WORD	GMODE		; <ESC>g -- display graphics screen
	.WORD	DSACURS		; <ESC>h -- hide cursor
	.WORD	NOOP		; <ESC>i -- unimplemented
	.WORD	NOOP		; <ESC>j -- unimplemented
	.WORD	NOOP		; <ESC>k -- unimplemented
	.WORD	NOOP		; <ESC>l -- draw line
	.WORD	NOOP		; <ESC>m -- unimplemented
	.WORD	DSARVV		; <ESC>n -- disable reverse video
	.WORD	NOOP		; <ESC>o -- unimplemented
	.WORD	NOOP		; <ESC>p -- plot point
	.WORD	NOOP		; <ESC>q -- unimplemented
	.WORD	ENARVV		; <ESC>r -- enable reverse video
	.WORD	NOOP		; <ESC>s -- unimplemented
	.WORD	TMODE		; <ESC>t -- display text screen
	.WORD	NOOP		; <ESC>u -- unimplemented
	.WORD	NOOP		; <ESC>v -- enable auto newline
	.WORD	NOOP		; <ESC>w -- disable auto newline
	.WORD	NOOP		; <ESC>x -- unimplemented
	.WORD	NOOP		; <ESC>y -- unimplemented
	.WORD	NOOP		; <ESC>z -- unimplemented

	.SBTTL	Advanced Cursor Motions

;++
;   TAB will move the cursor to the next tab stop, which are located in columns
; 9, 17, 25, and 33 (i.e. column 8i+1, 0<=i<=4). But after column 33, a tab
; will only advance the cursor to the next character, and once the cursor
; reaches the right margin a tab will not advance it any further.  This is 
; similar to the way a real terminal works, except that they usually have 80
; columns and 9 tab stops up to column 72.
;--
TAB:	RLDI(T1,CURSX)\ LDN T1	; get the current column of the cursor
	SMI	MAXCOL-8-1	; are we close to the right edge of the screen?
	LBGE	RIGHT		; just do a single right motion if we are
	LDN T1\ ANI $F8		; clear the low 3 bits of the address
	ADI 8\ STR T1		; advance to the next multiple of 8
	LBR	UPDCURS		; change the picture on the screen


;++
;   Carriage return moves the cursor back to the left margin of the current
; line.  The vertical cursor position doesn't change.
;--
CRET:	RLDI(T1,CURSX)		; point to the X cursor location
	LDI 0\ STR T1		; and set it to the first column
	LBR	UPDCURS		; update the screen and we're done

;++
;   CRIGHT is the opposite of carriage return - it moves the cursor to the 
; right margin of the current line ...
;--
CRIGHT:	RLDI(T1,CURSX)		; change the X cursor position
	LDI MAXCOL-1\ STR T1	; to the right margin
	LBR	UPDCURS		; update the cursor and we're done


;++
;   This routine will implement the line feed function. This function will
; move the cursor down one line, unless the cursor happens to be on the
; bottom of the screen. In this case the screen is scrolled up one line and
; the cursor remains in the same location (on the bottom line of the screen).
;--
AUTONL:	CALL(CRET)		; here for an auto carriage return/line feed
LINEFD: RLDI(T1,CURSY)\ LDN T1	; get the line location of the cursor
	SMI	MAXROW-1	; is it on the bottom of the screen ?
	LBL	DOWN		; just do a down operation if it is
	LBR	SCRUP		; otherwise go scroll the screen up

;++
;   This routine will implement the reverse line feed function.  This
; function will move the cursor up one line, unless the cursor happens to
; be on the top of the screen. In this case the screen is scrolled down one
; line and the cursor remains in the same location (on the screen).
;--
RLF:	RLDI(T1,CURSY)\ LDN T1	; load the current Y location of the cursor
	LBNZ	UP		; do cursor up if we're not at the top
	LBR	SCRDWN		; otherwise go scroll the screen down

	.SBTTL	Screen Scrolling Routines

;++
;   This routine will scroll the screen up one line. The new bottom line on
; the screen (which used to be the top line) is then cleared to	all spaces.
; The cursor position on the screen does NOT CHANGE, but that's tricky because
; CURSADR is actually a physical page memory pointer.  To keep the cursor in
; the same relative position on the screen, we actually need to move it down
; a row.
;--
SCRUP:	RLDI(T1,TOPLIN)\ LDN T1	; get the current top line on the screen
	PLO	P1		; and remember that for later
	ADI 1\ STR T1		; then move the top line down to the next line
	SMI MAXROW\ LBL SCRUP1	; do we need to wrap the line counter around ?
	LDI 0\ STR T1		; yes -- reset back to the top line
SCRUP1:	GLO	P1		; then get back the number of the bottom line
	CALL(LINADD)		; calculate its address
	CALL(CLRLIN)		; and then go clear it
	CALL(UPDCURS)		; move the cursor down a row
	LBR	UPDTOS		; update the VIS chipset and we're done


;++
;   This routine will scroll the screen down one line. The new top line on the
; screen (which used to be the bottom line) is the cleared to all spaces.  Like
; SCRUP, the position of the cursor on the screen does not change, but since
; TOPLIN moves we have to re-calculate the new cursor address.
;--
SCRDWN:	RLDI(T1,TOPLIN)\ LDN T1	; get the line number of the top of the screen
	SMI 1\ LBGE SCRDW1	; jump if we don't need to wrap around
	LDI	MAXROW-1	; wrap around to the other end of the screen
SCRDW1: STR	T1		; update the top line on the screen
	CALL(LINADD)		; calculate the address of this line
	CALL(CLRLIN)		; clear the new line and we're done
	CALL(UPDCURS)		; move the cursor up a row
	LBR	UPDTOS		; update the VIS chipset and we're done


;++
;   This routine updates the HMA (home memory address) register in the VIS
; to correspond to the new top line on the screen.  It needs to be called
; any time TOPLIN is changed (i.e. for any scrolling operation!).
;--
UPDTOS:	RLDI(T1,GMODEF)\ LDN T1	; are we in graphics mode?
	LBNZ	UPDTO9		; yes - no scrolling in graphcis mode!
	CALL(SELIO0)		; select I/O group 0
	RLDI(T1,TOPLIN)\ LDN T1	; find the address of the top of the screen
	CALL(LINADD)		; ...
	SEX P1\ OUT VISHMA	; update the HMA register
UPDTO9:	RETURN			; and we're done

	.SBTTL	Screen Erase Functions

;++
;   This routine will erase all characters from the current cursor location
; to the end of the screen, including the character under the cursor.  The
; cursor doesn't actually move and any characters before the cursor aren't
; changed.
;
;   Note that this is fairly slow because it does NOT turn off the display.
; Because of that it has to wait for the VBI for every character that it's
; erasing, and that adds up when you're doing a lot.  If you want to home the
; cursor AND erase the entire screen at the same time, then call ERASE instead.
; That one does disable video during the erase and is much faster.
;
; Uses T1, T2 and P1.
;--
EEOS:	CALL(TMODE)		; be sure the text screen is displayed
	RLDI(T1,TOPLIN)\ LDN T1	; find the line that's on the top of the screen
	CALL(LINADD)		; then calculate its address in P1
	RCOPY(T2,P1)		; put that address in T2 for a while
	CALL(WHERE)		; and find out where the cursor is
EEOS1:	B_DISPLAY $		; synchronize with the display
	LDI BLANK\ STR P1	; clear this character
	INC P1\ GLO P1		; and increment the pointer
	XRI	LOW(PAGEEND)	; have we reached the end of the screen space ?
	LBNZ	EEOS2		; jump if we haven't
	GHI P1\ XRI HIGH(PAGEEND); check both bytes
	LBNZ	EEOS2		; again jump if we haven't
	RLDI(P1,PAGEMEM)	; yes -- wrap around to the start of the screen
EEOS2:	GLO P1\ STR SP		; get the low byte of the address (again!)
	GLO T2\ XOR		; have we reached the top of the screen yet ?
	LBNZ	EEOS1		; keep clearing if we haven't
	GHI P1\ STR SP		; maybe -- we need to check the high byte too
	GHI T2\ XOR		; ????
	LBNZ	EEOS1		; keep on going if we aren't there yet
	LBR	EEOL2		; clear CURSCHR too and we're done


;++
;   This routine will erase all characters from the current cursor location to
; the end of the line, including the character under the cursor.
;
; Uses T1 and P1 ...
;--
EEOL:	CALL(TMODE)		; be sure the text screen is displayed
	CALL(WHERE)		; set P1 = address of the cursor
	RLDI(T1,CURSX)\ LDN T1	; get the current column of the cursor
	SMI MAXCOL\ PLO T1	; how many characters remain on this line
EEOL1:	B_DISPLAY $		; synchronize PMEM access
	LDI BLANK\ STR P1	; blank this character
	INC	 P1		; ... and advance to the next character
	INC T1\ GLO T1		; count the number of characters cleared
	LBNZ	EEOL1		; keep going until the EOL
;   We don't need to worry about the blinking cursor here, since we just erase
; the blink bit along with everything else.  But we do need to erase the old
; character stored at CURSCHR; if we don't, then the old character will come
; back as soon as we move the cursor!
EEOL2:	RLDI(T1,CURSCHR)	; point to CURSCHR
	LDI BLANK\ STR T1	; and erase that too
	RETURN			; that's all there is



;++
;   This routine will home the cursor AND erase the entire screen. It actually
; turns off the display while it's working (you'll hardly notice, since the
; screen is being erased anyway!) and that means we don't have to wait for
; access to page memory.
;
; Uses T1 and T2.
;--
ERASE:	CALL(TMODE)		; be sure the text screen is displayed
	CALL(DSPOFF)		; turn the screen refresh off
	RLDI(T1,TOPLIN)		; set TOPLIN, cursor X and Y to zeros
	LDI 0\ STR T1		; ...
	INC T1\ STR T1		; ...
	INC T1\ STR T1		; ...
	RLDI(T1,CURSADR)	; reset the cursor address
	LDI	HIGH(PAGEMEM)	; ...
	STR T1\ INC T1		; ...
	LDI	LOW(PAGEMEM)	; ...
	STR T1\ INC T1		; ...
	LDI BLANK\ STR T1	; and clear CURSCHR
	RLDI(T1,PAGEMEM)\ SEX T1; point at the top of page memory
	RLDI(T2,PAGESIZE)	; and load the number of characters
 NOP\ NOP\ NOP ; for alignment
ESCR1:	B_DISPLAY $		; shouldn't need this, but we do!!
	LDI BLANK\ STR T1\ INC T1; clear another byte
	DBNZ(T2,ESCR1)		; loop over the entire page memory
	RCLR(T1)\ SEX T1	; reset the HMA register
	OUT	VISHMA		; ...
	LBR	DSPON		; turn the display back on and we're done

;++
;   This routine will clear 40 characters in the page memory.  This is normally
; used to erase lines for scrolling purposes. It expects the address of the
; first byte to be passed in P1; this byte and the next 39 are set to a space
; character.
;
;  Uses T1 ...
;--
CLRLIN:	LDI MAXCOL\ PLO T1	; characters per line stored here
CLRLI1:	B_DISPLAY $		; synchronize PMEM access
	LDI BLANK\ STR P1	; set this byte to a space
	INC P1\ DEC T1\ GLO T1	; and advance to the next one
	LBNZ	CLRLI1		; loop until we've done all 40
	RETURN			; and that's all for now

	.SBTTL	Basic Cursor Motions

;++
;   This routine will implement the home function which moves the cursor to the
; upper left corner of the screen.  Nothing else changes, and no characters
; on the screen are altered.
;--
HOME:	RLDI(T1,CURSX)		; (CURSX comes before CURSY)
	LDI 0\ STR T1		; set both CURSX and CURSY to zero
	INC T1\ STR T1		; and CURSY...
	LBR	UPDCURS		; then let the user see the change


;++
;   This routine will implement the cursor left function. This will move the
; cursor left one character. If, however, the cursor is already against the
; left  margin of the screen, then no action occurs.
;--
LEFT:	RLDI(T1,CURSX)\ LDN T1	; get the cursor column number
	SMI 1\ LBL CURRET	; quit if we're already the left margin
	STR T1\ LBR UPDCURS	; change the software cursor and update screen


;++
;   This routine will implement the cursor right function. This will move the
; cursor right one character. If, however, the cursor is already against the
; right margin of the screen, then no action occurs.
;--
RIGHT:	RLDI(T1,CURSX)\ LDN T1	; get the cursor X location
	XRI MAXCOL-1\ LBZ CURRET; don't allow it to move past the right margin
RIGHT1:	LDN T1\ ADI 1\ STR T1	; its safe to move right
	LBR	UPDCURS		; and update the screen


;++
;   This routine will implement the cursor up function.  This will move the
; cursor up one character line. If, however, the cursor is already at the top
; of the screen, then no action occurs.
;--
UP:	RLDI(T1,CURSY)\ LDN T1	; get the row which contains the cursor
	SMI 1\ LBL CURRET	; don't allow it to move past the top line
	STR T1\ LBR UPDCURS	; no -- change the virtual location
	LBR	UPDCURS		; change the software cursor and update screen


;++
;   This routine will implement the cursor down function. This will move the
; cursor down one character line. If, however, the cursor is already at the
; bottom of the screen, then no action occurs.
;--
DOWN:	RLDI(T1,CURSY)\ LDN T1	; get the row number where the cursor is
	XRI MAXROW-1\ LBZ CURRET; don't allow the Y position to go off screen
	LDN T1\ ADI 1\ STR T1	; its safe to move down
	LBR	UPDCURS		; and update the screen

	.SBTTL	Cursor Functions

;++
;   This routine will update the displayed cursor location so that it agrees
; with the software location in (CURSX, CURSY).  This routine sould be called
; after most cursor motion functions to actually change the image on the screen.
;
;   The cursor is implemented by having the VISISR toggle the CURSBIT on the
; character at the cursor location.  If font memory is set up correctly, this
; will toggle the character between normal and reverse video, which gives us
; a very conventional looking blinking block cursor.
;
;   To make this work we have to set up a couple of things.  First, we have to
; store the absolute address in page memory of the cursor character so the ISR
; can use it to toggle the cursor bit.  Second, since the reverse video font
; can be used by regular text too, it's possible that the character at the
; cursor location was originally in reverse video.  No problem, but when we go
; to move the cursor elsewhere then we have to restore the original character
; at the old cursor location.  We save a copy of the character in location
; CURSCHR for just that reason.
;
;   One more thing - remember that the VISISR is busy toggling the cursor bit
; all the time, so we have to disable interrupts while we mess with the cursor
; data to avoid any conflicts.
;
; Uses T1 and T2 ...
;--
;;  NOP\ NOP\ NOP	; for alignment
UPDCURS:CALL(TMODE)		; be sure the text screen is displayed
	CALL(WHERE)		; get the new cursor address and leave in P1
	IOFF			; no interrupts for now
	RLDI(T1,CURSADR)	; get the old cursor address
	LDA T1\ PHI T2		; load the address of the character under
	LDA T1\ PLO T2		;  ... the cursor into T2
	B_DISPLAY $		; synchronize with the display
	LDN T1\ STR T2		; restore the character at the old location
	LDN P1\ STR T1		; save the character at the new location
	DEC T1\ DEC T1		; backup pointer to CURSADR
	GHI P1\ STR T1\ INC T1	; save the new cursor location
	GLO P1\ STR T1		; ...
	ION			; everything is safe now
	RETURN			; and we're done


;++
;   This routine will change the character on the screen at the current cursor
; location.  You might think that this is as easy as just writing it to page
; memory, but there's the complication that we have copy stored in CURSCHR,
; as well as the binking thing.  It's trickier than you think!  Note that we
; don't need to call WHERE here (which saves a lot of time) because we already
; know where the cursor is.
;
;   The new character that will replace the one currently under the cursor,
; is passed in D.  Uses T1 and T2 ...
;--
UPDCCHR:IOFF			; interrupts off for now
	STR	SP		; save the new character for a moment
	RLDI(T1,CURSADR)	; point to the cursor location in PMEM
	LDA T1\ PHI T2		; and put that in T2
	LDA T1\ PLO T2		; ...
	LDN SP\ STR T1		; update CURSCHR
	B_DISPLAY $		; synchronize with the display
	STR	T2		; and then update the screen too
	ION			; all done with the dangerous part
	RETURN			; ...


;++
;   This subroutine will compute the actual address of the character under the
; cursor.  This address depends on the cursor location (obviously) and also
; the value of TOPLIN (which represents the number of the top line on the
; screen after scrolling).  The address computed is returned in P1.  Uses T1.
;--
WHERE:	RLDI(T1,TOPLIN)\ LDA T1	; get the current TOPLIN for starters
	INC T1\ SEX T1		; (skip over CURSX for a moment)
	ADD			; compute TOPLIN+CURSY
	CALL(LINADD)		; set P1 = address of the cursor line
	RLDI(T1,CURSX)		; now add in the cursor X address
	GLO P1\ SEX T1		; get the low byte of the line address
	ADD\ PLO P1		; and add in the cursor X location
	GHI P1\ ADCI 0\ PHI P1	; and propagate the carry
CURRET:	RETURN			; leave the address in P1 and we're done...


;++
;   This routine will disable display of the cursor.  Note that the cursor
; still exists as far as the software is concerned, so all the functions that
; are relative to the current cursor position work normally.  All this does
; is make the blinking block disappear from the screen.
;--
DSACURS:PUSHR(T1)\ PUSHR(T2)	; save some registers for working
	IOFF			; interrupts off again
	RLDI(T1,CURSOFF)\ LDN T1; point to the cursor display flag
	LBNZ	DSACU1		; skip all this if it's already off
	LDI $FF\ STR T1\ INC T1	; turn off the cursor display
	LDA T1\ PHI T2		; put the address of the character under
	LDA T1\ PLO T2		;  ... the cursor in T2
	B_DISPLAY $		; synchronize with the display
	LDN T1\ STR T2		; and restore the character at the cursor
	ION			; interrupts are safe again
DSACU1:	IRX\ POPR(T2)		; restore registers
	POPRL(T1)\ RETURN	; all done


;++
;   And this routine will re-enable the cursor display after it has been
; disabled.  We save the character under the cursor again just to be safe,
; but that probably isn't necessary.
;--
ENACURS:PUSHR(T1)\ PUSHR(T2)	; save some registers for working
	IOFF			; don't want to be interrupted here
	RLDI(T1,CURSOFF)\ LDN T1; address the cursor display flag
	LBZ	ENACU1		; skip all this if it's already on
	LDI $00\ STR T1\ INC T1	; turn the cursor back on
	LDA T1\ PHI T2		; load the address of the cursor location
	LDA T1\ PLO T2		; ...
	B_DISPLAY $		; synchronize
	LDN T2\ STR T1		; save the character at the cursor
	ION			; interrupts back on again
ENACU1:	IRX\ POPR(T2)		; restore registers
	POPRL(T1)\ RETURN	; and we're done

	.SBTTL	Compute the Address of Any Line

;++
;   This subroutine will calculate the address of any line on the screen.
; The absolute number of the line (i.e. not relative to any scrolling) should
; be passed in the D and the resulting address is returned in P1. Uses T1.
;--
LINADD:	SMI MAXROW\ LBDF LINADD	; reduce line number modulo MAXROW
	ADI MAXROW\ SHL		; double the row number
	ADI LOW(LINTAB)\ PLO T1	; index into LINTAB
	LDI	HIGH(LINTAB)	; ...
	ADCI 0\ PHI T1		; include any carry from the low byte
	LDA T1\ PHI P1		; get the high and low bytes of the line
	LDN T1\ PLO P1		;  ... from the table
	RETURN			; and then that's all there is to do

;++
;   This table is used to translate character row numbers into actual screen
; buffer addresses.  It is indexed by twice the row number (0, 2, 4, ... 48) and
; contains the corresponding RAM address of that line. This address is stored in
; two bytes, with the low order bits of the address being first.  Needless to
; say, it should have at least MAXROW entries!
;--
LINTAB:	.WORD	PAGEMEM+( 0*MAXCOL)	; line #0
	.WORD	PAGEMEM+( 1*MAXCOL)	; line #1
	.WORD	PAGEMEM+( 2*MAXCOL)	; line #2
	.WORD	PAGEMEM+( 3*MAXCOL)	; line #3
	.WORD	PAGEMEM+( 4*MAXCOL)	; line #4
	.WORD	PAGEMEM+( 5*MAXCOL)	; line #5
	.WORD	PAGEMEM+( 6*MAXCOL)	; line #6
	.WORD	PAGEMEM+( 7*MAXCOL)	; line #7
	.WORD	PAGEMEM+( 8*MAXCOL)	; line #8
	.WORD	PAGEMEM+( 9*MAXCOL)	; line #9
	.WORD	PAGEMEM+(10*MAXCOL)	; line #10
	.WORD	PAGEMEM+(11*MAXCOL)	; line #11
	.WORD	PAGEMEM+(12*MAXCOL)	; line #12
	.WORD	PAGEMEM+(13*MAXCOL)	; line #13
	.WORD	PAGEMEM+(14*MAXCOL)	; line #14
	.WORD	PAGEMEM+(15*MAXCOL)	; line #15
	.WORD	PAGEMEM+(16*MAXCOL)	; line #16
	.WORD	PAGEMEM+(17*MAXCOL)	; line #17
	.WORD	PAGEMEM+(18*MAXCOL)	; line #18
	.WORD	PAGEMEM+(19*MAXCOL)	; line #19
	.WORD	PAGEMEM+(20*MAXCOL)	; line #20
	.WORD	PAGEMEM+(21*MAXCOL)	; line #21
	.WORD	PAGEMEM+(22*MAXCOL)	; line #22
	.WORD	PAGEMEM+(23*MAXCOL)	; line #23
	.WORD	PAGEMEM+(24*MAXCOL)	; line #24

	.SBTTL	Load Font Memory

;++
;   This routine will load a character font from EPROM or RAM into the VIS
; CMEM (character memory, aka the font RAM).  The VIS CMEM has room for 256
; character glyphs, corresponding to ASCII codes 0x00..0xFF.  The fonts we use
; can contain either 64 (for an upper case only set) or 128 (for a full upper
; and lower case) glyphs, as determined by the FONTSIZE constant.  Typically
; we store multiple copies of the same font in CMEM, with the copies being
; reverse video or in a different color.
;
;CALL:
;	P1 -> pointer to font data in RAM/EPROM
;	P2 -> font modification flags
;	 D -> starting font character to load
;	CALL(LDFONT)
;
;   The pointer to the font in P1 is pretty self explanatory, and must always
; contain at least FONTSIZE characters.  Each byte of the font is ORed with
; P2.0 and XORed with P2.1.  The idea is that P2.1 should either be zero (in
; which case the font is stored normally) or $3F (which converts the font to
; reverse video).  P2.0 contains the color bits, $00, $40, $80 or $C0, that
; are to be added to the font.
;
;   One last comment - loading the CMEM automatically destroys the PMEM data
; at $F800, because we need to use the PMEM to set the CMEM address.  During
; startup that's not too bad but when setting the font colors via <ESC>O that's
; annoying.  This routine will save and restore the PMEM data.
;
; Uses T1 and T2 ...  Leaves P1 and P2 unchanged!
;--
LDFONT:	PHI	T2		; keep the font index in T2.1
	PUSHR(P1)		; save P1 (we don't change P2)
	CALL(SELIO0)		; select I/O group 0
	RLDI(T1,VN.MODE+VN.CMEM); enable CMEM access
	SEX T1\  OUT VISCONF	; ...
	LDI FONTSIZE\ PLO T2	; and count characters in T2.0
	RLDI(T1,PAGEMEM)	; save the character at $F800
;; NOP\ NOP\ NOP	; for alignment
	B_DISPLAY $		; wait for access
	LDN T1\ SEX SP\ PUSHD	; and put it on the stack

; Load the CMEM ...
LDFON1:	RLDI(T1,PAGEMEM)	; point to VIS PMEM
	B_DISPLAY $		; wait for PMEM access
	GHI T2\ STR T1		; and set the character index we want to load
	GHI T2\ ADI 1\ PHI T2	; increment the index for next time
	RLDI(T1,CHARMEM)	; now point to the VIS CMEM
LDFON2:	LDA P1\ STR SP\ SEX SP	; load the next font byte
	GLO P2\ OR\ STR SP	; OR in the color bits
	GHI P2\ XOR\ STR SP	; and XOR the reverse video bits
	B_DISPLAY $		; wait for CMEM access
	STR T1\ LDN T1		; store this byte in CMEM and read it back
	INC T1\ GLO T1		; on to the next scan line
	ANI $7\ LBNZ LDFON2	; keep going for 8 bytes
	DEC T2\ GLO T2		; have we loaded the entire font?
	LBNZ	LDFON1		; keep going until we have

; Restore normal PMEM operation and we're done!
	RLDI(T1,PAGEMEM)	; restore the character at $F800
	SEX SP\ POPD\ STR T1	; ...
	RLDI(T1,VN.MODE)	; yes - turn off CMEM access
	SEX T1\ OUT VISCONF	; ...
	SEX SP\ IRX\ POPRL(P1)	; restore the original P1
	RETURN			; and that's it

	.SBTTL	Miscellaneous VIS Functions

;++
;   Turn the display off.  This allows unfettered access to page or character
; RAM, but be warned that it will also stop VIS interrupts (so time will stop
; for the beeper, et al).  Just don't leave it turned off for very long.
;--
DSPOFF:	CALL(SELIO0)		; display off and we're done
	RLDI(T1,CURCLR)\ LDN T1	; get the current color bits
	ORI VC.HRES+VC.DOFF	; set the display OFF bit
	STR SP\ SEX SP		; ...
	OUT	VISCOLR		; write that the CDP1870
	DEC SP\ RETURN		; and return


;++
; Turn the display back on ...
;--
DSPON:	CALL(SELIO0)		; display on and we're done
	RLDI(T1,CURCLR)\ LDN T1	; get the current color bits
	ORI	VC.HRES		; DON'T set the DOFF bit!
	STR SP\	SEX SP		; ...
	OUT	VISCOLR		; write those to the 1870
	DEC SP\ RETURN		; and return

	.SBTTL	Bell (^G) Function

;++
;   This routine will make the ^G bell sound using the tone generator in the
; CDP1869.  It sounds a 440Hz tone for approximately 1/2 second.  Note that
; we just start the tone here - it gets turned off by the VISISR after counting
; half a second ...
;--
BELL:	CALL(SELIO0)		; all VIS registers are in group 0
	RLDI(T1,VT.BELL)	; program the CDP1869 tone generator
	SEX T1\ OUT VISTONE	;  ... to make a 440Hz sound
	RLDI(T1,TTIMER)		; this variable controls the duration
	LDI BELLTIME\ STR T1	; program the turn off time
	RETURN			; and we're done

	.SBTTL	Display Startup Splash Screen

;++
;   This routine will display a "splash" screen at startup.  This screen
; the copyright notice, build date, checksum, and the character sets that
; are available.  The screen persiists, and this routine spins here, until
; we receive any input from the PS/2 keyboard or the serial port.  After
; that, the screen is cleared and we return.
;--
SPLASH:	CALL(ERASE)		; erase the screen
	CALL(DSPOFF)		; turn the display off
	RLDI(T1,CURSCHR)	; store a "block" at the cursor location too
	LDI BLANK+RVVBIT\ STR T1; ...

;   Display a solid row of "blocks" (reverse video spaces!) across the top
; line of the display.
	RLDI(T1,PAGEMEM)	; point to page memory
	LDI MAXCOL\ PLO T2	; and fill 40 columns
SPLAS1:	LDI BLANK+RVVBIT\ STR T1; display a reverse video space
	INC T1\ DEC T2\ GLO T2	; increment PMEM, decrement the count
	LBNZ	SPLAS1		; and loop until we've done 40

;   Now display vertical columns of blocks on the left and right edges of
; the screen. 
	LDI MAXROW-2\ PLO T2	; do all rows except the top and bottom
SPLAS2:	LDI BLANK+RVVBIT\ STR T1; display a block on the left margin
	GLO T1\ ADI MAXCOL-1	; and move PMEM pointer to the right margin
	PLO T1\ GHI T1		; ...
	ADCI 0\ PHI T1		; ...
	LDI BLANK+RVVBIT\ STR T1; display a block on the right margin too
	INC T1\ DEC T2\ GLO T2	; have we done all the rows?
	LBNZ	SPLAS2		; keep going until we have

; Display another solid row across the bottom of the screen ...
	LDI MAXCOL\ PLO T2	; fill aoo 40 columns
SPLAS3:	LDI BLANK+RVVBIT\ STR T1; with reverse video spaces
	INC T1\ DEC T2\ GLO T2	; have we done all 40?
	LBNZ	SPLAS3		; keep going until they're done

;   Display the entire 256 glyph character set (regardless of whether it's a
; 64 or 128 character font) as four rows of 32 characters each.
	RLDI(T1,PAGEMEM+564)	; magic location for row 14, column 4
	LDI 0\ PLO T2		; count characters here
SPLAS4:	GLO T2\ STR T1		; display another ASCII character
	INC T1\ INC T2		; ...
	GLO T2\ ANI $1F		; have we done 32 on this line?
	LBNZ	SPLAS4		; no - display more
	GLO T1\ ADI 8\ PLO T1	; yes - wrap around to the next line
	GHI T1\ ADCI 0\ PHI T1	; ...
	GLO T2\ LBNZ SPLAS4	; but quit after 256 characters
	CALL(DSPON)		; turn the display back on
	CALL(DSACURS)		; but hide the cursor

; Display the copyright texts ...
	CALL(TOUT)		; send all output to the VIS display
	INLMES("\033Y\"#\000")	; position the cursor at the upper left
	OUTSTR(SYSNAM)		; display the system name
	INLMES("\033Y#$\000")	; next line down
	OUTSTR(SYSDAT)		; display the build date
	INLMES(" CHECKSUM ")	;  ... and the EPROM checksum
	RLDI(P1,CHKSUM)		;  ...
	SEX P1\ POPR(P2)	;  ...
	CALL(THEX4)		;  ... in hex
	INLMES("\033Y$\"\000")	; next line down
	OUTSTR(RIGHTS1)		; display our copyright notice
	INLMES("\033Y%*\000")	; ...
	OUTSTR(RIGHTS2)		; ...
	.IF (BASIC != 0)
	INLMES("\033Y'%\000")	; and one last line
	OUTSTR(BRIGHTS)		;  ... to display the BASIC3 notice
	.ENDIF

; Wait for input from either the keyboard or the serial port ...
SPLAS8:	RLDI(T1,RXGETP)\ LDA T1	; get the receiver circular buffer pointer
	SEX T1\ XOR		; does GETP == PUTP ?
	LBNZ	SPLAS9		; buffer not empty if not
	RLDI(T1,KEYGETP)\ LDA T1; same test for the keyboard buffer
	SEX T1\ XOR		; GETP == PUTP?
	LBZ	SPLAS8		; yes - keep waiting

; All done ...
SPLAS9:	CALL(RSTIO)		; reset the console input
	CALL(ENACURS)		; and turn the cursor back on
	CALL(ERASE)		; erase the screen
	RETURN			; all done

	.SBTTL	Initialize VIS Display

;++
;   This code initializes the CDP1869 and CDP1870/76 VIS chipset.  The VIS
; parts are really weird chips, especially the CDP1869.  This chip isn't even
; conneceted to the data bus at all.  When we want to send commands to it,
; they're loaded off the  ADDRESS bus.  Exactly what that address points to,
; if anything, doesn't matter.  The CDP1870/76 is more conventional and its
; sole internal register is loaded from the data bus.  This routine also
; initializes the VIS1802 mode control register, which is unique to our PCB
; and controls how various VIS options are connected.
;
;   The VIS chips are initialized to
;	* "high resolution" (40 coluns x 24 lines)
;	* noise and tone generator OFF
;	* PMA and HMA registers reset to zero
;	* default background color 
;
;   The VIS font RAM (aka CMEM) is loaded with the current font, either two
; copies (normal and reverse video) for the 128 character font, or four
; copies (normal and reverse, and in two colors) for the 64 character font.
;
;   The VIS1802 video mode is initialized to connect PMEM A10 to PMD7, and to
; set the PCB bit always one.  And lastly, the screen is erased and the video
; enabled.
;--
VISINI:
; Configure the CDP1870 first - it's easy ...
	OUTI(FLAGS, FL.PCB1)		; set PCB=1
	CALL(SELIO0)			; all other VIS chips are group 0
	OUTI(VISCOLR,VC.HRES+VC.DOFF)	; high resolution, display off

;   Initialize the CDP1869 to turn the tone and noise generator off, and the
; PMA and HMA initialized to zeros.  Remember that the 1869 is that weird
; chip that takes it's command from the ADDRESS bus...
	SEX	T1		; commands come from T1!
	RLDI(T1,VT.TOFF)	; tone generator off
	OUT	VISTONE		; ...
	RLDI(T1,VN.MODE)	; noise off, 40 columns, 24 rows, 8 scanlines
	OUT	VISCONF		; ...
	RCLR(T1)\ OUT VISPMA	; zero the page memory address
	RCLR(T1)\ OUT VISHMA	; and zero the home address
	RLDI(T1,CURCLR)		; set the default screen background color
	LDI DEFBCKCLR\ STR T1	; ...

; Load the font RAM (aka character memory, aka CMEM) ...
	RLDI(P1,FONT)
	.IF (FONTSIZE == 64)
	RLDI2(P2,      0,DEFFORCLR)\ LDI   0\ CALL(LDFONT)
	RLDI2(P2,      0,DEFALTCLR)\ LDI  64\ CALL(LDFONT)
	RLDI2(P2,RVVMASK,DEFFORCLR)\ LDI 128\ CALL(LDFONT)
	RLDI2(P2,RVVMASK,DEFBCKCLR)\ LDI 192\ CALL(LDFONT)
	.ENDIF
	.IF (FONTSIZE == 128)
	RLDI2(P2,      0,DEFFORCLR)\ LDI   0\ CALL(LDFONT)
	RLDI2(P2,RVVMASK,DEFFORCLR)\ LDI 128\ CALL(LDFONT)
	.ENDIF

; All done - it's up to the caller to turn the display on!
	RETURN			; ...

	.SBTTL	Music Notation

;++
;   The music player takes an ordinary ASCII string and interprets it as
; a musical notation of sorts.  The letters A..G (or a..g, since case is
; ignored) refer to the notes A thru G.  Each letter may be followed by a
; "+" or "#" to indicate a sharp, or a "-" to indicate a flat. "DABF#GDGA"
; would get you the famous 8 note cello part from Pachelbel's Canon.
;
;   Other characters have special meanings as well.  The digits 1, 2, 4 or
; 8 specify the note duration - whole note, half note, quarter note or eighth
; note (notice that larger numbers are shorter intervals!).  Sixteenth notes
; are unfortunately not possible - sorry!  The note duration must preceed the
; note ("4D" for a quarter note D, NOT "D4"!) and remain in effect until
; changed by another digit.  So the string "4DABF" would be ALL quarter notes.
;
;   The "," indicates a rest of the same duration as the current note (e.g.
; "1," is a whole rest.  A ">" shifts all notes up one octave and "<" shifts
; all notes down one octave.  The player has an overal range of four octaves,
; from one octave below middle C to two octaves above, and attempts to shift
; above or below this range will be ignored.  There is no way to absolutely
; set the current octave, however something like "<<<<>" would select the
; octave of middle C.
;
;   Spaces in the string are ignored, and playing terminates when any illegal
; character, including EOS ('\0'), is encountered.  
;
;   Summary -
;	A, B, C, D, E, F, G - a note to play
;	# or +, -	    - sharp or flat (place AFTER note!)
;	1, 2, 4, 8	    - note length (whole, half, quarter, eighth)
;	>, <		    - shift up or down one octave
;	,		    - rest (silence)
;	<space>		    - ignored
;
;   Note that by tradition a quarter note lasts one beat, so a whole note is
; 4 beats, a half note is 2 beats, and an eighth note is 1/2 beat.   Yeah,
; it would have been better to start at the eighth note, but I don't make the
; rules!  If the tempo is, say 60 beats per minute, then a quarter note is
; 1 second and a whole note 4 seconds.  Given that we count note times in
; 60Hz VRTC interrupts, at 60 BPM a whole note would be 240 ticks which is
; about the longest count we can fit into one byte.  That makes the slowest
; possible tempo about 60 BPM, which turns out to be pretty reasonable for
; most music.
;
;   Various examples -
;	gg>ddeed,cc<bbaag	- Twinkle, Twinkle Little Star
;	dec<cg			- Close Encounters
;	see below!		- Ode to Joy
;	see below!		- Popcorn
;--

; Beethoven's Ninth, 4th movement (aka Ode to Joy) ...
ODE:	.TEXT	"EEFGGFEDCCDEE8D2D4,EEFGGFEDCCDED8C2C4,"
	.TEXT	"DDECD8EF4ECD8EF4EDCD<G>,EEFGGFEDCCDED8C2C\000"

; Popcorn, Gershon Kingsley, 1969 ...
POPCORN:.TEXT	"8BABF#DF#<B,>BABF#DF#<B,,B>C#DC#D<B>C#<B>C#<ABABGB,,"
	.TEXT	">BABF#DF#<B\000"

	.SBTTL	Play Music

;++
;   The PLay command plays a musical string according to the rules on the
; previous page.  
;--
PLAY:	CALL(LTRIM)\ CALL(ISEOL); skip leading spaces
	LBDF	CMDERR		; error if no argument
	CALL(PLAY1)		; play the actual string
	CALL(CHKEOL)		; and we'd better end with the EOL
	RETURN			; return to the command scanner

; Play a musical demo ...
PDEMO:	CALL(CHKEOL)		; no arguments here
	RLDI(P1,ODE)		; point to the sample tune
				; and fall into PLAY1

; This routine actually plays the string pointed to by P1 ...
PLAY1:	RLDI(T1,OCTVOL)		; initialize OCTVOL, TEMPO and NOTIME
	LDI $3F\ STR T1\ INC T1	; octave of middle C, volume maximum
	LDI	HERTZ/2		; a quarter note lasts one half second
	STR T1\ INC T1\ STR T1	; for a 120 BPM tempo

; Play the string pointed to by P1 ...
PLAY2:	CALL(LTRIM)		; ignore any spaces
	CALL(PNOTE)		; try to play a note
	LBNF	PWAIT		; and wait for the note to finish
	CALL(PSPCL)		; is it a "special" character"
	LBNF	PLAY2		; yes - on to the next one
PLAY9:	RETURN			; return when we find anything illegal

;   Wait for the current note to finish playing.  We do this simply by waiting
; for the VRTC ISR to count down the tone timer to zero.  We don't really need
; to turn off interrupts here, because we don't cause any race conditons by
; just watching the count ...
PWAIT:	RLDI(T1,TTIMER)		; wait for the timer to go to zero
PLAY20:	LDN T1\ LBNZ PLAY20	; just spin until it does

;   Now insert a brief break before the next note.  We use the same VRTC ISR
; to count this one too, but we leave the tone generator turned off.
	LDI HERTZ/15\ STR T1
PLAY21:	LDN T1\ LBNZ PLAY21
	LBR	PLAY2		; then play the next note

	.SBTTL	Play One Note

;++
;   This routine will examine the character pointed to by P1 and if it's one
; of the letters A..G then it will start playing that note and return with
; DF=0.  If the character is a ',', then we play a "rest" - this is just like
; a note, except that the tone generator is turned off.  If it's NOT a letter
; A..G or comma then we'll leave P1 unchanged and return with DF=1.
;
;   If it is a letter, A..G, then we advance P1 and look ahead at the next
; character to see if that's a "+" or "#" for a sharp, or "-" for a flat.
; If either of those are found then we move up or down one step in the note
; table and advance P1 past the +/#/- too.  Needless to say, sharps and flats
; don't apply to rests (commas).
;
;   IMPORTANT - our note table covers only one octave, from C to B.  A C-
; (C flat) requires us to shift down one octave and then play a B.  Likewise,
; a B# requires us to shift up an octave and then play C.  We can actually
; do that, but the octave shift will not be undone when the note finishes!
;--
PNOTE:	RLDI(T1,NOTES)		; prepare to search the NOTES table
	LDN P1\ CALL(FOLD)	; get the note letter and fold to upper case
	PHI AUX\ SEX T1		; and save that temporarily
	SMI ','\ LBZ PREST	; handle rests first
PNOTE1:	LDX\ LBZ PNOTE9		; end of note table?
	GHI AUX\ XOR		; does this note match?	
	LBZ	PNOTE2		; yes - play it!
	IRX\ IRX\ LBR PNOTE1	; no match - increment T1 and try again

; Here when we find a match in the NOTES table ...
PNOTE2:	INC P1\ LDN P1		; look ahead to the next character
	SMI '#'\     LBZ PNOTE4	; branch if sharp
	SMI '+'-'#'\ LBZ PNOTE4	; another way to indicate sharps
	SMI '-'-'+'\ LBZ PNOTE5	; and lastly test for a flat

; Play the note pointed to by T1 ...
PNOTE3:	INC T1\ LDN T1\ PHI T2	; get the frequency divider
	RLDI(T1,OCTVOL)		; get volume and octave
	LDN T1\ PLO T2		;  ...
PNOTE30:CALL(SELIO0)		; select the VIS I/O group
	SEX T2\ OUT VISTONE	; and program the tone generator
	RLDI(T1,TTIMER)		; set the note duration
	RLDI(T2,NOTIME)		;  ... to the current note duration
	LDN T2\ STR T1		; ...
	CDF\ RETURN		; return DF=0 and we're done

; Here if the note is a sharp ...
PNOTE4:	INC	P1		; skip over the '#' or '+'
	GLO T1\ SMI LOW(NOTEND)	; is this the last note in the table?
	LBNZ	PNOTE41		; no - everything is OK
	CALL(OCTUP)		; yes - bump up an octave
	RLDI(T1,NOTES-2)	; and play the first note in the table
PNOTE41:INC T1\ INC T1		; bump up one half step
	LBR	PNOTE3		; and play that one

; Here if the note is a flat ...
PNOTE5:	INC	P1		; skip over the '-'
	GLO T1\ SMI LOW(NOTES)	; is this the first note in the table?
	LBNZ	PNOTE51		; no - we're fine
	CALL(OCTDN)		; yes - drop down an octave
	RLDI(T1,NOTEND+2)	; and play the last note in the table
PNOTE51:DEC T1\ DEC T1		; drop down one half step
	LBR	PNOTE3		; and play that

;   Here to play a rest ...  Rests are "played" just like notes, however the
; tone generator is turned off.
PREST:	INC	P1		; skip over the ','
	RLDI(T2,VT.TOFF)	; tone off
	LBR	PNOTE30		; and then "play" that

; Here if we don't find a matching note ...
PNOTE9:	SDF\ RETURN		; return DF=1 and leave P1 unchanged

	.SBTTL	Note Divisors for The CDP1869

;++
;   The table at NOTES: gives the name (as an ASCII character) and the
; corresponding divider for the CDP1869.  The sharps and flats have 80H added
; to the ASCII character - this ensures that they will NEVER match when the
; table is searched.  The code handles sharps and flats by finding the letter
; first and then adding or subtracting one table entry.
;
;   Note that the tone generator in the CDP1869 is clocked by TPB from the
; 1802, and these divisors assume that the CPU clock is generated by the
; 5.67Mhz/2 output from the CDP1869.  If you elect to use a different CPU
; clock frequency, then you'll need to adjust these values!
;
;   Here are two tables of note  divisors - one for a 2.835MHz CPU clock, which
; is what you get if you don't install a crystal and use the VIS clock/2 as the
; CPU clock.  There's another table here for a 3.579545Mhz CPU crystal.
;--

; Note frequencies for a 2.835MHz CPU clock ...
	.IF	CPUCLOCK == 2835000
NOTES:	.DB	'C',     $54	; 0 middle C (with octave == 3)
	.DB	'C'+80H, $4F	; 1 C#/D-
	.DB	'D',     $4B	; 2 D
	.DB	'D'+80H, $47	; 3 D#/E-
	.DB	'E',     $43	; 4 E
	.DB	'F',	 $3F	; 5 F
	.DB	'F'+80H, $3B	; 6 F#/G-
	.DB	'G',	 $38	; 7 G
	.DB	'A'+80H, $35	; 8 G#/A-
	.DB	'A',     $32	; 9 A
	.DB	'B'+80H, $2F	;10 A#/B-
NOTEND:	.DB	'B',	 $2C	;11 B
	.DB	0
	.ENDIF

; Note frequencies for a 3.579545MHz CPU clock ...
	.IF	CPUCLOCK == 3579545
NOTES:	.DB	'C',     $6A	; 0 middle C (with octave == 3)
	.DB	'C'+80H, $64	; 1 C#/D-
	.DB	'D',     $5F	; 2 D
	.DB	'D'+80H, $59	; 3 D#/E-
	.DB	'E',     $54	; 4 E
	.DB	'F',	 $50	; 5 F
	.DB	'F'+80H, $4B	; 6 F#/G-
	.DB	'G',	 $47	; 7 G
	.DB	'A'+80H, $43	; 8 G#/A-
	.DB	'A',     $3F	; 9 A
	.DB	'B'+80H, $3B	;10 A#/B-
NOTEND:	.DB	'B',	 $38	;11 B
	.DB	0
	.ENDIF

	.SBTTL	Shift Octaves and Change Note Duration

;++
;   This routine will examine the character pointed to by P1 and if it's one
; of '<', '>', '1', '2, '4', or '8' then it will either shift the octave or
; set the note duration accordingly.  In this case P1 is incremented and DF=0
; on return.  If the character is none of those, then P1 is unchanged and
; DF=1 on return.
;--
PSPCL:	RLDI(T1,OCTVOL)		; point T1 to OCTVOL for later
	LDA	P1		; get the character (and assume it matches!)
	SMI '<'\     LBZ OCTDN	; '<' -> shift down one octave
	SMI '>'-'<'\ LBZ OCTUP	; '>' -> shift up one octave
	INC	T1		; point T1 at TEMPO for later
	SMI '1'-'>'\ LBZ NOTED1	; '1' -> set duration whole note
	SMI '2'-'1'\ LBZ NOTED2	; '2' -> set duration half note
	SMI '4'-'2'\ LBZ NOTED4	; '4' -> set duration quarter note
	SMI '8'-'4'\ LBZ NOTED8	; '8' -> set duration eighth note
	DEC P1\ SDF\ RETURN	; none of those - restore P1 and return DF=1


;  Shift the current notes up one octave, unless we're already at octave 5,
; in which case do nothing ...
OCTUP:	LDN T1\ ADI $10\ PHI AUX; bump it up one octave
	SMI $60\ LBGE OCTUP1	; but stop after octave 5
	GHI AUX\ STR T1		; update it
OCTUP1:	CDF\ RETURN		; return DF=0 and we're done


;  Shift the current notes down one octave, unless we're already at octave 2,
; in which case do nothing ...
OCTDN:	LDN T1\ SMI $10\ PHI AUX; drop down one octave
	SMI $20\ LBL OCTDN1	; but stop at octave 2
	GHI AUX\ STR T1		; update it
OCTDN1:	CDF\ RETURN		; and return DF=0


;   Here to set the current note duration to a whole, half, quarter or eighth
; note.  The current tempo gives the duration of a QUARTER note in VRTC ticks,
; so for the whole or half notes we have to multiply by 4 or 2, and for the
; eighth note we have to divide by 2.

; Here to select whole notes ...
NOTED1:	LDA T1\ SHL\ SHL	; get current tempo *4
	STR T1\ CDF\ RETURN	; set NOTIME and return

; Here to select half notes ...
NOTED2:	LDA T1\ SHL		; get current tempo *2
	STR T1\ CDF\ RETURN	; set NOTIME and return

; Here to select quarter notes ...
NOTED4:	LDA T1\ STR T1		; quarter note == current tempo
	CDF\ RETURN		; set NOTIME and return

; Here to select eighth notes ...
NOTED8:	LDA T1\ SHR		; get current tempo /2
	STR T1\ CDF\ RETURN	; set NOTIME and return

	.SBTTL	Graphics Mode Notes

;++
;   The VIS1802 provides no less than three SRAM chips for the frame buffer.
; In text mode, there's a 1K "page memory" which contains the ASCII code for
; each character cell on the screen, and a 2K "character memory" (aka font RAM)
; that provides the glyph for each ASCII character.  Font RAM contains glyphs
; for 256 characters with 8 scan lines per character, with six pixels per scan
; line.
;
;   In graphics mode we switch to a separate SRAM chip which gives us eight
; scan lines of six pixels for each of the 960 character cells on the screen.
; It's effectively still text mode, but with a separate and independent glyph
; for each and every character cell.  Forty characters per line with six pixels
; per scan line gives us 240 pixels in the horizontal direction, and 24 text
; rows with 8 scan lines per row gives us 192 pixels in the vertical direction.
; That's 7680 bytes in total, but remember that only six bits out of each byte
; are used for pixels.  The upper two bits are used for color, but that's yet
; another complexity that we'll ignore for now.
;
;   As you might imagine, addressing graphics memory in that mode gets a little
; messy.  Given an (X,Y) coordinate, where 0 <= X < 240 and 0 <= Y < 192, the
; corresponding horizontal character position in text memory is given by X/6,
; and the bit position within that character cell is given by 5 - (X MOD 6).
; Remember that the bits in the font glyph are scanned left to right, so bit
; 0 (e.g. $01) is the RIGHTMOST pixel and bit 5 ($20) is the leftmost.  The
; Y coordinate is a little easier to deal with; the vertical character row
; within text memory is given by Y/8, and the font glyph scan line within that
; row is Y MOD 8.  Note that this assumes the home, (0,0) position is in the
; upper left corner of the screen.  To move it to the lower right, you need
; to compute Y = 191 - Y first.
;
;   So, if we want to set the pixel at (X,Y) to one, we need to -
;
;   1) Compute Y/8*40 to get the page memory offset of the corresponding text
; row, and hang onto the result for step 2, below.  Y/8*40 is of course Y*5,
; and we can compute that with a couple of shifts and an addition.  Note that
; we really only need 10 bits for this computation, but that's still more than
; 8 so we're stuck with double precision.  And alternatively we could use Y/8
; as an index into LINTAB and use that to get the address of the corresponding
; row; it's not clear if that's faster or slower so take your pick.
;
;   2) Compute X/6 to get the horizontal offset for the character cell, and add
; that value to the result of the Y row computation from step 1.  This is the
; value that gets loaded into the VIS PMA register.  Note that we only need 10
; bits for this, and if you have more (e.g. if you use LINTAB) the extra bits
; will be ignored.
;
;   3) Compute 1 << (5-(X MOD 6)) to get a bit mask for the pixel in question.
; 
;   4) And lastly, compute Y MOD 8 to get the appropriate scan line.  This
; gives us the CMEM (aka font memory) address that we need to modify with the
; bit mask computed in step 3.  OR, AND, XOR, or whatever to CMEM and we're
; done!
;
;   As you might guess, some of these steps, particularly X/6 and X MOD 6, are
; a little slow on the poor 1802.  To that end we cheat totally and use a table
; lookup with 240 entries to give us the exact X/6 and bit mask values for
; each possible X coordinate.  Yes, that's a 480 byte table, but we have lots
; and lots of room in EPROM.
;--
	.SBTTL	Switch Between Graphics and Text Modes

;++
;   These two routines will switch the display between graphics and text modes.
; In theory this is as simple as flipping the GPAHICS MODE bit in the FLAGS
; I/O port, but in practice there are several other things we have to worry
; about too.  This is complicated by the fact that both graphics and text mode
; can co-exist and you can flip the display back and forth between them.
;
;   * The blinking cursor is hidden in graphics mode.  There is no graphics
; cursor, and the VISISR would screw up our graphics display if it tried to
; blink something!
;
;   * The VIS PMA register, which is essential in graphics mode but unused in
; text mode, needs to be reset when we switch.  Graphics mode just leaves PMA
; set to whatever was last in there, and that screws up the text display.
;
;   * In graphics mode CMEM access is always enabled, and in text mode it's
; disabled except during LDFONT.  This particular step is probably not necessary
; since there doesn't seem to be any harm in leaving CMEM access enabled at all
; times, but since we're here anyway ...
;
;   * In graphics mode there's no scrolling, so when entering graphics we always
; set the HMA to zero.  But when we return to text mode though, we need to
; restore the correct HMA for the current TOPLIN.
;
;   * And lastly we need to set or clear the GMODEF flag.  This is used by other
; parts of the code to find out which mode is currently active (remember that
; we can't read back the FLAGS I/O port!).
;--

; Switch to graphics mode ...
GMODE:	PUSHR(T1)		; save a temporary register
	CALL(SELIO0)		; address the VIS chipset
	RLDI(T1,GMODEF)\ LDN T1	; see if we're already in graphics mode
	LBNZ	GMODE9		;  ... just quit now if we are
	LDI $FF\ STR T1		;  ... otherwise set GMODEF = 0xFF
	CALL(DSACURS)		; hide the text mode cursor
	OUTI(FLAGS, FL.GRAP)	; access the bitmap RAM
	RCLR(T1)\ SEX T1	; clear the PMA register
	OUT	VISPMA		; ...
	RCLR(T1)\ OUT VISHMA	; and clear the HMA register too
	RLDI(T1,VN.MODE+VN.CMEM); enable CMEM access
	OUT	VISCONF		; ...
GMODE9:	SEX SP\ IRX\ POPRL(T1)	; restore T1
	RETURN			; and I think that's it

; Switch to text mode ...
TMODE:	PUSHR(T1)		; save a temporary register
	RLDI(T1,GMODEF)\ LDN T1	; get the GMODEF flag
	LBZ	GMODE9		; just quit now if we're already in text mode
	LDI $00\ STR T1		;  ... otherwise set GMODEF = 0
	CALL(SELIO0)		; address the VIS chipset
	RCLR(T1)\ SEX T1	; clear the PMA register
	OUT	VISPMA		; ...
	RLDI(T1,VN.MODE)	; turn off CMEM access
	OUT	VISCONF		; ...
	OUTI(FLAGS, FL.TEXT)	; access the text/font RAM now
	CALL(UPDTOS)		; reset the VIS HMA register
	CALL(ENACURS)		; show the cursor again
	LBR	GMODE9		; and return

	.SBTTL	Clear Graphics Memory

;++
;   This routine will clear the entire graphics memory and will leave you
; with a blank screen displayed.  Remember that in graphics mode there's no
; cursor, so the screen will be totally dark.  Like text erase, it actually
; turns off the display while we're erasing to speed things up.
;
;   Note that we set each byte of graphics memory to the default foreground
; color, NOT $00.  Paradoxically the screen will still be blank since the
; associated pixes $3F are all zero, but when we later OR in one pixel bits
; they'll assume the default foreground.
;
;   Uses T1, T2 and T3 ...
;--
GERASE:	PUSHR(T1)\ PUSHR(T2)	; save temporary registers
	PUSHR(T3)		; ...
	CALL(GMODE)		; ensure graphics mode is selected
	CALL(DSPOFF)		; and turn the display off

;  This outer loop goes thru all 960 character cells in the graphics memory,
; and the inner loop goes thru 8 bytes of font memory for each cell ...
	RLDI(T1,PAGEMEM)	; base of character (page) memory
	RLDI(T2,PAGESIZE)	; and the number of characters 
GERA1:	SEX T1\ OUT VISPMA	; set the PMA to address this character cell
	RLDI(T3,CHARMEM+7)	; loop thru 8 font bytes per character cell
	SEX T3\ LDI DEFFORCLR	;   ... and set all pixels to zero
;;	NOP\ NOP\ NOP	; for alignment
	B_DISPLAY $		; synchronize with the display (just in case)
	STXD\ STXD\ STXD\ STXD	; set four bytes to zero
;;	NOP\ NOP\ NOP	; for alignment
	B_DISPLAY $		; then synchronize again just to be sure
	STXD\ STXD\ STXD\ STXD	; and set four more to zero
	DBNZ(T2,GERA1)		; on to the next character

; Turn the display back on and we're done ...
	CALL(DSPON)		; ...
	SEX SP\ IRX\ POPR(T3)	; restore registers
	POPR(T2)\ POPRL(T1)	; ...
	RETURN

	.SBTTL	Compute Bitmap Address for (X,Y) Coordinate

;++
;   This routine will compute the actual bit map address for a given (X,Y)
; coordinate.  
;
;CALL:
;	P1/ coordinate		; P1.1 == X, P1.0 == Y
;	CALL(XYTORC)
;	DF/ coordinate valid	; DF=0 valid, DF=1 invalid
;	T1/ PMEM address	; already loaded into PMA!
;	T2/ CMEM address	; $F4xx, where 0 <= xx < 8
;	D/ bit mask		; $20, $10, $08, $04, $02 or $01
;
;   Note that DF=1 is returned if X .GE. 240 or Y .GE. 192.  In this case the
; other values returned in T1, T2 and D are invalid!   The original coordinate
; in P1 will be unchanged regardless of success or failure.
;
;  Uses T3 (which we should probably preserve!) ...
;--
XYTORC:	PUSHR(T3)		; save T3 for a temporary
	GLO P1\ SMI 192		; is Y valid ?
	LBGE	XYTO99		; branch if not

; Compute Y*4+Y (i.e. Y*5) to get the PMEM address ...
	GLO P1\ ANI $F8\ PLO T1	; ...
	LDI 0\ PHI T1		; ...
	RSHL(T1)\ RSHL(T1)	; Y*4
	GLO P1\ ANI $F8\ STR SP	; and then add Y again
	GLO T1\ ADD\ PLO T1	; ...
	GHI T1\ ADCI 0\ PHI T1	; ...

; Use X to index the XTABLE and get the column and bit mask ...
	GHI P1\ SMI 240		; make sure X .LT. 240
	LBGE	XYTO99		; branch if bad
	GHI P1\ ANI $FE		; compute X/2 and then *2 to index XTABLE
	ADI LOW(XTABLE)\ PLO T3	; ...
	LDI HIGH(XTABLE)\ ADCI 0; ...
	PHI T3\ SEX T3		; ...

; Add the character offset (the first byte in XTABLE) to the PMEM address ...
	GLO T1\ ADD\    PLO T1	; add the low bytes
	GHI T1\ ADCI 0\ PHI T1	;  ... and handle the carry

; Y MOD 8 gives us the CMEM address ...
	GLO P1\ ANI $7\ PLO T2	; the PMEM address is always in the
	LDI HIGH(CHARMEM)\ PHI T2; ... range $F400 .. $F407 .

;   And lastly, get the bit mask from XTABLE.  Note that if the original X
; coordinate was odd, then we need to shift this mask right one bit ...
	GHI P1\ SHR		; put the LSB of X in DF
	INC T3\ LDN T3		; and get the bit mask
	LSNF			; skip if X was even
	 SHR\ NOP		; X was odd - shift mask one bit
	CDF\ LSKP		; return DF=0 and we're done

; Here if either X or Y is invalid ...
XYTO99:	SDF			; return DF=1
	PHI	AUX		; save the bitmask 
	SEX SP\ IRX\ POPRL(T3)	; restore T3
	GHI AUX\ RETURN		; restore the bitmask and we're done here

	.SBTTL	Plot a Single Point

;++
;   This routine will plot, by setting the corresponding pixel to 1, a single
; (X,Y) point.  The coordinates are passed in P1 using the usual convention
; of P1.1 == Y, P1.0 == X.  If the coordinates are invalid, i.e. outside the
; screen, then we return with DF=1 and nothing is plotted.  Otherwise we return
; DF=0 and a new pixel appears on the screen.  In either case, P1 is not
; changed.
;
;CALL:
;	P1/ coordinate		; P1.1 == X, P1.0 == Y
;	CALL(PLOT)
;	DF/ coordinate valid	; DF=0 valid, DF=1 invalid
;
; Uses (and does not preserve) T1 and T2 ...
;--
PLOT:	CALL(GMODE)		; be sure graphics mode is enabled
	CALL(XYTORC)		; convert P1 to row and column
	LBDF	PLOT2		; quit now if coordinates are invalid
	SEX T1\ OUT VISPMA	; select the correct character cell
	SEX	T2		; ...
	B_DISPLAY $		; synchronize with the display
	OR\ STR T2		; set the pixel in D
	CDF			; and return DF=0
PLOT2:	RETURN			; that's all there is to it!

	.SBTTL	Draw Horizontal Lines

;++
;   This routine draws the special case of a horizontal line, from (X1,Y1) to
; (X2,Y2) where Y1==Y2.  
;
;CALL:
;	P1/ coordinate #1	; P1.1 == X1, P1.0 == Y1
;	P2/ coordinate #2	; P2.1 == X2, P2.0 == Y2
;	CALL(HLINE)
;	DF/ coordinate valid	; DF=0 valid, DF=1 invalid
;
;   Note that the Y2 coordinate in P2 (P2.0) is actually ignored and can be
; anything.  It's assumed to be the same as Y1 (P1.0) but we don't actually
; bother to check.  If X1 (P1.1) is .GT. X2 (P2.1) then then P1.1 and P2.1
; will be swapped so that X1 is the smaller of the two.  In any case, when
; we return P1 and/or P2 will be changed such that P1.1 == P2.1.
;
;   Uses T1, T2 and T2.  Assumes that the caller has already entered graphics
; mode!
;--
HLINE:	CALL(GMODE)		; be sure graphics mode is enabled
	GHI P2\ STR SP		; test that X2 .GE. X1
	GHI P1\ SD		; ...
	LBGE	HLINE1		; jump if X1 .LT. X2
	GHI P1\ PHI P2		; otherwise swap X1 and X2
	LDN SP\ PHI P1		; ...
HLINE1:	CALL(XYTORC)		; convert P1 to screen coordinates
	LBDF	HLINE9		; quit if they're invalid

;   "OR" in one bits horizontally, shifting the mask right after every pixel.
; When we hit the right end of the character cell, reset the mask to $20 and
; increment the character address by one.
HLINE2:	SEX T1\ OUT VISPMA	; select the correct character cell
	DEC	T1		;  ... correct for OUT
HLINE3:	PHI AUX\ SEX T2		; save the current pixel mask
;;  NOP\ NOP\ NOP  ; for alignment
	B_DISPLAY $		; wait for display memory access
	OR\ STR T2		; set this bit in the frame buffer
	GHI P1\ ADI 1\ PHI P1	; increment X1
	STR SP\ SEX SP		; compare with X2
	GHI P2\ SM		; ...
	LBL	HLINE4		; quit when X2-X1 .LT. 0
	GHI AUX\ SHR		; shift the bit mask right one pixel
	LBNZ	HLINE3		; branch if still the same character cell
	LDI $20\ INC T1		; otherwise start with the leftmost pixel
	LBR	HLINE2		;  ... of the next character cell

; Here when we're finished ...
HLINE4:	CDF			; return DF=0 for success
HLINE9:	RETURN			; ...

	.SBTTL	Draw Vertical Lines

;++
;   This routine draws the special case of a vertical line, from (X1,Y1) to
; (X2,Y2) where X1==X2.  
;
;CALL:
;	P1/ coordinate #1	; P1.1 == X1, P1.0 == Y1
;	P2/ coordinate #2	; P2.1 == X2, P2.0 == Y2
;	CALL(VLINE)
;	DF/ coordinate valid	; DF=0 valid, DF=1 invalid
;
;   Note that the X2 coordinate in P2 (P2.1) is actually ignored and can be
; anything.  It's assumed to be the same as X1 (P1.1) but we don't actually
; bother to check.  If Y1 (P1.0) is .GT. Y2 (P2.0) then then P1.0 and P2.0
; will be swapped so that Y1 is the smaller of the two.  In any case, when
; we return P1 and/or P2 will be changed such that P1.0 == P2.0.
;
;   Uses T1, T2 and T2.  Assumes that the caller has already entered graphics
; mode!
;--
VLINE:	CALL(GMODE)		; be sure graphics mode is enabled
	GLO P2\ STR SP		; test that Y2 .GE. Y1
	GLO P1\ SD		; ...
	LBGE	VLINE1		; jump if Y1 .LT. Y2
	GLO P1\ PLO P2		; otherwise swap Y1 and Y2
	LDN SP\ PLO P1		; ...
VLINE1:	CALL(XYTORC)		; convert P1 to screen coordinates
	LBDF	VLINE9		; quit if they're invalid
	PHI	AUX		; save the pixel mask

;  "OR" in ones to set the pixel at the location given by AUX.1 for each
; font (CHARMEM) row, incrementing the font row each time.  Everytime we've
; done 8 font rows, increment the text row and restart with font row 0.
VLINE2:	SEX T1\ OUT VISPMA	; select the correct character row
	DEC	T1		; ... correct for OUT
VLINE3:	GHI AUX\ SEX T2		; set this pixel in the frame buffer
	B_DISPLAY $		; wait for display memory access
	OR\ STR T2		; ...
	INC P1\ GLO P1\ STR SP	; increment Y1
	SEX SP\ GLO P2\ SM	; compare with Y2
	LBL	VLINE4		; quit when Y2-Y1 .LT. 0
	INC T2\ GLO T2\ ANI $7	; have we filled this character cell?
	LBNZ	VLINE3		; no - do another pixel
	GLO T1\ ADI 40\ PLO T1	; bump to the next text row
	GHI T1\ ADCI 0\ PHI T1	; ...
	LDI 0\ PLO T2		; and reset the font row
	LBR	VLINE2		; 

; Here when we're finished ...
VLINE4:	CDF			; return DF=0 for success
VLINE9:	RETURN			; ...

	.SBTTL	Draw Line with ABS(slope) .LE. 1

;++
;   This code is called by LINE when it finds a line where the absolute
; magnitude of the slope is .LE. 1 (that is, the change in X is greater than
; the change in Y).  This is Bresenham's algorithm - we iterate X one pixel
; at a time, and for each step we figure out whether we need to increment Y
; (or decrement it if the slope is negative), or leave it unchanged.
;
;   This is the C code that we're (approximately) trying to implement ...
;
;  void Line1()
;  {
;    int8_t yi = 1;
;    if (dy < 0) {
;      yi = -1;  dy = -dy;
;    }
;    int16_t D = (2 * dy) - dx;
;    do {
;      Plot(x0,y0);
;      if (D > 0) {
;        y0 += yi;
;        D += 2 * (dy - dx);
;      } else {
;        D += 2 * dy;
;      }
;      ++x0;
;    } while (x0 <= x1);
;  }
;
;   Note that dx and dy have already been calculated when we get here, and
; we don't need to repeat that operation.  See LINE for a description of 
; the register usage.
;--
LINE1:	LDI 1\ PLO T3		; set Y increment = 1
	GHI P4\ LBZ LINE11	;  ... but if dy < 0
	LDI $FF\ PLO T3		;  ... Y increment = -1
	RCOPY(P4,T4)		;  ... and set dy = ABS(dy)
LINE11:	RCOPY(T4,P4)		; D = (2 * dy) - dx
	RSHL(T4)\ DSUB(T4,P3)	;  ...
LINE12:	CALL(PLOT)		; plot a pixel at (P1.1, P1,0)
	LBDF	LINE19		;  ... quit if coordinates are invalid
	GHI T4\ ANI $80		; test the sign of D ...
	LBNZ	LINE13		;  ... branch if D is negative
	GLO P1\ STR SP\ SEX SP	;  ... Y += Y increment
	GLO T3\ ADD\ PLO P1	;  ...
	RCOPY(T1,P4)		;  ... and D += 2 * (dy - dx)
	DSUB(T1,P3)\ RSHL(T1)	;  ...
	DADD(T4,T1)\ LBR LINE14	;  ...
LINE13:	RCOPY(T1,P4)		; else ...
	RSHL(T1)\ DADD(T4,T1)	;  ... D += 2 * dy
LINE14:	GHI P1\ ADI 1\ PHI P1	; X += 1
	GHI P1\ STR SP		; if P2.1 - P1.1 >= 0	
	GHI P2\ SM\ LBGE LINE12	;   ... continue
	CDF			; return DF=0 for success
LINE19:	RETURN			; all done!

	.SBTTL	Draw Line with ABS(slope) .GE. 1

;++
;   This code is called by LINE when it finds a line where the absolute
; magnitude of the slope is .GE. 1 (that is, the change in Y is greater than
; the change in X).  Once again this is Bresenham's algorithm and this code is
; basically identical to LINE1, EXCEPT that here we iterate Y one pixel at a
; time. For each step we figure out whether we need to increment (or decrement)
; X.
;
;   This is the C code that we're (approximately) trying to implement ...
;
;  void Line2()
;  {
;    int8_t xi = 1;
;    if (dx < 0) {
;      xi = -1;  dx = -dx;
;    }
;    int16_t D = (2 * dx) - dy;
;    do {
;      Plot(x0, y1);
;      if (D > 0) {
;        x0 += xi;
;        D += 2 * (dx - dy);
;      } else {
;        D += 2 * dx;
;      }
;      ++y0;
;    } while (y0 <= y1);
;  }
;  
;   Once again, dx and dy have already been calculated before we get here, and
; see the LINE for a complete description of the register usage ...
;--
LINE2:	LDI 1\ PLO T4		; set X increment = 1
	GHI P3\ LBZ LINE21	;  ... but if dx < 0
	LDI $FF\ PLO T4		;  ... X increment = -1
	RCOPY(P3,T3)		;  ... and set dx = ABS(dx)
LINE21:	RCOPY(T3,P3)		; D = (2 * dx) - dy
	RSHL(T3)\ DSUB(T3,P4)	;  ...
LINE22:	CALL(PLOT)		; plot a pixel at (P1.1, P1,0)
	LBDF	LINE29		;  ... quit if coordinates are invalid
	GHI T3\ ANI $80		; test the sign of D ...
	LBNZ	LINE23		;  ... branch if D is negative
	GHI P1\ STR SP\ SEX SP	;  ... X += X increment
	GLO T4\ ADD\ PHI P1	;  ...
	RCOPY(T1,P3)		;  ... D += 2 * (dx - dy)
	DSUB(T1,P4)\ RSHL(T1)	;  ...
	DADD(T3,T1)\ LBR LINE24	;  ...
LINE23:	RCOPY(T1,P3)		; else
	RSHL(T1)\ DADD(T3,T1)	;  ... D += 2 * dx;
LINE24:	GLO P1\ ADI 1\ PLO P1	; Y += 1
	GLO P1\ STR SP		; if P2.0 - P1.0 >= 0
	GLO P2\ SM\ LBGE LINE22	;  ... continue
	CDF			; return success
LINE29:	RETURN			; all done!

	.SBTTL	Draw Arbitrary Lines

;++
;   This routine will draw an arbitrary line from the point (X1,Y1) to the
; point (X2,Y2). The basic plan is to use Bresenham's Algorithm, just like
; I learned way back when in CS461.  Bresenham's has the advantages of avoiding
; not only floating point arithmetic, but also any need for multiplication or
; division, which is a big win for the little 1802.
;
;CALL:
;	P1/ coordinate #1	; P1.1 == X1, P1.0 == Y1
;	P2/ coordinate #2	; P2.1 == X2, P2.0 == Y2
;	CALL(LINE)
;	DF/ coordinate valid	; DF=0 valid, DF=1 invalid
;
;   This particular routine calculates the difference in the X coordinates
; (aka dx) and the Y coordinates (dy).  From those we first check for vertical
; lines (dx == 0) and horizontal lines (dy == 0), and handle those as special
; cases.  Failing that, we need to figure out whether ABS(dy) is .GE. or .LE.
; ABS(dx) and call either LINE1 or LINE2 to handle that case.  BTW, if the
; slope happens to be exactly one (or -1) then either LINE1 or LINE2 will work.
;
;   This is approximately the C code that we're trying to implement -
;
;  void LINE (uint8_t x0, uint8_t y0, uint8_t x1, uint8_t y1)
;  {
;    int16_t dx = x1 - x0;
;    int16_t dy = y1 - y0;
;    if (dx == 0) {
;      VLine();
;    } else if (dy == 0) {
;      HLine();
;    } else if (ABS(dy) < ABS(dx)) {
;      if (x0 > x1) LSwap();
;      LINE1();
;    } else {
;      if (y0 > y1) LSwap();
;      LINE2();
;    }
;  }
;
;   This code uses pretty much ALL the available registers, and they're
; allocated as follows -
;
;	P1 -> P1.1 == X0, P1.0 == Y0
;	P2 -> P2.1 == X1, P2.2 == Y1
;	P3 -> dx (16 bit signed)
;	P4 -> dy (16 bit signed)
;	T1 -> temporary (used by PLOT!) 
;	T2 -> temporary (used by PLOT!) 
;	T3 -> contains ABS(P3), then D (LINE2) or yi (LINE1)
;	T4 -> contains ABS(P4), then D (LINE1) or xi (LINE2)
;
;   The code in LINE1 and LINE2 depends on the registers, particularly P3,
; P4, T3, and T4, being left with these values!
;
;   One last word on arithmetic - remember that the VIS coordinate space is
; 240x192 pixels.  As unsigned values this fits perfecting into an 8 bit byte,
; but some calculations (notably dx and dy) require SIGNED quantities.  That
; means we need an extra bit, so we use an entire 16 bit register where the
; upper byte will always be either $00 or $FF depending on the sign of the
; lower half.
;--
LINE:

;   First calculate dx and leave the result in P3.  Remember that we always
; calculate x1-x0 and the result may be negative if x1 < x0!  We also leave
; the absolute value of the difference, which is used later, in T3.  Believe
; it or not, we don't bother to range check for valid coordinates here; if the
; caller passed bogus values we just do the calculations anyway.  Eventually,
; when we call PLOT, that will fail and we'll return DF=1 then.
	GHI P2\ PLO P3		; set P3 = X1
	GHI P1\ PLO T1		; and set T1 = X0
	LDI 0\ PHI P3\ PHI T1	;  ...
	DSUB(P3,T1)		; compute dx = X1 - X0
	GLO P3\ LBZ VLINE	; if dx == 0 then draw a vertical line
	RCOPY(T3,P3)		; now set T3 = ABS(P3)
	GHI T3\ LBZ LINE01	;  ... if it's already positive, do nothing
	GLO T3\ SDI 0\ PLO T3	;  ... otherwise T3 = -T3
	LDI 0\ PHI T3		;  ...

; Here to do the same kind of calculation for dy ...
LINE01:	GLO P2\ PLO P4		; set P4 = Y1
	GLO P1\ PLO T1		; and set T1 = Y0
	LDI 0\ PHI P4\ PHI T1	;  ...
	DSUB(P4,T1)		; compute dy = Y1 - Y0
	GLO P4\ LBZ HLINE	; if dy == 0 then draw a horizontal line
	RCOPY(T4,P4)		; now set T4 = ABS(P4)
	GHI T4\ LBZ LINE02	;  ... branch if it's already positive
	GLO T4\ SDI 0\ PLO T4	;  ... otherwise T4 = -T4
	LDI 0\ PHI T4		;  ...

;   Now we want to figure out if the magnitude of the slope is less or greater
; than 1, i.e. if ABS(dy) < ABS(dx).  Remember that T4 and T4 already have
; ABS(dy) and ABS(dx) respecively, so we want to know is T4-T3 < 0?  Since we
; know that T4 and T3 are positive values, we only need to compare the lower
; 8 bits!
LINE02:	GLO T3\ STR SP\ SEX SP	; put dx on the stack
	GLO T4\ SM\ LBGE LINE04	;  ... and branch if dy-dx >= 0

;   Here if the slope is less than 1, so we're going to iterate in X.  We want
; to arrange things so X0 is the smaller X value and X1 is the greater.  If
; that's not the case, then swap the two end points and draw the line in the
; other direction.
	GHI P2\ STR SP		; put X1 on the stack
	GHI P1\ SM\ LBL LINE03	; branch if X0-X1 <= 0
	CALL(LSWAP)		; otherwise swap P1 and P2
LINE03:	LBR	LINE1		; draw the line and we're done!

;   Here if the slope is greater than 1.  It's pretty much the same as above,
; except this time we want P1 to have the smaller Y value, and swap if needed.
LINE04: GLO P2\ STR SP		; put Y1 on the stack
	GLO P1\ SM\ LBL LINE05	; branch if Y0-Y1 <= 0
	CALL(LSWAP)		;   ... swap P1 and P2
LINE05:	LBR	LINE2		; and draw the line


;++
;   This little routine will exchange the two end points of the line, P1 and
; P2.  Since dx = x1-x0 and dy = y1-y0, that also means we have to negate
; both P3 and P4.  Remember that T3 and T4 contain the absolute value of dx
; and dy, so they're not affected by the change.
;--
LSWAP:	GHI P1\ STR SP		; swap P1 and P2 ...
	GHI P2\ PHI P1		;  ...
	LDN SP\ PHI P2		;  ...
	GLO P1\ STR SP		;  ...
	GLO P2\ PLO P1		;  ...
	LDN SP\ PLO P2		;  ...
	GHI P3\ XRI $FF\ PHI P3	; P3 = 0 - P3
	GLO P3\ SDI 0\ PLO P3	;  ...
	GHI P4\ XRI $FF\ PHI P4	; P4 = 0 - P4
	GLO P4\ SDI 0\ PLO P4	; ...
	RETURN			; all done

	.SBTTL	X/6 and X MOD 6 Tables

;++
;   This table is indexed by X/2*2 (i.e. X with the LSB cleared).  We really
; need to compute X/6 and X MOD 6, however to save space we actually compute
; (X/2)/3 and (X/2) MOD 3, the X/2 part being easy to manage with a simple
; shift.  However this table contains a word (i.e. two bytes) for every X/2
; value, so we need to multiply by 2 again when computing the index.  Hence
; it turns out that we don't even need to do the shift or compute X/2; we
; just clear the LSB of X and we're good.  Simple, not?
;
;   The first byte of every table entry gives the character position within
; the character row corresponding to this X coordinate, and the second byte
; gives the bit mask for the specific bit corresponding to that position. 
; If the original X value was odd, then we need to shift that bit mask right
; one bit to account for that.
;--
XTABLE:	.DB	 0,$20,  0,$08,  0,$02	;   0<=X<  6
	.DB	 1,$20,  1,$08,  1,$02	;   6<=X< 12
	.DB	 2,$20,  2,$08,  2,$02	;  12<=X< 18
	.DB	 3,$20,  3,$08,  3,$02	;  18<=X< 24
	.DB	 4,$20,  4,$08,  4,$02	;  24<=X< 30
	.DB	 5,$20,  5,$08,  5,$02	;  30<=X< 36
	.DB	 6,$20,  6,$08,  6,$02	;  36<=X< 42
	.DB	 7,$20,  7,$08,  7,$02	;  42<=X< 48
	.DB	 8,$20,  8,$08,  8,$02	;  48<=X< 54
	.DB	 9,$20,  9,$08,  9,$02	;  54<=X< 60
	.DB	10,$20, 10,$08, 10,$02	;  60<=X< 66
	.DB	11,$20, 11,$08, 11,$02	;  66<=X< 72
	.DB	12,$20, 12,$08, 12,$02	;  72<=X< 78
	.DB	13,$20, 13,$08, 13,$02	;  78<=X< 84
	.DB	14,$20, 14,$08, 14,$02	;  84<=X< 90
	.DB	15,$20, 15,$08, 15,$02	;  90<=X< 96
	.DB	16,$20, 16,$08, 16,$02	;  96<=X<102
	.DB	17,$20, 17,$08, 17,$02	; 102<=X<108
	.DB	18,$20, 18,$08, 18,$02	; 108<=X<114
	.DB	19,$20, 19,$08, 19,$02	; 114<=X<120
	.DB	20,$20, 20,$08, 20,$02	; 120<=X<126
	.DB	21,$20, 21,$08, 21,$02	; 126<=X<132
	.DB	22,$20, 22,$08, 22,$02	; 132<=X<138
	.DB	23,$20, 23,$08, 23,$02	; 138<=X<144
	.DB	24,$20, 24,$08, 24,$02	; 144<=X<150
	.DB	25,$20, 25,$08, 25,$02	; 150<=X<156
	.DB	26,$20, 26,$08, 26,$02	; 156<=X<162
	.DB	27,$20, 27,$08, 27,$02	; 162<=X<168
	.DB	28,$20, 28,$08, 28,$02	; 168<=X<174
	.DB	29,$20, 29,$08, 29,$02	; 174<=X<180
	.DB	30,$20, 30,$08, 30,$02	; 180<=X<186
	.DB	31,$20, 31,$08, 31,$02	; 186<=X<192
	.DB	32,$20, 32,$08, 32,$02	; 192<=X<198
	.DB	33,$20, 33,$08, 33,$02	; 198<=X<204
	.DB	34,$20, 34,$08, 34,$02	; 204<=X<210
	.DB	35,$20, 35,$08, 35,$02	; 210<=X<216
	.DB	36,$20, 36,$08, 36,$02	; 216<=X<222
	.DB	37,$20, 37,$08, 37,$02	; 222<=X<228
	.DB	38,$20, 38,$08, 38,$02	; 228<=X<234
	.DB	39,$20, 39,$08, 39,$02	; 234<=X<240

	.SBTTL	Parse Hex Numbers

;++
; Scan two hexadecimal parameters and return them in registers P4 and P3...
;--
HEXNW2:    CALL(HEXNW)        ; scan the first parameter
    RCOPY(P3,P2)        ; return first parameter in P3
    CALL(ISEOL)        ; there had better be more there
    LBDF    CMDERR        ; error if not
    CALL(HEXNW)        ; scan the second parameter
    RCOPY(P4,P2)        ; return second parameter in P4
    RETURN            ; and we're done

;++
;   Scan a single hexadecimal parameter and return its value in register P2.
; Leading spaces are ignored, and on return P1 will point to the first non-
; hexadecimal character found.  If NO hexadecimal digits are found, then we
; branch to CMDERR and abort this command.
;--
HEXNW:	CALL(LTRIM)\ RCLR(P2)	; ignore leading spaces and clear result
	CALL(ISHEX)\ LBDF CMDERR; quit if first char isn't a hex digit
HEXNW1:	PUSHD			; save the current digit
	RSHL(P2)\ RSHL(P2)	; shift the current value left 4 bits
	RSHL(P2)\ RSHL(P2)	; ...
	IRX			; point to the original digit
	GLO P2\ OR\ PLO P2	; and add that digit to P2
	INC P1\ CALL(ISHEX)	; is the next character another hex digit?
	LBNF	 HEXNW1		; loop if it is
	RETURN			; otherwise return success!


;++
; This routine will return DF=1 if (P3 .LE. P4) and DF=0 if it is not...
;--
P3LEP4: GHI P3\ STR SP\ GHI P4	; first compare the high bytes
	SM			; see if P4-P3 < 0 (which implies that P3 > P4)
	LBL	P3GTP4		; because it is an error if so
	LBNZ	P3LE0		; return if the high bytes are not the same
	GLO P3\ STR SP\ GLO P4	; the high bytes are the same, so we must
	SM			; ....
	LBL	P3GTP4		; ....
P3LE0:	SDF\ RETURN		; return DF=1
P3GTP4:	CDF\ RETURN		; return DF=0

;++
; This routine will compute P4-P3+1 and return the result in P3 ...
;--
P4SBP3:	GLO P3\ STR  SP		; subtract the low bytes first
	GLO P4\ SM\  PLO P3	; ...
	GHI P3\ STR  SP		; and then the high bytes
	GHI P4\ SMB\ PHI P3	; ...
	INC P3\ RETURN		; +1 and we're done

	.SBTTL	Command Parsing Functions

;++
;   Examine the character pointed to by P1 and if it's a space, tab, or end
; of line (NULL) then return with DF=1...
;--
ISSPAC:	LDN P1\ LBZ ISSPA1	; return TRUE for EOL
	SMI CH.TAB\ LBZ ISSPA1	; return TRUE for tab too
	SMI	 ' '-CH.TAB	; lastly, check for a space?
	LBZ	ISSPA1		; that works as well
	CDF\ RETURN		; it's not a space, return DF=0
ISSPA1:	SDF\ RETURN		; it IS a space!


;++
; If the character pointed to by P1 is EOL, then return with DF=1...
;--
ISEOL:	CALL(LTRIM)		; ignore any trailing spaces
	LDN P1\ LBZ ISSPA1	; return DF=1 if it's EOL
	CDF\ RETURN		; otherwise return DF=0


;++
; Just like ISEOL, but if the next character is NOT an EOL, then error ..
;++
CHKEOL:	CALL(ISEOL)		; look for the end of line next
	LBNF	CMDERR		; abort this command if it's not
	RETURN			; otherwise do nothing


;++
;  Trim leading white space from string pointed to by P1.  Returns with P1
; pointing to the first non-whitespace character in the string (which might
; be the EOS!).
;--
LTRIM:	LDN P1\ LBZ TRMRET	; get the next char and return if EOS
	XRI CH.CRT\ LBZ TRMRET	; stop on <CR>
	LDN P1\ XRI CH.LFD	;  ... or <LF>
	LBZ	TRMRET		;  ...
	LDN P1\ XRI CH.ESC	;  ... or <ESC>
	LBZ	TRMRET		;  ...
	LDN P1\ SMI ' '+1	; otherwise compare to space
	LBGE	TRMRET		; ignore space or any other control characters
	INC P1\ LBR LTRIM	; keep looking
TRMRET:	RETURN			; all done


;++
;   This routine will examine the ASCII character in D and, if it is a lower
; case letter 'a'..'z', it will fold it to upper case.  All other ASCII
; characters are left unchanged...
;--
FOLD:	ANI $7F\ PHI AUX	; only use seven bits
	SMI 'a'\ LBL FOLD1	; branch if .LT. 'a'
	SMI 'z'-'a'+1		; check it against both ends of the range
	LBGE	FOLD1		; nope -- it's not a letter
	GHI AUX\ SMI $20	; it is lower case - convert it to upper case
	RETURN			; and return that
FOLD1:	GHI AUX\ RETURN		; not lower case - return the original


;++
;   This routine will examine the ASCII character at P1 and, if it is a hex
; character '0'..'9' or 'A'..'Z', it will convert it to the equivalent binary
; value and return it in D.  If the character is not a hex digit, then it
; will be returned in D unmolested and the DF will be set.
;--
ISHEX:	LDN P1\ ANI $7F		; get the character
	SMI '0'\ LBL ISHEX3	; branch if .LT. '0'
	SMI  10\ LBL ISHEX2	; branch if it's a decimal digit
	LDN P1\ CALL(FOLD)	; convert lower case 'a'..'z' to upper
	SMI 'A'\ LBL ISHEX3	; branch if .LT. 'A'
	SMI  6\ LBGE ISHEX3	; branch if .GE. 'G'
; Here for a letters 'A' .. 'F'...
	ADI	6		; convert 'A' back to the value 10
; Here for a digit '0' .. '9'...
ISHEX2:	ADI	10		; convert '0' back to the value 0
	CDF\ RETURN		; return DF=0
; Here if the character isn't a hex digit at all...
ISHEX3:	LDN	P1		; get the original character back
	SDF\ RETURN		; and return with DF=1

;++
;   Return DF=0 if the character at P1 is a decimal digit 0..9 AND return the
; corresponding binary value in D.  If the character isn't a digit, then return
; DF=1 and the original character, unmolested, in D.
;--
ISDIGIT:LDN P1\ ANI $7F		; get the character
	SMI '0'\ LBL NOTDIGT	; branch if .LT. '0'
	SMI 10 \ LBGE NOTDIGT	; branch if .GT. '9'
	ADI	10		; convert the digit to binary
	CDF\ RETURN		; and return DF=0
NOTDIGT:LDN	P1		; return the original character
	SDF\ RETURN		; and return DF=1

	.SBTTL	Console Line Input w/Editing

;++
;   The READLN routine reads an entire line from the console and stores the
; result in a buffer provided by the caller.  Text is echoed as it is read and
; several intraline editing characters are recognized -
;
;   BACKSPACE ($08) - erase the last character input
;   DELETE    ($7F) - same as BACKSPACE
;   CONTROL-U ($15) - erase the entire line and start over
;   RETURN    ($0D) - echos <CRLF>, terminates input and returns
;   LINE FEED ($0A) - same as RETURN
;   ESCAPE    ($1B) - echos "$" and <CRLF>, then terminates input and returns
;   CONTROL-C ($03) - aborts all input and returns with DF=1
;
;   The BACKSPACE, DELETE and CONTROL-U functions all work by echoing the
; <backspace> <space> <backspace> sequence and assume that you're using a CRT
; terminal (does anybody even use hardcopy these days?).
;
;   The line terminators, RETURN, LINE FEED, ESCAPE and CONTROL-C all insert a
; NULL byte in the buffer to end the string, however the terminator itself is
; not added to the buffer. CONTROL-C returns with DF=1 to signal that input was
; aborted, but the other terminators all return with DF=0.
;
;   Other control characters echo as "^x" where "x" is the printing equivalent,
; however the original ASCII control character will be added to the buffer.
; If the buffer overflows during input then a BELL ($07) will be echoed for
; everything instead of the original character.
;
; CALL:
;	P1 -> buffer address
;	P3 -> buffer size
;	CALL(READLN)
;	DF=1 (CONTROL-C typed) or DF=0 otherwise
;--
READLN:	PUSHR(T1)		; save a work register
	LDI 0\ PLO T1		; and keep a byte count there

; Read the next character and figure out what it is ...
READL1:	CALL(INCHNE)		; read WITHOUT echo
	ANI	$7F		; always trim this input to 7 bits
	LBZ	READL1		; ignore nulls
	PHI	AUX		; and save the character temporarily
	SMI	CH.CTC		; CONTROL-C?
	LBZ	REACTC		; ...
	SMI	CH.BSP-CH.CTC	; BACKSPACE?
	LBZ	REABSP		; ...
	SMI	CH.LFD-CH.BSP	; LINE FEED?
	LBZ	REAEOL		; ...
	SMI	CH.CRT-CH.LFD	; CARRIAGE RETURN?
	LBZ	REAEOL		; ...
	SMI	CH.CTU-CH.CRT	; CONTROL-U?
	LBZ	REACTU		; ...
	SMI	CH.ESC-CH.CTU	; ESCAPE?
	LBZ	REAESC		; ...
	SMI	CH.DEL-CH.ESC	; DELETE?
	LBZ	REABSP		; ...

;   Here for any normal, average, boring, printing ASCII character.  If the
; buffer isn't full, then store this one and echo it.  If the buffer IS full,
; then echo a bell instead and don't store anything.  Remember that we always
; need at least one empty byte left over to store the terminating null!
READL2:	GHI P3\ LBNZ REAU2A	; if the buffer size .GE. 256 then no worries
	GLO P3\ SMI 2		; otherwise be sure there at least 2 bytes free
	LBL	REABEL		; nope - the buffer is full
REAU2A:	GHI AUX\ STR P1		; store the original character in the buffer
	CALL(TFECHO)		; and echo it
	DEC	P3		; decrement the buffer size
	INC	T1		; increment the character count
	INC	P1		; and and increment the buffer pointer
	LBR	READL1		; then go do it all over again

; Here if the buffer is full - echo a bell and don't store anything ...
REABEL:	CALL(TBELL)\ LBR READL1	; and wait for a line terminator

; Here for a BACKSPACE or a DELETE - try to erase the last character ...
REABSP:	CALL(DELCHR)		; do all the real work
	LBDF	REABEL		; ring the bell if there's nothing there
	LBR	READL1		; and then keep going

; Here for CONTROL-U - erase ALL the characters back to the prompt ...
REACTU:	CALL(DELCHR)		; try to delete the last character
	LBNF	REACTU		; and keep going until the buffer is empty
	LBR	READL1		; then start over again

; Here for a CONTROL-C - echo ^C and then terminate input ...
REACTC:	GHI AUX\ CALL(TFECHO)	; echo ^C
	CALL(TCRLF)		; and newline
	LBR	MAIN		; and then restart everything!

; Here for ESCAPE - echo "$" and terminate the input ...
REAESC:	OUTCHR('$')		; echo "$" 
				; and fall into the rest of the EOL code

; Here for RETURN or LINE FEED ...
REAEOL:	CDF			; return DF=0
READL3:	CALL(TCRLF)		; echo <CRLF> regardless 
	LDI 0\ STR P1		; then terminate the input string
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're finally done!

;   This little subroutine erases the last character from the buffer, and from
; the screen as well.  If the buffer is currently empty, then it does nothing
; and returns with DF=1...
DELCHR:	SDF			; assume DF=1
	GLO	T1		; get the character count
	LBZ	DELCH2		; if it's zero then quit now
	CALL(TBACKSP)		; erase the character from the screen
	INC	P3		; increment the buffer size
	DEC	T1		; decrement the character count
	DEC	P1		; and back up the buffer pointer
	LDN	P1		; get the character we just erased
	ANI	~$1F		; is it a control character??
	LBNZ	DELCH1		; no - quit now
	CALL(TBACKSP)		; yes - erase the "^" too
DELCH1:	CDF			; and return with DF=0
DELCH2:	RETURN			; ...

	.SBTTL	Console Output Routines

;   This routine will convert a four bit value in D (0..15) to a single hex
; digit and then type it on the console...
THEX1:	ANI $0F\ ADI '0'	; trim to 4 bits and convert to ASCII
	SMI '9'+1\ LBL THEX11	; branch if this digit is 0..9
	ADI	'A'-'9'-1	; convert 10..15 to letters
THEX11:	ADI	'9'+1		; and restore the original character
	LBR	TCHAR		; type it and return


; This routine will type a two digit (1 byte) hex value from D...
THEX2:	PUSHD			; save the whole byte for a minute
	SHR\ SHR\ SHR\ SHR	; and type type MSD first
	CALL(THEX1)		; ...
	POPD			; pop the original byte
	LBR	THEX1		; and type the least significant digit


; This routine will type a four digit (16 bit) hex value from P2...
THEX4:	GHI	P2		; get the high byte
	CALL(THEX2)		; and type that first
	GLO	P2		; then type the low byte next
	LBR	THEX2		; and we're done


;++
;   Send an entire ASCIZ (null terminated) string to the serial port.  A
; pointer to the string is passed in P1, and we return with P1 pointing to
; the byte AFTER the NULL at the end of the string.  That's essential for
; INLMES, below.   Note that this works by calling TCHAR, so if the buffer
; fills up, we'll just wait.  Uses T1 (and P1).
;--
TSTR:	LDA	P1		; get the next character
	LBZ	TSTR1		; stop when we find the EOS
	CALL(TCHAR)		; send it
	LBR	TSTR		; and keep going
TSTR1:	RETURN			; ...


;++
;   Send an inline string to the serial port and then return to the next
; byte after the end of the string.  For example -
;
; 	CALL(TMSG)
;	.TEXT	"HELLO WORLD!\000"
;	<return here>
;
; Uses P1 and T1.
;--
TMSG:	RCOPY(P1, A)		; put the string address in P1
	CALL(TSTR)		; type it
	RCOPY(A, P1)		; and then update the return address
	RETURN


; This routine will type a carriage return/line feed pair on the console...
TCRLF:	LDI CH.CRT\ CALL(TCHAR)	; type carriage return
	LDI CH.LFD\ LBR TCHAR	; and then line feed


; Type a single space on the console...
TSPACE:	LDI ' '\ LBR TCHAR	; this is what we want


; Type a (horizontal) tab...
TTABC:	LDI CH.TAB\ LBR TCHAR	; ...


; Type a question mark...
TQUEST:	LDI '?'\ LBR TCHAR	; ...


; Ring the bell (type a ^G) ...
TBELL:	LDI CH.BEL\ LBR TCHAR	; ...


; Type the sequence <BACKSPACE> <SPACE> <BACKSPACE> to erase the last character.
TBACKSP:OUTCHR(CH.BSP)		; type <backspace>
	OUTCHR(' ')		; <space>
	LDI CH.BSP\ LBR TCHAR	; <backspace>

	.SBTTL	Low Level Console I/O

;++
;   Read one character from the console, but with NO echo.  If nothing is
; buffered now, then wait until something is typed ...
;--
INCHNE:	CALL(CONGET)		; try to get a character
	LBDF	INCHNE		; and wait until one appears
	RETURN			; ...


;++
;   Read one character from the console, with echo.  If nothing is buffered
; now, then wait until something is typed.  Note that we CAN'T call TCHAR
; here for the echo - we don't know that the console output is going to the
; same device as input comes from.  We have to call TECHO instead.
;--
INCHRW:	CALL(INCHNE)		; wait for a character
	ANI $7F\ LBZ INCHRW	; trim to 7 bits and ignore NULs
	PUSHD\ CALL(TFECHO)	; echo it
	POPD\ RETURN		; restore the character and return


;++
;   Echo user input by calling CONECHO rather than CONPUT.  All printing
; characters are echoed normally, but "funny" characters are handled specially.
; ASCII control characters are printed as "^x", where "x" is the printing
; equivalent, with the the exception of 
;
;	<ESC> ($1B) which echos as "$"
;	<CR>  ($0D) which echos as itself
;	<BS>  ($08) which echos as itself
;--
TFECHO:	PHI	AUX		; save the character for a moment
	SMI ' '\ LBGE TFECH2	; if it's not a control character, echo it
	GHI AUX\ SMI CH.ESC	; is it an escape?
	LBZ	TFECH0		; yes - echo "$"
	GHI AUX\ SMI CH.CRT	; is it a carriage return?
	LBZ	TFECH2		; yes - echo literally
	GHI AUX\ SMI CH.BSP	; is it a backspace ?
	LBZ	TFECH2		; echo that literally
; Here to echo a control character as ^X ...
TFECH1:	GHI AUX\ PUSHD		; save the character more permanently
	LDI '^'\ CALL(TECHO)	; echo a "^" first
	POPD\ ADI '@'\ LBR TECHO; and print the printing equivalent
; Here to echo <ESC> as $ ...
TFECH0:	LDI '$'\ LBR TECHO	; yes - echo escape as "$"
; Here to echo a <CR> and <LF> ...
;TFECH3:	GHI AUX\ CALL(TECHO)	; echo the original <CR>
;	LDI CH.LFD\ LBR TECHO	; and then add a line feed
; Here to echo a normal printing character ...
TFECH2:	GHI AUX\ LBR TECHO	; restore and echo it


;++
;   Type a character on the console.  If the buffer is currently full, then
; wait until space is available ...
;--
TCHAR:	CALL(CONPUT)		; try to buffer the character
	LBDF	TCHAR		; and keep waiting if we can't
	RETURN			; success!

;++
;   Echo a character to the device associated with the keyboard, rather than
; the console.
;--
TECHO:	CALL(CONECHO)		; otherwise this is the same as TCHAR!
	LBDF	TECHO		; ...
	RETURN			; ...

	.SBTTL	Console Redirection

;++
;   The CONGET and CONPUT RAM locations contain an LBR to the console input
; and console output routines.  This can be either SERGET and SERPUT, or
; GETKEY and VTPUTC, depending on whether the console is directed to the
; serial port or the keyboard/video display.
;
;   CONECHO contains an LBR to the routine used to echo user input.  You
; might think this would always be CONPUT, but if the input and output devices
; are different - for example, input from the PS/2 keyboard but output to the
; serial port - then you want echo to go to the device associated with the
; input.  In this example, output might go to the serial port but echo still
; goes to the VIS display.
;
;   Lastly, the CONBRK routine is called to test for a break, either ISKBRK
; which tests for the PAUSE/BREAK key on the PS/2 keyboard, or ISSBRK which
; tests for a receiver framing error on the UART.
;--

;++
;   This routine will set the console input, echo and break test routines
; according to the parameters passed inline.
;
;CALL:
;	CALL(SETINP)
;	.WORD	<input routine>
;	.WORD	<echo routine>
;	.WORD	<break test routine>
;--
SETINP:	PUSHR(T1)		; preserve T1 for BASIC
	RLDI(T1,CONGET)		; point to the console vectors
	LDI $C0\ STR T1\ INC T1	; store LBR opcode
	LDA A\ STR T1\ INC T1	; store the address for the input routine
	LDA A\ STR T1\ INC T1	; ...
	LDI $C0\ STR T1\ INC T1	; store LBR opcode
	LDA A\ STR T1\ INC T1	; store the address for the echo routine
	LDA A\ STR T1\ INC T1	; ...
	LDI $C0\ STR T1\ INC T1	; store LBR opcode
	LDA A\ STR T1\ INC T1	; store the address for the break routine
	LDA A\ STR T1\ INC T1	; ...
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done


;++
;   This routine will set the console output ONLY according to the parameter
; passed inline.
;
;CALL:
;	CALL(SETOUT)
;	.WORD	<output routine>
;--
SETOUT:	PUSHR(T1)		; preserve T1 for BASIC
	RLDI(T1,CONPUT)		; point to the console output vector
	LDI $C0\ STR T1\ INC T1	; store LBR opcode
	LDA A\ STR T1\ INC T1	; store the address for the output routine
	LDA A\ STR T1\ INC T1	; ...
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done


; Direct console INPUT to the serial port ...
SIN:	CALL(SETINP)		; setup the CONxxx locations ...
	 .WORD	 SERGET		;  ... serial input routine
	 .WORD	 SERPUT		;  ... serial output for echo
	 .WORD	 ISSBRK		;  ... serial break test
	RETURN			; ...

; Direct console OUTPUT to the serial port ...
;   Note that this routine always returns DF=0.  That's used by BRSTIO
; via RSTIO!
SOUT:	CALL(SETOUT)		; setup the CONPUT location
	 .WORD	 SERPUT		;  ... output to the serial port
	CDF\ RETURN		; ...


; Direct console INPUT to the PS/2 keyboard ...
TIN:	CALL(SETINP)		; setup the CONxxx locations ...
	 .WORD	 GETKEY		;  ... PS/2 keyboard input routine
	 .WORD	 VTPUTC		;  ... echo to the VIS display
	 .WORD	 ISKBRK		;  ... keyboard break test
	RETURN			; ...

; Direct console OUTPUT to the VIS display ...
;   Note that this routine always returns DF=1.  That's used by BRSTIO
; via RSTIO!
TOUT:	CALL(SETOUT)		; setup the CONPUT location
	 .WORD	 VTPUTC		;  ... output to the serial port
	SDF\ RETURN		; ...


;++
;   And this routine will select the console depending on the setting of
; switch SW6.  SW6=1 selects "local mode", PS/2 keyboard and VIS display
; for the console.  SW6=0 selects "online mode", and the serial port is
; used for console I/O.
;--
RSTIO:	CALL(SELIO1)		; the DIP switches live in I/O group 1
	INP DIPSW\ ANI $20	; check the setting of SW6
	LBZ	RSTIO1		; SW6=0 
	CALL(TIN)		; SW6=1 -> select PS/2 keyboard
	LBR	TOUT		;  ... and VIS display
RSTIO1:	CALL(SIN)		; SW6=0 -> select serial port for input
	LBR	SOUT		;  ... and serial port for output

	.SBTTL	I/O Group Control

;++
;   The VIS1802 has two I/O groups - group 0 for the VIS chipset, and group 1
; for everything else.  You can change the I/O group by writing to the FLAG
; register, but unfortunately there's no way to read back the current group
; selection.  That's a huge problem for interrupts, because we need to select
; an I/O group to service an interrupt, but then we have no way to restore the
; original setting when we leave the ISR!
;
;   The only solution is to have the background code remember, in a byte of
; RAM, the current I/O group selection.  Then when the ISR exits, it can
; restore the I/O group based on what's saved in RAM.  It's ugly, but it will
; work.  
;
;   So, any time the backgroud code needs to change the I/O group, it must do
; so by calling either the SELIO0 or SELIO1 routines here.  They will remember
; the current selection, and then the ISR can restore that.
;
;   One more note - we don't need to worry about disabling interrupts here,
; IF we're careful to update CURGRP before we actually change the FLAGS. In
; that case if an interrupt occurs during the process, the worst that could
; happen is that the FLAGS get changed an instruction or two early.  If we
; updated FLAGS first and then CURGRP after and an interrupt occurred between
; those two steps, then the FLAGS would get changed back without us knowing!
;--
SELIO0:	LDI FL.IO0\ LSKP	; select I/O group 0
SELIO1:	LDI FL.IO1		; select I/O group 1
	PHI AUX\ PUSHR(T1)	; save the group selection and then T1
	GHI AUX\ STR SP\ SEX SP	; put the group selection on the stack
	RLDI(T1,CURGRP)		; store the current selection here
	LDN SP\ STR T1		; and save the current I/O group
	OUT FLAGS\ DEC SP	; also select that group
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done

	.SBTTL	Interrupt Service Routine
	PAGE	;; for alignment!!!!
;++
;   Branch here to return from the current interrupt service routine.  Restore
; the current I/O group first (see the code at SELIO0/1 for that story), then
; pop T1, DF, D and lastly (X,P) off the stack.  Re-enable interrupts and we're
; done!
;
;   Note that, unlike SAV, the RET instruction DOES increment X!
;--
ISRRET:	RLDI(T1,CURGRP)		; point to the current I/O group
	SEX T1\ OUT FLAGS	; restore that selection
	SEX SP\ IRX		; ...
	LDXA\ PHI T1		; restore T1
	LDXA\ PLO T1		; ...
	LDXA\ SHL		; restore DF
	LDXA			; restore D
	RET			; and return from the interrupt
				; leaving R1 pointing at the ISR!

;++
;   Here's the interrupt service routine.  When we get here we can assume that
; P=1 and X=2 (the SP).  We need to save T (which contains the old X,P), and
; then D, DF and finally T1.  After that, figure out what caused the interrupt
; and dispatch to some code to handle it.  Note that it's a common 1802 coding
; technique to use M(SP) as a temporary, so we must decrement SP before saving
; anything on the stack to protect any temporary data that the background may
; have there.  
;
;   BTW, the 1804/5/6 has a DSAV instruction which would be nice here, but
; there's no corresponding DRET!  Why, RCA?  We'll just do it the hard way.
;--
ISR:	DEC SP\ SAV		; save T (the old X,P) on the stack first
	DEC SP\ STXD		; then save D on the stack next
	SHRC\   STXD		; and save DF
	GLO T1\ STXD		; and lastly, save T1
	GHI T1\ STXD		; ...

; Decode the interrupt source, then branch to ISRRET when done ...
	BN_SLUIRQ ISR1		; skip if it's not the SLU inrerrupting
	LBR	SLUISR		; go service SLU interrupts
; Next, check for keyboard interrupts ...
ISR1:	BN_KEYIRQ ISR2		; skip if it's not a keyboard interrupt
	LBR	KEYISR		; go service keyboard interrupts
;   Always check for video interrupts last.  That's because video interrupts
; are caused by the VISIRQ flip flop, which is reset as soon as the VIDISR is
; called the first time. BUT, we don't have a way to test the VISIRQ F-F
; directly; B_DISPLAY tests the PREDISPLAY output from the VIS, which remains
; active for the entire blanking interval.  That means if another interrupt,
; say PS/2, comes in after the VISIRQ but while PREDISPLAY is still active, 
; we'll get stuck on the B_DISPLAY!
;
;   Note that B_DISPLAY is true while the display is active, and we get an
; interrupt when the display is NOT active, so it's B_DISPLAY to branch around
; the call to VIDISR!
ISR2:	B_DISPLAY ISR3		; skip if display active
	LBR	VISISR		; go service display interrupts
ISR3:

;   We get here if we can't identify the interrupt source.  That's probably 
; BAD, because if we simply dismiss the interrupt now it will likely just
; interrupt again immediately, leaving us in an endless loop.  But there's
; nothing else we can do, so just dismiss the interrupt and hope for the best!
	LBR	ISRRET

	.SBTTL	Display Interrupt Service

;++
;   This routine is called (via an LBR, not an actual subroutine CALL!) by the
; main interrupt service routine when it detects that the VIS chipset is
; requesting an interrupt.  This interrupt is generated by the VIS PREDISPLAY
; output, which is asserted during the vertical blanking (aka retrace) interval
; of every frame.
;
;   Oddly enough, we don't need to do anything with the VIS chips here.  They
; can pretty much take care of themselves and will keep the display refreshed
; without any help from the software.  We simply use this as a convenient clock
; interrupt of 60Hz (unless you're using PAL, so 50Hz there) to time things
; like the bell and the blinking cursor.
;--
VISISR:	SEX INTPC\ OUT FLAGS	; select I/O group 0
	.BYTE	FL.IO0		; ...

;   The frame counter counts up from zero to HERTZ-1 and then resets.  That
; would give us a convenient once-a-second timer tick, say for keeping track
; of the time of day, but it's currently unused.  This code also takes care
; of blinking the cursor at a 1Hz rate, so whenever the frame counter exactly
; equals HERTZ/2 we toggle the cursor reverse video status.
	RLDI(T1,FRAME)\ LDN T1	; get the current frame counter
	ADI 1\ STR T1		; and update it
	SMI HERTZ/2\ LBZ VISIS1	; toggle the cursor if it's exactly HERTZ/2
	LDN T1\ SMI HERTZ	; else see if we've overflowed 1 second
	LBL	VISIS2		; nothing more if it hasn't overflowed yet
	LDI 0\ STR T1		; reset the frame counter back to zero
				; and fall into the toggle cursor code

;   Here to blink the character under the cursor.  Blinking is easily done
; by toggling the MSB (PMD7) of the cursor character, which flips between
; normal and reverse video.  CURSADR contains the actual address, in the
; frame buffer, of the cursor, but loading CURSADR into T1 is a bit tricky
; since we only have one register, T1, to work with!
VISIS1:	RLDI(T1,CURSOFF)\ SEX SP; point to CURSOFF first
	LDA T1\ LBNZ VISIS2	; skip this if the cursor is hidden
	LDA T1\ STR SP		; get the high order cusor address
	LDN T1\ PLO T1		; then get the low order address
	LDN SP\ PHI T1		; and finally the high
	LDN	T1		; get the character under the cursor
	XRI	CURSBIT		; toggle the magic bits
	STR	T1		; and put it back

;   If the bell timer is non-zero, then the CDP1869 tone generator is turned
; on. We decrement TTIMER and when it reaches zero, we turn off the tone.
; This is used to implement the ^G bell function of the VT52...
VISIS2:	RLDI(T1,TTIMER)\ LDN T1	; get the TONECNT
	LBZ	VISIS3		; nothing to do if it's zero
	SMI 1\ STR T1		; otherwise decrement it
	LBNZ	VISIS3		; keep going until it reaches zero
	RLDI(T1,VT.TOFF)	; turn the tone generator off
	SEX T1\ OUT VISTONE	; ...

;   The UPTIME location keeps a 32 bit counter of the VRTC interrupts since
; the system was turned on.  This is used by BASIC to keep track of the time
; of day.  FWIW, a 32 bit counter incremented at 60Hz will take over 800 days
; to overflow!
VISIS3:	RLDI(T1,UPTIME)		; point to the system uptime counter
	LDN T1\ ADI 1\ STR T1	; and increment the LSB
	LBNF VISIS4\ INC T1	; quit if there's no carry 
	LDN T1\ ADCI 0\ STR T1	; ... carry to the next byte
	LBNF VISIS4\ INC T1	; ... and quit if there's no carry 
	LDN T1\ ADCI 0\ STR T1	; do the same thing for byte 3
	LBNF VISIS4\ INC T1	; ...
	LDN T1\ ADCI 0\ STR T1	; and byte four
				; ... don't care about any carry now!

;  The PREDISPLAY flag stays set for a long time (4ms, more or less) but the
; VIS IRQ is edge triggered by the I/O GAL.  To dismiss this interrupt we need
; to do any output (the actual data doesn't matter) to port 2, group 0.
VISIS4:	SEX INTPC\ OUT VISIRQR	; and write anything to port 2
	.BYTE	0		; ...
	LBR	ISRRET		; all done here!

	.SBTTL	Serial Port Interrupt Service

;++
;   This routine is called (via an LBR, not an actual subroutine CALL!) by the
; main interrupt service routine when it detects that the CDP1854 UART is
; requesting an interrupt.  We poll the SLU, figure out what it needs, and then
; branch back to ISRRET to dismiss this interrupt.
;
;   REMEMBER!  This is an ISR, so a) we want to be reasonably fast, and b)
; we have to be careful to save and restore anything we change.  When we get
; here the main ISR has already saved D, DF and T1 (and X and P, of course)
; but anything else we use we have to preserve.
;
;   The exception to that is the I/O group selection in the FLAGS register,
; since there is no easy way to save and restore that.  The code at SELIO0/1
; and ISRRET takes care of it for us, though, so we can change the I/O group
; without fear.
;--
SLUISR:	SEX INTPC\ OUT FLAGS	; DON'T use OUT!
	 .BYTE	 FL.IO1		;  ... select I/O group 1

;   First, read the UART status register and see if the framing error (FE)
; bit is set.  If it is, then set the SERBRK flag and ignore any data in the
; receiver buffer (it's garbage anyway).  Note that we currently ignore the
; parity error and overrun error bits - it's not clear what useful thing we
; could do with these anyway.
	SEX	SP		; ...
	INP SLUSTS\ ANI SL.FE	; framing error?
	LBZ	SLUIS0		; no - check for received data
	RLDI(T1,SERBRK)		; point to the serial break flag
	LDI $FF\ STR T1		; and set it to indicate a break received
	INP	SLUBUF		; read and discard the received data
	LBR	SLUIS1		; and go check the transmitter

;   See if the UART receiver needs service.  If there's a character waiting,
; then add it to the RXBUF.  If the RXBUF is full, then we just discard the
; character; there's not much else that we can do.  Note that simply reading
; the status register will have cleared the interrupt request, so if the buffer
; is full there's no need to actually read the data register.
SLUIS0:	INP SLUSTS\ ANI SL.DA	; is the DA bit set?
	LBZ	SLUIS1		; no - go check the transmitter
	RLDI(T1,RXPUTP)\ LDN T1	; load the RXBUF PUT pointer
	ADI 1\ ANI RXBUFSZ-1	; try incrementing it (w/wrap around!)
	STR	SP		; save that temporarily
	DEC T1\ LDA T1\ XOR	; would it equal the GET pointer?
	LBZ	SLUIS4		; yes - buffer full; discard character
	LDN SP\ STR T1		; no - update the PUT pointer
	ADI LOW(RXBUF)\ PLO T1	; and index into the buffer
	LDI HIGH(RXBUF)\ PHI T1	; ...
	INP SLUBUF\ STR T1	; read and store the character

;   Increment the count of characters in the RX buffer and, if the buffer is
; 2/3rds or more full, clear the CTS bit.  Hopefully the other end will stop
; sending until we catch up!
	RLDI(T1,RXBUFC)\ LDN T1	; increment count of characters in buffer
	ADI 1\ LSNZ\ LDI $FF	;  ... but don't allow overflow 255 -> 0!
	STR T1\ SMI RXSTOP	; is the buffer almost full?
	LBL	SLUIS1		; no - go check the transmitter
	INC T1\ LDN T1		; get the flow control mode
	LBZ	SLUIS1		; branch if no flow control
	XRI $FF\ LBZ SLUI00	; branch if XON/XOFF flow control

; Here for CTS flow control ...
	SEX INTPC\ OUT FLAGS	; clear CTS
	 .BYTE	 FL.CCTS	;  ...
	SEX SP\ LBR SLUIS1	; and now check the transmitter next

; Here for XON/XOFF flow control ...
SLUI00:	INC T1\ LDN T1		; read the TXONOF flag
	LSNZ\ LDI $FF		; set to $FF unless already non-zero
	STR T1\ LBR SLUIS1	; now go check the transmitter

;   Here if the SLU has received a character but the RXBUF is full.  We still
; have to read the receiver buffer to clear the DA flag, otherwise the IRQ
; will never go away!
SLUIS4:	SEX SP\ INP SLUBUF	; read the character and discard it

;   And now see if the UART transmitter needs service.  If the holding register
; is empty and there are more characters in the TXBUF, then transmit the next
; one.  If the buffer is empty, then there's no need to do anything - just
; reading the status will clear the CDP1854 interrupt request, and we can let
; the transmitter go idle.
SLUIS1:	INP SLUSTS\ ANI SL.THRE	; is the THRE bit set?
	LBZ	SLUIS3		; no - go check something else
	RLDI(T1,FLOCTL)\ LDN T1	; see if flow control is enabled
	XRI $FF\ LBNZ SLUI10	; no - go check the transmit buffer
	INC T1\ LDN T1		; read TXONOF - do we need to send XON or XOFF?
	XRI $FF\ LBZ SLUIS6	; branch if we need to send XOFF
	LDN T1\ XRI $01		; do we need to send XON ?
	LBNZ	SLUI10		; no - go transmit something from TXBUF

; Here if we need to transmit XON ...
	SEX INTPC\ OUT SLUBUF	; transmit XON
	 .BYTE	 CH.XON		;  ...
	LDI 0\ STR T1		; clear TXONOF
	LBR	SLUIS3		; and we're done for now

; Here if we need to transmit XOFF ...
SLUIS6:	SEX INTPC\ OUT SLUBUF	; here to transmit XOFF
	 .BYTE	 CH.XOF		;  ...
	LDI $FE\ STR T1		; set TXONOF to $FE to remember XOFF sent
	LBR	SLUIS3		; and we're done for now

; Transmit the next character from the TXBUF ...
SLUI10:	RLDI(T1,TXGETP)\ LDA T1	; load the GET pointer
	SEX T1\ XOR		; does GET == PUT?
	LBZ	SLUIS2		; yes - buffer empty!
	DEC T1\ LDN T1		; no - reload the GET pointer
	ADI 1\ ANI TXBUFSZ-1	; increment it w/wrap around
	STR	T1		; update the GET pointer
	ADI LOW(TXBUF)\ PLO T1	; index into the TX buffer
	LDI HIGH(TXBUF)\ PHI T1	; ...
	OUT	SLUBUF		; transmit the character at M(T1)
	LBR	SLUIS3		; and on to the next thing

;   Here if the TXBUF is empty AND the THRE bit is set, and at this point we
; need to clear the TR bit.  That alone doesn't do much, however the next
; time we have something to transmit then SERPUT will set the TR bit and
; that will cause another THRE interrupt to start the process again.
SLUIS2:	RLDI(T1,SLUFMT)\ LDN T1	; get the current SLU format bits
	STR SP\ SEX SP		; store it on the stack
	OUT SLUCTL\ DEC SP	; and clear TR
				; and fall into SLUIS3

;   Here after we've checked both the receiver and transmitter.  The CDP1854
; has other interrupt conditions (e.g. PSI or CTS), but we don't care about
; any of those AND they're all cleared by reading the status register.
; There's nothing more to do!
SLUIS3:	LBR	ISRRET		; dismiss the interrupt and we're done

	.SBTTL	Keyboard Interrupt Service

;++
;   This routine is called (via an LBR from the main ISR) when a PS/2 keyboard
; interrupt is detected.  We read the key code from the keyboard, check for
; a few "special" keys, and if it's not one of those then we just add this key
; to the KEYBUF circular buffer.
;
;   Why do we even need this at all?  After all, the PS/2 APU has its own 
; buffer for keys already, and nothing would get lost.  This is here because
; we need to look ahead and check for "special" keys like MENU or BREAK, and
; tell the background code immediately when we find one.
;--
KEYISR:	SEX INTPC\ OUT FLAGS	; DON'T use OUTI here!
	.BYTE	FL.IO1		; select I/O group 1

;   Read the key from the keyboard buffer (which will clear the interrupt
; request at the same time) and check for one of the "special" keys or codes,
; BREAK, MENU or VERSION.  If it's one of those then set the appropriate flag
; but otherwise drop the key code. 
	RLDI(T1,KEYVER)		; just in case we get lucky :)
	SEX SP\ INP KEYDATA	; read the keyboard port, key on the stack
	ANI KEYVERS\ XRI KEYVERS; is this the firmware version?
	LBZ	KEYIS4		; yes - go save that
	LDI KEYBREAK\ SD	; is it the BREAK key?
	LBZ	KEYIS3		; yes 
	LDI KEYMENU\ SD		; and check for the MENU key
	LBZ	KEYIS2		; ...

; It's a normal key - just add it to the buffer (assuming there's room) ...
	DEC	SP		; protect the keycode on the stack
	RLDI(T1,KEYPUTP)\ LDN T1; load the KEYBUF PUT pointer
	ADI 1\ ANI KEYBUFSZ-1	; try incrementing it (w/wrap around!)
	STR	SP		; save that temporarily
	DEC T1\ LDA T1\ XOR	; would it equal the GET pointer?
	LBZ	KEYIS1		; yes - buffer full; discard keystroke
	LDA SP\ STR T1		; no - update the PUT pointer
	ADI LOW(KEYBUF)\ PLO T1	; and index into the buffer
	LDI HIGH(KEYBUF)\ PHI T1; ...
	LDN SP\ STR T1\ SKP	; store the original key code and return
KEYIS1:	INC SP\ LBR ISRRET	; fix the stack and return

;   Here if we receive a version number from the APU firmware, or if either
; the BREAK or MENU key is pressed ...
KEYIS2:	INC	T1		; point to KEYMNU
KEYIS3:	INC	T1		; point to KEYBRK
KEYIS4:	LDN SP\ STR T1		; update the flag in RAM
	LBR	ISRRET		; and we're done here

	.SBTTL	Serial Port Buffer Routines

;++
;   This routine will extract and return the next character from the serial
; port receive buffer and return it in D.  If the buffer is empty then it
; returns DF=1.  Uses T1 ...
;
;   Note that we have to disable interrupts while we mess with the buffer
; pointers; otherwise we risk a race condition if a serial port interrupt
; occurs while we're here.
;--
SERGET:	PUSHR(T1)		; save a temporary register
	IOFF			; no interrupts for now
	RLDI(T1,RXGETP)\ LDA T1	; load the GET pointer
	SEX  T1\ XOR		; does GET == PUT?
	LBZ	SERGE1		; yes - the buffer is empty!
	DEC T1\ LDN T1		; no - reload the GET pointer
	ADI 1\ ANI RXBUFSZ-1	; and increment it w/wrap around
	STR	T1		; update the GET pointer
	ADI LOW(RXBUF)\ PLO T1	; build a pointer into the buffer
	LDI HIGH(RXBUF)\ PHI T1	; ...
	LDN T1\ SEX SP\ PUSHD	; load the character and save it

; If the buffer is now empty or nearly so, turn on CTS or send XON!
	RLDI(T1,RXBUFC)\ LDN T1	; get the RX buffer count
	LSZ\ SMI 1		; decrement it but don't allow wrap around!
	STR T1\ SMI RXSTART	; is the buffer almost empty?
	LBGE	SERGE0		; no - just keep going
	RLDI(T1,FLOCTL)\ LDN T1	; see if flow control is enabled
	LBZ	SERGE0		; not enabled
	XRI $FF\ LBZ SERG00	; branch if XON/XOFF flow control

; Here for CTS flow control ...
	OUTI(FLAGS, FL.SCTS)	; yes - enable CTS again
	LBR	SERGE0		; and we're done

; Here for XON/XOFF flow control ...
SERG00:	INC T1\ LDN T1		; read TXONOFF next
	XRI $FE\ LBNZ SERGE0	; have we previously sent XOFF?
	LDI 1\ STR T1		; yes - send an XON ASAP
	CALL(SELIO1)		; select I/O group 1
	OUTI(SLUCTL, SL.TR)	; and always set the TR bit

; Return whatever we found ...
SERGE0:	SEX SP\ POPD		; restore the character read
	CDF\ LSKP		; and return DF=0
SERGE1:	SDF			; buffer empty - return DF=1
	ION			; allow interrupts again
	PHI AUX\ IRX\ POPRL(T1)	; restore T1
	GHI AUX\ RETURN		; and we're done

;++
;  This is just like SERGET, except that it will wait for input if none is
; available now.  There's no timeout on the wait!
;--
SERGEW:	CALL(SERGET)		; try to read something
	LBDF	SERGEW		; and loop until there's something there
	RETURN			; ...


;++
;   This routine will add a character to the serial port tranmitter buffer.
; If the buffer is currently full, it will return with DF=1 and the original
; character still in D.  Uses T1.
;
;   This is slightly more complicated than it might seem because if the buffer
; is empty and the transmitter is idle, then simply adding this character to
; the buffer won't do anything.  We'll just sit here waiting for a THRE
; interrupt which will never happen.  Fortunately the CDP1854 provides a simple
; way around this - setting the TR bit in the control register will cause an
; interrupt if THRE is also set.  If THRE isn't set and the transmitter is
; already busy, then setting TR does nothing so it's safe to simply always set
; TR, regardless.
;--
SERPUT:	PHI AUX\ PUSHR(T1)	; save a temporary register
	IOFF			; interrupts OFF while we mess with the buffer
	RLDI(T1,TXPUTP)\ LDN T1	; load the current PUT pointer first
	ADI 1\ ANI TXBUFSZ-1	; increment it w/wrap around
	STR SP\ DEC T1		; now get the current GET pointer
	LDA T1\ XOR		; would GET == PUT after increment?
	LBZ	SERPU1		; yes - the buffer is full now!
	LDN SP\ STR T1		; no - update the PUT pointer
	ADI LOW(TXBUF)\ PLO T1	; and index into the buffer
	LDI HIGH(TXBUF)\ PHI T1	; ...
	GHI AUX\ STR T1\ DEC SP	; store the original character in the buffer
	CALL(SELIO1)		; select I/O group 1
	OUTI(SLUCTL, SL.TR)	; and always set the TR bit
	SEX SP\ POPD		; restore the original character
	CDF\ LBR SERPU2		; and return DF=0
; Here if the TX buffer is full!
SERPU1:	SDF			; return the original character and DF=1
SERPU2:	ION			; interrupts on again
	IRX\ POPRL(T1)		; restore T1
	GHI AUX\ RETURN		; and we're done

;++
;   And this routine is just like SERPUT, except that it will wait for space
; to be available if the buffer is currently full.
;--
SERPUW:	CALL(SERPUT)		; try to buffer this character
	LBDF	SERPUW		; keep waiting until space is available
	RETURN			; ...

	.SBTTL	Serial Port Break Routines

;++
;   Test the serial port break flag and return DF=1 (and also clear the flag)
; if it's set. 
;--
ISSBRK:	PUSHR(T1)		; save a temporary
	RLDI(T1,SERBRK)\ LDN T1	; get the flag setting
	LBZ	ISSBR1		; branch if it's not set
	LDI 0\ STR T1		; clear the flag
	SDF\ LSKP		; and return DF=1
ISSBR1:	CDF			; return DF=0
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done

;++
;   Transmit a break on the serial port by setting the FORCE BREAK bit in the
; CDP1854 control register.  This will force the UART's TXD output low to
; transmit a space condition for as long as the force break bit is set.
; To be detected by the other end we have to remain in this condition for at
; least as long as one character time.  A shorter time may not work, but longer
; does no harm (except to slow things down).
;
;   The way you time this with most UARTs is to set the force break bit and
; then transmit some arbitrary data byte.  The byte never actually gets sent
; (because TXD is held low) but the shift register timing still works and we
; can simply wait for that to finish.  Unfortunately, this DOESN'T WORK with
; the CDP1854!  The 1854 freezes the transmitter entirely while the force
; break bit is set, and nothing will happen with the transmitter status as
; long as it is.
;
;   So we're stuck with timing the interval manually, and we have to be sure
; that it's longer than the time it would take to transmit one byte at the
; slowest baud rate we support.  Worse, once we clear the force break bit,
; the CDP1854 needs us to transmit a byte, which will be turned into garbage
; by the other end since there will be no start bit, to finally and completely
; clear the break condition.  Seems like RCA could have done better!
;--
TXSBRK:	PUSHR(T1)		; save a temporary register
; Set the force break bit in the CDP1854 ...
	RLDI(T1,SLUFMT)\ LDN T1	; get the current SLU character format
	ANI ~SL.IE\ ORI SL.BRK	; clear IE and set break
	STR	SP		; save for out
	OUT SLUCTL\ DEC SP	; write the UART control register
; Now delay for 100ms ...
	LDI 50\ PLO T1		; 50 iterations ...
TXSBR2:	DLY2MS			; ... of a 2ms delay
	DEC T1\ GLO T1		; ...
	LBNZ	TXSBR2		; ...
; Reset the CDP1854 control register and clear the force break bit ...
	LDN	SP		; it's still on the stack!
	ANI ~SL.BRK\ ORI SL.IE	; ...
	STR	SP		; ...
	OUT SLUCTL\ DEC SP	; ...
;   The CDP1854 needs us to transmit a byte, which will be turned into garbage
; by the other end since there will be no start bit, to finally and completely
; clear the break condition.  Note that we don't bother to check THRE here -
; we've just delayed for 100ms; I'm pretty sure it's done now!
	LDI 0\ STR SP		; transmit a null byte
	OUT SLUBUF\ DEC SP	;  ...
; Finish by flushing the serial buffers ...
TXSBR4:	CALL(SERCLR)		; flush the TX and RX buffers
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done

	.SBTTL	Initialize Serial Port

;++
;   This routine will clear the serial port buffers, both transmit and receive.
; Any characters currently in the buffers are lost!  If flow control is enabled,
; then we will re-enable the other end (either by asserting CTS or sending XON)
; immediately after we're done.
;--
SERCLR:	PUSHR(T1)		; save a temporary
	RLDI(T1,RXPUTP)		; point to the buffer pointers
	IOFF			; no interrupts while we mess with the pointers
	LDI 0\ SEX T1		; ...
	STXD\ STXD		; clear RXPUTP and RXGETP
	STXD\ STXD		; clear TXPUTP and TXGETP
	RLDI(T1,TXONOF)		; clear the XON/XOFF flow control state
	LDI 0\ STXD		; ...
	DEC T1\ STXD		; and clear RXBUFC too
	ION			; interrupts are safe again
	RLDI(T1,FLOCTL)\ LDN T1	; see if flow control is enabled
	LBZ	SERCL9		; not enabled
	XRI $FF\ LBZ SERCL1	; branch if XON/XOFF flow control
; Here for CTS flow control ...
	OUTI(FLAGS, FL.SCTS)	; yes - enable CTS again
	LBR	SERCL9		; and we're done
;   Here for XON/XOFF flow control ...  Note that this ALWAYS sends an XON, 
; even if no XOFF has recently been sent.  This should be harmless!
SERCL1:	INC T1\ LDI 1\ STR T1	; send an XON ASAP
	OUTI(SLUCTL, SL.TR)	; and always set the TR bit
SERCL9:	SEX SP\ IRX\ POPRL(T1)	; restore T1
	RETURN			; and we're done here


;++
;   This routine will initialize the CDP1854 serial port and CDP1963 baud rate
; generator according to the DIP switch settings.  Remember that SW1..3 control
; the baud rate, SW4 ON selects 7E1 format and SW4 OFF selects 8N1  (sorry,
; those are the only options!).  The number of stop bits is set automatically
; based on the baud rate - 1200 and up gets one stop bit, and less than 1200
; gets two stop bits.  And lastly, SW5 ON selectss XON/XOFF flow control and
; SW5 OFF selects CTS flow control.  There is no option to disable flow
; control entirely, but you can always select CTS control and then just leave
; the CTS signal disconnected.
;--

SERINI:	CALL(SELIO1)		; select I/O group 1

; First initialize the CDP1863 baud rate generator ...
	INP DIPSW\ ANI $07	; get the baud rate selection
	ADI LOW(BAUDS)\ PLO T1	; index into the baud rate table
	LDI 0\ ADCI HIGH(BAUDS)	; ...
	PHI T1\ LDN T1\ STR SP	; get the baud rate divisor
	OUT SLUBAUD\ DEC SP	; program the CDP1863

; Select the number of stop bits based on the baud rate ...
	LDI 0\ PLO T1		; build the UART control word here
	INP DIPSW\ ANI $04	; is the baud rate 1200 or up?
	LBNZ	SERIN1		; one stop bit if it is
	LDI SL.SBS\ PLO T1	; nope - select two stop bits

; Now figure out the parity and word length for the CDP1854 ...
SERIN1:	INP DIPSW\ ANI $08	; SW4 selects 7E1 or 8N1 format
	LBZ	SERIN2		; SW4=0 -> 8N1
	LDI SL.7E1\ LSKP	; select even parity and 7 data bits
SERIN2:	LDI SL.8N1\ STR SP	; select no parity and 8 data bits
	GLO T1\ OR		; and OR those with the stop bit select
	ORI SL.IE\ STR SP	; always set interrupt enable
	OUT SLUCTL\ DEC SP	; write the UART control register
	RLDI(T1,SLUFMT)		; and save the UART settings here
	LDN SP\ STR T1		;  ... for later

; Select XON/XOFF or CTS flow control according to SW5 ...
	RLDI(T1,FLOCTL)		; point at the flow control flag
	INP DIPSW\ ANI $10	; and read SW5
	LBNZ	SERIN3		; branch if XON/XOFF is selected
	LDI $01\ LSKP		; select CTS flow control
SERIN3:	LDI $FF\ STR T1		; select XON/XOFF and update FLOCTL
	OUTI(FLAGS, FL.SCTS)	; be sure CTS is asserted regardless
	RETURN			; and we're done here


; Table of baud rate divisors for CDP1863 ...
					;SW3 SW2 SW1	BAUD
BAUDS:	.BYTE	BAUD_DIVISOR( 110)	; 0   0   0	 110
	.BYTE	BAUD_DIVISOR( 150)	; 0   0   1	 150
	.BYTE	BAUD_DIVISOR( 300)	; 0   1   0	 300
	.BYTE	BAUD_DIVISOR( 600)	; 0   1   1	 600
	.BYTE	BAUD_DIVISOR(1200)	; 1   0   0	1200
	.BYTE	BAUD_DIVISOR(2400)	; 1   0   1	2400
	.BYTE	BAUD_DIVISOR(4800)	; 1   1   0	4800
	.BYTE	BAUD_DIVISOR(9600)	; 1   1   1	9600

	.SBTTL	Keyboard Buffer Routines

;++
;   This routine will get the next key code from the keyboard buffer, AND then
; it will handle expanding the special function keys into their corresponding
; VT52 escape codes.  The escape codes are generated by first returning an
; <ESC> and then returning the one or two byte sequence in the KEYESC table
; corresponding to the extended key code.  In order to remember where we are
; in this sequence, we keep a one or two byte "push back" buffer in KEYPBK
; to store the bytes that we'll return next.
;
;   And of course if the next key code is a normal ASCII character, then we
; just return it immediately, with no funny business.
;--
GETKEY:	PUSHR(T1)\ PUSHR(T2)	; save two working registers
	RLDI(T1,KEYPBK)		; anything is waiting in the push back buffer?
	LDN T1\ LBNZ GETKE1	; yes - go send that!
; Try to read the next keycode from the interrupt buffer ...
	CALL(KEYGET)		; try to get a keycode
	LBDF	GETKE3		; nothing there - just return now
	PHI AUX\ ANI $80	; is this an extended key code?
	LBZ	GETKE2		; no - regular ASCII character
	DEC T1\ LDA T1		; get the keypad application mode flag
	LBNZ	GETKE0		; branch if application mode
	GHI AUX\ ANI $F0	; was the key code a keypad key
	XRI $A0\ LBZ GETKE4	; yes - handle numeric keypad codes
; Here if we need to send an escape sequence ...
GETKE0:	GHI AUX\ ANI $7F	; get the key code back
	SMI KEYELEN\ LBGE GETKE3; just ignore it if out of range
	GHI AUX\ ANI $7F\ SHL	; each table entry is 2 bytes
	ADI LOW(KEYESC)\ PLO T2	; index into the KEYESC table
	LDI 0\ ADCI HIGH(KEYESC); ...
	PHI T2\ LDA T2\ STR T1	; copy two bytes to KEYPBK
	LBZ	GETKE3		; if the table entry is zero, ignore it
	INC T1\ LDA T2\ STR T1	; ...
	LDI CH.ESC\ PHI AUX	; and return <ESC> for the first byte
	LBR	GETKE2		; ... all done for now
; Here for a keypad key in numeric keypad mode ...
GETKE4:	GHI AUX\ ANI $0F	; get the keycode
	ADI LOW(KEYNUM)\ PLO T2	; index into the numeric keypad table
	LDI 0\ ADCI HIGH(KEYNUM); ...
	PHI T2\ LDN T2\ PHI AUX	; get the ASCII code from the KEYNUM table
	LBR	GETKE2		; and return that
; Here to return the next byte from the push back buffer ...
GETKE1:	PHI	AUX		; save the byte we want to send
	INC T1\ LDN T1		; and pop a byte off the push back buffer
	DEC T1\ STR T1		; ...
	INC T1\ LDI 0\ STR T1	; ...
; Success - we have an ASCII code of some kind ...
GETKE2:	CDF\ LSKP		; return DF=0
; Here if no keys are available ...
GETKE3:	SDF			; return DF=1
	IRX\ POPR(T2)\ POPRL(T1); restore saved registers
	GHI AUX\ RETURN		; and we're done


;++
;   This routine will extract and return the next character from the keyboard
; buffer and return it in D.  If the buffer is empty then it returns DF=1.
; Uses T1 ...
;
;   Note that we have to disable interrupts while we mess with the buffer
; pointers; otherwise we risk a race condition if a keyboard port interrupt
; occurs while we're here.
;--
KEYGET:	PUSHR(T1)		; save a temporary register
	IOFF			; no interrupts for now
	RLDI(T1,KEYGETP)\ LDA T1; load the GET pointer
	SEX  T1\ XOR		; does GET == PUT?
	LBZ	KEYGE1		; yes - the buffer is empty!
	DEC T1\ LDN T1		; no - reload the GET pointer
	ADI 1\ ANI KEYBUFSZ-1	; and increment it w/wrap around
	STR	T1		; update the GET pointer
	ADI LOW(KEYBUF)\ PLO T1	; build a pointer into the buffer
	LDI HIGH(KEYBUF)\ PHI T1; ...
	LDN	T1		; load the character
	CDF\ LSKP		; and return with DF=0
KEYGE1:	SDF			; buffer empty - return DF=1
	ION			; allow interrupts again
	PHI AUX\ IRX\ POPRL(T1)	; restore T1
	GHI AUX\ RETURN		; and we're done


;++
;   Test the keyboard break flag and return DF=1 (and also clear the flag)
; if it's set. 
;--
ISKBRK:	PUSHR(T1)		; save a temporary
	RLDI(T1,KEYBRK)\ LDN T1	; get the flag setting
ISKBR0:	LBZ	ISKBR1		; branch if it's not set
	LDI 0\ STR T1		; clear the flag
	SDF\ LSKP		; and return DF=1
ISKBR1:	CDF			; return DF=0
	IRX\ POPRL(T1)		; restore T1
	RETURN			; and we're done

;++
;   Test the keyboard menu flag and return DF=1 (and also clear the flag) if
; it's set.
;--
ISKMNU:	PUSHR(T1)		; save a temporary
	RLDI(T1,KEYMNU)\ LDN T1	; get the flag setting
	LBR	ISKBR0		; and the rest is the same as ISKBRK

	.SBTTL	Keyboard Escape Code Table

;++
;   This table is indexed by the "extended" key code, 0x80..0xFF, which are
; sent by the PS/2 keyboard APU for function keys, keypad keys, arrow keys,
; editing keys, etc.  Each entry contains two bytes which are the escape code
; corresponding to that key (the <ESC> itself being sent first automatically).
; For keys which have only a single character escape sequence (e.g. the arrow
; keys) then the second byte should be zero.
;
;   Note that for the keypad keys these are the APPLICATION keys.  The numeric
; keys are in a separate table.
;--
KEYESC:	.BYTE	  0, 0		; 0x80 BREAK (handled by ISR!)
	.BYTE	"/", "a"	; 0x81 F1  KEY
	.BYTE	"/", "b"	; 0x82 F2  KEY
	.BYTE	"/", "c"	; 0x83 F3  KEY
	.BYTE	"/", "d"	; 0x84 F4  KEY
	.BYTE	"/", "e"	; 0x85 F5  KEY
	.BYTE	"/", "f"	; 0x86 F6  KEY
	.BYTE	"/", "g"	; 0x87 F7  KEY
	.BYTE	"/", "h"	; 0x88 F8  KEY
	.BYTE	"/", "i"	; 0x89 F9  KEY
	.BYTE	"/", "j"	; 0x8A F10 KEY
	.BYTE	"/", "k"	; 0x8B F11 KEY
	.BYTE	"/", "l"	; 0x8C F12 KEY
	.BYTE	  0, 0		; 0x8D SCROLL LOCK (unused)
	.BYTE	  0, 0		; 0x8E NUM LOCK (unused)
	.BYTE	  0, 0		; 0x8F (unused)
	.BYTE	"A", 0		; 0x90 UP ARROW
	.BYTE	"B", 0		; 0x91 DOWN ARROW
	.BYTE	"C", 0		; 0x92 RIGHT ARROW
	.BYTE	"D", 0		; 0x93 LEFT ARROW
	.BYTE	  0, 0		; 0x94 (unused)
	.BYTE	  0, 0		; 0x95 MENU (handled by ISR)
	.BYTE	"/", "n"	; 0x96 END
	.BYTE	"/", "o"	; 0x97 HOME
	.BYTE	"/", "p"	; 0x98 INSERT
	.BYTE	"/", "q"	; 0x99 PAGE DOWN
	.BYTE	"/", "r"	; 0x9A PAGE UP
	.BYTE	"/", "s"	; 0x9B DELETE
	.BYTE	  0, 0		; 0x9C (unused)
	.BYTE	  0, 0		; 0x9D (unused)
	.BYTE	  0, 0		; 0x9E (unused)
	.BYTE	  0, 0		; 0x9F (unused)
	.BYTE	"?", "p"	; 0xA0 KEYPAD 0
	.BYTE	"?", "q"	; 0xA1 KEYPAD 1
	.BYTE	"?", "r"	; 0xA2 KEYPAD 2
	.BYTE	"?", "s"	; 0xA3 KEYPAD 3
	.BYTE	"?", "t"	; 0xA4 KEYPAD 4
	.BYTE	"?", "u"	; 0xA5 KEYPAD 5
	.BYTE	"?", "v"	; 0xA6 KEYPAD 6
	.BYTE	"?", "w"	; 0xA7 KEYPAD 7
	.BYTE	"?", "x"	; 0xA8 KEYPAD 8
	.BYTE	"?", "y"	; 0xA9 KEYPAD 9
	.BYTE	"?", "z"	; 0xAA KEYPAD .
	.BYTE	  0, 0		; 0xAB KEYPAD + (unused)
	.BYTE	"P", 0		; 0xAC KEYPAD / (VT52 F1 BLUE KEY)
	.BYTE	"Q", 0		; 0xAD KEYPAD * (VT52 F2 RED KEY)
	.BYTE	"R", 0		; 0xAE KEYPAD - (VT52 F3 GRAY KEY)
	.BYTE	"?", "M"	; 0xAF KEYPAD ENTER
KEYELEN	.EQU	($-KEYESC)/2

;++
;   This table gives the translation for extended key codes in the range
; 0xA0..0xAF (i.e. the numeric keypad) when keypad application mode is NOT
; enabled!   Note that each one of these entries is only ONE byte!
;--
KEYNUM:	.BYTE	"0"		; 0xA0 KEYPAD 0
	.BYTE	"1"		; 0xA1 KEYPAD 1
	.BYTE	"2"		; 0xA2 KEYPAD 2
	.BYTE	"3"		; 0xA3 KEYPAD 3
	.BYTE	"4"		; 0xA4 KEYPAD 4
	.BYTE	"5"		; 0xA5 KEYPAD 5
	.BYTE	"6"		; 0xA6 KEYPAD 6
	.BYTE	"7"		; 0xA7 KEYPAD 7
	.BYTE	"8"		; 0xA8 KEYPAD 8
	.BYTE	"9"		; 0xA9 KEYPAD 9
	.BYTE	"."		; 0xAA KEYPAD .
	.BYTE	"+"		; 0xAB KEYPAD + 
	.BYTE	"/"		; 0xAC KEYPAD / 
	.BYTE	"*"		; 0xAD KEYPAD *
	.BYTE	"-"		; 0xAE KEYPAD -
	.BYTE	CH.CRT		; 0xAF KEYPAD ENTER

	.SBTTL	XMODEM Protocol

;++
;   These routines will transmit an arbitrary block of RAM, using the XMODEM
; protocol up to the host over the serial port.  And they'll also download an
; arbitrary block of RAM from the host using XMODEM in a similar way.  The
; basic plan for uploading RAM is -
;
;   1) Call XOPENW, which will wait for the host to send us a NAK, indicating
;   that it is ready to receive data.
;
;   2) Call XWRITE to transmit a block of RAM.  Note that XMODEM data blocks
;   are always 128 bytes, however you can call XWRITE with any arbitrary sized
;   chunk of RAM and XWRITE will handle reblocking it.  Also note that you may
;   call XWRITE more than once, for contiguous or discontiguous blocks of RAM,
;   however remember that the addresses and byte counts are NOT transmitted.
;   Only the raw data is saved, so if you want to later download the same file
;   you are responsible for getting everything back in the right spot.
;
;   3) When you're done, call XCLOSEW.  This will transmit any partial XMODEM
;   block remaining and then send an EOT to the host, telling it that we're
;   done.  Note that XMODEM blocks are always 128 bytes, and by tradition any
;   partial block at the end is padded with SUB ($1A, Control-Z) characters.
;
; Downloading a file to RAM goes basically the same way -
;
;   1) Call XOPENR. This will send a NAK to the host, after a short delay,
;   and it should start sending us data.
;
;   2) Call XREAD one or more times to read data from the host.  Once again
;   you can read any arbitrary number of bytes with XREAD, and it will handle
;   reblocking into 180 byte chunks but remember that you're responsible for
;   getting everything back in the right RAM locations.
;
;   3) Call XCLOSER to wait for the host to send EOT, indicating the end of
;   file.  Note that any additional data the host may send while XCLOSER is
;   waiting for EOT will be ignored.
;
;   The XMODEM code uses 132 bytes of RAM for a temporary buffer.  THIS PART 
; OF RAM CANNOT BE UPLOADED OR DOWNLOADED!
;
; ATTRIBUTION
;   Most of this code has been adapted from the original XMODEM written for the
; Elf2K and PicoElf EPROMs by Mike Riley.  That code was copyright 2020 by
; Michael H Riley.  You have permission to use, modify, copy, and distribute
; this software so long as this copyright notice is retained.  This software
; may not be used in commercial applications without express written permission
; from the author.
;--

	.SBTTL	Upload Data to the Host Using XMODEM

;++
;   This routine will open the XMODEM channel for sending data up to the host
; machine.  After initializing a few variables, it waits for the host to send
; us a NAK indicating that it's ready to receive.   Any characters other than
; NAK are ignored.  
;
;   There is a timeout of approximately 10 seconds on waiting for the host to
; send that NAK.  If we time out without receiving it, we return with DF=1.
;
;   Echo on the console is automatically disabled while XMODEM is active.
;--
XOPENW:	PUSHR(P1)		; save working register
	RLDI(P1,XBLOCK)		; current block number
	LDI 1\ STR P1		; set starting block to 1
	INC P1\ LDI 0\ STR P1	; set byte count to zero
	RLDI(P1,5000)		; 5000 times 2ms delay -> 10 second timeout
XOPNW1:	CALL(SERGET)		; read a byte from the serial port w/o waiting
	LBDF	XOPNW2		; branch if nothing was read
	SMI	CH.NAK		; did we get a NAK?
	LBZ	XOPNW3		;  ... yes - success!
XOPNW2:	DLY2MS			; delay for 2ms, more or less
	DBNZ(P1,XOPNW1)		; and count down the 10s timeout
	SDF\ LSKP		; return DF=1 for timeout
XOPNW3:	CDF			; return DF=0 for success
	IRX\ POPRL(P1)		; restore P1
	RETURN			; and we're done


;++
;   This routine will transmit a block of RAM to the host via XMODEM.  P3
; should contain a pointer to the start of the data, and P2 should contain
; a count of the bytes to send.  XMODEM naturally sends data in 128 byte
; byte blocks and this routine will automatically handle reblocking the
; original data, regardless of its actual length.  
;
;   If the data length is not a multiple of 128, meaning that the last XMODEM
; record is partially filled, then data data remains in the XBUFFER.  If this
; routine is called a second time then that additional data is simply appended
; to what's already in the XBUFFER.  If not, then you must call XCLOSEW to
; pad out and transmit the final record.
;
;   Note that at the moment there isn't any error detection or correction
; here.  About the only thing that could go wrong is that we time out waiting
; for the host to respond, or that we get in an infinite retransmit loop.
;
;CALL:
;	P2 -> count of bytes to send
;	P3 -> address of the first byte
;	CALL(XWRITE)
;--
XWRITE:	PUSHR(T2)\ PUSHR(T3)	; save working registers
	RLDI(T3,XCOUNT)\ LDN T3	; get byte count
	STR SP\ PLO T2		; store for add
	LDI LOW(XBUFFER)\ ADD	; index into XBUFFER
	PLO	T3		;  ...
	LDI HIGH(XBUFFER)\ ADCI	0; ...
	PHI	T3		;  ...
XWRIT1:	LDA P3\ STR T3\ INC T3	; copy byte from caller to XBUFFER
	INC T2\ GLO T2		; count bytes in XBUFFER
	ANI $80\ LBZ XWRIT2	; keep going if it's not 128 yet
	CALL(XSEND)		; send current buffer
	LDI 0\ PLO T2		; zero buffer byte count
	RLDI(T3,XBUFFER)	; and start at the beginning of XBUFFER
XWRIT2:	DBNZ(P2,XWRIT1)		; decrement caller's count until it's zero
	RLDI(T3,XCOUNT)		; update XCOUNT with the
	GLO T2\ STR T3		;  ... remaining partial buffer count
	IRX\ POPR(T3)		; restore registers
	POPRL(T2)\ RETURN	; and we're done here


;++
;   This routine is used by XWRITE to send one data block to the host.  It
; fills in the block number and checksum, transmits all 132 bytes, and then
; wait for the ACK or NAK to come back.  If the host NAKs us, then we'll
; send the same record over again.
;--
XSEND:	PUSHR(P1)\ PUSHR(P2)	; save some temporary registers
XSEND0:	LDI CH.SOH\ PHI P2	; send SOH and init checksum in P2.1
	CALL(SERPUW)		; ...
	RLDI(P1,XBLOCK)		; get current block number
	LDN P1\ STR SP		;  ... on the stack
	GHI P2\ ADD\ PHI P2	; add block number to checksum
	LDN SP\ CALL(SERPUW)	; transmit block number
	LDN P1\ SDI 255\ STR SP	; next we send 255 - block nujmber
	GHI P2\ ADD\ PHI P2	; add that to the checksum
	LDN SP\ CALL(SERPUW)	; and transmit it
	LDI 128\ PLO P2		; P2.0 counts number of bytes to send
	RLDI(P1,XBUFFER)	; and P1 points at the data block
XSEND1:	LDA P1\ STR SP		; get next byte to send
	GHI P2\ ADD\ PHI P2	; add it to the checksum
	LDN SP\ CALL(SERPUW)	; then transmit it
	DEC P2\ GLO P2		; decrement byte count
	LBNZ	XSEND1		; keep going until we've sent all 128
	GHI P2\ CALL(SERPUW)	; transmit the checksum byte next
XSEND2:	CALL(SERGEW)\ STR SP	; read the response from the host
	SMI CH.NAK\ LBZ XSEND0	; resend the block if it was a NAK
	RLDI(P1,XBLOCK)\ LDN P1	; otherwise increment the block number
	ADI 1\ STR P1		; ...
	INC P1\ LDI 0\ STR P1	; and zero the buffer byte count
	IRX\ POPR(P2)\ POPRL(P1); restore P1 and P2
	RETURN			; all done


;++
;   This routine will "close" the XMODEM channel.  If there's any partial data
; remaining in the XBUFFER then we'll pad that out with SUB characters to fill
; the full 128 bytes, and transmit it.  After the last block has been sent we
; transmit an EOT, telling the host that we're done, and then wait for an ACK
; to come back.  After that, console echo is re-enabled and we return.
;
;   Note that there's no timeout on waiting for the final ACK from the host.
; There probably should be!
;--
XCLOSEW:PUSHR(P1)\ PUSHR(P2)	; save working registers
	RLDI(P1,XCOUNT)\ LDN P1	; get count remaining in last block
	LBZ	XCLSW2		; if it's zero then we're done
	PLO P2\ STR SP		; ...
	LDI LOW(XBUFFER)\ ADD	; index into XBUFFER again
	PLO P1			; ...
	LDI HIGH(XBUFFER)	; ...
	ADCI 0\ PHI P1		; ...
XCLSW1:	LDI CH.SUB\  STR P1	; fill the rest of the buffer with ^Z
	INC P1\ INC P2		; increment pointer and count
	GLO P2\ ANI $80		; have we done 128 bytes?
	LBZ	XCLSW1		; loop until we have
	CALL(XSEND)		; and then transmit the final block
XCLSW2:	LDI CH.EOT\ CALL(SERPUW); transmit EOT next
	CALL(SERGEW)		; and read the host's response
	SMI	CH.ACK		; did he send an ACK?
	LBNZ	XCLSW2		; keep resending EOT until we get one
	IRX\ POPR(P2)\ POPRL(P1); restore P1 and P2
	RETURN			; and return

	.SBTTL	Download Data from the Host Using XMODEM

;++
;   This routine will open the XMODEM channel for receiving data from the host
; machine.  After initializing all XMODEM related variables, it will delay for
; approximately 10 seconds.  This delay is to give the operator a chance to
; start up the XMODEM transmitter on his end.  When sending, the host will
; wait for us to make the first move by sending a NAK upstream, and after that
; the host will respond by sending the first data block.
;--
XOPENR:	PUSHR(P1)		; save consumed registers
	RLDI(P1,XINIT)		; ...
	LDI CH.NAK\ STR P1	; initially we send a NAK
	INC P1\ LDI   1\ STR P1	; set initial block number to 1
	INC P1\ LDI 128\ STR P1	; set initial count as 128 empty bytes
	INC P1\ LDI   0\ STR P1	; set XDONE = 0
	RLDI(P1,5000)		; 5000 * 2ms -> 10 second delay
XOPNR1:	DLY2MS			; delay for 2 milliseconds
	DBNZ(P1,XOPNR1)		; do that 5000 times
	IRX\ POPRL(P1)		; restore P1
	RETURN			; and return


;++
;   This routine will receive a block of RAM transmitted from the host using
; XMODEM.  P3 should contain a pointer to the start of the RAM block, and P2
; contains a count of the bytes to be written.  XMODEM sends data in 128 byte
; blocks, and this routine will pack up multiple blocks to fill the caller's
; buffer as necessary.  If the size passed in P2 is not a multiple of 128 then
; the last partial block will be left in the XBUFFER.  It can be discarded,
; or it will be used if this routine is called a second time.
;
;   If the host has less data than we want to read - i.e. if it sends an EOT
; before our count is exhausted, then we return with DF=1 and the remainder
; of the buffer will be left unchanged.
;
;CALL:
;	P2 -> count of bytes to receive
;	P3 -> address of the first byte
;	CALL(XREAD)
;--
XREAD:	PUSHR(T2)\ PUSHR(T3)	; save temporary registers
	RLDI(T2,XCOUNT)\ LDN T2	; get current buffer byte count
	PLO T3\ STR SP		; ...
	LDI LOW(XBUFFER)\ ADD	; index into the buffer
	PLO	T2		; ...
	LDI	HIGH(XBUFFER)	; ...
	ADCI 0\ PHI T2		; ...
XREAD0:	GLO T3\ ANI $80		; have we read 128 bytes?
	LBZ	XREAD1		; jump if yes
	CALL(XRECV)		; otherwise receive another block
	LBDF	XREAD2		; quit if EOT received
	LDI 0\ PLO T3		; and reset the buffer to empty
	RLDI(T2,XBUFFER)	; ...
XREAD1:	LDA T2\ STR P3		; copy byte from XBUFFER to caller
	INC P3\ INC T3		; increment pointer and count
	DBNZ(P2,XREAD0)		; keep going until caller's count is zero
	RLDI(T2,XCOUNT)		; update count of bytes remaining in buffer
	GLO T3\ STR T2		; ...
	CDF			; return DF=0 for success
XREAD2:	IRX\ POPR(T3)		; restore registers
	POPRL(T2)\ RETURN	; and we're done here


;++
;   THis routine is used by XREAD to receive one block, verify the block
; number and checksum, and handle the handshake with the host.  If either the
; block or checksum is wrong, the we'll send a NAK back to the host and wait
; for this block to be retransmitted.
;
;   If we receive an EOT, signifying the end of transmission, from the host
; instead of another data block, then we return DF=1.
;--
XRECV:	PUSHR(P1)\ PUSHR(P2)	; save some working room
XRECV0:	CALL(XRDBLK)		; read 128 bytes (more or less)
	LBDF	XRECV3		; jump if EOT received
	RLDI(P1,XHDR2)		; get block number received
	LDN P1\ STR SP		;  ... and store for comparison
	RLDI(P1,XBLOCK)\ LDN P1	; get the block number we expect
	SM\ LBNZ XRECV2		; jump if they aren't the same
	RLDI(P1,XBUFFER)	; point to first data byte
	LDI   0\ PHI P2		; accumulate checksum in P2.1
	LDI 128\ PLO P2		; and count bytes in P2.0
XRECV1:	LDA P1\ STR SP		; add byte from buffer to checksum
	GHI P2\ ADD\ PHI P2	; ...
	DEC P2\ GLO P2		; have we done 128 bytes?
	LBNZ	XRECV1		;  ... keep going until we have
	LDN P1\ STR SP		; get checksum we received
	GHI P2\ SM		; does it match what we computed?
	LBNZ	XRECV2		; request a retransmit if not
	RLDI(P1,XINIT)		; send an ACK for this block
	LDI CH.ACK\ STR P1	; ...
	INC P1\ LDN P1		; increment the block number
	ADI 1\ STR P1		; ...
	INC P1\ LDI 0\ STR P1	; and zero the byte count
	CDF			; return DF=0 for success
XRECV9:	IRX\ POPR(P2)\ POPRL(P1); restore P1 and P2
	RETURN			; and return

; Here if there was some error and we need a re-transmit of the last block ...
XRECV2:	RLDI(P1,XINIT)		; send a NAK
	LDI CH.NAK\ STR P1	; ...
	LBR	XRECV0		; and go try again

; Here if the host sends an EOT (end of transmission!) ...
XRECV3:	RLDI(P1,XDONE)		; set the XDONE flag
	LDI $FF\ STR P1		; ...
	LBR	XRECV9		; and return DF=1 for EOT


;++
;   This routine will "close" the XMODEM download channel.  If we haven't
; already received an EOT from the host, then we'll contine reading (and just
; discarding) data blocks until the host does send us an EOT.  After that
; we turn the console echo back on and we're done.
;--
XCLOSER:PUSHR(P1)		; save a temporary register
	RLDI(P1,XDONE)\ LDN P1	; have we already received an EOT?
	LBNZ	XCLSR2		; yes - don't look for another!
XCLSR1:	CALL(XRDBLK)		; look for EOT but the host may send more data
	LBNF	XCLSR1		; just ignore any extra data until EOT
XCLSR2:	IRX\ POPRL(P1)		; restore P1
	RETURN			; and we're done


;++
;   This routine will read 132 bytes from the host and store them in the XMODEM
; buffer.  This includes the SOH, the block number (two bytes), 128 bytes of
; data, and the checksum.  It doesn't verify any of this; it simply stuffs it
; into the buffer for later review.
;
;   Note that this is the only code that needs to be fast in order to keep up
; with the host and not drop bytes.  Everything else has built in delays while
; waiting for an ACK, NAK or something else, but here the host is sending those
; 132 bytes as fast as it can.  
;
;   One last thing - it's possible that we'll receive an EOT instead of an SOH.
; This indicates that the host is done sending data.  If that happens we'll
; automatically ACK the EOT immediately and then return with DF=1.
;--
XRDBLK:	PUSHR(P1)		; save several working registers
	PUSHR(T1)\ PUSHR(T3)	; ...
	LDI 132\ PLO T1		; expect to receive 132 bytes
	LDI 1\ PHI T1		; and remember this is the first byte
	RLDI(P1,XINIT)\ LDN P1	; get our response (either ACK or NAK)
	PHI T3			;  ... save it temporarily
	RLDI(P1,XHDR1)		; point to input buffer
	GHI T3\ CALL(SERPUW)	; and transmit our ACK/NAK
XRDBK1:	CALL(SERGEW)		; read next byte from host
	STR P1\ INC P1		; store it in the buffer
	GHI T1\ SHR\ PHI T1	; get the first time thru flag
	LBNF	XRDBK2		; jump if not first character
	GHI	AUX		; first character - get it back
	SMI	CH.EOT		; was it an EOT?
	LBNZ	XRDBK2		; jump if not
	LDI CH.ACK\ CALL(SERPUW); send an ACK for the EOT
	SDF\ LBR XRDBK3		; return DF=1 and we're done
XRDBK2:	DEC T1\ GLO T1		; decrement received byte count
	LBNZ	XRDBK1		; and keep going until we've done 132
	CDF			; return DF=0 and we're done
XRDBK3:	IRX\ POPR(T3)		; restore all those registers
	POPR(T1)\ POPRL(P1)	; ...
	RETURN			; and we're done

	.SBTTL	Standard Call and Return Technique

;++
;   These two routines implement the "standard call and return tecnhique", more
; or less right out of the RCA manual.  All assume the following register usage
;
;	R2 (SP)     - stack pointer (1802 stacks grow DOWNWARD!)
;	R3 (PC)     - program counter
;	R4 (CALLPC) - always points to the SCALL routine
;	R5 (RETPC)  - always points to the SRETURN routine
;	R6 (A)	    - subroutine argument list pointer
;
;   A subroutine call goes like this -
;
;	SEP	CALLPC
;	.WORD	<address of subroutine>
;	<any arguments, if desired>
;
; The SCALL routine first pushes the current argument pointer, register R6/A,
; onto the stack.  It then copies the R3/PC, which is the caller's PC to the
; A register.  Next it uses A to fetch the two bytes following the SEP CALLPC,
; which are the address of the subroutine, and load them into the PC register.
; Finally it switches the P register back to R3/PC and the called subroutine
; is running.  The subroutine may use the A register to fetch additional inline
; arguments if desired, being sure to increment A as it does.  
;
;  When the subroutine wants to return it executes a
;
;	SEP	RETPC
;
; This starts the SRETURN routine running, which copies the current A register
; back to the PC, and then pops the previous A value from the stack.  Lastly
; it switches the P register back to R3 and we're back at the caller's location.
;--
	PAGE ; for alignment

; Standard subroutine call ... 18 bytes ...
	SEP	PC		; start the subroutine running
SCALL:	PHI	AUX		; save the D register
	SEX	SP		; make sure the stack is selected
;   Note that the standard PUSHR macro pushes the low byte first, followed by
; the high byte.  This is consistent with the way the 1804/5/6 RSXD instruction
; works, and also the 1804/5/6 SCAL.  HOWEVER, it's NOT the way the BASIC 
; STCALL routine works, which pushes low byte first!
	GHI A\ STXD		; and save the A register
	GLO A\ STXD		;  ...
	RCOPY(A,PC)		; then copy the caller's PC to A
	RLDA(PC,A)		; fetch the subroutine address
	GHI	AUX		; restore D
	BR	SCALL-1		; restore CALLPC and start the subroutine

; Standard subroutine return ... 16 bytes ...
	SEP	PC		; return to the original caller
SRETURN:PHI	AUX		; save D temporarily
	SEX	SP		; just in case
	RCOPY(PC,A)		; A contains the return address
	INC	SP		; point to the saved A
; See the comments above about this code vs POPRL() !!
	LDA SP\ PLO A		; restore A
	LDN SP\ PHI A		;  ...
	GHI	AUX		; restore D
	BR	SRETURN-1	; restore RETPC and return to the caller

	.SBTTL	ASCII Character Fonts

FONT:
	.IF (FONTSIZE == 64)
	.include "font64.asm"
	.ENDIF

	.IF (FONTSIZE == 128)
	.include "font128.asm"
	.ENDIF

	.IF (($-FONT) != (FONTSIZE*SCANLINES))
	.ECHO	"**** FONTSIZE WRONG! *****\n"
	.ENDIF

	.SBTTL	EPROM Checksum

	.ORG	CHKSUM-2
	.BLOCK	4

	.END
