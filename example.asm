	icl "ANTIC.asm"

    org $8000 ;Start of code

begin:

    RAMTOP = 106    ; Returns last page number of available ram;
    pm = $a000      ; Player/Missile start address
    py = 200        ; Player0 vertical position
    p1y = 10        ; Player1 vertical position
    HPOSP0 = $d000  ; HPOSP0 - horizontal position of player0 (shadow registry)
    HSPOS1 = $d001  ; HPOSP0 - horizontal position of player0 (shadow registry)
    px = $6000      ; Stores value of player0 horizontal position
    DEL = $6001     ; Stores value of move delay

    lda #0
    sta $2C8 ; Set border color
    sta $2C5 ; Set text color
    sta $2C6 ; Set background color

	lda >pm         ; get high byte of pm
	sta $d407	    ; PMBASE - msb of Player/Missile address
	ldy #2          ; Show both player and missiles
	sty $d01d       ; PMCTL Player/Missile control
	lda #$e         ; Player0 color (white)
	sta $2C0	    ; Shadow registry of player0 color

	lda #123        ; Player1 color (white)
    sta $2C1	    ; Shadow registry of player1 color
    lda #120
    sta HSPOS1

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

	org pm + $500 + p1y
	dta b(%10000001)
	dta b(%10000001)
	dta b(%10000001)
	dta b(%10011001)
	dta b(%10111101)
	dta b(%11111111)
	dta b(%11111111)
	dta b(%11111111)
	dta b(%11111111)
	dta b(%10111101)
	dta b(%10011001)
	dta b(%10000001)
	dta b(%10000001)
	dta b(%10000001)

	run begin
