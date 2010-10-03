{{

 Nokia6100 Driver, ver 0.1
──────────────────────────────────────────────────────────────────

This is a simple 4096-color driver for the cheap and common Nokia 6100
LCD panel, using either the Epson S1D15G00 or Philips/NXP PCF8833 controllers.

This code is based on the interface tutorial document by Jim Lynch:
  http://www.sparkfun.com/tutorial/Nokia%206100%20LCD%20Display%20Driver.pdf

I have only been able to test it with the Epson chip so far, but it's designed
to work with either. If it doesn't work for you, please bang on it until it
does and send me patches :)

This module provides a public drawing interface that's (very) roughly a subset
of the Graphics object. This might make it easier to port software that's
written for a TV, but keep in mind that the coordinate system and color format
are different, and only a subset of the drawing commands are supported.

The default coordinate system of this LCD is rather odd, so this module
tries to normalize it to look more like a standard raster display. (0,0) is
at the top-left corner, +X is right, +Y is down.

XXX: Right now I'm using Beau's generic SPI_Asm driver, but this could
     be *significantly* faster using assembly and the video/counter hardware
     to generate a fast outgoing SPI signal, or even by just converting this
     whole module to asm.

     Something for a future version :)

 ┌──────────────────────────────────────────────────────────┐
 │ Copyright (c) 2010 Micah Elizabeth Scott <micah@navi.cx> │               
 │ See end of file for terms of use.                        │
 └──────────────────────────────────────────────────────────┘
}}

CON
  ' init() Mode
  EPSON   = 0
  PHILIPS = 1

  ' Dimensions
  WIDTH = 132
  HEIGHT = 132

  DISPLAY_LEFT   = 0
  DISPLAY_TOP    = 0
  DISPLAY_RIGHT  = WIDTH - 1 
  DISPLAY_BOTTOM = HEIGHT - 1

  ' Colors
  BLACK    = $000
  WHITE    = $FFF
  RED      = $F00
  GREEN    = $0F0
  BLUE     = $00F
  CYAN     = $0FF
  MAGENTA  = $F0F
  YELLOW   = $FF0
  BROWN    = $B22
  ORANGE   = $FA0
  PINK     = $F6A

OBJ
  spi : "SPI_Asm"

VAR
  byte  spi_clk, spi_dat     ' SPI pins
  byte  cmd_don, cmd_doff    ' Display on/off
  long  cmd_a1, cmd_a2       ' Pre-packed addressing commands
  long  packed_color         ' Pre-packed fill color
  word  cur_color, cur_bg    ' Current drawing color

  ' Blending table for current foreground/background colors.
  ' When downsampling a font, each output pixel is created by averaging
  ' four input pixels. So, we need 5 levels of gradation between
  ' our foreground and background. (0 to 4 pixels)
  '
  ' We generate this blending table only when the colors have changed, and only
  ' when we're actually drawing text.
  '
  ' Additionally, we generate a 5x5 table of packed colors for each combination
  ' of two blend levels.

  byte  blend_valid
  word  blend_val[5]
  long  blend_packed[25]


DAT  
'==============================================================================
' Initialization
'==============================================================================

  
PUB start(pin_rst, pin_data, pin_clk, pin_cs, mode) | cmd_dispon
  '' Initialize the LCD.
  '' (Uses one cog for the asm SPI driver)
  ''
  '' 'mode' must be either EPSON or PHILIPS.
  ''
  '' When the LCD is initialized, its contents will be undefined.
  '' Draw some kind of initial contents to the screen, then turn it
  '' on by calling 'on'.

  spi_clk := pin_clk
  spi_dat := pin_data

  spi.start(1, 0)

  ' Initial pin states
  spiByte(0)
  outa[pin_cs]~~
  outa[pin_rst]~~
  dira[pin_cs]~~
  dira[pin_rst]~~
  
  ' Reset pulse
  outa[pin_rst]~
  waitcnt(cnt + clkfreq/50)
  outa[pin_rst]~~
  waitcnt(cnt + clkfreq/50)

  ' Always keep Chip Select active
  outa[pin_cs]~

  if mode
    ' Philips
    cmd_a1 := constant((PCF_PASET << 22) | ($100 << 13) | ($100 << 4) | (PCF_CASET >> 5))
    cmd_a2 := constant((PCF_CASET << 27) | ($100 << 18) | ($100 << 9) | PCF_RAMWR)
    cmd_don := PCF_DISPON
    cmd_doff := PCF_DISPOFF
    spiList(@initPhilips)
  else
    ' Epson
    cmd_a1 := constant((S1D_PASET << 22) | ($100 << 13) | ($100 << 4) | (S1D_CASET >> 5))
    cmd_a2 := constant((S1D_CASET << 27) | ($100 << 18) | ($100 << 9) | S1D_RAMWR)
    cmd_don := S1D_DISON
    cmd_doff := S1D_DISOFF
    spiList(@initEpson)

PUB stop
  '' Stop the SPI driver cog.
  off
  spi.stop

PUB on
  '' Turn on the LCD power
  spiByte(cmd_don)

PUB off
  '' Turn off the LCD power
  spiByte(cmd_doff) 
  

DAT  
'==============================================================================
' Color Utilities
'==============================================================================


PUB color(c)
  '' Set the current drawing color, as a 12-bit packed value.
  cur_color := c
  packed_color := spiPackPair(c, c)
  blend_valid~

PUB background(c)
  '' Set the current background color for 'text' and 'clear'
  cur_bg := c
  blend_valid~

PUB alphaBlend(c1, c2, alpha) | x1, x2, xO
  '' If alpha=$0, returns c1.
  '' If alpha=$F, returns c2.
  '' Values in-between will blend between c1 and c2.

  ' Unpack the colors into a padded 24-bit format (000R0G0B)
  x1 := ((c1 << 8) & $0F0000) | ((c1 << 4) & $0F00) | (c1 & $0F)
  x2 := ((c2 << 8) & $0F0000) | ((c2 << 4) & $0F00) | (c2 & $0F)

  ' Now we can do the blend with fixed-point multiply,
  ' and the results will be in the format 00R0G0B0.
  xO := (x1 * ($10 - alpha)) + (x2 * (alpha + 1))

  ' Re-pack it.
  return ((xO >> 12) & $F00) | ((xO >> 8) & $0F0) | ((xO >> 4) & $00F)

PRI updateBlendTable | i, j
  ' If the blending table is not valid, re-generates it.

  if not blend_valid

    repeat i from 0 to 4
      blend_val[i] := alphaBlend(cur_bg, cur_color, i * $F / 4)

    repeat i from 0 to 4
      repeat j from 0 to 4
        blend_packed[i * 5 + j] := spiPackPair(blend_val[i], blend_val[j])
  
    blend_valid~~

  
DAT  
'==============================================================================
' Drawing Commands
'==============================================================================


PUB box(x, y, w, h)
  '' Draw a filled rectangle
  spiAddress(x, y, x+w-1, y+h-1)
  spiFill(w*h)

PUB plot(x, y)
  '' Draw a single pixel
  spiAddress(x, y, x, y)
  spiFill(1)

PUB clear | packed
  '' Clear the whole screen to the current background color
  spiAddress(DISPLAY_LEFT, DISPLAY_TOP, DISPLAY_RIGHT, DISPLAY_BOTTOM)
  packed := spiPackPair(cur_bg, cur_bg)  
  repeat constant((WIDTH * HEIGHT) >> 1)
    spi.SHIFTOUT(spi_dat, spi_clk, spi#MSBFIRST, 27, packed)

PUB text(x, y, str) | c, fontPtr, row1, row2, a1, a2
  '' Draw a nul-terminated string to (x, y), in the current color,
  '' using the ROM font downsampled by 1/2 to 8x16.

  updateBlendTable
  
  repeat while c := BYTE[str]

    ' Limit our drawing to this character cell
    spiAddress(x, y, x+7, y+15)

    ' The ROM font is 16x32. Each row is one LONG (using every other bit,
    ' depending on whether it's an even or odd character). To downsample
    ' it, for each output pixel we need to count the number of 1 bits
    ' in a 2x2 pixel block. Since we'd like to output two pixels at a time,
    ' this means sampling 4x2 pixels. (8x2 bits)

    fontPtr := constant($8000 - 4) + ((c >> 1) << 7)
    repeat 16
      row1 := LONG[fontPtr += 4]
      row2 := LONG[fontPtr += 4]

      if c & 1
        row1 >>= 1
        row2 >>= 1
      
      repeat 4
        a1 := (row1 & 1) + ((row1 >> 2) & 1) + (row2 & 1) + ((row2 >> 2) & 1)
        a2 := ((row1 >> 4) & 1) + ((row1 >> 6) & 1) + ((row2 >> 4) & 1) + ((row2 >> 6) & 1)
        
        row1 >>= 8
        row2 >>= 8

        spi.SHIFTOUT(spi_dat, spi_clk, spi#MSBFIRST, 27, blend_packed[a1 * 5 + a2])

    str++
    x += 8
        

DAT  
'==============================================================================
' SPI Utilities
'==============================================================================

PRI spiPackPair(p1, p2)
  ' Pack two 12-bit colors into a 27-bit command word.
  ' We draw two pixels at a time because:
  '    a) Two pixels pack evenly into three data bytes
  '    b) Three command bytes (27 SPI bits) is the most we can fit into one SHIFTOUT
  return $04020100 | ((p1 & $FF0) << 14) | ((p1 & $00F) << 13) | ((p2 & $F00) << 1) | (p2 & $0FF)

PRI spiByte(b)
  ' Send a single (9-bit) byte to the controller
  spi.SHIFTOUT(spi_dat, spi_clk, spi#MSBFIRST, 9, b)  

PRI spiList(ptr) | c
  ' Send a list of commands and/or bytes, from a WORD array terminated by EOL.

  repeat while c := WORD[ptr]
    spiByte(c)
    ptr += 2
  
PRI spiAddress(left, top, right, bottom)
  ' Set the box that we're drawing within, then start drawing.
  '
  ' This amounts to PASET, CASET, and RAMWR commands. The PASET and
  ' CASET each take two bytes of arguments, making 7 total bytes.
  ' With 9-bit bytes, this is a total of 63 bits. So we can pack it
  ' all into two SHIFTOUTs, to reduce the number of round-trips between
  ' this and the SPI cog.
  '
  ' XXX: There is a bug in SPI_Asm for MSBFIRST and Bits=32. To work around this,
  '      we use LSBFIRST and reverse the bits ourselves.
  
  spi.SHIFTOUT(spi_dat, spi_clk, spi#MSBFIRST, 31, cmd_a1 | ((DISPLAY_BOTTOM - bottom) << 13) | ((DISPLAY_BOTTOM - top) << 4))
  spi.SHIFTOUT(spi_dat, spi_clk, spi#LSBFIRST, 32, (cmd_a2 | ((DISPLAY_RIGHT - right) << 18) | ((DISPLAY_RIGHT - left) << 9)) >< 32)

PRI spiFill(count)
  ' Output 'count' pixels (rounding up to the nearest 2) of the current fill color

  repeat (count + 1) >> 1
    spi.SHIFTOUT(spi_dat, spi_clk, spi#MSBFIRST, 27, packed_color)
  

DAT  
'==============================================================================
' LCD Model-specific Data
'==============================================================================


CON
  ' Philips PCF8833 Command Codes
  PCF_NOP      = $00
  PCF_SWRESET  = $01
  PCF_BSTROFF  = $02
  PCF_BSTRON   = $03
  PCF_SLEEPIN  = $10
  PCF_SLEEPOUT = $11
  PCF_PTLON    = $12
  PCF_NORON    = $13
  PCF_INVOFF   = $20
  PCF_INVON    = $21
  PCF_DAL0     = $22
  PCF_DAL      = $23
  PCF_SETCON   = $25
  PCF_DISPOFF  = $28
  PCF_DISPON   = $29
  PCF_CASET    = $2A
  PCF_PASET    = $2B
  PCF_RAMWR    = $2C
  PCF_RGBSET   = $2D
  PCF_PTLAR    = $30
  PCF_VSCRDEF  = $33
  PCF_TEOFF    = $34
  PCF_TEON     = $35
  PCF_MADCTL   = $36
  PCF_SEP      = $37
  PCF_IDMOFF   = $38
  PCF_IDMON    = $39
  PCF_COLMOD   = $3A
  PCF_SETVOP   = $B0
  PCF_BRS      = $B4
  PCF_TRS      = $B6
  PCF_DISCTR   = $B9
  PCF_DOR      = $BA
  PCF_TCDFE    = $BD
  PCF_TCVOPE   = $BF
  PCF_EC       = $C0
  PCF_SETMUL   = $C2
  PCF_TCVOPAB  = $C3
  PCF_TCVOPCD  = $C4
  PCF_TCDF     = $C5
  PCF_DF8COLOR = $C6
  PCF_SETBS    = $C7
  PCF_NLI      = $C9

  ' Epson S1D15G00 Command Codes
  S1D_DISON    = $AF
  S1D_DISOFF   = $AE
  S1D_DISNOR   = $A6
  S1D_DISINV   = $A7
  S1D_COMSCN   = $BB
  S1D_DISCTL   = $CA
  S1D_SLPIN    = $95
  S1D_SLPOUT   = $94
  S1D_PASET    = $75
  S1D_CASET    = $15
  S1D_DATCTL   = $BC
  S1D_RGBSET8  = $CE
  S1D_RAMWR    = $5C
  S1D_PTLIN    = $A8
  S1D_PTLOUT   = $A9
  S1D_RMWIN    = $E0
  S1D_RMWOUT   = $EE
  S1D_ASCSET   = $AA
  S1D_SCSTART  = $AB
  S1D_OSCON    = $D1
  S1D_OSCOFF   = $D2
  S1D_PWRCTR   = $20
  S1D_VOLCTR   = $81
  S1D_VOLUP    = $D6
  S1D_VOLDOWN  = $D7
  S1D_TMPGRD   = $82
  S1D_NOP      = $25

  ' Adjust to taste
  EPSON_CONTRAST = $27
  
DAT

initPhilips   word  PCF_SLEEPOUT        ' Out of sleep mode
              word  PCF_INVON           ' Inversion ON (seems to be required?)
              word  PCF_COLMOD, $103    ' Color mode = 12 bpp
              word  PCF_MADCTL, $1C8    ' Mirror X/Y, reverse RGB
              word  PCF_SETCON, $130    ' Set contrast
              word  0

initEpson     word  S1D_DISCTL, $100, $120, $100
              word  S1D_COMSCN, $101
              word  S1D_OSCON
              word  S1D_SLPOUT
              word  S1D_PWRCTR, $10f
              word  S1D_DISINV
              word  S1D_DATCTL, $103, $100, $102
              word  S1D_VOLCTR, $100 | EPSON_CONTRAST, $103  
              word  0

DAT
{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}