; ============================================================
; BREAKOUT - Gra dla Atari 800 XL/XE
; Assembler: MADS 2.x
; Kompilacja: mads breakout.asm -o:breakout.xex
; Sterowanie: Joystick port 1 - lewo/prawo, ogien = start
; ============================================================

    OPT h+              ; Generuj naglowek pliku XEX

; ===== Rejestry sprzetowe =====
HPOSP0  = $D000     ; Pozioma pozycja Gracza 0 (pilka)
HPOSP1  = $D001     ; Pozioma pozycja Gracza 1 (paletka)
SIZEP1  = $D009     ; Rozmiar Gracza 1 (double width)
GRACTL  = $D01D     ; Wlaczenie grafiki P/M
DMACTL  = $D400     ; Sterowanie DMA
PMBASE  = $D407     ; Strona bazowa pamieci P/M

; ===== Rejestry OS (cienie, aktualizowane co VBI) =====
RTCLOK  = $0014     ; Zegar 60 Hz (niski bajt)
STICK0  = $0278     ; Joystick 0 (bit=0 = nacisniety)
STRIG0  = $0284     ; Spust joysticka 0 (0=nacisniety)
SDMCTL  = $022F     ; Cien DMACTL
SDLSTL  = $0230     ; Wskaznik Display List - niski bajt
SDLSTH  = $0231     ; Wskaznik Display List - wysoki bajt
GPRIOR  = $026F     ; Cien rejestru PRIOR
COLPM0S = $02C0     ; Cien koloru Gracza 0
COLPM1S = $02C1     ; Cien koloru Gracza 1
COLPF2S = $02C6     ; Cien koloru tekstu
COLBKS  = $02C8     ; Cien koloru tla
CRSINH  = $02F0     ; Ukryj kursor (!=0 = ukryty)

; ===== Pamiec P/M (4K wyrownana do granicy 4K) =====
PM_MEM  = $7000
PM_P0   = PM_MEM+$400   ; Gracz 0: pilka
PM_P1   = PM_MEM+$500   ; Gracz 1: paletka

; ===== Pamiec ekranu =====
SCRN    = $9C00     ; 40x24 = 960 bajtow
DL      = $9B00     ; Display List (~35 bajtow)

; ===== Stale gry =====
LWALL   = 48        ; Lewa sciana (P/M color clocks)
RWALL   = 208       ; Prawa sciana
TWALL   = 40        ; Gorna sciana (scanline)
BDEAD   = 222       ; Linia smierci
PADY    = 210       ; Pozycja Y paletki (scanline)
PADH    = 3         ; Wysokosc paletki (scanlines)
BROW    = 4         ; Startowy wiersz cegiel (text row)
BROWS   = 5         ; Liczba rzedow cegiel
BCOLS   = 10        ; Cegiel w rzedzie
BTOTAL  = BROWS*BCOLS
SC_SP   = $00       ; Spacja (puste pole)
SC_BRK  = $80       ; Cegle: inwers. spacja = pelny blok

; ===== Zmienne (strona zerowa $CB-$DE) =====
    ORG $CB
BX      .ds 1     ; X pilki (wartosc HPOSP0)
BY      .ds 1     ; Y pilki (scanline w PM_P0)
VX      .ds 1     ; Predkosc X (+2 lub -2 w U2)
VY      .ds 1     ; Predkosc Y (+2 lub -2 w U2)
PX      .ds 1     ; X paletki (wartosc HPOSP1)
BREM    .ds 1     ; Pozostale cegly
LIVES   .ds 1     ; Ilosc zyc
STATE   .ds 1     ; Stan: 0=tytul, 1=gra, 2=smierc, 3=koniec
SCRL    .ds 1     ; Wynik BCD dziesiatki/jednosci
SCRH    .ds 1     ; Wynik BCD tysiace/setki
FRTCK   .ds 1     ; Licznik klatek
PTRL    .ds 1     ; Wskaznik 16-bit (low)
PTRH    .ds 1     ; Wskaznik 16-bit (high)
TMP1    .ds 1     ; Bajt tymczasowy 1
TMP2    .ds 1     ; Bajt tymczasowy 2
OLD_Y   .ds 1     ; Poprzednie Y pilki

; ===== Kod glowny =====
    ORG $2000

; ============================================================
; ENTRY - Punkt wejscia programu
; ============================================================
ENTRY:
    SEI
    LDA #$FF
    STA CRSINH          ; Ukryj kursor OS
    JSR BUILD_DL
    JSR CLEAR_SCR
    JSR INIT_PM
    JSR SET_COLORS
    CLI
    JSR SHOW_TITLE
    LDA #0
    STA STATE

; ============================================================
; MAIN - Glowna petla gry (60Hz)
; ============================================================
MAIN:
    LDA RTCLOK
WAIT:
    CMP RTCLOK
    BEQ WAIT
    INC FRTCK
    LDA STATE
    CMP #1
    BEQ DO_PLAY
    CMP #2
    BEQ DO_DEAD
    CMP #3
    BEQ DO_END
    ; STATE=0: ekran tytulowy
    LDA STRIG0
    BNE MAIN
    JSR START_GAME
    JMP MAIN

DO_PLAY:
    JSR MOVE_PAD
    JSR MOVE_BALL
    LDA BREM
    BNE MAIN
    ; Wszystkie cegly zniszczone - wygrana!
    JSR SHOW_WIN
    LDA #3
    STA STATE
    JMP MAIN

DO_DEAD:
    LDA FRTCK
    CMP #90
    BCC MAIN
    DEC LIVES
    BEQ DO_OVER
    JSR DRAW_STATUS
    JSR RESET_BALL
    LDA #1
    STA STATE
    JMP MAIN

DO_OVER:
    JSR SHOW_OVER
    LDA #3
    STA STATE
    JMP MAIN

DO_END:
    LDA STRIG0
    BNE MAIN
    JSR CLEAR_SCR
    JSR SHOW_TITLE
    LDA #0
    STA STATE
    JMP MAIN

; ============================================================
; START_GAME
; ============================================================
START_GAME:
    LDA #3
    STA LIVES
    LDA #0
    STA SCRL
    STA SCRH
    JSR CLEAR_SCR
    JSR DRAW_BRICKS
    JSR DRAW_STATUS
    JSR RESET_BALL
    LDA #1
    STA STATE
    RTS

; ============================================================
; RESET_BALL - Ustaw pilke i paletke na starcie
; ============================================================
RESET_BALL:
    LDA #0
    STA FRTCK
    LDA #120
    STA PX
    STA HPOSP1
    LDA #116
    STA BX
    STA HPOSP0
    LDA #188
    STA BY
    STA OLD_Y
    LDA #1      ; Predkosc X: +1 (wolniejsza pilka)
    STA VX
    LDA #$FF    ; Predkosc Y: -1 (dopelnienie do 2)
    STA VY
    JSR DRAW_PAD
    JSR DRAW_BALL
    RTS

; ============================================================
; MOVE_PAD - Ruch paletka (joystick)
; ============================================================
MOVE_PAD:
    LDA STICK0
    AND #$04        ; Bit 2 = lewo (0=nacisniety)
    BNE MP_CHK_R
    LDA PX
    SEC
    SBC #3
    CMP #LWALL
    BCS MP_STORE
    LDA #LWALL
    JMP MP_STORE

MP_CHK_R:
    LDA STICK0
    AND #$08        ; Bit 3 = prawo (0=nacisniety)
    BNE MP_DONE
    LDA PX
    CLC
    ADC #3
    CMP #RWALL-16   ; Eff. szerokosc paletki 2x = 16 cc
    BCC MP_STORE
    LDA #RWALL-16

MP_STORE:
    STA PX
    STA HPOSP1
MP_DONE:
    RTS

; ============================================================
; MOVE_BALL - Ruch pilki i kolizje
; ============================================================
MOVE_BALL:
    ; Kasuj stara pozycje pilki w PM_P0 (4 scanlines)
    LDA OLD_Y
    TAX
    LDA #0
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X

    ; --- Ruch X ---
    LDA BX
    CLC
    ADC VX
    CMP #LWALL
    BCS MB_XR
    ; Uderzenie w lewa sciane
    LDA #LWALL
    STA BX
    STA HPOSP0
    JSR NEG_VX
    JMP MB_Y
MB_XR:
    CMP #RWALL-4
    BCC MB_XOK
    ; Uderzenie w prawa sciane
    LDA #RWALL-4
    STA BX
    STA HPOSP0
    JSR NEG_VX
    JMP MB_Y
MB_XOK:
    STA BX
    STA HPOSP0

    ; --- Ruch Y ---
MB_Y:
    LDA BY
    CLC
    ADC VY
    CMP #TWALL
    BCS MB_YB
    ; Uderzenie w gorna sciane
    LDA #TWALL
    STA BY
    STA OLD_Y
    JSR NEG_VY
    JMP MB_PAD
MB_YB:
    CMP #BDEAD
    BCC MB_YOK
    ; Pilka wypadla!
    LDA OLD_Y
    TAX
    LDA #0
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X
    LDA #2
    STA STATE
    LDA #0
    STA FRTCK
    RTS
MB_YOK:
    STA BY
    STA OLD_Y

    ; --- Kolizja z paletka ---
MB_PAD:
    LDA BY
    CMP #PADY-3
    BCC MB_BRK      ; Za wysoko
    LDA BY
    CMP #PADY+PADH+2
    BCS MB_BRK      ; Za nisko
    LDA BX
    SEC
    SBC PX
    CMP #24
    BCS MB_BRK      ; Poza zasiegiem
    LDA VY
    BMI MB_BRK      ; Juz idzie w gore
    JSR NEG_VY

    ; --- Kolizja z ceglami ---
MB_BRK:
    ; Przelicz BY na wiersz ekranu: row = (BY - 32) / 8
    LDA BY
    SEC
    SBC #32
    BCC MB_DRAW     ; Ujemne = poza ekranem
    LSR
    LSR
    LSR           ; /8
    CMP #BROW
    BCC MB_DRAW
    CMP #BROW+BROWS
    BCS MB_DRAW
    STA TMP1        ; TMP1 = wiersz ekranu

    ; Przelicz BX na kolumne: col = (BX - LWALL) / 4
    LDA BX
    SEC
    SBC #LWALL
    LSR
    LSR           ; /4
    CMP #40
    BCS MB_DRAW
    STA TMP2        ; TMP2 = kolumna

    ; Adres znaku = SCRN + ROWTAB[row] + col
    LDA TMP1
    ASL           ; x2 (indeks tablicy 16-bit)
    TAX
    LDA ROWTAB,X
    CLC
    ADC TMP2
    STA PTRL
    LDA ROWTAB+1,X
    ADC #0
    STA PTRH
    LDA PTRL
    CLC
    ADC #<SCRN
    STA PTRL
    LDA PTRH
    ADC #>SCRN
    STA PTRH

    LDY #0
    LDA (PTRL),Y
    BEQ MB_DRAW     ; Puste = brak cegly

    ; Zniszcz cegle!
    LDA #SC_SP
    STA (PTRL),Y
    JSR NEG_VY
    DEC BREM

    ; Wynik += 10 (BCD)
    SED
    LDA SCRL
    CLC
    ADC #$10
    STA SCRL
    LDA SCRH
    ADC #0
    STA SCRH
    CLD
    JSR DRAW_STATUS

MB_DRAW:
    JSR DRAW_BALL
    RTS

; ============================================================
; NEG_VX / NEG_VY - Negacja predkosci (odbit)
; Negacja w U2: -x = (x XOR $FF) + 1
;               = EOR #$FF : SEC : ADC #0
; ============================================================
NEG_VX:
    LDA VX
    EOR #$FF
    SEC
    ADC #0
    STA VX
    RTS

NEG_VY:
    LDA VY
    EOR #$FF
    SEC
    ADC #0
    STA VY
    RTS

; ============================================================
; DRAW_BALL - Rysuj pilke w PM_P0
; Ksztalt: $F0 = 4 bity szer. x 4 scanlines wys. = kwadrat
; (4 color clocks x 4 scanlines ~ 1:1 na ekranie ATARI)
; ============================================================
DRAW_BALL:
    LDA BY
    TAX
    LDA #$F0    ; 4 bity (lewa polowa gracza) = szerokosc kwadratowa
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X
    INX
    STA PM_P0,X ; 4 scanlines = odpowiednik 4 color clocks w pionie
    RTS

; ============================================================
; DRAW_PAD - Rysuj paletke w PM_P1 (wywolaj przy resecie)
; ============================================================
DRAW_PAD:
    LDA #0
    LDX #0
DP_CLR:
    STA PM_P1,X
    INX
    BNE DP_CLR
    LDA #$FF
    LDX #PADY
    STA PM_P1,X
    INX
    STA PM_P1,X
    INX
    STA PM_P1,X     ; PADH = 3 scanlines
    RTS

; ============================================================
; DRAW_BRICKS - Rysuj cegly na ekranie
; ============================================================
DRAW_BRICKS:
    LDA #BTOTAL
    STA BREM
    LDA #BROW
    STA TMP1
DB_ROW:
    LDA TMP1
    ASL
    TAX
    LDA ROWTAB,X
    CLC
    ADC #<SCRN
    STA PTRL
    LDA ROWTAB+1,X
    ADC #>SCRN
    STA PTRH
    LDA #SC_BRK
    LDY #39
DB_COL:
    STA (PTRL),Y
    DEY
    BPL DB_COL
    INC TMP1
    LDA TMP1
    CMP #BROW+BROWS
    BNE DB_ROW
    RTS

; ============================================================
; CLEAR_SCR - Wyczysc pamiec ekranu
; ============================================================
CLEAR_SCR:
    LDA #<SCRN
    STA PTRL
    LDA #>SCRN
    STA PTRH
    LDA #0
    LDY #0
    LDX #4
CS_L:
    STA (PTRL),Y
    INY
    BNE CS_L
    INC PTRH
    DEX
    BNE CS_L
    RTS

; ============================================================
; BUILD_DL - Zbuduj Display List (tryb tekstowy ANTIC Mode 2)
; ============================================================
BUILD_DL:
    LDX #0
    LDA #$70        ; 8 blank scanlines
    STA DL,X
    INX
    STA DL,X
    INX
    STA DL,X
    INX
    LDA #$42        ; Mode 2 + LMS (adres pamieci ekranu)
    STA DL,X
    INX
    LDA #<SCRN
    STA DL,X
    INX
    LDA #>SCRN
    STA DL,X
    INX
    LDA #$02        ; Mode 2 (kolejne wiersze)
    LDY #23
BDL_R:
    STA DL,X
    INX
    DEY
    BNE BDL_R
    LDA #$41        ; JVB - skok z VBL do poczatku DL
    STA DL,X
    INX
    LDA #<DL
    STA DL,X
    INX
    LDA #>DL
    STA DL,X
    INX
    LDA #<DL
    STA SDLSTL
    LDA #>DL
    STA SDLSTH
    RTS

; ============================================================
; INIT_PM - Inicjalizuj Player/Missile graphics
; ============================================================
INIT_PM:
    ; Wyczysc 4K pamieci P/M
    LDA #<PM_MEM
    STA PTRL
    LDA #>PM_MEM
    STA PTRH
    LDA #0
    LDY #0
    LDX #16         ; 16 stron x 256 = 4096 B
IPM_L:
    STA (PTRL),Y
    INY
    BNE IPM_L
    INC PTRH
    DEX
    BNE IPM_L
    ; PMBASE = adres >> 8 (musi byc wyrownany do 4K)
    LDA #>PM_MEM    ; = $70
    STA PMBASE
    ; SDMCTL: normalny tryb tekstu + DMA graczy/pociskow + 1 linia/piksel
    ; = %00111110 = $3E
    LDA #$3E
    STA SDMCTL
    ; GRACTL: bit 0=pociski, bit 1=gracze
    LDA #$03
    STA GRACTL
    ; Priorytet domyslny (gracze nad polem)
    LDA #$00
    STA GPRIOR
    ; Paletka: 2x szersza (16 cc zamiast 8)
    LDA #$01
    STA SIZEP1
    RTS

; ============================================================
; SET_COLORS - Ustaw kolory gry
; ============================================================
SET_COLORS:
    LDA #$00
    STA COLBKS      ; Tlo: czarne
    LDA #$0F
    STA COLPM0S     ; Pilka: biala
    LDA #$C6
    STA COLPM1S     ; Paletka: zielona
    LDA #$28
    STA COLPF2S     ; Cegly/tekst: pomaranczowy
    RTS

; ============================================================
; DRAW_STATUS - Wyswietl wynik i zycia w wierszu 0
; Screen codes: cyfra N -> SC = N + $10
; Litery: SC = ATASCII - 32 (np. 'Z'=90 -> SC=58=$3A)
; ============================================================
DRAW_STATUS:
    ; "ZYC:" (Z=$3A Y=$39 C=$23 :=$1A)
    LDA #$3A
    STA SCRN+0
    LDA #$39
    STA SCRN+1
    LDA #$23
    STA SCRN+2
    LDA #$1A
    STA SCRN+3
    ; Cyfra zyc
    LDA LIVES
    CLC
    ADC #$10
    STA SCRN+4
    LDA #$00
    STA SCRN+5
    ; "SCR:" (S=$33 C=$23 R=$32 :=$1A)
    LDA #$33
    STA SCRN+6
    LDA #$23
    STA SCRN+7
    LDA #$32
    STA SCRN+8
    LDA #$1A
    STA SCRN+9
    ; Wynik 4-cyfrowy BCD (SCRH=tysiace/setki SCRL=dziesiatki/jednosci)
    LDA SCRH
    LSR
    LSR
    LSR
    LSR
    CLC
    ADC #$10
    STA SCRN+10
    LDA SCRH
    AND #$0F
    CLC
    ADC #$10
    STA SCRN+11
    LDA SCRL
    LSR
    LSR
    LSR
    LSR
    CLC
    ADC #$10
    STA SCRN+12
    LDA SCRL
    AND #$0F
    CLC
    ADC #$10
    STA SCRN+13
    RTS

; ============================================================
; SHOW_TITLE - Ekran tytulowy
; Pozycje: row*40 + col (offset w SCRN)
;   Row 5 col 16 = 5*40+16 = 216 = $D8   -> "BREAKOUT"
;   Row 9 col 13 = 9*40+13 = 373 = $0175 -> "NACISNIJ OGIEN"
;   Row 11 col 15 = 11*40+15 = 455 = $01C7 -> "PRESS FIRE"
; ============================================================
SHOW_TITLE:
    ; "BREAKOUT" (B=$22 R=$32 E=$25 A=$21 K=$2B O=$2F U=$35 T=$34)
    LDA #$22
    STA SCRN+$D8+0
    LDA #$32
    STA SCRN+$D8+1
    LDA #$25
    STA SCRN+$D8+2
    LDA #$21
    STA SCRN+$D8+3
    LDA #$2B
    STA SCRN+$D8+4
    LDA #$2F
    STA SCRN+$D8+5
    LDA #$35
    STA SCRN+$D8+6
    LDA #$34
    STA SCRN+$D8+7

    ; "NACISNIJ OGIEN" (N=$2E A=$21 C=$23 I=$29 S=$33 N=$2E I J=$2A sp O=$2F G=$27 I E=$25 N)
    LDA #$2E
    STA SCRN+$175+0
    LDA #$21
    STA SCRN+$175+1
    LDA #$23
    STA SCRN+$175+2
    LDA #$29
    STA SCRN+$175+3
    LDA #$33
    STA SCRN+$175+4
    LDA #$2E
    STA SCRN+$175+5
    LDA #$29
    STA SCRN+$175+6
    LDA #$2A
    STA SCRN+$175+7
    LDA #$00
    STA SCRN+$175+8
    LDA #$2F
    STA SCRN+$175+9
    LDA #$27
    STA SCRN+$175+10
    LDA #$29
    STA SCRN+$175+11
    LDA #$25
    STA SCRN+$175+12
    LDA #$2E
    STA SCRN+$175+13

    ; "PRESS FIRE" (P=$30 R=$32 E=$25 S=$33 S sp F=$26 I=$29 R E)
    LDA #$30
    STA SCRN+$1C7+0
    LDA #$32
    STA SCRN+$1C7+1
    LDA #$25
    STA SCRN+$1C7+2
    LDA #$33
    STA SCRN+$1C7+3
    LDA #$33
    STA SCRN+$1C7+4
    LDA #$00
    STA SCRN+$1C7+5
    LDA #$26
    STA SCRN+$1C7+6
    LDA #$29
    STA SCRN+$1C7+7
    LDA #$32
    STA SCRN+$1C7+8
    LDA #$25
    STA SCRN+$1C7+9
    RTS

; ============================================================
; SHOW_WIN - Napis "WYGRALES!"
; Row 12 col 15 = 12*40+15 = 495 = $01EF
; ============================================================
SHOW_WIN:
    ; W=$37 Y=$39 G=$27 R=$32 A=$21 L=$2C E=$25 S=$33 !=$01
    LDA #$37
    STA SCRN+$1EF+0
    LDA #$39
    STA SCRN+$1EF+1
    LDA #$27
    STA SCRN+$1EF+2
    LDA #$32
    STA SCRN+$1EF+3
    LDA #$21
    STA SCRN+$1EF+4
    LDA #$2C
    STA SCRN+$1EF+5
    LDA #$25
    STA SCRN+$1EF+6
    LDA #$33
    STA SCRN+$1EF+7
    LDA #$01
    STA SCRN+$1EF+8
    RTS

; ============================================================
; SHOW_OVER - Napis "KONIEC GRY"
; Row 12 col 15 = $01EF
; ============================================================
SHOW_OVER:
    ; K=$2B O=$2F N=$2E I=$29 E=$25 C=$23 sp G=$27 R=$32 Y=$39
    LDA #$2B
    STA SCRN+$1EF+0
    LDA #$2F
    STA SCRN+$1EF+1
    LDA #$2E
    STA SCRN+$1EF+2
    LDA #$29
    STA SCRN+$1EF+3
    LDA #$25
    STA SCRN+$1EF+4
    LDA #$23
    STA SCRN+$1EF+5
    LDA #$00
    STA SCRN+$1EF+6
    LDA #$27
    STA SCRN+$1EF+7
    LDA #$32
    STA SCRN+$1EF+8
    LDA #$39
    STA SCRN+$1EF+9
    RTS

; ============================================================
; ROWTAB - Tabela offsetow wierszy ekranu (row * 40)
; 24 wiersze x 2 bajty = 48 bajtow
; ============================================================
ROWTAB:
    .word  0*40,  1*40,  2*40,  3*40
    .word  4*40,  5*40,  6*40,  7*40
    .word  8*40,  9*40, 10*40, 11*40
    .word 12*40, 13*40, 14*40, 15*40
    .word 16*40, 17*40, 18*40, 19*40
    .word 20*40, 21*40, 22*40, 23*40

; ============================================================
; Ustaw adres uruchomienia programu
; ============================================================
    RUN ENTRY
