//relocater.asm
#import "constants.asm"
#import "labelsII.asm"

Relocate:

    lda #$31
    sta _srcptr_h
    lda #$0E
    sta _destptr_h
    lda #$00
    sta _srcptr_l
    sta _destptr_l
    ldx #$03
    ldy #$00
!:
    lda (_srcptr),y
    sta (_destptr),y
    iny
    bne !-
    inc _srcptr_h
    inc _destptr_h
    dex
    bne !-
    rts
