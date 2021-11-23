//SoundEnvelope.asm

ENVELOPE1:
    .byte 1,4, -4,-1,-1,20,20,20, 1,0,0,0,1,1
ENVELOPE2:
    .byte 2,1, 2,2,2,20,20,20, 1,0,0,0,1,1
ENVELOPE3:
    .byte 3,1, 3,2,-2,6,6,6, 100,0,0,-5, 100,0
ENVELOPE4:
    .byte 4,1, -15,-15,-15,240,240,240, 20,0,0,-20, 126,126

#import "constants.asm"

SetUpEnvelopes:

    ldx #<ENVELOPE1
    ldy #>ENVELOPE1
    lda #$08
    jsr OSWORD
    ldx #<ENVELOPE2
    ldy #>ENVELOPE2
    lda #$08
    jsr OSWORD
    ldx #<ENVELOPE3
    ldy #>ENVELOPE3
    lda #$08
    jsr OSWORD
    ldx #<ENVELOPE4
    ldy #>ENVELOPE4
    lda #$08
    jsr OSWORD
    rts