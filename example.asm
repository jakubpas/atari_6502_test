; WUDSN IDE Atari Rainbow Example - MADS syntax

      org $4000 ;Start of code

start lda #0 ;Disable screen DMA
      sta 559
loop  lda $d40b ;Load VCOUNT
      clc
      adc 20 ;Add counter
      sta $d40a
      sta $d01a ;Change background color
      jmp loop

      run start ;Define run address