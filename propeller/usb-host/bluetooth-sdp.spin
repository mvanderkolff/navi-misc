{{

 bluetooth-sdp  ver 0.1
──────────────────────────────────────────────────────────────────

Service Discovery Protocol support for the Propeller Bluetooth stack.

The latest version of this file should always be at:
http://svn.navi.cx/misc/trunk/propeller/usb-host/bluetooth-sdp.spin

 ┌────────────────────────────────────────────────┐
 │ Copyright (c) 2010 Micah Dowty <micah@navi.cx> │               
 │ See end of file for terms of use.              │
 └────────────────────────────────────────────────┘

}}

CON

  ' Local error codes

  E_END_OF_BUFFER   = -1

  ' Limits maximum PDU size.
  ' (Currently only needs to be as big as our L2CAP MTU)

  BUFFER_SIZE       = 64 - 8

  ' SDP PDU Types

  SDP_ErrorResponse      = $01
  SDP_SearchRequest      = $02
  SDP_SearchResponse     = $03
  SDP_AttrRequest        = $04
  SDP_AttrResponse       = $05
  SDP_SearchAttrRequest  = $06
  SDP_SearchAttrResponse = $07
  
DAT

rxCurrent     word  0
rxEndMarker   word  0
rxEnd         word  0

txBegin       word  0
txCurrent     word  0
txEnd         word  0

rxBuffer      byte  0[BUFFER_SIZE]

DAT
''
''
''==============================================================================
'' Buffer Support
''==============================================================================
''

PUB FillReceiveBuffer(sourceData, length)
  '' Copy incoming data to the internal receive buffer,
  '' and point to the beginning of the buffer.

  bytemove(rxCurrent := @rxBuffer, sourceData, length)
  rxEnd := rxEndMarker := rxCurrent + length

PUB SetTransmitBuffer(ptr, length)
  '' Prepare the transmit buffer

  txBegin := txCurrent := ptr
  txEnd := txCurrent + length

PUB HasReceiveData
  '' Is there a nonzero amount of data in the receive buffer?

  return rxCurrent <> rxEnd
  
PUB TransmitLength
  '' Return the current length of buffered transmit data

  return txCurrent - txBegin

PRI Rx8
  ' Extract 8 bits from the receive buffer. Stops when we hit rxEndMarker

  if rxCurrent => rxEndMarker
    abort E_END_OF_BUFFER

  return BYTE[rxCurrent++]

PRI Rx16
  ' Extract 16 bits, in big-endian byte order, from the receive buffer.

  result := Rx8 << 8
  result |= Rx8

PRI Rx32
  ' Extract 32 bits, in big-endian byte order, from the receive buffer.

  result := Rx16 << 16
  result := Rx16

PRI Tx8(x)
  ' Append 8 bits to the transmit buffer. Stops when we hit txEnd.

  if txCurrent => txEnd
    abort E_END_OF_BUFFER

  BYTE[txCurrent++] := x

PRI Tx16(x)
  ' Append 16 bits to the transmit buffer.

  Tx8(x >> 8)
  Tx8(x)

PRI Tx32(x)
  ' Append 32 bits to the transmit buffer

  Tx16(x >> 16)
  Tx16(x)

DAT
''
''
''==============================================================================
'' SDP Server
''==============================================================================
''

PUB HandlePDU | pduId, transaction
  '' Handle one incoming Protocol Data Unit (PDU) and optionally
  '' write an outgoing PDU to the transmit buffer.

  ' Receive the PDU header: PDU ID, Transaction ID, Length.
  ' Set the end marker to the end of this PDU, so we'll stop
  ' automatically when it's reached.

  rxEndMarker := rxEnd
  pduId := Rx8
  transaction := Rx8
  rxEndMarker := Rx16
  rxEndMarker += rxCurrent
                
  case pduId
  
    SDP_SearchAttrRequest:
      Tx8(SDP_SearchAttrResponse)
      Tx16(transaction)
      Tx16(0)

  rxCurrent := rxEndMarker


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