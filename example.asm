    org $8000 ;Start of code

begin:
    RAMTOP = 106    ; Returns last page number of available ram;
    pm = $a000      ; Player/Missile start address
    py = 200        ; Player0 vertical position
    p1yi = 10       ; Player1 vertical position
    HPOSP0 = $d000  ; HPOSP0 - horizontal position of player0 (shadow registry)
    HSPOS1 = $d001  ; HPOSP0 - horizontal position of player0 (shadow registry)
    px = $6000      ; Stores value of player0 horizontal position
    DEL = $6001     ; Stores value of move delay
    SCORE = $6002
    LIVES = $6003
    PINIT = $6500
    P1Y = pm + $500 + p1yi

    lda #3
    sta LIVES

    lda #<dl        ; Set up display list
    sta $230
    lda #>dl
    sta $231

    lda #0          ; Get black color
    sta $2C8        ; Set border color
;    sta $2C5        ; Set text color
    sta $2C6        ; Set background color
	lda >pm         ; get high byte of pm
	sta $d407	    ; PMBASE - msb of Player/Missile address
	ldy #2          ; Show both player and missiles
	sty $d01d       ; PMCTL Player/Missile control
	lda #$e         ; Player0 color (white)
	sta $2C0	    ; Shadow registry of player0 color
	lda #123        ; Player1 color (white)
    sta $2C1	    ; Shadow registry of player1 color
	lda #%00111010  ; Player/Missile configuration bits settings
	sta 559		    ; DMACTLS - registry of Player/Missile settings
	lda #120        ; Player0 horizontal positon (44 - 205)
	sta HPOSP0      ; Set Player0 horizontal positon
	sta px

    jsr initialize_player1

loop:
    jsr delay

    jsr move_player1_down

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
		jsr decrease_lives
	jmp loop
right:
	inc px
	lda px
	sta HPOSP0
	jsr increase_score
	jmp loop

get_random:
    lda $D20A ; 44 - 205
    CMP #204
    BCS more_or_same
    CMP #44
    BCC less_or_same
    rts
    more_or_same:
    lda #204
    rts
    less_or_same:
    lda #44
    rts

delay:
	dec DEL
	ldx DEL
	cpx #0
	bne delay
	rts

move_player1_down:
    ldx p1yi + 15   ; Player1 height
    LOOP1:
    lda $a500,x
    sta $a500,x + 1
    dex
	bne LOOP1
	inc p1yi

    lda #255
	cmp p1yi
	beq initialize_player1
    rts

initialize_player1:
    jsr get_random   ; get random position to acumulator
    sta HSPOS1       ; Set Player1 horizontal position
    lda #10
    sta p1yi ;
    ldx #0 ; Player1 height
    LOOP2:
    lda PINIT,x
    sta P1Y,x
    inx
	cpx #15
	bne LOOP2
    rts

increase_score:
    sed
    lda SCORE
    adc #$11
    sta SCORE
    cld
    LDX #0
    LDY #0
    ONE:
    LDA SCORE,X
    LSR ;EACH BYTE HOLDS 2 NUMBERS
    LSR ;SHIFT UPPER NIBBLE OVER
    LSR ;AND DO IT
    LSR ;FIRST.
    ORA #16 ; TRANSLATE NUMBER INTO INTERNAL CHARACTER
    STA  text_score + 1,Y ;STORE HIGHER DIGIT OF PAIR ON SCREEN
    INY ; NEXT
    LDA SCORE ,X
    AND #$0F ; NOW DO LOWER NIBBLE
    ORA #16 ; MAKE A CHR
    STA  text_score + 1,Y ;STORE LOWER DIGIT OF PAIR ON SCREEN
    CPX #0 ; DONE BOTH BYTES? (ALL 4 SCORE DIGITS)
    BNE ONE
    RTS

decrease_lives:
    sed
    lda LIVES
    sbc #$11
    sta LIVES
    cld
    LDX #0
    LDY #0
    TWO:
    LDA LIVES,X
    LSR ;EACH BYTE HOLDS 2 NUMBERS
    LSR ;SHIFT UPPER NIBBLE OVER
    LSR ;AND DO IT
    LSR ;FIRST.
    ORA #16 ; TRANSLATE NUMBER INTO INTERNAL CHARACTER
    STA  text_lives,Y ;STORE HIGHER DIGIT OF PAIR ON SCREEN
    INY ; NEXT
    LDA LIVES ,X
    AND #$0F ; NOW DO LOWER NIBBLE
    ORA #16 ; MAKE A CHR
    STA  text_lives,Y ;STORE LOWER DIGIT OF PAIR ON SCREEN
    CPX #0 ; DONE BOTH BYTES? (ALL 4 SCORE DIGITS)
    BNE TWO

    ldx LIVES
    cpx #0
    beq game_over

    RTS

game_over:
    lda #<dl_over        ; Set up display list
    sta $230
    lda #>dl_over
    sta $231
    jmp *


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

	org PINIT
	dta b(%00000000)
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
	dta b(%00000000)

text1       dta d"Lives: "
text_lives  dta d"03"
text2       dta d" Score: "
text_score  dta d"0000"
text_over   dta d"     Game Over      "
dl          dta $70,$46,a(text1),$41,a(dl) ; Display list
dl_over     dta $70,$46,a(text_over),$41,a(dl)

	run begin
