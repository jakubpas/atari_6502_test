    org $8000 ;Start of code

begin:
    RAMTOP = 106    ; Returns last page number of available ram;
    pm = $a000      ; Player/Missile start address
    py = 200        ; Player0 vertical position
    p1yi = 10       ; Player1 vertical initial position
    p2y1 = 190      ; Player2 vertical initial position
    HPOSP0 = $d000  ; HPOSP0 - horizontal position of player0 (shadow registry)
    HSPOS1 = $d001  ; HPOSP0 - horizontal position of player1 (shadow registry)
    px = $6000      ; Stores value of player0 horizontal position
    DEL = $6001     ; Stores value of move delay
    score = $6002   ; Score
    LIVES = $6003   ; Lives
    start_lives = 5 ;
    P2 = $6004      ; Current Player2 vertical position
    PINIT = $6500   ;
    P2INIT = $6550
    P1Y = pm + $500 + p1yi
    P2Y = pm + $600 + p2y1

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

    lda #<dl        ; Set up display list
    sta $230
    lda #>dl
    sta $231

start_loop:
    ldx $0284 ; Check fire pressed
    cpx #1
    beq start_loop
    jsr start_game
    jmp start_loop

start_game:
    lda #start_lives
    sta LIVES
    lda #$15
    sta text_lives + 1

    lda #0
    sta score
    lda #$10
    sta text_score
    sta text_score + 1
    sta text_score + 2

    lda #<dl        ; Set up display list
    sta $230
    lda #>dl
    sta $231
    jsr initialize_player1


loop:
    jsr delay
    jsr move_player1_down
    jsr move_player2_up
    jsr detect_collisions

    fire:
    ldx $0284 ; Check fire pressed
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
	jmp loop
    right:
	inc px
	lda px
	sta HPOSP0
	jmp loop

get_random:
    lda $d20a ; 44 - 205
    cmp #204
    bcs more_or_same
    cmp #44
    bcc less_or_same
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

delete_player1:
    ldx p1yi + 15   ; Player1 height
    delete_player1_loop1:
    lda #0
    sta $a500,x + 1
    dex
	bne delete_player1_loop1
	inc p1yi
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
    lda P2
    cmp #0  ; if Player is already on the screen return
    beq cont
    rts
    cont:
    lda px
    sta $D002 ; Horizontal positoin of Player2
    lda #p2y1
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
    lda P2
    cmp #0
    bne LOOP3
    rts
    LOOP3:
    lda pm + $600 ,x
    sta pm + $600 ,x - 1
    inx
    cpx P2 + 6
	bne LOOP3
	dec P2
    rts

increase_score:
    inc score
    lda score
    ldy #$0f
    ldx #$1a
    sec
    a:
    iny
    sbc #100
    bcs a
    b:
    dex
    adc #10
    bmi b
    adc #$0f
    sty text_score
    stx text_score + 1
    sta text_score + 2
    jsr delete_player1
    rts

decrease_lives:
    dec lives
    sed
    lda lives
    cld
    and #$0f ; now do lower nibble
    ora #16 ; make a chr
    ldx #1
    sta  text_lives, x
    jsr delete_player1
    jsr initialize_player1
    ldx lives
    cpx #0
    beq game_over
    rts

detect_collisions:
    lda $D00C  ; Check collistio of plyer zero
    cmp #0
    beq det1
    jsr decrease_lives
    lda #1
    sta $D01E  ; reset collisions
    det1:
    lda $D00E  ; Check collistio of plyer two
    cmp #0
    beq det2
    jsr increase_score
    lda #1
    sta $D01E  ; reset collisions
    det2:
    rts

game_over:
    lda #1
    sta $D01E  ; reset collisions
    jsr delete_player1
    lda #<dl_over        ; Set up display list`
    sta $230
    lda #>dl_over
    sta $231
    jmp start_loop

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
text_lives  dta d"05"
text2       dta d" Score: "
text_score  dta d"000 "
text_over   dta d"     Game Over      "
dl          dta $70,$46,a(text1),$41,a(dl) ; Display list
dl_over     dta $70,$46,a(text_over),$41,a(dl)

	run begin
