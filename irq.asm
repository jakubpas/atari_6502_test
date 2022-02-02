		org $0600
begin   nop
pm	equ $a000	;od adresu `PM` bedzie nasz obszar na duchy i pociski
py	equ 56		;pozycja Y naszego duszka (duszek nie porusza się w pionie)
	opt h+
	ldx #0
petla	lda shape,x		;przepisujemy 25 bajtow z tablicy `SHAPE` pod adres `pm+$400+py`
	sta pm+$400+py,x	;w tej tablicy znajduja sie dane opisujace ksztalt duszka
	inx
	cpx #$19
	bne petla
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
animka	lda #80		;pozycja pozioma bedzie wartosc z zegara systemowego
	sta $d000	;HPOSP0 - pozycja pozioma duszka nr 0
	jmp animka
	
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