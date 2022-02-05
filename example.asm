	icl "ANTIC.asm"

    org $8000 ;Start of code

begin:
    pm = $a000      ; Player/Missile start address
    py = 0200       ; Vertical position of player0
    HPOSP0 = $d000  ; HPOSP0 - horizontal position of player0 (shadow registry)
    px = $6000      ; Stores value of player0 horizontal position
    DEL = $6001     ; Stores value of move delay

	lda >pm
	sta $d407	    ; PMBASE - msb of Player/Missile address
	ldy #2          ; Show both player and missiles
	sty $d01d       ; PMCTL Player/Missile control
	lda #$e         ; Player0 color (white)
	sta 704	        ; Shadow registry of player0 color
	lda #%00111010  ; Player/Missile configuration bits settings
	sta 559		    ; DMACTLS - registry of Player/Missile settings
	lda #120
	sta HPOSP0
	sta px
loop:
	dec DEL
	ldx DEL
	cpx #0
	bne loop
	
	ldx $278        ; Joystick position
	cpx #11
	beq left 
	cpx #7
	beq right
	cpx #0
	bne loop
left:
	dec px
	lda px
	sta HPOSP0
	jmp loop
right:
	inc px
	lda px
	sta HPOSP0
	jmp loop

	org pm + $400 + py
    dta b(%00010000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00111000)
	dta b(%00111000)
	dta b(%00111000)
	dta b(%00111000)
	dta b(%01111100)
	dta b(%01111100)
	dta b(%01111100)
	dta b(%11111110)
	dta b(%10111010)
	dta b(%10111010)
	run begin
