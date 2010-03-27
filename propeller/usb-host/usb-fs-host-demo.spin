
CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 6_000_000

OBJ
  hc : "usb-fs-host"
  term : "Parallax Serial Terminal"
  
VAR

PUB main : value
  term.Start(115200)
  hc.Start
      
  repeat
    waitcnt(cnt + clkfreq/2)
        
    value := hc.PacketTXRX

    term.str(string(term#NL))
    term.hex(value, 8)
    term.str(string(" "))
    term.bin(value, 32)
    