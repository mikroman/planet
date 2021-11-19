ParamBlk:
		//OSWORD parameter block, 4 signed words
	.byte $25,$24,$20,$1D,$1C,$19,$19,$19

		//sound parameters
		// MSB of Channel/HSFC (first SOUND param)
		//   Hold always off
		// LSB of Channel/HSFC (first SOUND param)
		//   Flush always on
		// LSB of Amplitude (second SOUND param)
		//   [0,-15] amplitude / [1-4] envelope #
		// LSB of Pitch (third SOUND param)
		// LSB of Duration (fourth SOUND param)
HoldSync:

	.byte $02,$02,$02,$00,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$00,$00
	.byte $01,$01,$00,$00

FlushChan:

	.byte $11,$12,$13,$10,$11,$10,$11,$10
	.byte $11,$10,$11,$10,$11,$10,$12,$12
	.byte $11,$10,$13,$12

AmplEnvel:

	.byte $F6,$F6,$F6,$00,$01,$F4,$02,$F6
	.byte $01,$F6,$01,$F1,$01,$F1,$03,$03
	.byte $01,$F1,$04,$03

Pitch:

	.byte $00,$00,$00,$00,$E6,$07,$64,$07
	.byte $FF,$07,$B4,$07,$82,$07,$32,$14
	.byte $FF,$03,$00,$AA

Duration:

	.byte $32,$32,$32,$00,$FF,$1E,$FF,$0C
	.byte $FF,$02,$FF,$11,$FF,$28,$08,$08
	.byte $FF,$3C,$23,$08
