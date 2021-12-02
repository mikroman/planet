SurfQuad:	
		//Packed 2-bit surface tiles (256) 4/byte;Corresponds to YSurface[256]
	.byte $2A,$00,$55,$55,$65,$66,$9A,$A9
	.byte $00,$01,$44,$55,$55,$55,$A5,$2A
	.byte $80,$2A,$08,$42,$55,$55,$55,$66
	.byte $66,$A6,$A6,$09,$82,$50,$10,$11
	.byte $41,$54,$55,$55,$55,$55,$55,$2A
	.byte $88,$08,$50,$69,$55,$55,$55,$55
	.byte $55,$55,$55,$55,$99,$A9,$99,$99
	.byte $19,$50,$40,$14,$54,$55,$55
ImgLaser:
	.byte $95//unused
		//Laser beam sprite data (tail to head)
		//colours: $00 bb, $10 bF, $20 Fb, $30 FF
	.byte $00,$00,$30,$00,$20,$30,$10,$30
	.byte $00,$30,$30,$20,$30,$30,$00,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
	.byte $30,$30,$30,$30,$30,$30,$30,$30
WarpX:	//warp animation points
		//x_offset_t
	.byte $50,$50,$28,$00,$00,$00,$28,$50
WarpY:
		//y_offset_t
	.byte $60,$C0,$C0,$C0,$60,$00,$00,$00
BlastX:
		//Blast animation point Xscr coord offsets
	.byte $02,$04,$00,$FC,$FE,$FC,$00,$04
BlastY:
	.byte $00,$0C,$06,$0C,$00,$F4,$FA,$F4
FlashPal:
		//PAL_FLASH (flashing) colour palettes
	.byte $45,$42,$46,$43,$47,$43,$46,$42
imgDot:
		//Minimap dots (2x2px) for each sprite #
		//SHIP    LAND    MUT     BAIT
	.byte $FF,$FF,$8A,$88,$A2,$88,$88,$88
		//BOMB    SWAR    MAN     POD
	.byte $A2,$A2,$82,$8A,$A8,$A8,$20,$20
		//KUGL    S250    S500	
	.byte $00,$D8,$00,$00,$00,$FF
		//imgDotR:
		//imgDot[] dots, >> 1 pixel to the right
	.byte $FF,$FF,$45,$44,$51,$44,$44,$44
	.byte $51,$51,$41,$45,$54,$54,$10,$10
	.byte $00,$6C,$00,$00,$00,$7F
SpriteMaxY:
		//Sprite height bitmask (-> _heightmask)
		//SHIP LAND MUT BAIT BOMB SWAR MAN POD
	.byte $07,$07,$07,$03,$07,$03,$0F,$07
	.byte $03,$07,$07
SpriteLen:
		//Sprite data lengths for:
		//SHIP LAND MUT BAIT BOMB SWAR MAN POD
	.byte $30, $20, $20,$14, $18, $0C, $08,$18
	.byte $02, $28, $28
		//KUGL S250 S500
SpriteV_l:
		//LB of vectors to sprite data
	.byte	<imgShipR,<imgLander,<imgMutant,<imgBaiter
	.byte	<imgBomber,<imgSwarmer,<imgMan,<imgPod
	.byte	<imgKugel,<img250,<img500
SpriteV_h:
		//HB of vectors to sprite data
	.byte	>imgShipR,>imgLander,>imgMutant,>imgBaiter
	.byte	>imgBomber,>imgSwarmer,>imgMan,>imgPod
	.byte	>imgKugel,>img250,>img500	
DoWarp:
		//bool unit 'warp in' animation
		//SHIP LAND  MUT BAIT BOMB SWAR MAN POD
	.byte $00,$01,$01,$01,$01,$00,$00,$01
	.byte $00,$00,$00
		//KUGL S250 S500
vsync:	//uint8_t vsync count -> irq_hook()
	.byte $30
rotatec://uint8_t  index into RotColour
	.byte $00
RotColour:		//colour_t  PAL_ROTx colours
	.byte $01,$03,$04
		//Red,Yellow,Blue
