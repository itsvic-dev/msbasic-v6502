.segment "CODE"

; ----------------------------------------------------------------------------
; INPUT CONVERSION ERROR:  ILLEGAL CHARACTER
; IN NUMERIC FIELD.  MUST DISTINGUISH
; BETWEEN INPUT, READ, AND GET
; ----------------------------------------------------------------------------
INPUTERR:
        lda     INPUTFLG
        beq     RESPERR	; INPUT
.ifndef CONFIG_SMALL
.ifndef CONFIG_BUG_GET_ERROR
        bmi     L2A63	; READ
        ldy     #$FF	; GET
        bne     L2A67
L2A63:
.endif
.endif
.ifdef CONFIG_CBM1_PATCHES
        jsr     PATCH5
		nop
.else
        lda     Z8C
        ldy     Z8C+1
.endif
L2A67:
        sta     CURLIN
        sty     CURLIN+1
SYNERR4:
        jmp     SYNERR
RESPERR:
.ifdef CONFIG_FILE
        lda     Z03
        beq     LCA8F
        ldx     #ERR_BADDATA
        jmp     ERROR
LCA8F:
.endif
        lda     #<ERRREENTRY
        ldy     #>ERRREENTRY
        jsr     STROUT
        lda     OLDTEXT
        ldy     OLDTEXT+1
        sta     TXTPTR
        sty     TXTPTR+1
RTS20:
        rts

; ----------------------------------------------------------------------------
; "GET" STATEMENT
; ----------------------------------------------------------------------------
.ifndef CONFIG_SMALL
GET:
        jsr     ERRDIR
; CBM: if GET#, then switch input
.ifdef CONFIG_FILE
        cmp     #'#'
        bne     LCAB6
        jsr     CHRGET
        jsr     GETBYT
        lda     #','
        jsr     SYNCHR
        jsr     CHKIN
        stx     Z03
LCAB6:
.endif
        ldx     #<(INPUTBUFFER+1)
        ldy     #>(INPUTBUFFER+1)
.if INPUTBUFFER >= $0100
        lda     #$00
        sta     INPUTBUFFER+1
.else
        sty     INPUTBUFFER+1
.endif
        lda     #$40
        jsr     PROCESS_INPUT_LIST
; CBM: if GET#, then switch input back
.ifdef CONFIG_FILE
        ldx     Z03
        bne     LCAD8
.endif
        rts
.endif

; ----------------------------------------------------------------------------
; "INPUT#" STATEMENT
; ----------------------------------------------------------------------------
.ifdef CONFIG_FILE
INPUTH:
        jsr     GETBYT
        lda     #$2C
        jsr     SYNCHR
        jsr     CHKIN
        stx     Z03
        jsr     L2A9E
LCAD6:
        lda     Z03
LCAD8:
        jsr     CLRCH
        ldx     #$00
        stx     Z03
        rts
LCAE0:
.endif

; ----------------------------------------------------------------------------
; "INPUT" STATEMENT
; ----------------------------------------------------------------------------
INPUT:
.ifndef KBD
        lsr     Z14
.endif
        cmp     #$22
        bne     L2A9E
        jsr     STRTXT
        lda     #$3B
        jsr     SYNCHR
        jsr     STRPRT
L2A9E:
        jsr     ERRDIR
        lda     #$2C
        sta     INPUTBUFFER-1
LCAF8:
.ifdef APPLE
        jsr     INLINX
.else
        jsr     NXIN
.endif
.ifdef KBD
        bmi     L2ABE
.else
  .ifdef CONFIG_FILE
        lda     Z03
        beq     LCB0C
        lda     Z96
        and     #$02
        beq     LCB0C
        jsr     LCAD6
        jmp     DATA
LCB0C:
  .endif
        lda     INPUTBUFFER
        bne     L2ABE
  .ifdef CONFIG_FILE
        lda     Z03
        bne     LCAF8
  .endif
  .ifdef CONFIG_CBM1_PATCHES
        jmp     PATCH1
  .else
        clc
        jmp     CONTROL_C_TYPED
  .endif
.endif

NXIN:
.ifdef KBD
        jsr     LFDDA
        bmi     RTS20
        pla
        jmp     LE86C
.else
  .ifdef CONFIG_FILE
        lda     Z03
        bne     LCB21
  .endif
        jsr     OUTQUES	; '?'
        jsr     OUTSP
LCB21:
        jmp     INLIN
.endif

; ----------------------------------------------------------------------------
; "GETC" STATEMENT
; ----------------------------------------------------------------------------
.ifdef KBD
GETC:
        jsr     CONINT
        jsr     LF43D
        jmp     LE664
.endif

; ----------------------------------------------------------------------------
; "READ" STATEMENT
; ----------------------------------------------------------------------------
READ:
        ldx     DATPTR
        ldy     DATPTR+1
.ifdef CBM2_KBD
        lda     #$98 ; AppleSoft, too
        .byte   $2C
L2ABE:
        lda     #$00
.else
        .byte   $A9
L2ABE:
        tya
.endif

; ----------------------------------------------------------------------------
; PROCESS INPUT LIST
;
; (Y,X) IS ADDRESS OF INPUT DATA STRING
; (A) = VALUE FOR INPUTFLG:  $00 FOR INPUT
; 				$40 FOR GET
;				$98 FOR READ
; ----------------------------------------------------------------------------
PROCESS_INPUT_LIST:
        sta     INPUTFLG
        stx     INPTR
        sty     INPTR+1
PROCESS_INPUT_ITEM:
        jsr     PTRGET
        sta     FORPNT
        sty     FORPNT+1
        lda     TXTPTR
        ldy     TXTPTR+1
        sta     TXPSV
        sty     TXPSV+1
        ldx     INPTR
        ldy     INPTR+1
        stx     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGOT
        bne     INSTART
        bit     INPUTFLG
.ifndef CONFIG_SMALL ; GET
        bvc     L2AF0
        jsr     MONRDKEY
  .ifdef CONFIG_IO_MSB
        and     #$7F
  .endif
        sta     INPUTBUFFER
  .ifdef CONFIG_INPUTBUFFER_ORDER
        ldy     #>(INPUTBUFFER-1)
        ldx     #<(INPUTBUFFER-1)
  .else
        ldx     #<(INPUTBUFFER-1)
        ldy     #>(INPUTBUFFER-1)
  .endif
        bne     L2AF8
L2AF0:
.endif
        bmi     FINDATA
.ifdef CONFIG_FILE
        lda     Z03
        bne     LCB64
.endif
.ifdef KBD
        jsr     OUTQUESSP
.else
        jsr     OUTQUES
.endif
LCB64:
        jsr     NXIN
L2AF8:
        stx     TXTPTR
        sty     TXTPTR+1

; ----------------------------------------------------------------------------
INSTART:
        jsr     CHRGET
        bit     VALTYP
        bpl     L2B34
.ifndef CONFIG_SMALL ; GET
        bit     INPUTFLG
        bvc     L2B10
  .ifdef CONFIG_CBM1_PATCHES
        lda     #$00
        jsr     PATCH4
        nop
  .else
        inx
        stx     TXTPTR
        lda     #$00
        sta     CHARAC
        beq     L2B1C
  .endif
L2B10:
.endif
        sta     CHARAC
        cmp     #$22
        beq     L2B1D
        lda     #$3A
        sta     CHARAC
        lda     #$2C
L2B1C:
        clc
L2B1D:
        sta     ENDCHR
        lda     TXTPTR
        ldy     TXTPTR+1
        adc     #$00
        bcc     L2B28
        iny
L2B28:
        jsr     STRLT2
        jsr     POINT
.ifdef CONFIG_SMALL
        jsr     LETSTRING
.else
        jsr     PUTSTR
.endif
        jmp     INPUT_MORE
; ----------------------------------------------------------------------------
L2B34:
        jsr     FIN
.ifdef CONFIG_SMALL
        jsr     SETFOR
.else
        lda     VALTYP+1
        jsr     LET2
.endif
; ----------------------------------------------------------------------------
INPUT_MORE:
        jsr     CHRGOT
        beq     L2B48
        cmp     #$2C
        beq     L2B48
        jmp     INPUTERR
L2B48:
        lda     TXTPTR
        ldy     TXTPTR+1
        sta     INPTR
        sty     INPTR+1
        lda     TXPSV
        ldy     TXPSV+1
        sta     TXTPTR
        sty     TXTPTR+1
        jsr     CHRGOT
        beq     INPDONE
        jsr     CHKCOM
        jmp     PROCESS_INPUT_ITEM
; ----------------------------------------------------------------------------
FINDATA:
        jsr     DATAN
        iny
        tax
        bne     L2B7C
        ldx     #ERR_NODATA
        iny
        lda     (TXTPTR),y
        beq     GERR
        iny
        lda     (TXTPTR),y
        sta     Z8C
        iny
        lda     (TXTPTR),y
        iny
        sta     Z8C+1
L2B7C:
        lda     (TXTPTR),y
        tax
        jsr     ADDON
        cpx     #$83
        bne     FINDATA
        jmp     INSTART
; ---NO MORE INPUT REQUESTED------
INPDONE:
        lda     INPTR
        ldy     INPTR+1
        ldx     INPUTFLG
.ifdef OSI ; CONFIG_SMALL && !CONFIG_11
        beq     L2B94 ; INPUT
.else
        bpl     L2B94; INPUT or GET
.endif
        jmp     SETDA
L2B94:
        ldy     #$00
        lda     (INPTR),y
        beq     L2BA1
.ifdef CONFIG_FILE
        lda     Z03
        bne     L2BA1
.endif
        lda     #<ERREXTRA
        ldy     #>ERREXTRA
        jmp     STROUT
L2BA1:
        rts

; ----------------------------------------------------------------------------
ERREXTRA:
.ifdef KBD
        .byte   "?Extra"
.else
        .byte   "?EXTRA IGNORED"
.endif
        .byte   $0D,$0A,$00
ERRREENTRY:
.ifdef KBD
        .byte   "What?"
.else
        .byte   "?REDO FROM START"
.endif
        .byte   $0D,$0A,$00
.ifdef KBD
LEA30:
        .byte   "B"
        .byte   $FD
        .byte   "GsBASIC"
        .byte   $00,$1B,$0D,$13
        .byte   " BASIC"
.endif