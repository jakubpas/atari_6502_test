; WUDSN IDE Atari Rainbow Example - MADS syntax

	org $8000 ;Start of code

begin	nop

pm	equ $a000	;od adresu `PM` bedzie nasz obszar na duchy i pociski
py	equ 200		;pozycja Y naszego duszka (duszek nie porusza się w pionie)

	opt h+
	ldx #0
	lda >pm
	sta $d407	;PMBASE - starszy adres obszaru z duchami
	ldy #2
	sty $d01d	;PMCTL - czy wyswietlic duchy lub pociski, czy oba razem
	dey
	sty 623		;GTICTLS - piorytet kolorów
	dey
	sty $d008	;SIZEP0 - szerokość
	lda #$e
	sta 704		;cien rejestru koloru gracza0
	lda #%00111010
	sta 559		;DMACTLS - dostep do pamieci dla duchow i pociskow wg odpowiednich bitow
	
	lda #120		;pozycja pozioma bedzie wartosc z zegara systemowego
	sta $d000	;HPOSP0 - pozycja pozioma duszka nr 0

animka nop
	ldx $278 ; Joystick position 
	cpx #11
	beq left ;if diverso da 0 salta al right
	cpx #7
	beq right ;if diverso da 0 salta a left
	cpx #0
	bne animka

left nop 	
;	dec $d000
	lda #50		;pozycja pozioma bedzie wartosc z zegara systemowego
	sta $d000	;HPOSP0 - pozycja pozioma duszka nr 0
	 jmp animka
	
right nop	
;	inc $d000
	lda #190		;pozycja pozioma bedzie wartosc z zegara systemowego
	sta $d000	;HPOSP0 - pozycja pozioma duszka nr 0

	jmp animka

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