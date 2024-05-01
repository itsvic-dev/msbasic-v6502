; configuration
CONFIG_2A := 1
CONFIG_SCRTCH_ORDER := 2

; zero page
ZP_START0 = $00
ZP_START1 = $02
ZP_START2 = $0C
ZP_START3 = $62
ZP_START4 = $6D

;extra ZP variables
USR := GORESTART

; constants
STACK_TOP		:= $FA
SPACE_FOR_GOSUB := $3E
WIDTH			:= 40
WIDTH2			:= 30

; memory layout
RAMSTART2		:= $0400

MONCOUT:
    sta $0200
    rts

; input a character
; carry flag indicates if a key was pressed
; key will be in accumulator
MONRDKEY:
    ; wait for keyboard readiness
    lda $0202
    cmp #1
    bne @no_key_pressed

    ; read keyboard
    lda $0201
    jsr MONCOUT  ; echo
    sec
    rts
@no_key_pressed:
    clc
    rts

ISCNTC:
    ; TODO: is ctrl-c?
    rts

SAVE:
LOAD:
    ; no other IO for this
    rts


.segment "RESVEC"
NMI: .word $0000
RESET: .word COLD_START
IRQ: .word $0000
