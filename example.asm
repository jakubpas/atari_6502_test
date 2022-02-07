    org $8000 ;Start of code

begin:
    RAMTOP = 106    ; Returns last page number of available ram;
    pm = $a000      ; Player/Missile start address
    py = 200        ; Player0 vertical position
    p1yi = 10       ; Player1 vertical position
    p2yi = 25       ; Player2 vertical position
    HPOSP0 = $d000  ; HPOSP0 - horizontal position of player0 (shadow registry)
    HSPOS1 = $d001  ; HPOSP0 - horizontal position of player1 (shadow registry)
    px = $6000      ; Stores value of player0 horizontal position
    DEL = $6001     ; Stores value of move delay
    SCORE = $6002
    LIVES = $6003
    P2 = $6004
    PINIT = $6500
    P2INIT = $6550
    P1Y = pm + $500 + p1yi
    P2Y = pm + $600 + py

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
	lda #123        ; Player1 color (red)
    sta $2C1	    ; Shadow registry of player1 color
    lda #20         ; Player2 color (white)
    sta $2C2	    ; Shadow registry of player1 color
	lda #%00111010  ; Player/Missile configuration bits settings
	sta $22F		; DMACTLS - registry of Player/Missile settings
	lda #%00000011
	sta $D01D       ; enable four players + fifth player or missiles
	lda #120        ; Player0 horizontal positon (44 - 205)
	sta HPOSP0      ; Set Player0 horizontal positon
	sta px

    jsr initialize_player1

loop:
    jsr delay
    jsr move_player1_down
    jsr move_player2_up

fire:
    ldx $0284
    cpx #1
    beq joystick
    jsr initialize_player2
joystick:
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
;	jsr decrease_lives
	jmp loop
right:
	inc px
	lda px
	sta HPOSP0
;	jsr increase_score
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

initialize_player2:
    lda px
    sta $D002 ; Horizontal positoin of Player2
    lda #py
    sta P2
    ldx #0 ; Player1 height
    LOOP4:
    lda P2INIT,x
    sta P2Y,x
    inx
	cpx #6
	bne LOOP4
    rts

move_player2_up:
    ldx P2   ; Player1 height
    LOOP3:
    lda pm + $600 ,x
    sta pm + $600 ,x - 1
    inx
    cpx P2 + 6
	bne LOOP3
	dec P2

;    lda #20
;	cmp p1yi
;	beq initialize_player1
    rts

increase_score:
    sed
    lda score
    adc #$11
    sta score
    cld
    ldx #0
    ldy #0
    one:
    lda score,x
    lsr ;each byte holds 2 numbers
    lsr ;shift upper nibble over
    lsr ;and do it
    lsr ;first.
    ora #16 ; translate number into internal character
    sta  text_score + 1,y ;store higher digit of pair on screen
    iny ; next
    lda score ,x
    and #$0f ; now do lower nibble
    ora #16 ; make a chr
    sta  text_score + 1,y ;store lower digit of pair on screen
    cpx #0 ; done both bytes? (all 4 score digits)
    bne one
    rts

decrease_lives:
    sed
    lda lives
    sbc #$11
    sta lives
    cld
    ldx #0
    ldy #0
    two:
    lda lives,x
    lsr ;each byte holds 2 numbers
    lsr ;shift upper nibble over
    lsr ;and do it
    lsr ;first.
    ora #16 ; translate number into internal character
    sta  text_lives,y ;store higher digit of pair on screen
    iny ; next
    lda lives ,x
    and #$0f ; now do lower nibble
    ora #16 ; make a chr
    sta  text_lives,y ;store lower digit of pair on screen
    cpx #0 ; done both bytes? (all 4 score digits)
    bne two
    ldx lives
    cpx #0
    beq game_over
    rts

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

	org P2INIT
	dta b(%00000000)
    dta b(%00010000)
    dta b(%00010000)
    dta b(%00010000)
    dta b(%00010000)
	dta b(%00000000)

text1       dta d"Lives: "
text_lives  dta d"03"
text2       dta d" Score: "
text_score  dta d"0000"
text_over   dta d"     Game Over      "
dl          dta $70,$46,a(text1),$41,a(dl) ; Display list
dl_over     dta $70,$46,a(text_over),$41,a(dl)

	run begin
