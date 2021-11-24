#import "constants.asm"
#import "labelsII.asm"

RedefinedCharacters:
    ldx #$00
GetAByte:
    lda CharacterBase,x
    jsr OSWRCH
    inx
    cpx #$E7
    bne GetAByte
    rts
    
CharacterBase:

    .byte $17,$E0,$EE,$A4,$A4,$E4,$A4,$A4,$A4,$00
    .byte $17,$E1,$EE,$4A,$4A,$4E,$4A,$4A,$4A,$00
    .byte $17,$E2,$EA,$8A,$8A,$8C,$8A,$8A,$EA,$00
    .byte $17,$E3,$0A,$0A,$0A,$0A,$0E,$0E,$0A,$00
    .byte $17,$E4,$EA,$AA,$AA,$EA,$AA,$A4,$A4,$00
    .byte $17,$E5,$E0,$80,$80,$E0,$80,$80,$E0,$00
    .byte $17,$E6,$0E,$08,$08,$08,$08,$08,$0E,$00
    .byte $17,$E7,$EA,$AE,$AE,$AA,$AA,$AA,$EA,$00
    .byte $17,$E8,$E8,$A8,$A8,$E8,$88,$88,$8E,$00
    .byte $17,$E9,$EE,$84,$84,$E4,$84,$84,$E4,$00
    .byte $17,$EA,$EC,$8A,$8A,$EA,$8A,$8A,$EC,$00
    .byte $17,$EB,$CE,$AA,$AA,$CA,$AA,$AA,$CE,$00
    .byte $17,$EC,$AA,$AA,$EA,$EA,$EA,$AA,$AE,$00
    .byte $17,$ED,$E0,$80,$80,$E0,$20,$20,$E0,$00
    .byte $17,$EE,$A0,$A0,$A0,$40,$A0,$A0,$A0,$00
    .byte $17,$EF,$37,$45,$45,$57,$55,$55,$35,$00
    .byte $17,$F0,$57,$74,$74,$57,$54,$54,$57,$00
    .byte $17,$F1,$EA,$AA,$AA,$AA,$AA,$A4,$E4,$00
    .byte $17,$F2,$EC,$8A,$8A,$EC,$8A,$8A,$EA,$00
    .byte $17,$F3,$AE,$A4,$A4,$E4,$A4,$A4,$AE,$00
    .byte $17,$F4,$0E,$08,$08,$EE,$02,$02,$0E,$00
    .byte $17,$F5,$EE,$8A,$8A,$8A,$8A,$8A,$EE,$00
    .byte $17,$F6,$CE,$A8,$A8,$CE,$A8,$A8,$AE,$00