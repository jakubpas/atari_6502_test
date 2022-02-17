	org $8000       ; Start of code on page 8
	RAMTOP = 106    ; Returns last page number of available ram;
	RTCLOK = $12    ; Real time clock register`
	VSCROL = $D405  ; Vertical scroll register
	PM = $a000      ; Player/Missile start address
	hposp0 = $d000  ; HPOSP0 - horizontal position of player0 (hardware shadow registry, save only)
    hspos1 = $d001  ; HPOSP0 - horizontal position of player1 (hardware shadow registry, save only)
    hspos2 = $d002  ; HPOSP0 - horizontal position of player2 (hardware shadow registry, save only)
	px = $6000      ; Stores value of player0 horizontal position
	score = $6001   ; Score address
    vscroll = $6002 ; Scroll status
	p1yi = 10       ; Player1 vertical initial position
	p2yi = 190      ; Player2 vertical initial position
	lives = 5       ; Lives number
	p2 = 0          ; Current Player2 vertical position
    fine = 8        ; Fine scrolling scan lines (scan lines per antic mode line)
    window = 24 + 1 ; Size of the scrolled screen window
    fin1 = fine - 1 ; Fine scrolling initial scan line position
    p0y = 200       ; Player0 vertical position
	p1y = PM + $500 + p1yi
	p2y = PM + $600 + p2yi

initialize:
	lda #window
	sta vscroll     ; number of lines in one screen background
    lda #fin1       ; Set initial value
    sta fine        ; of fine scrolling
    sta VSCROL      ; Set fine stroll register
	lda #0          ; Get black color
	sta $2c8        ; Set border color
	sta $2c6        ; Set background color
	lda >PM         ; get high byte of PM
	sta $d407	    ; PMBASE - msb of Player/Missile address
	ldy #2          ; Show both player and missiles
	sty $d01d       ; PMCTL Player/Missile control
	lda #$e         ; Player0 color (white)
	sta $2c0	    ; Shadow registry of player0 color
	lda #123        ; Player1 color (red)
	sta $2c1	    ; Shadow registry of player1 color
	lda #20         ; Player2 color (white)
	sta $2c2	    ; Shadow registry of player1 color
	lda #%00111010  ; Player/Missile configuration bits settings
	sta $22f		; DMACTLS - registry of Player/Missile settings
	lda #%00000011  ; Enable four players + fifth player or missiles
	sta $d01d       ; Save players configuration
	lda #120        ; Player0 horizontal positon (44 - 205)
	sta hposp0      ; Set Player0 horizontal positon to hadrware registry
	sta px          ; Set Player0 horizontal positon
	lda #<dl        ; Set up display list, get LSB of dl
	sta $230
	lda #>dl        ; Ger MSB of dl
	sta $231

start_loop:
	ldx $0284       ; Check fire pressed
	cpx #1
	beq start_loop
	jsr start_game
	jmp start_loop

start_game:
	lda #$15
	sta text_lives + 1
	lda #$10
	sta text_score
	sta text_score + 1
	sta text_score + 2
	jsr initialize_player0
	jsr initialize_player1
loop:
	jsr timing_loop
	jsr move_player1_down
	jsr move_player2_up
	jsr detect_collisions
	jsr scroll_down_background
	fire:
	ldx $0284       ; Check fire pressed
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
	sta hposp0
	jmp loop

get_random:
	lda $d20a       ; 44 - 205
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

move_player1_down:
	ldx p1yi + 15   ; Player1 height
	loop1:
	lda $a500,x
	sta $a500,x + 1
	dex
	bne loop1
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

initialize_player0:
	ldx #0          ; Player1 height
	loop5:
	lda player,x
	sta PM + $400 + p0y,x
	inx
	cpx #15
	bne loop5
	rts

initialize_player1:
	jsr get_random  ; Get random position to acumulator
	sta hspos1      ; Set Player1 horizontal position
	lda #10
	sta p1yi
	ldx #0          ; Player1 height
	loop2:
	lda enemy,x
	sta p1y,x
	inx
	cpx #15
	bne loop2
	rts

initialize_player2:
	lda p2
	cmp #0          ; If Player is already on the screen return
	beq cont
	rts
	cont:
	lda px
	sta hspos2       ; Horizontal positoin of Player2
	lda #p2yi
	sta p2
	ldx #0          ; Player1 height
	loop4:
	lda missile,x
	sta p2y,x
	inx
	cpx #6
	bne loop4
	rts

move_player2_up:
	lda p2
	cmp #0
	bne loop3
	rts
	loop3:
	lda PM + $600 ,x
	sta PM + $600 ,x - 1
	inx
	cpx p2 + 6
	bne loop3
	dec p2
	rts

increase_score:
	inc score       ; Actual increase
	lda score       ; Load score to Acumulator
	ldy #$0f        ; Load ATASCII "0" to Y registry
	ldx #$1a        ; Load ATASCII "1" to Y registry
	sec             ; Set Carry register
	a:
	iny             ; Increase Y register
	sbc #100        ; Subtract 100 with Carry (Binary mode)
	bcs a           ; Loop a on Carry Set
	b:
	dex             ; Decrease x
	adc #10         ; Add 10 to x
	bmi b           ; Branch if negative
	adc #$0f        ; Convert dec to ATASCII
	sty text_score  ; Store digit 1
	stx text_score + 1 ; Store digit 2
	sta text_score + 2 ; Store digit 3
	jsr delete_player1
	rts

decrease_lives:
	dec lives
	sed
	lda lives
	cld
	and #$0f        ; Now do lower nibble
	ora #16         ; Make a chr
	ldx #1
	sta text_lives, x
	jsr delete_player1
	jsr initialize_player1
	ldx lives
	cpx #0
	beq game_over
	rts

detect_collisions:
	lda $d00c       ; Check collisons of Player0
	cmp #0
	beq det1
	jsr decrease_lives
	lda #1
	sta $d01e       ; Reset collisions
	det1:
	lda $d00e       ; Check collistio of plyer two
	cmp #0
	beq det2
	jsr increase_score
	lda #1
	sta $d01e       ; Reset collisions
	det2:
	rts

game_over:
	lda #1
	sta $d01e       ; Reset collisions
	jsr delete_player1
	lda #<dl_over   ; Set up display list`
	sta $230
	lda #>dl_over
	sta $231
	jmp start_loop

scroll_down_background:
    dec fine
    lda fine
    cmp #0
    beq cont2
    sta VSCROL
    rts
    cont2:
    lda #fin1
    sta fine
    sta VSCROL
    dec vscroll
    lda vscroll
    cmp #0
    bne cont_scroll
    jsr reset_background
    cont_scroll:
    lda dl + 2
    sbc #40       ;  1,4,7,10
    sta dl + 2
    lda dl + 3
    sbc #0
    sta dl + 3
    rts

reset_background:
    lda #window
    sta vscroll
    lda #<background2
    sta dl + 2
    lda #>background2
    sta dl + 3
    rts

timing_loop
    ldx #0      ; number of VBLANKs to wait
    astart:
    lda RTCLOK+2    ; check fastest moving RTCLOCK byte
    await:
    cmp RTCLOK+2    ; VBLANK will update this
    beq await       ; delay until VBLANK changes it
    dex             ; delay for a number of VBLANKs
    bpl astart      ; Branch on plus
    rts

player:
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
enemy:
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
missile:
	dta b(%00000000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00010000)
	dta b(%00000000)
background1:
    dta d".   ..           .               ..     "
    dta d"                                        "
    dta d"                     .                  "
    dta d"                                        "
    dta d"    .                            .      "
    dta d"        .                   .           "
    dta d"                                        "
    dta d"                                        "
    dta d"                          .             "
    dta d"   .            .                       "
    dta d"                                        "
    dta d"                                    .   "
    dta d"    .                                   "
    dta d"                    .                   "
    dta d"        .                               "
    dta d"                                        "
    dta d"                                .       "
    dta d"    .                                   "
    dta d"                                        "
    dta d".      .                                "
    dta d"                .                       "
    dta d"                                        "
    dta d"                        .               "
    dta d"                                        "
    dta d"..           .                         ."
background2:
    dta d"1   ..           .               ..     "
    dta d"2                                       "
    dta d"                     .                  "
    dta d"                                        "
    dta d"    .                            .      "
    dta d"        .                   .           "
    dta d"                                        "
    dta d"                                        "
    dta d"                          .             "
    dta d"   .            .                       "
    dta d"                                        "
    dta d"                                    .   "
    dta d"    .                                   "
    dta d"                    .                   "
    dta d"        .                               "
    dta d"                                        "
    dta d"                                .       "
    dta d"    .                                   "
    dta d"                                        "
    dta d".      .                                "
    dta d"                .                       "
    dta d"                                        "
    dta d"                        .               "
    dta d"                                        "
    dta d"...          .                         ."
scor        dta d"          "
text1       dta d"Lives: "
text_lives  dta d"05"
text2       dta d" Score: "
text_score  dta d"000"
            dta d"          "
text_over   dta d"               Game Over                "
dl          dta $70,$62,a(background2-40),$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$22,$02,$42,a(scor),$41,a(dl) ; Display list
dl_over     dta $70,$42,a(text_over),$41,a(dl_over)
