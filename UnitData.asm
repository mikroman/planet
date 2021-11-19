HyperKeys:
		//hyperspace keycodes
	.byte $AC,$BB,$CA,$BA,$AA,$9B,$AB
		//GYUJNBH

AiVector://vector table for ai routines
	.word ai_ship,ai_lander,ai_mutant,ai_baiter
	.word ai_bomber,ai_swarmer,ai_human,ai_pod
	.word ai_object,ai_object,ai_object
Spawnc:
		//Duint8_t[8]  Unit spawn counts
	.byte $00,$05,$00,$00,$04,$00,$00,$00
		//SHP LND MUT BAI BOM SWM MAN POD
XMinInit:
		//xpos_t[8]  Initial unit minimum X
	.byte $07,$00,$40,$00,$40,$00,$00,$00
XRangeInit:
		//uint8_t[8]  Initial unit X range
	.byte $00,$FF,$7F,$0F,$07,$00,$FF,$3F
YMinInit:
		//ypos_t[8]  Initial unit minimum Y
	.byte $64,$B4,$00,$00,$00,$00,$0A,$00
		//SHP LND MUT BAI BOM SWM MAN POD	
YRangeInit:
		//uint8_t[8]  Initial unit Y range
	.byte $00,$00,$FF,$FF,$FF,$1F,$00,$FF
dXMinInit:
		//xoffset_t[8] Init minimum dX (abs)
	.byte $02,$18,$00,$0A,$18,$32,$04,$08
dXRangeInit:
		//uint8_t[8]  Initial unit dX range
	.byte $07,$0F,$00,$07,$0F,$07,$00,$07
		//SHP LND MUT BAI BOM SWM MAN POD
dYMinInit:
		//yoffset_t[8] Init minimum dY (abs)
	.byte $0A,$00,$00,$0A,$00,$18,$00,$08
dYRangeInit:
		//uint8_t[8]  Initial unit dY range	
	.byte $3F,$00,$00,$07,$0F,$07,$00,$07
Points_l:
		//bcd_t unit point scores (x1)
	.byte $00,$50,$50,$50,$00,$50,$00,$00
	.byte $25,$00,$00
Points_h:
		//bcd_t unit point scores (x100)
		//SHIP LAND  MUT BAIT BOMB SWAR MAN POD
	.byte $00,$01,$01,$01,$02,$02,$00,$10
	.byte $00,$00,$00
		//KUGL S250 S500
