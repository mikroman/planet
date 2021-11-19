StringV_l:
		//LSB of string pointers
	.byte <string0,<string1,<string2,<string3,<string4,<string5,<string6
StringV_h:
		//MSB of string pointers
	.byte >string0,>string1,>string2,>string3,>string4,>string5,>string6
string0:
		//Message string #0
		//length,text clr,restore default pallete
	.byte $02,$0C,$14
string1:
		//Message string #1
		//length,txt clr,PAL_FLASH,cursor,(4,12)
	.byte $18,$11,$04,$1F,$04,$0C,$E0,$E1
	.byte $E2,$E3,$E4,$E5,$20,$E6,$E7,$E8
	.byte $E9,$EA
		//cursor,(7,15)
	.byte $1F,$07,$0F,$EB,$EC,$ED,$EE
string2:
		//Message string #2
		//length,cursor,(7,15),txt clr #4
	.byte $0B,$1F,$07,$0F,$11,$04,$EF,$F0
	.byte $20,$20,$F1,$F2
string3:
		//Message string #3
		//length,mode,7,double height
	.byte $1B,$16,$07
	.byte $1F,$05,$00
		//cursor,(5,0)
		//Planetoid Hall of Fame
	.byte $50,$6C,$61,$6E,$65,$74,$6F,$69
	.byte $64,$20,$48,$61,$6C,$6C,$20,$6F
	.byte $66,$20,$46,$61,$6D,$65
string4:
		//Message string #4
		//length,cursor,(11,3)
	.byte $24,$1F,$08,$03
		//Congratulations
	.byte $43,$6F,$6E,$67,$72,$61,$74,$75
	.byte $6C,$61,$74,$69,$6F,$6E,$73
		//cursor,(8,23)
	.byte $1F,$08,$17
		//enter your name	
	.byte $65
	.byte $6E,$74,$65,$72,$20,$79,$6F,$75
	.byte $72,$20,$6E,$61,$6D,$65
string5:
		//Message string #5
		//length,' ... '
	.byte $05,$20,$2E,$2E,$2E,$20
string6:
		//Message string #6
		//length,cursor,(10,3)
	.byte $2B,$1F,$0A,$04
		//Today's Hi
	.byte $54,$6F,$64,$61,$79,$27,$73,$20
	.byte $48,$69
		//cursor,(2,23),flashing
	.byte $1F,$02,$17,$86,$88
		//Press SPACE to play again
	.byte $50,$72,$65,$73,$73
	.byte $20,$53,$50,$41,$43,$45,$20
	.byte $74,$6F,$20,$70
	.byte $6C,$61,$79,$20,$61,$67,$61,$69
	.byte $6E
