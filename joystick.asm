spritex = $80
spritey = $60

	org $0801
sprite1 dta b($0E, $08, $0A, $00, $9E, $20, $28, $32, $30, $36, $34, $29, $00, $00, $00)

	org $3000
sprite2 dta b($0E, $08, $0A, $00, $9E, $20, $28, $32, $30, $36, $34, $29, $00, $00, $00)


;=$3000 ;location dove inizia il puntatore per gli sprite
;incbin "mariocolor.bin"


;=$0810 ;location dove inizia il puntatore per il progra mma

	org $0810
begin	lda #$1 ;A=1
	sta $d025 ;POKE53285,1 (multicolor 01) A=1 =colore bianco)
	lda #$C ;C=12
	sta $d026 ;POKE53286,c (multicolor 11) C=12 =colore grigio)

	lda #147 ;cancella lo schermo
	jsr $ffd2 ;chiamata alla routina per stampare cancella schermo

	lda #$07 ;A=7
	sta $d020 ;53280,7 (7 = giallo colora il bordo di giallo)
	lda #$06 ;A=6
	sta $d021 ;53281,6 (6 = blue colora lo sfondo di blue)

	LDA $D015 ;A=peek(53269) (registro abilitazioni sprite)
	ORA #$01 ;sprite 0 e 1 (valore 3)
	sta $d015 ;poke53269,peek(53269) ORA 3 (abilita lo sprite 0 e 1)

	lda $D01c ;A=peek(53276) (registro abilitazioni sprite multicolore)
	ora #$01 ;sprite 0 e 2(valore 3)
	sta $d01c ;Poke53276,peek(53276) ORA 3 (abilita in Multicolore lo sprite 0 e 1)

	;"MARIOCOLOR.bin" SPRITE 0 (192x64 = 12288 ($3000)
	lda #$c0 ;a=192($c0= 192 dec.) –punta all indirizzo $3000

	sta $07f8 ;poke2040,192 ($07f8 = 2040 dec) ottiene i dati per lo sprite 0 dalla location 192

	lda #$2 ;2 red (BERETTO)
	sta $d027 ;POKE53287,2 - colore sprire 0


	lda spritex
	sta $d000 ;poke 53248,spritex
	lda spritey
	sta $d001 ;poke 53249,spritey

goto lda#$ff
	cmp $d012
	bne goto


left lda $dc00 ;A=peek(56320)
	and #$4
	bne right ;if diverso da 0 salta al right
	dec $d000
	jmp goto


right lda$dc00 ;A=peek(56320)
	and #$8
	bne left ;if diverso da 0 salta a left
	inc $d000
	jmp goto

	run begin 