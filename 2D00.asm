*=$2D00
SpriteLen:
//$2D00,X	Sprite data lengths
	.byte $30,$20,$20,$14,$18,$0C,$08,$18
	.byte $02,$28,$28
SpriteV_l:
//$2D0B,X	LB of vectors to sprite data
	.byte $C0,$2C,$4C,$6C,$94,$AC,$A0,$A8
	.byte $B8,$BE,$CE
SpriteV_h:
//$2D16,X	HB of vectors to sprite data
	.byte $0F,$10,$10,$10,$10,$10,$0F,$0F
	.byte $10,$10,$10
ImgDot:
//$2D21,X	Minimap dots (2x2px) for each sprite #
	.byte $FF,$FF,$8A,$88,$A2,$88,$88,$88
	.byte $A2,$A2,$82,$8A,$A8,$A8,$20,$20
	.byte $00,$D8,$00,$00,$00,$FF
//ImgDotR:
//2D37		imgDot[] dots, >> 1 pixel to the right
	.byte $FF,$FF,$45,$44,$51,$44,$44,$44
	.byte $51,$51,$41,$45,$54,$54,$10,$10
	.byte $00,$6C,$00,$00,$00,$7F
SpriteMaxY:
//$2D4D		Sprite height bitmask (-> _heightmask)
	.byte $07,$07,$07,$03,$07,$03,$0F,$07
	.byte $03,$07,$07
Points_l:
//$2D58,X	bcd_t[11] unit point scores (x1)
	.byte $00,$50,$50,$50,$00,$50,$00,$00
	.byte $25,$00,$00
Points_h:
//$2D63,X	bcd_t[11] unit point scores (x100)
	.byte $00,$01,$01,$01,$02
	.byte $02,$00,$10,$00,$00,$00
DoWarp:
//$2D6E,Y	bool[11] unit 'warp in' animation
	.byte $00,$01,$01,$01,$01,$00,$00,$01
	.byte $00,$00,$00
//$2d79		135 unused bytes
	.byte $BB,$CA,$BA,$AA,$9B,$AB,$60
	.byte $10,$01,$F1,$FF,$07,$00,$28,$00
	.byte $02,$02,$02,$00,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$00,$00
	.byte $01,$01,$00,$00,$11,$12,$13,$10
	.byte $11,$10,$11,$10,$11,$10,$11,$10
	.byte $11,$10,$12,$12,$11,$10,$13,$12
	.byte $F6,$F6,$F6,$00,$01,$F4,$02,$F6
	.byte $01,$F6,$01,$F1,$01,$F1,$03,$03
	.byte $01,$F1,$04,$03,$00,$00,$00,$00
	.byte $E6,$07,$64,$07,$FF,$07,$B4,$07
	.byte $82,$07,$32,$14,$FF,$03,$00,$AA
	.byte $32,$32,$32,$00,$FF,$1E,$FF,$0C
	.byte $FF,$02,$FF,$11,$FF,$28,$08,$08
	.byte $FF,$3C,$23,$08,$20,$38,$30,$30
	.byte $30,$0D,$35,$31,$30,$20,$21,$2C
	.byte $4D,$31,$39,$47,$3F,$58,$57,$80
vsync:
//$2E00	
	.byte $30
rotatec:
	.byte $00
RotColour:
	.byte $01,$03,$04//Red,Yellow,Blue
AiVector:		//vector table for ai routines
//$2E05	
	.byte $BC,$11,$DA,$11,$61,$13,$F8,$13
	.byte $2D,$14,$36,$14,$B1,$14,$68,$15
	.byte $BF,$11,$BF,$11,$BF,$11
//$2E1B		two unused bytes	
	.byte $00,$00
Spawnc:
//$2E1D		Duint8_t[8]  Unit spawn counts
	.byte $00,$05,$00,$00,$04,$00,$00,$00
XMinInit:
//$2e25		xpos_t[8]  Initial unit minimum X
	.byte $07,$00,$40,$00,$40,$00,$00,$00
XRangeInit:
//$2E2D		uint8_t[8]  Initial unit X range
	.byte $00,$FF,$7F,$0F,$07,$00,$FF,$3F
YMinInit:
//$2E35		ypos_t[8]  Initial unit minimum Y
	.byte $64,$B4,$00,$00,$00,$00,$0A,$00
YRangeInit:
//$2E3D		uint8_t[8]  Initial unit Y range
	.byte $00,$00,$FF,$FF,$FF,$1F,$00,$FF
dXMinInit:
//$2E45		xoffset_t[8] Init minimum dX (abs)
	.byte $02,$18,$00,$0A,$18,$32,$04,$08
dXRangeInit:
//$2E4D		uint8_t[8]  Initial unit dX range
	.byte $07,$0F,$00,$07,$0F,$07,$00,$07
dYMinInit:
//$2E55		yoffset_t[8] Init minimum dY (abs)
	.byte $0A,$00,$00,$0A,$00,$18,$00,$08
dYRangeInit:
//$2E5D		uint8_t[8]  Initial unit dY range	
	.byte $3F,$00,$00,$07,$0F,$07,$00,$07
stringV_l:
//$2E65		LSB of string pointers
	.byte $8D,$90,$A9,$B5,$F5,$39,$3F
//$2E6C		13 unused bytes	
	.byte $9C,$C4,$C4,$C8,$3C,$AC,$A4,$8C
	.byte $78,$CC,$90,$8C,$A0
StringV_h:
//$2E79		MSB of string pointers
	.byte $2E,$2E,$2E,$2E,$2E,$2F,$2F
//$2E80		13 unused bytes
	.byte $00,$00,$03,$00,$00,$00,$00,$00
	.byte $00,$FC,$00,$00,$03
string0:
//$2E8D		string_t[3]  Message string #0
	.byte $02,$0C,$14
string1:
//byte 02=length.clear text and restore def pallete	
//$2E90		string_t[25]  Message string #1
	.byte $18,$11,$04,$1F,$04,$0C,$E0,$E1
	.byte $E2,$E3,$E4,$E5,$20,$E6,$E7,$E8
	.byte $E9,$EA,$1F,$07,$0F,$EB,$EC,$ED
	.byte $EE
string2:
//$2EA9		string_t[12]  Message string #2
	.byte $0B,$1F,$07,$0F,$11,$04,$EF,$F0
	.byte $20,$20,$F1,$F2
string3:
//$2EB5		string_t[64]  Message string #3
//Planetoid Hall of Fame - double height
	.byte $3F,$16,$07,$81,$9D,$83,$8D,$1F
	.byte $09,$00,$50,$6C,$61,$6E,$65,$74
	.byte $6F,$69,$64,$20,$48,$61,$6C,$6C
	.byte $20,$6F,$66,$20,$46,$61,$6D,$65
	.byte $1F,$00,$01,$81,$9D,$83,$8D,$1F
	.byte $09,$01,$50,$6C,$61,$6E,$65,$74
	.byte $6F,$69,$64,$20,$48,$61,$6C,$6C
	.byte $20,$6F,$66,$20,$46,$61,$6D,$65
string4:
//$2EF5		string_t[68]  Message string #4
//Congratulations - double height
	.byte $43,$1F,$0B,$03,$86,$8D,$43,$6F
	.byte $6E,$67,$72,$61,$74,$75,$6C,$61
	.byte $74,$69,$6F,$6E,$73,$1F,$0B,$04
	.byte $86,$8D,$43,$6F,$6E,$67,$72,$61
	.byte $74,$75,$6C,$61,$74,$69,$6F,$6E
	.byte $73,$1F,$08,$17,$86,$88,$50,$6C
//Please enter your name	
	.byte $65,$61,$73,$65,$20,$65,$6E,$74
	.byte $65,$72,$20,$79,$6F,$75,$72,$20
	.byte $6E,$61,$6D,$65
string5:
//$2F39		string_t[6]  Message string #5
	.byte $05,$20,$2E,$2E,$2E,$20
string6:
//$2F3F		string_t[81]  Message string #6
//Today's Greatest
	.byte $50,$1F,$0A,$03,$8D,$86,$54,$6F
	.byte $64,$61,$79,$27,$73,$20,$47,$72
	.byte $65,$61,$74,$65,$73,$74,$1F,$0A
	.byte $04,$8D,$86,$54,$6F,$64,$61,$79
	.byte $27,$73,$20,$47,$72,$65,$61,$74
	.byte $65,$73,$74,$1F,$02,$17,$86,$88
//Press the SPACE BAR 
//to play again
	.byte $50,$72,$65,$73,$73,$20,$74,$68
	.byte $65,$20,$53,$50,$41,$43,$45,$20
	.byte $42,$41,$52,$20,$74,$6F,$20,$70
	.byte $6C,$61,$79,$20,$61,$67,$61,$69
	.byte $6E
//$2F90
	.byte $30,$20,$20,$30,$00,$00,$30,$00
	.byte $20,$20,$20,$20,$20,$20,$20,$00

	.byte $CC,$CD,$CD,$CC,$F3,$51,$51,$51
	.byte $00,$10,$10,$C3,$C3,$10,$10,$00

	.byte $82,$92,$92,$C3,$C3,$92,$92,$82
	.byte $00,$00,$00,$82,$82,$00,$00,$00

	.byte $15,$3F,$15,$11,$11,$11,$33,$11
	.byte $00,$2A,$3F,$3F,$37,$33,$33,$33

	.byte $00,$00,$00,$2A,$3F,$3F,$3F,$37
	.byte $00,$00,$00,$00,$00,$3F,$3F,$3F

	.byte $00,$00,$00,$00,$00,$07,$07,$3F
	.byte $00,$00,$00,$00,$00,$08,$1D,$3F
	
	.byte $00,$00,$00,$00,$00,$04,$2E,$3F
	.byte $00,$00,$00,$00,$00,$0B,$0B,$3F