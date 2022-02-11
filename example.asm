	org $8000       ; Start of code on page 8

begin:
	ramtop = 106    ; Returns last page number of available ram;
	pm = $a000      ; Player/Missile start address
	py = 200        ; Player0 vertical position
	p1yi = 10       ; Player1 vertical initial position
	p2y1 = 190      ; Player2 vertical initial position
	hposp0 = $d000  ; HPOSP0 - horizontal position of player0 (hardware shadow registry, save only)
	hspos1 = $d001  ; HPOSP0 - horizontal position of player1 (hardware shadow registry, save only)
	px = $6000      ; Stores value of player0 horizontal position
	del = $6001     ; Stores value of move delay
	score = $6002   ; Score address
	lives = $6003   ; Lives address
	start_lives = 5 ; Number of lives on start
	p2 = $6004      ; Current Player2 vertical position
	pinit = $6500   ; Player1 memory start address
	p2init = $6550  ; Player2 memory start address

	p1y = pm + $500 + p1yi
	p2y = pm + $600 + p2y1

	lda #0          ; Get black color
	sta $2c8        ; Set border color
;    sta $2c5        ; Set text color
	sta $2c6        ; Set background color
	lda >pm         ; get high byte of pm
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

	lda #<dl        ; Set up display list
	sta $230
	lda #>dl
	sta $231

start_loop:
	ldx $0284       ; Check fire pressed
	cpx #1
	beq start_loop
	jsr start_game
	jmp start_loop

start_game:
	lda #start_lives
	sta lives
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

delay:
	dec del
	ldx del
	cpx #0
	bne delay
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

initialize_player1:
	jsr get_random  ; Get random position to acumulator
	sta hspos1      ; Set Player1 horizontal position
	lda #10
	sta p1yi
	ldx #0          ; Player1 height
	loop2:
	lda pinit,x
	sta p1y,x
	inx
	cpx #15
	bne loop2
	rts

initialize_player2:
	lda P2
	cmp #0          ; If Player is already on the screen return
	beq cont
	rts
	cont:
	lda px
	sta $d002       ; Horizontal positoin of Player2
	lda #p2y1
	sta P2
	ldx #0          ; Player1 height
	loop4:
	lda p2init,x
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
	lda pm + $600 ,x
	sta pm + $600 ,x - 1
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

	org pinit
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

	org p2init
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
