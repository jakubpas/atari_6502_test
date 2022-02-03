; WUDSN IDE Atari Rainbow Example - MADS syntax

	org $8000 ;Start of code

begin
pm = $a000	    ;od adresu `PM` bedzie nasz obszar na duchy i pociski
py = 200		;pozycja Y naszego duszka (duszek nie porusza się w pionie)
HPOSP0 = $d000   ;HPOSP0 - pozycja pozioma duszka nr 0
POS = $6000
DEL = $6001 ; Stores value of move delay

	ldx #0
	lda >pm
	sta $d407	;PMBASE - starszy adres obszaru z duchami
	ldy #2
	sty $d01d	;PMCTL - czy wyswietlic duchy lub pociski, czy oba razem
	lda #$e
	sta 704		;cien rejestru koloru gracza0
	lda #%00111010
	sta 559		;DMACTLS - dostep do pamieci dla duchow i pociskow wg odpowiednich bitow
	lda #120
	sta HPOSP0
	sta POS	
loop
	dec DEL
	ldx DEL
	cpx #0
	bne loop
	
	ldx $278 ; Joystick position 
	cpx #11
	beq left 
	cpx #7
	beq right
	cpx #0
	bne loop
left 	
	dec POS
	lda POS
	sta HPOSP0
	jmp loop
right	
	inc POS
	lda POS
	sta HPOSP0
	jmp loop

finish

	org pm + $400 + py	
shape	dta b(%00010000)
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