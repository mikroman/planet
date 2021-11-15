// Acornsoft Planetoid, BBC Micro
// Written by Neil Raine, 1982
// 6502 disassembly by rainbow
// 2020.02.08
// <djrainbow50@gmail.com>
// https://github.com/r41n60w/planetoid-disasm
// https://github.com/mikroman/planet (Kick Assembler version by)

#import "constants.asm"
#import "labels.asm"

*=$1100 "Game"

	jmp Boot

IRQHook:

	lda #%00000010
	bit SYS6522 + 13	//systemVIA Interrupt Flag Register
	beq L_BRS_110D_1108

VsyncAddress1:

	inc vsync 

L_BRS_110D_1108:

	jmp (_irq1v)

WaitVSync:

	lda vsync 
	cmp _vsync0 
	beq WaitVSync
	sta _vsync0 
	rts 

IsVSync:

	lda vsync 
	cmp _vsync0 
	rts 

SetPallette:

	pha 
	eor #%00000111		//top four bits define logical colour field, bottom four bits are the physical colour EOR 7.
	sta ULAPALETTE		//videoULAPaletteRegister
	pla 
	rts 

Out6845:

	stx SHEILA			//crtcAddressRegister
	sta SHEILA + 1		//crtcAddressWrite
	rts 

StartTimer:

	lda #%10000000		//one shot mode
	sta USR6522 + 11	//userVIAAuxiliaryControlRegister:
	stx USR6522 + 4		//userVIATimer1CounterLow=#$80
	sty USR6522 + 5		//userVIATimer1CounterHigh=#$14
	rts 

TimerState:

	bit USR6522			//userVIARegisterB (input/output)
	rts 

AIBatch:

	ldx #$00
	jsr GetXScreen
	sta _ship_xscr
	lda #$00
	sta _min_xscr
	lda #$4D
	sta _max_xscr
	lda  _scrolloff_l
	bpl L_BRS_1159_1150
	clc 
	adc #$4D
	sta _max_xscr
	bne L_BRS_115B_1157

L_BRS_1159_1150:

	sta _min_xscr

L_BRS_115B_1157:

	lda _batch
	sta _batchc
	ldx _id

L_BRS_1161_117F:

	jsr AIUnit
	ldx _id

L_BRS_1166_1169:

	inx 
	cpx #HITCH
	beq L_BRS_1166_1169
	cpx #ID_MAX + 1
	bne L_BRS_1178_116D
	ldx #ID_MIN
	lda Anim 
	beq L_BRS_1178_1174
	ldx #SHIP

L_BRS_1178_116D:
L_BRS_1178_1174:

	stx _id
	jsr IsVSync
	dec _batchc
	bne L_BRS_1161_117F
	rts 

AIAlt:

	ldx _id_alt
	jsr AIUnit
	inx 
	cpx #ID_ALT3 + 1
	bne L_BRS_118E_118A
	ldx #ID_ALT1

L_BRS_118E_118A:

	stx _id_alt
	rts 

AIUnit:

	lda Unit,X 
	bpl L_BRS_11BB_1194
	asl 
	tay 
	bmi L_BRS_11BB_1198
	lsr 
	sta Unit,X 
	lda Anim,X 
	beq L_BRS_11AE_11A1
	bmi L_BRS_11AB_11A3
	jsr AnimFrame
	jmp MMUpdate

L_BRS_11AB_11A3:

	jmp AnimFrame

L_BRS_11AE_11A1:	//M $2E05
	// .byte $BC,$11,$DA,$11,$61,$13,$F8,$13
	// .byte $2D,$14,$36,$14,$B1,$14,$68,$15
	// .byte $BF,$11,$BF,$11,$BF,$11,$00,$00

	lda AiVector,Y 
	sta _destptr_l 
	lda AiVector + 1,Y 
	sta _destptr_h 
	jmp (_destptr) 

L_BRS_11BB_1194:
L_BRS_11BB_1198:

	rts

AIShip:	 

	jmp MoveUnit

AIKugel:
AI250:
AI500:
AIObject:

	ldy Param,X 
	iny 
	tya 
	sta Param,X 
	cpy #$A0
	bne L_BRS_11CE_11C9
	jmp EraseUnit

L_BRS_11CE_11C9:

	jsr MoveUnit
	lda pNext_h,X 
	bne L_BRS_11D9_11D4
	jmp EraseUnit

L_BRS_11D9_11D4:

	rts

AILander:

	lda  _humanc
	bne L_BRS_11E9_11DC
	jsr EraseUnit
	lda #MUTANT
	sta Unit,X 
	jmp AIMutant

L_BRS_11E9_11DC:

	lda #$0A
	jsr ShootChance
	lda Param,X 
	pha 
	and #%00111111
	tay 
	pla 
	bne L_BRS_11FB_11F6
	jmp J1VE

L_BRS_11FB_11F6:

	bmi L_BRS_1235_11FB
	lda Y_h,X 
	cmp #$BE
	bcc L_BRS_1227_1202
	lda #MAN
	jsr IsLinked
	bne L_BRS_122A_1209
	tya 
	tax 
	jsr KillUnit
	ldx _id
	jsr EraseUnit
	lda #MUTANT
	sta Unit,X 
	jmp AIMutant

L_BRS_121D_126D:
L_BRS_121D_1274:

	ldy #LANDER
	jsr InitDXY

L_BRS_1222_1240:

	lda #$00
	sta Param,X 

L_BRS_1227_1202:

	jmp AIUpdate

L_BRS_122A_1209:

	jsr EraseUnit
	lda #LANDER
	sta Unit,X 
	jmp InitUnit

L_BRS_1235_11FB:

	lda Param,X 
	asl 
	bmi L_BRS_1266_1239
	lda #MAN
	jsr IsUnlinked
	bne L_BRS_1222_1240
	lda X_h,X 
	cmp X_h,Y 
	beq L_BRS_124D_1248
	jmp J1VF

L_BRS_124D_1248:

	lda #$FC
	sta dY_h,X 
	lda dX_l,Y 
	sta dX_l,X 
	lda dX_h,Y 
	sta dX_h,X 
	lda Param,X 
	ora #%01000000
	sta Param,X 

L_BRS_1266_1239:

	lda Unit,Y 
	and #%01111111
	cmp #MAN
	bne L_BRS_121D_126D
	lda Param,Y 
	and #%11000000
	bne L_BRS_121D_1274
	lda Param,Y 
	beq L_BRS_1286_1279
	lda #$00
	sta dY_l,X 
	sta dY_h,X 
	jmp AIUpdate

L_BRS_1286_1279:

	lda Y_h,X 
	sec 
	sbc #$0A
	cmp Y_h,Y 
	bcs L_BRS_12CF_128F
	sta Y_h,Y 
	lda dXMinInit + LANDER
	lsr 
	lsr 
	sec 
	sbc #$01
	sta dY_h,X 
	sta dY_h,Y 
	lda #$00
	sta dY_l,X 
	sta dY_l,Y 
	sta dX_l,X 
	sta dX_h,X 
	sta dX_l,Y 
	sta dX_h,Y 
	clc 
	lda X_l,X 
	adc #$80
	sta X_l,Y 
	lda X_h,X 
	adc #$00
	sta X_h,Y 
	tya 
	sta Param,X 
	txa 
	sta Param,Y 

L_BRS_12CF_128F:

	jmp AIUpdate

J1VE:

	jsr Random
	and #%00011111
	cmp #$20
	bcs J1VE
	cmp #ID_MIN
	bcc J1VE
	tay 
	lda #MAN
	jsr IsUnlinked
	bne J1VF
	sec 
	lda X_h,Y 
	sbc X_h,X 
	sta _temp 
	lda dX_h,X 
	asl 
	lda _temp 
	bcc L_BRS_12FC_12F6
	lda #$00
	sbc _temp 

L_BRS_12FC_12F6:

	cmp #$32
	bcs J1VF
	tya 
	ora #%10000000
	sta Param,X 

J1VF:

	lda dX_l,X 
	sta _temp_l 
	lda dX_h,X //DIFF
	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	sta _temp_h 
	jsr GetYSurf
	sta _temp_l 
	sec 
	lda Y_h,X 
	sbc _temp_l 
	cmp #$14
	bcc MoveUp
	cmp #$1E
	bcs MoveDown
	jmp AIUpdate

MoveUp:

	bit _temp_h 
	bpl L_BRS_134D_1331
	bmi L_BRS_1339_1333

MoveDown:

	bit _temp_h 
	bmi L_BRS_134D_1337

L_BRS_1339_1333:

	sec 
	lda Y_l,X 
	sbc _temp_l 
	sta Y_l,X 
	lda Y_h,X 
	sbc _temp_h 
	sta Y_h,X 
	jmp AIUpdate

L_BRS_134D_1331:
L_BRS_134D_1337:

	clc 
	lda Y_l,X 
	adc _temp_l 
	sta Y_l,X 
	lda Y_h,X 
	adc _temp_h 
	sta Y_h,X 
	jmp AIUpdate

AIMutant:

	lda #$19
	jsr ShootChance
	lda pSprite_h,X 
	beq L_BRS_1377_1369
	jsr Random
	cmp #$14
	bcs L_BRS_1377_1370
	lda #$10
	jsr PlaySound

L_BRS_1377_1369:
L_BRS_1377_1370:

	jsr GetXDisph
	cmp #$0A
	bpl L_BRS_13B3_137C
	cmp #$EC
	bmi L_BRS_13CA_1380

L_BRS_1382_13BC:

	jsr ABSYDisp

J1385:

	ldy #$06
	lda #$00
	bcs L_BRS_138F_1389
	ldy #$FA
	lda #$00

L_BRS_138F_1389:

	sta dY_l,X 
	tya 
	sta dY_h,X 

J1396:

	sec 
	lda X_h + SHIP 
	sbc X_h,X 
	php 
	ldy #$03
	lda #$50
	plp 
	bpl L_BRS_13A9_13A3
	ldy #$FD
	lda #$B0

L_BRS_13A9_13A3:

	sta dX_l,X 
	tya 
	sta dX_h,X 
	jmp AIUpdate

L_BRS_13B3_137C:

	cmp #$32
	bpl L_BRS_13CA_13B5
	jsr ABSYDisp
	cmp #$28
	bcs L_BRS_1382_13BC
	jsr ABSYDisp
	php 
	pla 
	eor #%00000001
	pha 
	plp 
	jmp J1385

L_BRS_13CA_1380:
L_BRS_13CA_13B5:

	jsr Random
	and #$01
	pha 
	plp 
	jmp J1385

GetXDisph:

	ldy X_h + SHIP 
	lda _ddx_h
	asl 
	lda X_h,X 
	bcc L_BRS_13E3_13DD
	tya 
	ldy X_h,X 

L_BRS_13E3_13DD:

	sty _temp 
	sec 
	sbc _temp 
	rts 

ABSYDisp:

	sec 
	lda Y_h,X 
	sbc Y_h + SHIP 
	pha 
	asl 
	pla 
	bpl L_BRS_13F7_13F3
	eor #%11111111

L_BRS_13F7_13F3:

	rts

AIBaiter:	 

	lda #$28
	jsr ShootChance
	lda Param,X 
	beq L_BRS_1408_1400
	dec Param,X 
	jmp AIUpdate

L_BRS_1408_1400:

	jsr Random
	and #%00000111
	clc 
	adc #$0A
	sta Param,X 
	txa 
	tay 
	jsr TargetShip
	asl dY_l,X 
	rol dY_h,X 
	asl dX_l,X 
	rol dX_h,X 
	asl dX_l,X 
	rol dX_h,X 
	jmp AIUpdate

AIBomber:	

	jsr MineChance
	jsr DYSine
	jmp AIUpdate

AISwarmer:	

	jsr DYSine
	sec 
	lda X_h,X 
	sbc X_h + SHIP 
	sta _temp 
	eor dX_h,X 
	bmi L_BRS_1457_1445
	lda _temp 
	bpl L_BRS_144D_1449
	eor #%11111111

L_BRS_144D_1449:

	cmp #$14
	bcs L_BRS_1454_144F
	jmp AIUpdate

L_BRS_1454_144F:

	jmp J1396

L_BRS_1457_1445:

	lda pSprite_h,X 
	beq L_BRS_1468_145A
	jsr Random
	cmp #$0F
	bcs L_BRS_1468_1461
	lda #$13
	jsr PlaySound

L_BRS_1468_145A:
L_BRS_1468_1461:

	lda #$1E
	jsr ShootChance
	jmp AIUpdate

DYSine:

	lda #$00
	sta _temp 
	lda Y_h,X 
	sec 
	sbc #$62
	bcs L_BRS_1497_147A
	eor #%11111111
	clc 
	adc #$01
	asl 
	rol _temp 
	asl 
	rol _temp 
	clc 
	adc dY_l,X 
	sta dY_l,X 
	lda _temp 
	adc dY_h,X 
	sta dY_h,X 
	rts 

L_BRS_1497_147A:

	asl 
	rol _temp 
	asl 
	rol _temp 
	sta _temp2
	sec 
	lda dY_l,X 
	sbc _temp2 
	sta dY_l,X 
	lda dY_h,X 
	sbc _temp 
	sta dY_h,X 
	rts

AIHuman:	 

	lda Param,X 
	bne L_BRS_14B9_14B4
	jmp Walk

L_BRS_14B9_14B4:

	bmi L_BRS_14C6_14B9
	tay 
	lda #LANDER
	jsr IsLinked
	bne L_BRS_14FC_14C1
	jmp AIUpdate

L_BRS_14C6_14B9:

	asl 
	bmi L_BRS_1509_14C7
	stx _xreg
	ldx #HITCH
	jsr GetYSurf
	ldx _xreg
	cmp Y_h + HITCH 
	bcs L_BRS_14D8_14D5
	rts 

L_BRS_14D8_14D5:

	dec  _hikerc
	lda X_h + HITCH 
	sta X_h,X 
	lda Y_h + HITCH 
	sta Y_h,X 
	lda #$00
	sta dY_h,X 
	sta dY_l,X 
	sta Param,X 
	lda #$0F
	jsr PlaySound
	jsr Score500
	jmp AIUpdate

L_BRS_14FC_14C1:

	lda #$FF
	sta Param,X 
	lda #$00
	sta dY_l,X 
	sta dY_h,X 

L_BRS_1509_14C7:

	sec 
	lda dY_l,X 
	sbc #$40
	sta dY_l,X 
	lda dY_h,X 
	sbc #$00
	sta dY_h,X 
	jsr GetYSurf
	cmp Y_h,X 
	bcc AIUpdate
	lda dY_h,X 
	cmp #$FB
	bcs L_BRS_152C_1527
	jmp KillUnit

L_BRS_152C_1527:

	lda #$00
	sta Param,X 
	ldy #MAN
	jsr InitDXY
	lda #$0F
	jsr PlaySound
	jmp Score250

Walk:

	lda dX_l,X 
	sta _temp_l 
	lda dX_h,X 
	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	sta _temp2 
	jsr GetYSurf
	sec 
	sbc Y_h,X 
	cmp #$04
	bmi L_BRS_1565_155A
	cmp #$08
	bpl L_BRS_1562_155E
	bmi AIUpdate

L_BRS_1562_155E:

	jmp MoveUp

L_BRS_1565_155A:

	jmp MoveDown

AIUpdate:
AIPod:

	ldx _id
	jsr MoveUnit
	ldx _id
	jmp MMUpdate

PlaySound:

	sta _temp
	txa 
	pha 
	tya 
	pha 
	ldx _temp 
	lda HoldSync,X 
	sta _temp 

L_BRS_157F_15AF:

	lda HoldSync,X 
	sta ParamBlk + 1 
	lda FlushChan,X 
	sta ParamBlk 
	ldy #$02
	lda AmplEnvel,X 
	jsr InsParam
	lda Pitch,X 
	jsr InsParam
	lda Duration,X
	jsr InsParam
	txa 
	pha 
	ldx #$80
	ldy #$2C		//8 byte parameter block
	lda #$07		//short tone
	jsr OSWORD
	pla 
	tax 
	inx 
	dec _temp 
	bpl L_BRS_157F_15AF
	pla 
	tay 
	pla 
	tax 
	rts 

InsParam:

	sta ParamBlk,Y 
	iny 
	asl 
	lda #$00
	bcc L_BRS_15C1_15BD
	lda #$FF

L_BRS_15C1_15BD:

	sta ParamBlk,Y 
	iny 
	rts 

RepaintMap:

	lda _min_xscr
	pha 
	lda _max_xscr
	pha 
	lda #$00
	sta _min_xscr
	lda #$50
	sta _max_xscr
	ldx #$1F

L_BRS_15D6_161D:

	stx _xreg
	lda Unit,X 
	bpl L_BRS_161A_15DB
	asl 
	bmi L_BRS_161A_15DE
	ldy pDot_l,X 
	sty _destptr_l 
	ldy pDot_h,X 
	beq L_BRS_161A_15E8
	sty _destptr_h 
	lda Dot,X 
	tax 
	stx _yreg
	jsr MMBlit
	ldx _xreg
	clc 
	lda _destptr_l 
	adc  _scrolloff_l
	sta _destptr_l 
	sta pDot_l,X 
	lda _destptr_h 
	adc _scrolloff_h 
	bpl L_BRS_160A_1605
	sec 
	sbc #$50

L_BRS_160A_1605:

	cmp #$30
	bcs L_BRS_1610_160C
	adc #$50

L_BRS_1610_160C:

	sta _destptr_h 
	sta pDot_h,X 
	ldx _yreg
	jsr MMBlit

L_BRS_161A_15DB:
L_BRS_161A_15DE:
L_BRS_161A_15E8:

	ldx _xreg
	dex 
	bpl L_BRS_15D6_161D
	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

MMBlit:

	lda _destptr_h 
	bne L_BRS_162B_1628
	rts 

L_BRS_162B_1628:

	ldy #$00
	lda (_destptr),Y 
	eor imgDot,X 
	sta (_destptr),Y 
	lda _destptr_h 
	sta _srcptr_h 
	lda _destptr_l 
	sta _srcptr_l 
	and #%00000111
	cmp #$07
	bne L_BRS_1654_1640
	clc 
	lda _srcptr_l 
	adc #$78
	sta _srcptr_l 
	lda _srcptr_h 
	adc #$02
	bpl L_BRS_1652_164D
	sec 
	sbc #$50

L_BRS_1652_164D:

	sta _srcptr_h 

L_BRS_1654_1640:

	iny 
	lda (_srcptr),Y 
	eor imgDot + 1,X 
	sta (_srcptr),Y 
	rts 

MMUpdate:

	jsr TimerState
	bpl MMUpdate
	cpx #ID_MAX + 1
	bcc L_BRS_1667_1664
	rts 

L_BRS_1667_1664:

	lda _min_xscr
	pha 
	lda _max_xscr
	pha 
	txa 
	pha 
	lda #$00
	sta _min_xscr
	lda #$50
	sta _max_xscr
	lda pDot_l,X 
	sta _destptr_l 
	lda pDot_h,X 
	sta _destptr_h 
	lda Dot,X 
	tax 
	jsr MMBlit
	pla 
	pha 
	tax 
	lda Y_h,X 
	lsr 
	lsr 
	clc 
	adc #$C4
	tay 
	sec 
	lda X_l,X 
	sbc _xrel_l
	lda X_h,X 
	sbc _xrel_h
	clc 
	adc #$6C
	lsr 
	lsr 
	php 
	clc 
	adc #$08
	tax 
	jsr XYToVidP
	plp 
	pla 
	tax 
	php 
	lda _destptr_l 
	sta pDot_l,X 
	lda _destptr_h 
	sta pDot_h,X 
	lda Unit,X 
	asl 
	plp 
	bcc L_BRS_16C3_16BF
	adc #$15

L_BRS_16C3_16BF:

	sta Dot,X 
	tax 
	jsr MMBlit
	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

KeyFire:

	ldx #KEY_RETURN		//Return key
	jsr ScanInkey
	beq L_BRS_16DA_16D6
	eor _inkey_enter

L_BRS_16DA_16D6:

	stx _inkey_enter
	beq L_BRS_16E7_16DC
	ldx #$03

L_BRS_16E0_16E5:

	lda _Laser,X 
	beq L_BRS_16E8_16E2
	dex 
	bpl L_BRS_16E0_16E5

L_BRS_16E7_16DC:

	rts 

L_BRS_16E8_16E2:

	stx _xreg
	lda Y_h + SHIP 
	sec 
	sbc #$06
	tay 
	ldx #SHIP
	jsr GetXScreen
	tax 
	dex 
	lda #$81
	bit _ddx_h
	bmi L_BRS_1705_16FC
	txa 
	clc 
	adc #$07
	tax 
	lda #$01

L_BRS_1705_16FC:

	pha 
	txa 
	pha 
	tya 
	pha 
	jsr XYToVidP
	ldx _xreg
	lda _destptr_l 
	sta _pTail_l,X 
	sta _pHead_l,X 
	lda _destptr_h 
	sta _pTail_h,X 
	sta _pHead_h,X 
	pla 
	sta _BeamY,X 
	pla 
	sta _BeamX,X 
	pla 
	sta _Laser,X 
	lda #$00
	sta _Tail,X 
	sta _Head,X 
	lda #$04
	jmp PlaySound

DoLaser:

	ldx #$03

LZRight:

	lda #$08
	sta _offset_l 
	lda #$00
	sta _offset_h 
	lda _dxwin
	ldy _Laser,X 
	bpl L_BRS_174C_173D
	lda #$F8
	sta _offset_l 
	lda #$FF
	sta _offset_h 
	sec 
	lda #$00
	sbc _dxwin

L_BRS_174C_173D:

	sta  _dxedge
	sec 
	lda _BeamX,X 
	sbc _dxwin
	sta _BeamX,X 
	lda _Laser,X 
	bne L_BRS_175C_1757
	jmp LaserNext

L_BRS_175C_1757:

	lda _pHead_l,X 
	sta _destptr_l 
	lda _pHead_h,X 
	sta _destptr_h 
	clc 
	lda #$04
	adc  _dxedge
	sta _laserc

L_BRS_176B_1799:

	lda _BeamX,X 
	ldy _Laser,X 
	bmi L_BRS_1779_176F
	cmp _max_xscr
	bpl EraseLaser
	inc _BeamX,X 
	bne L_BRS_177F_1777

L_BRS_1779_176F:

	cmp _min_xscr
	bmi EraseLaser
	dec _BeamX,X 

L_BRS_177F_1777:

	ldy _Head,X 
	jsr BlitLaser
	sta _Head,X 
	jsr NextPtr
	ldy #$00
	lda (_destptr),Y 
	and #%11000000
	beq L_BRS_1797_178F
	jsr LaserHit
	bcs L_BRS_1797_1794
	rts 

L_BRS_1797_178F:
L_BRS_1797_1794:

	dec _laserc
	bne L_BRS_176B_1799
	lda _destptr_l 
	sta _pHead_l,X 
	lda _destptr_h 
	sta _pHead_h,X 
	bne L_BRS_17DC_17A3

EraseLaser:

	lda _destptr_l 
	sta _srcptr_l 
	lda _destptr_h 
	sta _srcptr_h 
	lda _pTail_l,X 
	sta _destptr_l 
	lda _pTail_h,X 
	sta _destptr_h 
	lda #NULL
	sta _Laser,X 
	lda _Tail,X 
	tax 
	ldy #$00

L_BRS_17BE_17D3:
L_BRS_17BE_17D9:

	inx 
	lda ImgLaser,X 
	eor (_destptr),Y 
	sta (_destptr),Y 
	cpx #$50
	bne L_BRS_17CC_17C8
	ldx #$4F

L_BRS_17CC_17C8:

	jsr NextPtr
	lda _destptr_l 
	cmp _srcptr_l 
	bne L_BRS_17BE_17D3
	lda _destptr_h 
	cmp _srcptr_h 
	bne L_BRS_17BE_17D9
	rts 

L_BRS_17DC_17A3:

	lda _pTail_l,X 
	sta _destptr_l 
	lda _pTail_h,X 
	sta _destptr_h 
	clc 
	lda #$01
	adc  _dxedge
	sta _laserc
	beq LaserNext
	bmi LaserNext

L_BRS_17EF_17FB:

	ldy _Tail,X 
	jsr BlitLaser
	sta _Tail,X 
	jsr NextPtr
	dec _laserc
	bne L_BRS_17EF_17FB
	lda _destptr_l 
	sta _pTail_l,X 
	lda _destptr_h 
	sta _pTail_h,X 

LaserNext:

	dex 
	bmi L_BRS_180B_1806
	jmp LZRight

L_BRS_180B_1806:

	rts 

LaserHit:

	lda _destptr_l 
	pha 
	lda _destptr_h 
	pha 
	lda _offset_l 
	pha 
	lda _offset_h 
	pha 
	lda _BeamX,X 
	jsr LZCollide
	pla 
	sta _offset_h 
	pla 
	sta _offset_l 
	pla 
	sta _destptr_h 
	pla 
	sta _destptr_l 
	bcs L_BRS_1833_1829
	txa 
	pha 
	jsr EraseLaser
	pla 
	tax 
	clc 

L_BRS_1833_1829:

	rts 

BlitLaser:

	iny 
	tya 
	pha 
	lda ImgLaser,Y 
	ldy #$00
	eor (_destptr),Y 
	sta (_destptr),Y 
	pla 
	cmp #$50
	bne L_BRS_1847_1843
	lda #$4F

L_BRS_1847_1843:

	rts 

NextPtr:

	clc 
	lda _destptr_l 
	adc _offset_l 
	sta _destptr_l 
	lda _destptr_h 
	adc _offset_h 
	bpl L_BRS_1857_1853
	lda #$30

L_BRS_1857_1853:

	cmp #$30
	bcs L_BRS_185D_1859
	adc #$50

L_BRS_185D_1859:

	sta _destptr_h 
	rts 

LZCollide:

	cmp #$50
	bcc L_BRS_1865_1862
	rts 

L_BRS_1865_1862:

	stx _xreg
	sta _anim_xscr 
	lda _BeamY,X 
	sta _beam_yscr
	ldx #$02

L_BRS_186F_18E3:

	lda pSprite_h,X 
	beq L_BRS_18E0_1872
	lda Y_h,X 
	sec 
	sbc _beam_yscr
	cmp #$08
	bcs L_BRS_18E0_187C
	lda pSprite_l,X 
	and #%11111000
	sta _temp 
	sec 
	lda _destptr_l 
	and #%11111000
	sbc _temp 
	sta _offset_l 
	lda _destptr_h 
	sbc pSprite_h,X 
	bpl L_BRS_1898_1893
	clc 
	adc #$50

L_BRS_1898_1893:

	lsr 
	ror _offset_l 
	lsr 
	ror _offset_l 
	lsr 
	ror _offset_l 
	sta _offset_h 
	sec 

L_BRS_18A4_18B0:

	lda _offset_l 
	sbc #$50
	sta _offset_l 
	lda _offset_h 
	sbc #$00
	sta _offset_h 
	bcs L_BRS_18A4_18B0
	lda _offset_l 
	adc #$50
	cmp #$04
	bcs L_BRS_18E0_18B8
	lda Anim,X 
	bne L_BRS_18E0_18BD
	lda Unit,X 
	asl 
	bmi L_BRS_18E0_18C3
	lsr 
	cmp #MAN
	bne L_BRS_18D1_18C8
	lda Param,X 
	cmp #$80
	beq L_BRS_18E0_18CF

L_BRS_18D1_18C8:

	lda #$03
	jsr PlaySound
	jsr ScoreUnit
	jsr KillUnit
	ldx _xreg
	clc 
	rts 

L_BRS_18E0_1872:
L_BRS_18E0_187C:
L_BRS_18E0_18B8:
L_BRS_18E0_18BD:
L_BRS_18E0_18C3:
L_BRS_18E0_18CF:

	inx 
	cpx #$20
	bne L_BRS_186F_18E3
	ldx _xreg
	sec 
	rts 

KillUnit:

	lda Unit,X 
	and #%01111111
	cmp #KUGEL
	bcs EraseUnit
	cmp #BAITER
	beq KillU2
	pha 
	jsr KillU2
	pla 
	bcs L_BRS_1903_18FB
	cmp #MAN
	beq L_BRS_1904_18FF
	dec _enemyc

L_BRS_1903_18FB:
L_BRS_1903_190B:
L_BRS_1903_1918:

	rts 

L_BRS_1904_18FF:

	lda #$0A
	jsr PlaySound
	dec  _humanc
	bne L_BRS_1903_190B
	jmp RMSurface

KillU2:

	lda Unit,X 
	pha 
	jsr EraseUnit
	pla 
	bcs L_BRS_1903_1918
	sta Unit,X 
	lda #BLAST
	sta Anim,X 
	lda #$08
	sta Param,X 
	rts 

EraseUnit:

	txa 
	pha 
	lda Unit,X 
	asl 
	bmi L_BRS_199F_192E
	cpx #$20
	bcs L_BRS_194C_1932
	ldy pDot_l,X 
	sty _destptr_l 
	ldy pDot_h,X 
	sty _destptr_h 
	beq L_BRS_194C_193E
	lda #NULL
	sta pDot_h,X 
	lda Dot,X 
	tax 
	jsr MMBlit

L_BRS_194C_1932:
L_BRS_194C_193E:

	pla 
	pha 
	tax 
	lda Anim,X 
	bne L_BRS_1967_1952
	lda pSprite_l,X 
	sta _destptr_l 
	lda pSprite_h,X 
	sta _destptr_h 
	lda Unit,X 
	and #%01111111
	tax 
	jsr XBLTSprite

L_BRS_1967_1952:

	pla 
	tax 
	jsr ClearData
	lda Unit,X 
	and #%01111111
	cmp #POD
	bne L_BRS_1998_1973
	lda X_h,X 
	sta XMinInit + SWARMER
	lda Y_h,X 
	sec 
	sbc #$08
	sta YMinInit + SWARMER
	jsr Random
	and #%00000111
	clc 
	adc #$05
	sta Spawnc + SWARMER 
	txa 
	pha 
	lda #(SWARMER|$80)
	jsr MSpawn
	pla 
	tax 

L_BRS_1998_1973:

	lda #$FF
	sta Unit,X 
	clc 
	rts 

L_BRS_199F_192E:

	pla 
	tax 
	sec 
	rts 

MSpawn:

	sta _spawn_spr
	and #%01111111
	tay 
	lda Spawnc,Y 
	beq L_BRS_19F0_19AB
	sta _count
	cpy #LANDER
	bne L_BRS_19B9_19B1
	lda  _humanc
	bne L_BRS_19B9_19B5
	ldy #MUTANT

L_BRS_19B9_19B1:
L_BRS_19B9_19B5:
L_BRS_19B9_19EE:

	jsr MSPWFrame
	ldx #ID_MIN

L_BRS_19BE_19E2:
L_BRS_19BE_19EA:

	lda Unit,X 
	asl 
	bpl L_BRS_19DB_19C2
	tya 
	ora #$80
	sta Unit,X 
	jsr InitUnit
	cpy #BAITER
	beq L_BRS_19D7_19CF
	cpy #MAN
	beq L_BRS_19D7_19D3
	inc _enemyc

L_BRS_19D7_19CF:
L_BRS_19D7_19D3:

	dec _count
	beq L_BRS_19F0_19D9

L_BRS_19DB_19C2:

	txa 
	clc 
	adc #$05
	tax 
	cpx #ID_MAX + 1
	bcc L_BRS_19BE_19E2
	sec 
	sbc #$1D
	tax 
	cpx #$07
	bne L_BRS_19BE_19EA
	bit _spawn_spr
	bpl L_BRS_19B9_19EE

L_BRS_19F0_19AB:
L_BRS_19F0_19D9:

	rts 

MSPWFrame:

	lda _spawn_spr
	bmi L_BRS_1A06_19F3
	pha 
	lda _count
	pha 
	tya 
	pha 
	jsr Frame
	pla 
	tay 
	pla 
	sta _count
	pla 
	sta _spawn_spr

L_BRS_1A06_19F3:

	rts 

SpawnBait:

	dec _baitdelay_l
	bne L_BRS_1A23_1A09
	dec _baitdelay_h
	bne L_BRS_1A23_1A0D
	lda #$01
	sta Spawnc + BAITER 
	lda X_h + SHIP 
	sta XMinInit +  BAITER
	lda #($80|BAITER)
	jsr MSpawn
	lda #$02
	sta _baitdelay_h

L_BRS_1A23_1A09:
L_BRS_1A23_1A0D:

	rts 

InitUnit:

	lda Unit,X 
	asl 
	php 
	lsr 
	tay 
	jsr ClearData
	sta pDot_h,X 
	plp 
	bpl L_BRS_1A35_1A32
	rts 

L_BRS_1A35_1A32:

	lda DoWarp,Y 
	beq L_BRS_1A44_1A38
	lda #$01
	sta Anim,X 
	lda #$08
	sta Param,X 

L_BRS_1A44_1A38:

	jsr Random
	and XRangeInit,Y 
	clc 
	adc XMinInit,Y 
	sta X_h,X 
	jsr Random
	and YRangeInit,Y 
	clc 
	adc YMinInit,Y 
	cmp #$C0
	bcc L_BRS_1A61_1A5D
	sbc #$C0

L_BRS_1A61_1A5D:

	sta Y_h,X 

InitDXY:

	jsr Random
	and dXRangeInit,Y 
	clc 
	adc dXMinInit,Y 
	jsr ToVelocity
	sta dX_l,X 
	lda _temp_h 
	sta dX_h,X 
	jsr Random
	and dYRangeInit,Y 
	clc 
	adc dYMinInit,Y 
	jsr ToVelocity
	sta dY_l,X 
	lda _temp_h 
	sta dY_h,X 
	rts 

ToVelocity:

	sta _temp_l 
	lda #$00
	sta _temp_h 
	jsr Random
	bpl L_BRS_1AA5_1A98
	sec 
	lda #$00
	sbc _temp_l 
	sta _temp_l 
	bcs L_BRS_1AA5_1AA1
	dec _temp_h 

L_BRS_1AA5_1A98:
L_BRS_1AA5_1AA1:

	lda _temp_l 
	asl 
	rol _temp_h 
	asl 
	rol _temp_h 
	asl 
	rol _temp_h 
	rts 

MSpawnAll:

	ldx #$01

L_BRS_1AB3_1ABD:

	txa 
	pha 
	jsr MSpawn
	pla 
	tax 
	inx 
	cpx #POD + 1
	bne L_BRS_1AB3_1ABD
	rts 

SmartBomb:

	lda _bombs
	bne L_BRS_1AC5_1AC2
	rts 

L_BRS_1AC5_1AC2:

	sed
	sec 
	lda _bombs
	sbc #$01
	sta _bombs
	cld 
	ldx #$00
	ldy #$00
	jsr AddScore
	lda #FALSE
	jsr Deteonate
	lda #TRUE

Deteonate:

	sta _bomb_pass2
	lda #(PAL_BG|WHITE)
	sta _bgpal
	ldx #$02
	jsr DoNFrames
	jsr BombScreen
	lda #(PAL_BG|BLACK)
	sta _bgpal
	ldx #$02
	jsr DoNFrames
	rts 

BombScreen:

	ldx #ID_MIN

L_BRS_1AF6_1B32:

	lda Unit,X 
	asl 
	bmi BombNext
	lsr 
	cmp #MAN
	beq BombNext
	lda Anim,X 
	bne BombNext
	lda pSprite_h,X 
	bne L_BRS_1B29_1B09
	lda _bomb_pass2
	beq BombNext
	lda Unit,X 
	and #%01111111
	cmp #SWARMER
	bne BombNext
	jsr GetXScreen
	cmp #$50
	bcs BombNext
	lda X_h,X 
	eor #10000000
	sta X_h,X 
	bne BombNext

L_BRS_1B29_1B09:

	jsr ScoreUnit
	jsr KillUnit

BombNext:

	inx 
	cpx #$20
	bne L_BRS_1AF6_1B32
	rts 

KeysHyper:

	ldx #$06

L_BRS_1B37_1B45:

	stx _xreg
	lda HyperKeys,X 
	tax 
	jsr ScanInkey
	bne L_BRS_1B48_1B40
	ldx _xreg
	dex 
	bpl L_BRS_1B37_1B45

L_BRS_1B47_1B4B:
L_BRS_1B47_1B52:

	rts 

L_BRS_1B48_1B40:

	bit Anim 
	bvs L_BRS_1B47_1B4B
	lda Param 
	cmp #$05
	bcs L_BRS_1B47_1B52
	jsr Random
	jsr NewScreen
	jsr Random
	ldx #WARP
	cmp #$28
	bcs L_BRS_1B65_1B61
	ldx #(WARP|HAL)

L_BRS_1B65_1B61:

	stx Anim + SHIP
	lda #$08
	sta Param + SHIP
	rts 

FrameNoCheck:

	lda _no_planet
	ora  _humanc
	bne L_BRS_1B97_1B72
	lda #TRUE
	sta _no_planet

L_BRS_1B78_1B95:

	iny 
	tya 
	and #%00000111
	pha 
	tay 
	lda FlashPal,Y 
	and #(PAL_BG|%00001111)
	sta _bgpal
	ldx #$03
	jsr DoNFrames
	lda #(PAL_BG|BLACK)
	sta _bgpal
	ldx #$04
	jsr DoNFrames
	pla 
	tay 
	bne L_BRS_1B78_1B95

L_BRS_1B97_1B72:

	jmp FrameAll

ShootChance:

	sta _temp 
	lda _dead
	beq L_BRS_1BA1_1B9E
	rts 

L_BRS_1BA1_1B9E:

	jsr Random
	cmp _temp 
	bcs L_BRS_1BC1_1BA6
	sec 
	lda X_h + SHIP 
	sbc X_h,X 
	bpl L_BRS_1BB8_1BAF
	sta _temp 
	sec 
	lda #$00
	sbc _temp 

L_BRS_1BB8_1BAF:

	cmp #$28
	bcs L_BRS_1BC1_1BBA
	jsr Shoot
	bcc L_BRS_1BC2_1BBF

L_BRS_1BC1_1BA6:
L_BRS_1BC1_1BBA:

	rts 

L_BRS_1BC2_1BBF:

	lda #$08
	jsr PlaySound

TargetShip:

	sec 
	lda X_h + SHIP 
	sbc X_h,X 
	jsr DistDiv64
	sta _srcptr_h 
	clc 
	lda _temp_l 
	sta _srcptr_l 
	adc dX_l + SHIP
	sta dX_l,Y 
	lda _temp_h 
	adc dX_h 
	sta dX_h,Y 
	sec 
	lda Y_h + SHIP 
	sbc Y_h,X 
	jsr DistDiv64
	sta _destptr_h 
	sta dY_h,Y 
	lda _temp_l 
	sta _destptr_l 
	sta dY_l,Y 

TargetLoop:

	lda dY_h,Y 
	cmp #$03
	bcc L_BRS_1C07_1C01
	cmp #$FE
	bcc L_BRS_1C4B_1C05

L_BRS_1C07_1C01:

	lda dX_h,Y 
	beq L_BRS_1C19_1C0A
	cmp #$FF
	bne L_BRS_1C4B_1C0E
	sec 
	lda #$00
	sbc dX_l,Y 
	jmp ShootSpeed

L_BRS_1C19_1C0A:

	lda _srcptr_l 
	ora _srcptr_h
	beq L_BRS_1C4B_1C1D
	lda dX_l,Y 

ShootSpeed:

	cmp _shootspeed
	bcs L_BRS_1C4B_1C24
	clc 
	lda dX_l,Y 
	adc _srcptr_l 
	sta dX_l,Y 
	lda dX_h,Y 
	adc _srcptr_h 
	sta dX_h,Y 
	clc 
	lda dY_l,Y 
	adc _destptr_l 
	sta dY_l,Y 
	lda dY_h,Y 
	adc _destptr_h 
	sta dY_h,Y 
	jmp TargetLoop

L_BRS_1C4B_1C05:
L_BRS_1C4B_1C0E:
L_BRS_1C4B_1C1D:
L_BRS_1C4B_1C24:

	rts 
	lda #$08
	jmp PlaySound

MineChance:

	lda pNext_h,X 
	beq L_BRS_1C70_1C54
	jsr Random
	cmp #$3C
	bcs L_BRS_1C70_1C5B
	jsr SpawnMisc
	bcs L_BRS_1C70_1C60
	lda #$00
	sta dY_l,Y 
	sta dY_h,Y 
	sta dX_l,Y 
	sta dX_h,Y 

L_BRS_1C70_1C54:
L_BRS_1C70_1C5B:
L_BRS_1C70_1C60:

	rts 

DistDiv64:

	sta _temp_l 
	php 
	lda #$00
	plp 
	bpl L_BRS_1C7B_1C77
	lda #$FF

L_BRS_1C7B_1C77:

	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	sta _temp_h 
	rts 

Shoot:

	ldy #ID_BULLET1
	bne L_BRS_1C8A_1C86

SpawnMisc:

	ldy #ID_ALT1

L_BRS_1C8A_1C86:
L_BRS_1C8A_1C92:

	jsr ShootID
	bcc L_BRS_1C94_1C8D
	iny 
	cpy #ID_ALT3 + 1
	bne L_BRS_1C8A_1C92

L_BRS_1C94_1C8D:

	rts 

ShootID:

	lda Unit,Y 
	eor #%11000000
	asl 
	asl 
	bcs L_BRS_1CCA_1C9C
	lda #(UPDATE|KUGEL)
	sta Unit,Y 
	lda X_l,X 
	sta X_l,Y 
	clc 
	lda X_h,X 
	adc #$01
	sta X_h,Y 
	lda Y_l,X 
	sta Y_l,Y 
	sec 
	lda Y_h,X 
	sbc #$04
	sta Y_h,Y 
	lda #$00
	sta Param,Y 
	sta Anim,Y 
	clc 

L_BRS_1CCA_1C9C:

	rts 

Frame:

	ldx #KEY_TAB		//tab key
	jsr ScanInkey
	beq L_BRS_1CD4_1CD0
	eor _inkey_tab

L_BRS_1CD4_1CD0:

	stx _inkey_tab
	beq L_BRS_1CDB_1CD6
	jsr SmartBomb

L_BRS_1CDB_1CD6:

	jsr KeysHyper
	jsr FrameNoCheck
	lda _dead
	bne L_BRS_1CE6_1CE3
	rts 

L_BRS_1CE6_1CE3:

	lda #(PAL_BG|WHITE)
	sta _bgpal
	jsr FrameAll
	lda #(PAL_BG|BLACK)
	sta _bgpal
	ldx #$32
	jsr DoNFrames
	ldx #FALSE
	stx _dead
	jsr EraseUnit
	lda #$0C
	jsr PlaySound
	ldx #ID_MAX

L_BRS_1D04_1D41:

	jsr ClearSPtrs
	lda Unit,X 
	sta Param,X 
	lda Anim,X 
	sta pDot_l,X 
	lda #(UPDATE|U_SHIP)
	sta Unit,X 
	lda #$00
	sta Anim,X 
	sta pDot_h,X 
	lda X_h + SHIP 
	clc 
	adc #$02
	sta X_h,X 
	lda X_l 
	sta X_l,X 
	lda Y_h + SHIP 
	sta Y_h,X 
	lda Y_l 
	sta Y_l,X 
	ldy #U_SHIP
	jsr InitDXY
	dex 
	bpl L_BRS_1D04_1D41
	lda #<imgShrapnel
	sta SpriteV_l 
	lda #>imgShrapnel
	sta SpriteV_h 
	lda #$04
	sta SpriteLen 
	lda _batch
	pha 
	lda #$1E
	sta _batch
	ldx #$3C

L_BRS_1D5B_1D72:

	txa 
	pha 
	jsr AIBatch
	jsr NextFrame
	jsr RepaintAll
	pla 
	tax 
	cpx #$12
	bne L_BRS_1D71_1D6A
	lda #(PALX_METAL|RED)
	jsr SetPallette

L_BRS_1D71_1D6A:

	dex 
	bne L_BRS_1D5B_1D72
	ldx #ID_MAX

L_BRS_1D76_1D83:

	lda Param,X 
	sta Unit,X 
	lda pDot_l,X 
	sta Anim,X 
	dex 
	bpl L_BRS_1D76_1D83
	pla 
	sta _batch
	ldx #$64
	jsr Delay
	sed
	sec 
	lda _lives
	sbc #$01
	sta _lives
	cld 
	lda _is_spawning
	ora _enemyc
	beq L_BRS_1DA4_1D9A
	lda _lives
	bne L_BRS_1DA8_1D9E
	ldx _gameover_sp 
	txs 
	rts 

L_BRS_1DA4_1D9A:

	ldx _nextlvl_sp
	txs 
	rts 

L_BRS_1DA8_1D9E:

	jsr ContLevel
	ldx #$32
	jsr Delay
	rts 

Game:

	tsx 
	stx _nextlvl_sp
	lda #TRUE
	sta _is_spawning
	lda #MAN
	jsr MSpawn
	lda #$00
	sta Spawnc + MAN
	ldx #$14
	jsr DoNFrames
	jsr MSpawnAll
	jsr SpawnSquad
	jsr SpawnSquad
	lda _level 
	cmp #$06
	bcc L_BRS_1DD9_1DD4
	jsr SpawnSquad

L_BRS_1DD9_1DD4:

	lda #FALSE
	sta _is_spawning

L_BRS_1DDD_1DE2:

	jsr Frame
	lda _enemyc
	bne L_BRS_1DDD_1DE2
	rts 

SpawnSquad:

	lda #$00
	sta _framec_l
	sta _framec_h

L_BRS_1DEB_1E00:

	jsr Frame
	lda _enemyc
	beq L_BRS_1E02_1DF0
	lda _humanc
	beq L_BRS_1E02_1DF4
	inc _framec_l
	bne L_BRS_1DFC_1DF8
	inc _framec_h

L_BRS_1DFC_1DF8:

	lda _framec_h
	cmp _squaddelay
	bne L_BRS_1DEB_1E00

L_BRS_1E02_1DF0:
L_BRS_1E02_1DF4:

	lda #LANDER
	jsr MSpawn
	rts 

RMSurface:

	txa 
	pha 
	lda #(PAL_SURF|BLACK)
	sta _surfpal
	jsr SetPallette
	pla 
	tax 
	rts 

ScanInkey:

	ldy #$FF
	lda #$81//Read key with time limit/Scan for any keys/Read OS version
	jsr OSBYTE
	txa 
	rts 

WaitSpaceBar:

	lda #$0F		//Flush all buffers/input buffer
	ldx #$01
	jsr OSBYTE

L_BRS_1E24_1E2E:

	lda #$7E		//Acknowledge ESCAPE Condition
	jsr OSBYTE
	jsr OSRDCH		//OSRDCH Read character (from keyboard) to A
	cmp #$20		//is space pressed
	bne L_BRS_1E24_1E2E
	rts 

XYToVidP:

	lda #NULL
	sta _destptr_h 
	cpx _min_xscr
	bcc L_BRS_1E7D_1E37
	cpx _max_xscr
	bcs L_BRS_1E7D_1E3B
	tya 
	eor #%11111111
	pha 
	lsr 
	lsr 
	lsr 
	tay 
	lsr 
	sta _temp 
	lda #$00
	ror 
	adc _originp_l
	php 
	sta _destptr_l 
	tya 
	asl 
	adc _temp 
	plp 
	adc _originp_h
	sta _destptr_h 
	lda #$00
	sta _temp 
	txa 
	asl 
	rol _temp 
	asl 
	rol _temp 
	asl 
	rol _temp 
	adc _destptr_l 
	sta _destptr_l 
	lda _temp 
	adc _destptr_h 
	bpl L_BRS_1E74_1E6F
	sec 
	sbc #$50

L_BRS_1E74_1E6F:

	sta _destptr_h 
	pla 
	and #%00000111
	ora _destptr_l
	sta _destptr_l 

L_BRS_1E7D_1E37:
L_BRS_1E7D_1E3B:

	rts 

XORBlit:

	lda _destptr_h 
	bne L_BRS_1E83_1E80
	rts 

L_BRS_1E83_1E80:

	lda #$00
	sta _paintmask
	lda _imglen 
	pha 
	ldy #$00

L_BRS_1E8C_1EF1:

	lda _destptr_h 
	pha 
	lda _destptr_l 
	pha 
	lda _destptr_l 
	and #%00000111
	sta _dest_crow 
	lda _destptr_l 
	and #%11111000
	sta _destptr_l 

L_BRS_1E9E_1EC1:

	lda (_srcptr),Y 
	php 
	iny 
	sty _temp 
	ldy _dest_crow 
	eor (_destptr),Y 
	sta (_destptr),Y 
	iny 
	plp 
	beq L_BRS_1EB2_1EAC
	ora _paintmask
	sta _paintmask

L_BRS_1EB2_1EAC:

	cpy #$08
	beq L_BRS_1EC9_1EB4

L_BRS_1EB6_1EDD:

	sty _dest_crow 
	ldy _temp 
	tya 
	and _heightmask
	beq L_BRS_1EDF_1EBD
	dec _imglen 
	bne L_BRS_1E9E_1EC1
	pla 
	pla 
	pla 
	sta _imglen 
	rts 

L_BRS_1EC9_1EB4:

	ldy #$00
	clc 
	lda _destptr_l 
	adc #$80
	sta _destptr_l 
	lda _destptr_h 
	adc #$02
	bpl L_BRS_1EDB_1ED6
	sec 
	sbc #$50

L_BRS_1EDB_1ED6:

	sta _destptr_h 
	bne L_BRS_1EB6_1EDD

L_BRS_1EDF_1EBD:

	clc 
	pla 
	adc #$08
	sta _destptr_l 
	pla 
	adc #$00
	bpl L_BRS_1EED_1EE8
	sec 
	sbc #$50

L_BRS_1EED_1EE8:

	sta _destptr_h 
	dec _imglen 
	bne L_BRS_1E8C_1EF1
	pla 
	sta _imglen 
	rts 

ScreenStart:

	lda _originp_l
	sta _temp 
	lda _originp_h
	lsr 
	ror _temp 
	lsr 
	ror _temp 
	lsr 
	ror _temp 
	ldx #$0C
	jsr Out6845
	ldx #$0D
	lda _temp 
	jmp Out6845

NextFrame:

	jsr ScreenStart
	jsr WaitVSync
	ldy #$14
	ldx #$80
	jsr StartTimer
	lda _bgpal
	jsr SetPallette
	lda _humanc
	bne L_BRS_1F2F_1F26
	lda _bgpal
	ora #PAL_SURF
	jsr SetPallette

L_BRS_1F2F_1F26:

	dec _flpalc
	bne L_BRS_1F46_1F31
	lda _flpalframes
	sta _flpalc
	inc _flashc
	lda _flashc
	and #%00000111
	sta _flashc
	tax 
	lda FlashPal,X 
	jsr SetPallette

L_BRS_1F46_1F31:

	inc _rotpalc
	lda _rotpalc
	and #%00000011
	bne L_BRS_1F70_1F4C
	ldx rotatec 
	lda #PAL_ROT1

L_BRS_1F53_1F6E:

	sta _temp 
	stx rotatec 
	lda RotColour,X 
	ora _temp
	jsr SetPallette
	inx 
	cpx #$03
	bne L_BRS_1F67_1F63
	ldx #$00

L_BRS_1F67_1F63:

	lda _temp 
	clc 
	adc #$10
	cmp #$40
	bne L_BRS_1F53_1F6E

L_BRS_1F70_1F4C:

	rts 

PSurfRight:

	pha 
	sta _dxwinc
	sty _xscrc
	ldy _xwinedge,X 

L_BRS_1F78_1F80:

	jsr XBltSurface
	inc _xscrc
	iny 
	dec _dxwinc
	bne L_BRS_1F78_1F80
	tya 
	sta _xwinedge,X 
	pla 
	rts 

PSurfLeft:

	pha 
	sta _dxwinc
	sty _xscrc
	ldy _xwinedge,X 

L_BRS_1F8E_1F96:

	dec _xscrc
	dey 
	jsr XBltSurface
	inc _dxwinc
	bne L_BRS_1F8E_1F96
	tya 
	sta _xwinedge,X 
	pla 
	rts 

XBltSurface:

	stx _xreg
	sty _yreg
	tya 
	and #%00000011
	tax 
	tya 
	lsr 
	lsr 
	tay 
	lda SurfQuad,Y 

L_BRS_1FAC_1FB1:

	dex 
	bmi L_BRS_1FB3_1FAD
	lsr 
	lsr 
	bne L_BRS_1FAC_1FB1

L_BRS_1FB3_1FAD:

	and #%00000011
	asl 
	asl 
	adc #<imgSurface
	sta _srcptr_l 
	lda #>imgSurface
	sta _srcptr_h 
	ldx _xscrc 
	ldy _yreg
	lda SurfaceY,Y
	tay 
	jsr XYToVidP
	lda #$04
	sta _imglen 
	lda #$07
	sta _heightmask
	jsr XORBlit
	ldx _xscrc
	ldy #$C4
	jsr XYToVidP
	ldy #$00
	lda #$F0
	eor (_destptr),Y 
	sta (_destptr),Y 
	iny 
	lda #$F0
	eor (_destptr),Y 
	sta (_destptr),Y 
	ldx _xreg
	ldy _yreg
	rts 

ShipAll:

	lda Anim + SHIP
	beq L_BRS_1FF8_1FF3
	jmp ScrollScreen

L_BRS_1FF8_1FF3:

	lda _dead
	beq L_BRS_2016_1FFA
	lda _shippal
	eor #$80
	sta _shippal
	bmi L_BRS_200B_2002
	eor #%00000110
	sta _shippal
	jsr SetPallette

L_BRS_200B_2002:

	lda #$00
	sta dX_l + SHIP
	sta dX_h 
	jmp UpdateShip

L_BRS_2016_1FFA:

	jsr KeyFire
	ldx #KEY_A		//A key
	jsr ScanInkey
	beq L_BRS_202D_201E
	clc 
	lda Y_h + SHIP 
	adc #$02
	cmp #$C3
	bcs L_BRS_202D_2028
	sta Y_h + SHIP 

L_BRS_202D_201E:
L_BRS_202D_2028:

	ldx #KEY_Z		//Z key
	jsr ScanInkey
	beq L_BRS_2041_2032
	sec 
	lda Y_h + SHIP 
	sbc #$02
	cmp #$09
	bcc L_BRS_2041_203C
	sta Y_h + SHIP 

L_BRS_2041_2032:
L_BRS_2041_203C:

	ldx #KEY_SPACE		//space bar
	jsr ScanInkey
	beq L_BRS_204A_2046
	eor _inkey_space

L_BRS_204A_2046:

	stx _inkey_space
	beq L_BRS_2077_204C
	lda pSprite_l 
	sta _destptr_l 
	lda pSprite_h 
	sta _destptr_h 
	ldx #U_SHIP
	jsr XBLTSprite
	lda SpriteV_l 
	eor #%00110000
	sta SpriteV_l 
	lda #NULL
	sta pSprite_h 
	sec 
	lda #$00
	sbc _ddx_l
	sta _ddx_l
	lda #$00
	sbc _ddx_h
	sta _ddx_h

L_BRS_2077_204C:

	ldx #KEY_SHIFT		//Shift key
	jsr ScanInkey
	beq L_BRS_208F_207C
	clc 
	lda dX_l + SHIP
	adc _ddx_l
	sta dX_l + SHIP
	lda dX_h 
	adc _ddx_h
	sta dX_h 

L_BRS_208F_207C:

	lda dX_h 
	ora dX_l + SHIP
	beq L_BRS_20EB_2095
	lda dX_h 
	bpl L_BRS_20C2_209A
	clc 
	lda dX_l + SHIP
	adc #$03
	sta dX_l + SHIP
	lda dX_h 
	adc #$00
	sta dX_h 
	bcs L_BRS_20E3_20AD
	lda dX_h 
	cmp #$FF
	bpl L_BRS_20EB_20B4
	lda #$FF
	sta dX_h 
	lda #$00
	sta dX_l + SHIP
	beq L_BRS_20EB_20C0

L_BRS_20C2_209A:

	sec 
	lda dX_l + SHIP
	sbc #$03
	sta dX_l + SHIP
	lda dX_h 
	sbc #$00
	sta dX_h 
	bcc L_BRS_20E3_20D3
	lda dX_h 
	cmp #$01
	bmi L_BRS_20EB_20DA
	lda #$00
	sta dX_l + SHIP
	beq L_BRS_20EB_20E1

L_BRS_20E3_20AD:
L_BRS_20E3_20D3:

	lda #$00
	sta dX_l + SHIP
	sta dX_h 

L_BRS_20EB_2095:
L_BRS_20EB_20B4:
L_BRS_20EB_20C0:
L_BRS_20EB_20DA:
L_BRS_20EB_20E1:

	ldx #$00
	jsr GetXScreen
	tax 
	ldy #$0F
	lda _ddx_h
	bpl L_BRS_20F9_20F5
	ldy #$3B

L_BRS_20F9_20F5:

	sty _temp 
	lda #$00
	ldy #$00
	cpx _temp 
	beq L_BRS_210B_2101
	lda #$80
	bcs L_BRS_210B_2105
	lda #$80
	ldy #$FF

L_BRS_210B_2101:
L_BRS_210B_2105:

	clc 
	adc dX_l + SHIP
	sta _dxrel_l
	tya 
	adc dX_h 
	sta _dxrel_h
	clc 
	lda _dxrel_l
	adc _xrel_l
	sta _xrel_l
	lda _dxrel_h
	adc _xrel_h
	sta _xrel_h

UpdateShip:

	jsr ScrollScreen
	ldx #SHIP
	jsr MoveXUnit
	ldx #SHIP
	jsr MMUpdate
	rts 

Hitchhiker:

	lda  _hikerc
	beq L_BRS_215D_2134
	lda #MAN
	sta Unit + HITCH 
	lda X_l + SHIP
	clc 
	adc #$80
	sta X_l + HITCH
	lda #$00
	adc X_h + SHIP 
	sta X_h + HITCH 
	lda Y_h + SHIP 
	sec 
	sbc #$0A
	sta Y_h + HITCH 
	ldx #HITCH
	jsr NextVidP
	jmp MMUpdate

L_BRS_215D_2134:

	ldx #HITCH
	jmp EraseUnit

MoveUnit:

	lda Unit,X 
	and #%01110111
	tay 
	clc 
	lda dY_l,X 
	adc Y_l,X 
	sta Y_l,X 
	lda dY_h,X 
	adc Y_h,X 
	cmp #$C3
	bcc L_BRS_2182_217A
	cpy #(U_SHIP&KUGEL)
	beq L_BRS_21D1_217E
	lda #$09

L_BRS_2182_217A:

	cmp #$09
	bcs L_BRS_219A_2184
	cpy #(U_SHIP&KUGEL)
	bne L_BRS_2190_2188
	cmp #$04
	bcs L_BRS_219A_218C
	bcc L_BRS_21D1_218E

L_BRS_2190_2188:

	cpy #MAN
	php 
	lda #$C2
	plp 
	bne L_BRS_219A_2196
	lda #$09

L_BRS_219A_2184:
L_BRS_219A_218C:
L_BRS_219A_2196:

	sta Y_h,X 

MoveXUnit:

	clc 
	lda dX_l,X 
	adc X_l,X 
	sta X_l,X 
	lda dX_h,X 
	adc X_h,X 
	sta X_h,X 

NextVidP:

	ldy Y_h,X 
	txa 
	pha 
	jsr GetXScreen
	tax 
	jsr XYToVidP
	pla 
	tax 

L_BRS_21BE_21D5:

	lda _destptr_l 
	sta pNext_l,X 
	lda _destptr_h 
	sta pNext_h,X 
	lda Unit,X 
	and #%01111111
	sta Unit,X 
	rts 

L_BRS_21D1_217E:
L_BRS_21D1_218E:

	lda #NULL
	sta _destptr_h 
	beq L_BRS_21BE_21D5

GetXScreen:

	sec 
	lda X_l,X 
	sbc _xrel_l
	sta _offset_l 
	lda X_h,X 
	sbc _xrel_h
	sta _offset_h 
	asl _offset_l 
	rol 
	sta _temp 
	eor _offset_h 
	bmi L_BRS_21F2_21ED
	lda _temp 
	rts 

L_BRS_21F2_21ED:

	lda #$80
	rts 

RepaintAll:

	ldx #SHIP

L_BRS_21F7_224B:

	txa 		//save X
	pha 
	lda Unit,X 
	bmi L_BRS_2246_21FC
	ora #$80
	sta Unit,X 
	lda Anim,X 
	bne L_BRS_2246_2206
	lda pSprite_l,X 
	cmp pNext_l,X 
	bne L_BRS_221C_220E
	lda pSprite_h,X 
	cmp pNext_h,X 
	bne L_BRS_221C_2216
	cpx #SHIP
	bne L_BRS_2246_221A

L_BRS_221C_220E:
L_BRS_221C_2216:

	lda pSprite_l,X 
	sta _destptr_l 
	lda pSprite_h,X 
	sta _destptr_h 
	lda Unit,X 
	and #%01111111
	tax 
	jsr XBLTSprite
	pla 
	tax 
	lda pNext_l,X 
	sta pSprite_l,X 
	sta _destptr_l 
	lda pNext_h,X 
	sta pSprite_h,X 
	sta _destptr_h 
	txa 
	pha 
	jsr XORBlit

L_BRS_2246_21FC:
L_BRS_2246_2206:
L_BRS_2246_221A:

	pla 
	tax 
	inx 
	cpx #ID_ALT3 + 1
	bne L_BRS_21F7_224B
	rts 

XBLTSprite:

	lda SpriteMaxY,X //$07,$07,$07,$03,$07,$03,$0F,$07,$03,$07,$07
	sta _heightmask
	lda SpriteLen,X //$30,$20,$20,$14,$18,$0C,$08,$18,$02,$28,$28
	sta _imglen 
	lda SpriteV_l,X //$C0,$2C,$4C,$6C,$94,$AC,$A0,$A8,$B8,$BE,$CE
	sta _srcptr_l 
	lda SpriteV_h,X //$0F,$10,$10,$10,$10,$10,$0F,$0F,$10,$10,$10
	sta _srcptr_h 
	jsr XORBlit
	cpx #U_SHIP
	bne L_BRS_226D_2267
	lda _paintmask
	sta _collision

L_BRS_226D_2267:

	rts 

ScrollSurface:

	lda #$00
	sta _min_xscr
	lda #$50
	sta _max_xscr
	lda _originp_l
	pha 
	lda _originp_h
	pha 
	lda _oldorgp_l 
	sta _originp_l
	lda _oldorgp_h 
	sta _originp_h
	lda _dxwin
	beq L_BRS_22C8_2286
	bpl L_BRS_22A9_2288
	ldx #RIGHT
	ldy #$50
	jsr PSurfLeft
	sta _temp 
	pla 
	sta _originp_h
	pla 
	sta _originp_l
	sec 
	lda #$00
	sbc _temp 
	tay 
	ldx #LEFT
	lda _temp 
	jsr PSurfLeft
	jmp SSurfRTS

L_BRS_22A9_2288:

	ldx #LEFT
	ldy #$00
	jsr PSurfRight
	sta _temp 
	pla 
	sta _originp_h
	pla 
	sta _originp_l
	sec 
	lda #$50
	sbc _temp 
	tay 
	ldx #RIGHT
	lda _temp 
	jsr PSurfRight
	jmp SSurfRTS

L_BRS_22C8_2286:

	pla 
	sta _originp_h
	pla 
	sta _originp_l

SSurfRTS:

	rts 

ScrollScreen:

	lda _originp_l
	sta _oldorgp_l 
	lda _originp_h
	sta _oldorgp_h 
	lda _xrel_l
	asl 
	lda _xrel_h
	rol 
	pha 
	sec 
	sbc _xwin
	sta _dxwin
	asl 
	asl 
	asl 
	ldy #$00
	bcc L_BRS_22EC_22E8
	ldy #$FF

L_BRS_22EC_22E8:

	sta _scrolloff_l
	clc 
	adc _originp_l
	sta _originp_l
	tya 
	sta _scrolloff_h 
	adc _originp_h
	bpl L_BRS_22FD_22F8
	sec 
	sbc #$50

L_BRS_22FD_22F8:

	cmp #$30
	bcs L_BRS_2303_22FF
	adc #$50

L_BRS_2303_22FF:

	sta _originp_h
	pla 
	sta _xwin
	jmp ScreenStart

Collision:

	lda _collision
	and #%11000000
	beq L_BRS_2315_230F
	lda _dead
	beq L_BRS_2316_2313

L_BRS_2315_230F:

	rts 

L_BRS_2316_2313:

	ldx #SHIP
	jsr GetXScreen
	sta _ship_xscr
	ldx #ID_ALT3

L_BRS_231F_2389:

	lda Unit,X 
	asl 
	bmi CollideNext
	cmp #$12
	bcs CollideNext
	lda Anim,X 
	bne CollideNext
	lda Y_h,X 
	sec 
	sbc Y_h + SHIP 
	cmp #$08
	bpl CollideNext
	cmp #$F9
	bmi CollideNext
	jsr GetXScreen
	cmp #$50
	bcs CollideNext
	sec 
	sbc _ship_xscr
	cmp #$06
	bpl CollideNext
	cmp #$FD
	bmi CollideNext
	lda Unit,X 
	and #%01111111
	cmp #MAN
	beq L_BRS_2366_2356
	jsr ScoreUnit
	jsr KillUnit
	lda #TRUE
	sta _dead
	lda #(PAL_SHIP|WHITE)
	sta _shippal

L_BRS_2366_2356:

	lda Param,X 
	bpl CollideNext
	cmp #$80
	beq CollideNext
	jsr EraseUnit
	lda #$80
	sta Param,X 
	lda #(UPDATE|MAN)
	sta Unit,X 
	inc _hikerc
	lda #$0E
	jsr PlaySound
	jsr Score500

CollideNext:

	dex 
	cpx #ID_MIN
	bcs L_BRS_231F_2389
	rts 

Random:

	txa 
	pha 
	ldx #$08

L_BRS_2390_239F:

	lda _rand_h
	and #%01001000
	adc #%00111000
	asl 
	asl 
	rol _rand_l
	rol _rand_m
	rol _rand_h
	dex 
	bne L_BRS_2390_239F
	pla 
	tax 
	lda _rand_h
	rts 

NextLevel:

	sed
	lda _level 
	clc 
	adc #$01
	sta _level 
	cmp #$05
	bcc L_BRS_23B4_23B0
	lda #$05

L_BRS_23B4_23B0:

	sta _humanbonus
	lda _level 
	sec 
	ldx #(PAL_SURF|RED)		//pallete colour(terrain)

L_BRS_23BB_23BD:

	sbc #$05
	bcs L_BRS_23BB_23BD
	cmp #$95
	bne L_BRS_23CF_23C1
	lda #$A		//#of humanoids
	sta  _humanc
	lda #FALSE
	sta _no_planet
	ldx #(PAL_SURF|GREEN)
	inc _batch

L_BRS_23CF_23C1:

	cld 
	lda  _humanc
	bne L_BRS_23D6_23D2
	ldx #(PAL_SURF|BLACK)

L_BRS_23D6_23D2:

	stx _surfpal
	clc 
	lda _shootspeed
	adc #$08
	sta _shootspeed
	lda #$0A
	sta _baitdelay_h
	lda #$00
	sta Spawnc + BAITER
	lda _humanc
	sta Spawnc + MAN
	ldx #ID_MAX
	lda #EMPTY

L_BRS_23F1_23F5:

	sta Unit,X 
	dex 
	bpl L_BRS_23F1_23F5
	lda #$00
	sta _hikerc
	lda #ID_ALT1
	sta _id_alt
	lda #$00
	sta rotatec 
	sta _flashc
	lda #$06
	sta _flpalframes
	sta _flpalc
	lda #$00
	sta _enemyc
	lda #$02
	sta _squaddelay
	lda #$00
	sta Spawnc + SWARMER 
	ldx #$00
	lda _level 
	cmp #$01
	beq L_BRS_2429_241F
	ldx #$04
	cmp #$04
	bcc L_BRS_2429_2425
	ldx #$07

L_BRS_2429_241F:
L_BRS_2429_2425:

	stx Spawnc +  BOMBER
	ldx #$04
	cmp #$04
	bcs L_BRS_243E_2430
	dex 
	cmp #$03
	beq L_BRS_243E_2435
	dex 
	dex 
	cmp #$02
	beq L_BRS_243E_243B
	dex 

L_BRS_243E_2430:
L_BRS_243E_2435:
L_BRS_243E_243B:

	stx Spawnc + POD
	lda dXMinInit + LANDER
	clc 
	adc #$02
	cmp #$18		//progressive difficulty
	bcs L_BRS_244E_2449
	sta dXMinInit + LANDER

L_BRS_244E_2449:

	lda #(PAL_BG|BLACK)
	sta _bgpal

ContLevel:

	lda #$80
	sta XMinInit + SWARMER
	ldx #ID_MAX + 1

L_BRS_2459_246E:

	lda Unit,X 
	and #%01111111
	cmp #BAITER
	bne L_BRS_2467_2460
	lda #EMPTY
	sta Unit,X 

L_BRS_2467_2460:

	jsr resetUnit
	jsr InitUnit
	dex 
	bpl L_BRS_2459_246E
	lda #ID_MIN
	sta _id
	lda #$00
	sta  _hikerc
	lda #KEYDOWN
	sta _inkey_space
	sta _inkey_enter
	sta _inkey_tab

NewScreen:

	sta _xrel_h
	asl 
	sta _xwin
	lda #$00
	sta _xrel_l
	lda #$80
	sta X_l 
	clc 
	lda _xrel_h
	adc #$07
	sta X_h + SHIP 
	lda #$00
	sta Y_l 
	lda #$64
	sta Y_h + SHIP 
	lda #$07
	sta _ddx_l
	lda #$00
	sta _ddx_h
	lda #$00
	ldx #$03

L_BRS_24AC_24AF:

	sta _Laser,X 
	dex 
	bpl L_BRS_24AC_24AF
	lda #EMPTY
	sta Unit + HITCH 
	ldx #ID_ALT3

L_BRS_24B8_24C3:

	lda #EMPTY
	sta Unit,X 
	jsr ClearData
	dex 
	cpx #ID_BULLET1
	bpl L_BRS_24B8_24C3

L_BRS_24C5_24C9:

	jsr resetUnit
	dex 
	bpl L_BRS_24C5_24C9
	lda #$80
	sta Param + HITCH
	lda #$00
	sta Unit + SHIP
	sta dX_l + SHIP
	sta dX_h 
	sta Anim 
	sta _dead
	sta _collision
	lda #<imgShipR
	sta SpriteV_l 
	lda #>imgShipR
	sta SpriteV_h 
	lda #$30
	sta SpriteLen 
	lda #$00
	sta _dxwin
	sta _scrolloff_l
	sta _scrolloff_h 
	lda #<VRAM
	sta _originp_l
	sta _oldorgp_l 
	lda #>VRAM
	sta _originp_h
	sta _oldorgp_h 
	sta _digitp_h
	lda #<VRAM + (26*8)
	sta _digitp_l
	jsr WaitVSync
	lda #(PAL_BG|BLACK)

L_BRS_2510_2516:

	jsr SetPallette
	clc 
	adc #$10
	bne L_BRS_2510_2516
	lda #$00
	jsr PrintN
	lda #$80		//#(PALX_ENEMYB|BLACK) DIFF error?

L_BRS_251F_2525:

	jsr SetPallette
	clc 
	adc #$11
	bcc L_BRS_251F_2525
	lda #(PAL_FLASH|WHITE)
	jsr SetPallette
	lda _surfpal
	jsr SetPallette
	lda #$00
	sta _min_xscr
	lda #$50
	sta _max_xscr
	lda _xwin
	sta _xwinleft 
	sta _xwinright
	ldx #RIGHT
	lda #$50
	ldy #$00
	jsr PSurfRight
	ldx #$00
	ldy #$00
	jmp AddScore

resetUnit:

	lda Anim,X 
	beq L_BRS_2562_2552
	bpl L_BRS_255D_2554
	lda #EMPTY
	sta Unit,X 
	bne L_BRS_2562_255B

L_BRS_255D_2554:

	lda #$08
	sta Param,X 

L_BRS_2562_2552:
L_BRS_2562_255B:

	jsr ClearSPtrs
	sta pDot_h,X 
	rts 

ClearData:

	lda #$00
	sta Anim,X 
	sta Param,X 

ClearSPtrs:

	lda #NULL
	sta pNext_h,X 
	sta pSprite_h,X 
	rts 

PrintN:

	stx _savedx
	sty _savedy
	tax 
	lda StringV_l,X 
	sta _destptr_l 
	lda StringV_h,X 
	sta _destptr_h 
	ldy #$00
	lda (_destptr),Y 
	sta _strlen

L_BRS_258F_2597:

	iny 
	lda (_destptr),Y 
	jsr OSWRCH
	cpy _strlen
	bne L_BRS_258F_2597
	ldx _savedx
	ldy _savedy
	rts 

ScoreUnit:

	txa 
	pha 
	tya 
	pha 
	lda Unit,X 
	cmp #EMPTY
	beq L_BRS_25B7_25A7
	and #%01111111
	tax 
	lda Points_h,X 
	tay 
	lda Points_l,X 
	tax 
	jsr AddScore

L_BRS_25B7_25A7:

	pla 
	tay 
	pla 
	tax 
	rts 

Score500:

	tya 
	pha 
	txa 
	pha 
	ldy #$05
	ldx #$00
	jsr AddScore
	pla 
	tax 
	jsr SpawnMisc
	bcs L_BRS_25FF_25CC
	lda #(UPDATE|S500)
	sta Unit,Y 

L_BRS_25D3_2619:

	clc 
	lda Y_h,Y 
	adc #$0C
	sta Y_h,Y 
	lda dX_h 
	asl 
	lda dX_h 
	ror 
	sta dX_h,Y 
	lda dX_l + SHIP
	ror 
	sta dX_l,Y 
	lda #$00
	sta dY_h,Y 
	sta dY_l,Y 
	sec 
	lda X_h,Y 
	sbc #$01
	sta X_h,Y 

L_BRS_25FF_25CC:
L_BRS_25FF_2612:

	pla 
	tay 
	rts 

Score250:

	tya 
	pha 
	txa 
	pha 
	ldy #$02
	ldx #$50
	jsr AddScore
	pla 
	tax 
	jsr SpawnMisc
	bcs L_BRS_25FF_2612
	lda #(UPDATE|S250)
	sta Unit,Y 
	bne L_BRS_25D3_2619

AddScore:

	sed
	clc 
	txa 
	adc _score_lsb
	sta _score_lsb
	tya 
	adc _score_100
	sta _score_100
	php 
	lda #$00
	adc _score_msb
	sta _score_msb
	plp 
	cld 
	bcc L_BRS_2635_2630
	jsr Reward

L_BRS_2635_2630:

	lda _digitp_l
	sta _destptr_l 
	lda _digitp_h
	sta _destptr_h 
	lda #FALSE
	sta _leading0
	ldx #$02

L_BRS_2643_2649:

	lda _score_lsb,X 
	jsr PaintBCD
	dex 
	bpl L_BRS_2643_2649
	lda #FALSE
	sta _leading0
	jsr PaintDigit
	ldx #$00
	lda _lives
	jsr PaintBCD
	lda #FALSE
	sta _leading0
	jsr PaintDigit
	ldx #$00
	lda _bombs

PaintBCD:

	pha 
	and #%11110000
	jsr PaintDigit
	cpx #$00
	bne L_BRS_2672_266C
	lda #TRUE
	sta _leading0

L_BRS_2672_266C:

	pla 
	asl 
	asl 
	asl 
	asl 

PaintDigit:

	stx _temp 
	tax 
	ora _leading0
	sta _leading0
	ldy #$00

L_BRS_2680_26A8:

	lda _leading0
	beq L_BRS_2689_2682
	lda imgDigit,X 		//HUD numbers
	sta (_destptr),Y 

L_BRS_2689_2682:

	iny 
	inx 
	tya 
	and #%00000111
	tay 
	bne L_BRS_26A5_268F
	clc 
	lda _destptr_l 
	adc #$08
	sta _destptr_l 
	bcc L_BRS_26A5_2698
	inc _destptr_h 
	bpl L_BRS_26A5_269C
	lda _destptr_h 
	sec 
	sbc #$50
	sta _destptr_h 

L_BRS_26A5_268F:
L_BRS_26A5_2698:
L_BRS_26A5_269C:

	txa 
	and #%0000111
	bne L_BRS_2680_26A8
	ldx _temp 
	rts 

RepaintDigit:

	ldy #$00
	lda  _scrolloff_l
	bpl L_BRS_26B5_26B1
	ldy #$FF

L_BRS_26B5_26B1:

	sty _temp 
	clc 
	lda _digitp_l
	sta _srcptr_l 
	adc  _scrolloff_l
	sta _destptr_l 
	sta _digitp_l
	lda _digitp_h
	sta _srcptr_h 
	adc _temp 
	bpl L_BRS_26CD_26C8
	sec 
	sbc #$50

L_BRS_26CD_26C8:

	cmp #$30
	bcs L_BRS_26D3_26CF
	adc #$50

L_BRS_26D3_26CF:

	sta _destptr_h 
	sta _digitp_h
	lda #$FF
	eor _temp 
	sta _temp_h 
	lda #$08
	sta _temp_l 
	sec 
	lda #$18
	sbc _dxwin
	bit _dxwin
	bmi L_BRS_271B_26E8
	clc 
	lda _destptr_l 
	adc #$B8
	sta _destptr_l 
	bcc L_BRS_26FE_26F1
	inc _destptr_h 
	bpl L_BRS_26FE_26F5
	sec 
	lda _destptr_h 
	sbc #$50
	sta _destptr_h 

L_BRS_26FE_26F1:
L_BRS_26FE_26F5:

	clc 
	lda _srcptr_l 
	adc #$B8
	sta _srcptr_l 
	bcc L_BRS_2712_2705
	inc _srcptr_h 
	bpl L_BRS_2712_2709
	sec 
	lda _srcptr_h 
	sbc #$50
	sta _srcptr_h 

L_BRS_2712_2705:
L_BRS_2712_2709:

	lda #$F8
	sta _temp_l 
	clc 
	lda #$18
	adc _dxwin

L_BRS_271B_26E8:

	tax 

L_BRS_271C_2756:

	ldy #$07

L_BRS_271E_2723:

	lda (_srcptr),Y 
	sta (_destptr),Y 
	dey 
	bpl L_BRS_271E_2723
	clc 
	lda _srcptr_l 
	adc _temp_l 
	sta _srcptr_l 
	lda _temp_h 
	adc _srcptr_h 
	bpl L_BRS_2735_2730
	sec 
	sbc #$50

L_BRS_2735_2730:

	cmp #$30
	bcs L_BRS_273B_2737
	adc #$50

L_BRS_273B_2737:

	sta _srcptr_h 
	clc 
	lda _destptr_l 
	adc _temp_l 
	sta _destptr_l 
	lda _temp_h 
	adc _destptr_h 
	bpl L_BRS_274D_2748
	sec 
	sbc #$50

L_BRS_274D_2748:

	cmp #$30
	bcs L_BRS_2753_274F
	adc #$50

L_BRS_2753_274F:

	sta _destptr_h 
	dex 
	bne L_BRS_271C_2756
	rts 

InitZP:

	lda #$0A		//#of humanoids
	sta  _humanc
	lda #$08		//starting difficulty
	sta dXMinInit + LANDER 
	lda #$00
	sta $3A 
	lda #$05		//game speed
	sta _batch
	lda #$03		//ships per game
	sta _lives
	sta _bombs
	lda #$00
	sta _score_lsb
	sta _score_100
	sta _score_msb
	sta _level 
	sta _no_planet
	rts 

Reward:

	sed
	clc 
	lda _lives
	adc #$01
	sta _lives
	clc 
	lda _bombs
	adc #$01
	sta _bombs
	cld 
	lda #$12
	jmp PlaySound

DoNFrames:

	txa 
	pha 
	jsr FrameNoCheck
	pla 
	tax 
	dex 
	bne DoNFrames
	rts 

FrameAll:

	jsr DoLaser
	jsr ShipAll
	jsr Hitchhiker
	jsr RepaintDigit
	jsr RepaintMap
	ldx #ID_BULLET1
	jsr AIUnit
	ldx #ID_BULLET2
	jsr AIUnit
	jsr AIAlt
	jsr AIAlt
	jsr AIAlt
	jsr AIBatch
	jsr NextFrame
	jsr ScrollSurface
	jsr RepaintAll
	jsr Collision
	jsr SpawnBait
	lda #$7E		//Acknowledge ESCAPE Condition
	jmp OSBYTE

CursorOn:

	lda #$04		//enable/disable cursor editing keys
	ldx #$00		//enable
	jsr OSBYTE
	ldx #$0A
	lda #_srcptr_l
	jmp Out6845

CursorOff:

	lda #$04		//enable/disable cursor editing keys
	ldx #$01		//disable
	jsr OSBYTE
	ldx #$0A
	lda #%00100000
	jmp Out6845
	lda #FALSE
	sta _leading0
	ldx #$02
	ldy #$00
	jsr CursorXY
	ldx #$02

L_BRS_27FF_2805:

	lda _score_lsb,X 
	jsr PrintBCD
	dex 
	bpl L_BRS_27FF_2805
	rts 

PrintBCD:

	pha 
	lsr 
	lsr 
	lsr 
	lsr 
	jsr PrintDigit
	pla 
	and #%00001111

PrintDigit:

	stx _xreg
	tax 
	ora _leading0
	sta _leading0
	bne L_BRS_281E_281A
	ldx #$F0		//#(' '-'0')	;0 -> $f0

L_BRS_281E_281A:

	txa 
	clc 
	adc #$30		//'0'
	ldx _xreg
	jmp OSWRCH

RJustBCD:

	pha 
	lda #FALSE
	sta _leading0
	pla 
	jmp PrintBCD

CursorXY:

	lda #$1F
	jsr OSWRCH
	txa 
	jsr OSWRCH
	tya 
	jmp OSWRCH

Hiscore:

	lda #$7E		//Acknowledge ESCAPE Condition
	jsr OSBYTE
	ldx #$00

L_BRS_2844_285C:

	lda HiScore,X 
	cmp _score_lsb
	lda HiScore + 1,X 
	sbc _score_100
	lda HiScore + 2,X 
	sbc _score_msb
	bcc L_BRS_2860_2853
	txa 
	clc 
	adc #$18
	tax 
	cpx #$A9		//#(24*7 + 1)
	bcc L_BRS_2844_285C
	bcs PrintHighs

L_BRS_2860_2853:

	stx _temp 
	cpx #$A8		//#(24*7)
	beq L_BRS_2873_2864
	ldx #$A8

L_BRS_2868_2871:

	dex 
	lda HiScore,X 
	sta $0718,X 
	cpx _temp 
	bne L_BRS_2868_2871

L_BRS_2873_2864:

	lda #$0D		//Return
	sta HiScore + 3,X 
	lda _score_lsb
	sta HiScore,X 
	lda _score_100
	sta HiScore + 1,X 
	lda _score_msb
	sta HiScore + 2,X 
	jsr PrintHighs
	jsr InputName

PrintHighs:

	lda #$03
	jsr PrintN
	jsr CursorOff
	ldx #$00
	stx _high_rank
	ldy #$06

L_BRS_289B_28F1:

	txa 
	pha 
	pha 
	sed
	clc 
	lda _high_rank
	adc #$01
	sta _high_rank
	cld 
	ldx #$03
	jsr CursorXY
	lda _high_rank
	jsr RJustBCD
	lda #$2E		//'.' dot
	jsr OSWRCH
	ldx #$07
	jsr CursorXY
	pla 
	tax 
	lda HiScore + 2,X 
	jsr RJustBCD
	lda HiScore + 1,X 
	jsr PrintBCD
	lda HiScore,X 
	jsr PrintBCD
	cpx _temp 
	bne L_BRS_28D5_28D1
	sty _temp2 

L_BRS_28D5_28D1:

	lda #$05
	jsr PrintN
	inx 
	inx 
	inx 

L_BRS_28DD_28E6:

	lda HiScore,X 
	jsr OSWRCH
	inx 
	cmp #$0D
	bne L_BRS_28DD_28E6
	iny 
	iny 
	pla 
	clc 
	adc #$18
	tax 
	cpx #$C0
	bne L_BRS_289B_28F1
	rts 

InputName:

	lda #$04
	jsr PrintN
	jsr CursorOn
	lda #$0F		//Flush all buffers/input buffer
	ldx #$01		//current buffer will be flushed
	jsr OSBYTE
	ldx #$12
	ldy _temp2 
	jsr CursorXY
	clc 
	lda _temp 
	adc #$03
	sta ParamBlk 
	lda #$00
	adc #$07
	sta ParamBlk + 1 
	lda #$14
	sta ParamBlk + 2 
	lda #$20
	sta ParamBlk + 3 
	lda #$7E
	sta ParamBlk + 4 
	ldx #<ParamBlk
	ldy #>ParamBlk
	lda #$00		//input line
	jsr OSWORD
	bcc L_BRS_293A_2931
	ldx _temp 
	lda #$0D
	sta HiScore + 3,X 

L_BRS_293A_2931:

	jmp CursorOff

InitVideo:

	lda #$16
	jsr OSWRCH
	lda #$02		//MODE2 = 20 × 32 characters : 160 × 256 pixels
	jsr OSWRCH
	ldx #$08
	lda #$00
	jsr Out6845
	jmp CursorOff

DoneLevel:

	lda _xrel_h
	jsr NewScreen
	lda #$01
	jsr PrintN
	ldx #$28
	ldy #$9F
	jsr XYToVidP
	lda #FALSE
	sta _leading0
	lda _level
	jsr PaintBCD
	ldx #$2A
	ldy #$87
	jsr XYToVidP
	lda #FALSE
	sta _leading0
	lda  _humanbonus
	jsr PaintBCD
	lda #$00
	jsr PaintBCD
	lda  _humanc
	beq L_BRS_29A9_2982
	sta _count
	ldx #$19

BonusLoop:

	ldy #$77
	txa 
	pha 
	jsr XYToVidP
	ldx #MAN
	jsr XBLTSprite
	ldy  _humanbonus
	ldx #$00
	jsr AddScore
	ldx #$04
	jsr Delay
	pla 
	clc 
	adc #$03
	tax 
	dec _count
	bne BonusLoop

L_BRS_29A9_2982:

	ldx #$46
	jsr Delay
	rts 

Delay:

	txa 
	pha 
	jsr NextFrame
	pla 
	tax 
	dex 
	bne Delay
	rts 

Main:

	jsr InitVideo
	jsr Planetoid
	lda _xrel_h
	jsr NewScreen
	lda #$02
	jsr PrintN
	ldx #$64
	jsr Delay
	jsr Hiscore
	lda #$06
	jsr PrintN
	jsr WaitSpaceBar
	jmp Main

Planetoid:

	tsx 
	stx _gameover_sp 
	lda #$00		//power hum sound
	jsr PlaySound
	jsr InitZP

L_BRS_29E8_29F3:

	jsr NextLevel
	jsr Game
	jsr DoneLevel
	lda _lives
	bne L_BRS_29E8_29F3
	rts 

AnimFrame:

	lda Param,X 
	cmp #$08
	beq L_BRS_2A2C_29FB
	lda _originp_l
	pha 
	lda _originp_h
	pha 
	lda _xrel_l
	pha 
	lda _xrel_h
	pha 
	lda pNext_l,X 
	sta _originp_l
	lda pNext_h,X 
	sta _originp_h
	lda pSprite_l,X 
	sta _xrel_l
	lda pSprite_h,X 
	sta _xrel_h
	jsr XORAnimate
	pla 
	sta _xrel_h
	pla 
	sta _xrel_l
	pla 
	sta _originp_h
	pla 
	sta _originp_l

L_BRS_2A2C_29FB:

	ldy Param,X 
	dey 
	tya 
	sta Param,X 
	beq L_BRS_2A4D_2A34
	lda _originp_l
	sta pNext_l,X 
	lda _originp_h
	sta pNext_h,X 
	lda _xrel_l
	sta pSprite_l,X 
	lda _xrel_h
	sta pSprite_h,X 
	jmp XORAnimate

L_BRS_2A4D_2A34:

	lda Anim,X 
	bmi L_BRS_2A69_2A50
	cpx #SHIP
	bne L_BRS_2A5D_2A54
	asl 
	bpl L_BRS_2A5D_2A57
	lda #TRUE
	sta _dead

L_BRS_2A5D_2A54:
L_BRS_2A5D_2A57:

	lda #$00
	sta Anim,X 
	sta pSprite_h,X 
	sta pNext_h,X 
	rts 

L_BRS_2A69_2A50:

	lda #EMPTY
	sta Unit,X 
	jmp InitUnit

XORAnimate:

	lda _min_xscr
	pha 
	lda _max_xscr
	pha 
	lda #$00
	sta _min_xscr
	lda #$50
	sta _max_xscr
	jsr GetXScreen
	cmp #$64
	bpl XAnimRet
	cmp #$EC
	bmi XAnimRet
	sta _anim_xscr 
	lda Anim,X 
	bmi L_BRS_2ADE_2A8F
	lda Param,X 
	cmp #$07
	bne L_BRS_2A9D_2A96
	lda #$06
	jsr PlaySound

L_BRS_2A9D_2A96:

	ldy #$07

L_BRS_2A9F_2AD3:

	sty _yreg
	ldx _anim_xscr 
	lda WarpX,Y 
	jsr WarpCoord
	pha 
	ldx _id
	lda Y_h,X 
	tax 
	lda WarpY,Y 
	jsr WarpCoord
	tay 
	pla 
	tax 
	jsr XYToVidP
	lda _destptr_h 
	beq L_BRS_2AD0_2ABE
	ldy #$00
	ldx _id
	lda Unit,X 
	asl 
	tax 
	lda imgDot,X 
	eor (_destptr),Y 
	sta (_destptr),Y 

L_BRS_2AD0_2ABE:

	ldy _yreg
	dey 
	bpl L_BRS_2A9F_2AD3
	ldx _id

XAnimRet:

	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

L_BRS_2ADE_2A8F:

	ldy #$07

L_BRS_2AE0_2B19:

	lda _anim_xscr 
	ldx BlastX,Y 
	jsr BlastCoord
	pha 
	lda Y_h,X 
	ldx BlastY,Y 
	jsr BlastCoord
	tay 
	pla 
	tax 
	cpy #$C0
	bcs BlastNext
	jsr XYToVidP
	lda _destptr_h 
	beq BlastNext
	ldy #$00
	ldx _id
	lda Unit,X 
	asl 
	tax 
	lda imgDot,X 
	eor (_destptr),Y 
	sta (_destptr),Y 
	jmp BlastNext
	pla 

BlastNext:

	ldx _id
	ldy _yreg
	dey 
	bpl L_BRS_2AE0_2B19
	jmp XAnimRet

BlastCoord:

	sty _yreg
	stx _temp 
	ldx _id
	pha 
	sec 
	lda #$08
	sbc Param,X 
	tay 
	pla 

L_BRS_2B2D_2B31:

	clc 
	adc _temp 
	dey 
	bne L_BRS_2B2D_2B31
	php 
	ldy _yreg
	ldx _id
	plp 
	rts 

WarpCoord:

	stx _xreg
	sec 
	sbc _xreg
	sta _offset_l 
	lda #$00
	sbc #$00
	sta _offset_h 
	lda #$00
	sta _srcptr_l 
	sta _srcptr_h 
	ldx _id
	lda Param,X 
	tax 

L_BRS_2B53_2B61:

	clc 
	lda _srcptr_l 
	adc _offset_l 
	sta _srcptr_l 
	lda _srcptr_h 
	adc _offset_h 
	sta _srcptr_h 
	dex 
	bne L_BRS_2B53_2B61
	lda _srcptr_l 
	lsr _srcptr_h 
	ror 
	lsr _srcptr_h 
	ror 
	lsr _srcptr_h 
	ror 
	clc 
	adc _xreg
	rts 
	rts 

GetYSurf:

	lda X_l,X 
	asl 
	lda X_h,X 
	rol 
	tay 
	lda SurfaceY,Y
	rts 

IsUnlinked:

	stx _temp_h 
	ldx #NULL
	jsr IsLinked
	php 
	ldx _temp_h 
	plp 
	rts 

IsLinked:

	eor Unit,Y 
	and #%01111111
	bne L_BRS_2B9F_2B91
	stx _temp_l
	lda Param,Y 
	cmp _temp_l
	bne L_BRS_2B9F_2B9A
	lda Anim,Y 

L_BRS_2B9F_2B91:
L_BRS_2B9F_2B9A:

	rts

//$2BA0-2FEF global vars x2 (vsync,rotatec)
//(32unused bytes)
	.byte $00,$08,$00,$08,$00,$08,$00,$00
	.byte $00,$00,$04,$04,$04,$08,$08,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
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
WarpX:		//warp animation points
//$2C50 x_offset_t
	.byte $50,$50,$28,$00,$00,$00,$28,$50
WarpY:
//$2C50 y_offset_t
	.byte $60,$C0,$C0,$C0,$60,$00,$00,$00
BlastX:
//$2C60 Blast animation point Xscr coord offsets
	.byte $02,$04,$00,$FC,$FE,$FC,$00,$04
BlastY:
	.byte $00,$0C,$06,$0C,$00,$F4,$FA,$F4
FlashPal:
//$2C70 PAL_FLASH (flashing) colour palettes
	.byte $45,$42,$46,$43,$47,$43,$46,$42
HyperKeys:
//$2C78	hyperspace keycodes
	.byte $AC,$BB,$CA,$BA,$AA,$9B,$AB
	.byte $28	// (unused)
	//     G   Y   U   J   N   B   H
ParamBlk:
//$2C80	OSWORD parameter block, 4 signed words
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
//$2C88
	.byte $02,$02,$02,$00,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$00,$00
	.byte $01,$01,$00,$00
FlushChan:
//$2C9C	FlushChan
	.byte $11,$12,$13,$10,$11,$10,$11,$10
	.byte $11,$10,$11,$10,$11,$10,$12,$12
	.byte $11,$10,$13,$12
AmplEnvel:
//$2CB0
	.byte $F6,$F6,$F6,$00,$01,$F4,$02,$F6
	.byte $01,$F6,$01,$F1,$01,$F1,$03,$03
	.byte $01,$F1,$04,$03
Pitch:
//$2CC4
	.byte $00,$00,$00,$00,$E6,$07,$64,$07
	.byte $FF,$07,$B4,$07,$82,$07,$32,$14
	.byte $FF,$03,$00,$AA
Duration:
//$2CD8
	.byte $32,$32,$32,$00,$FF,$1E,$FF,$0C
	.byte $FF,$02,$FF,$11,$FF,$28,$08,$08
	.byte $FF,$3C,$23,$08
//$2CEC	unused
	.byte $28,$25,$25,$24,$20,$1D,$1D,$1D
	.byte $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D
	.byte $1D,$1D,$1D,$1E

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
imgDot:
//$2D21,X	Minimap dots (2x2px) for each sprite #
	.byte $FF,$FF,$8A,$88,$A2,$88,$88,$88
	.byte $A2,$A2,$82,$8A,$A8,$A8,$20,$20
	.byte $00,$D8,$00,$00,$00,$FF
//imgDotR:
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
StringV_l:
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
	.byte _originp_h,$00,$50,$6C,$61,$6E,$65,$74
	.byte $6F,$69,$64,$20,$48,$61,$6C,$6C
	.byte $20,$6F,$66,$20,$46,$61,$6D,$65
	.byte $1F,$00,$01,$81,$9D,$83,$8D,$1F
	.byte _originp_h,$01,$50,$6C,$61,$6E,$65,$74
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

Boot:

	tsx 
	stx _gameover_sp
	lda #<NewBRKVector
	sta BRKVector
	lda #<NewBRKVector+1
	sta BRKVector + 1 
	lda NULL		//00 Read host OS
	jsr OSBYTE

NewBRKVector:		//$3012

	ldx _gameover_sp 
	txs 
	jsr SystemCheck
	bne Hook
	lda ALT_VSYNC_LB
	sta VsyncAddress1 + 1
	sta WaitVSync + 1
	lda ALT_VSYNC_HB
	sta VsyncAddress1 + 2
	sta WaitVSync + 2

Hook:

	sei 
	lda IRQ1V		//IRQ1V - Main interrupt vector
	sta _irq1v 
	lda IRQ1V+1 
	sta _irq1v + 1
	lda #<IRQHook		//New IRQ = $1103
	sta IRQ1V 
	lda #>IRQHook+1
	sta IRQ1V+1 
	cli 

MakeScores:

	ldx #$00

YReset:

	ldy #$00

mkScLoop:

	lda DefHigh,Y 
	sta HiScore,X 
	inx 
	iny 
	cpy #$18
	bcc mkScLoop
	cpx #$A9
	bcc YReset
	jmp Main

SystemCheck:

	jsr Check2
	bne L_BRS_305D_305A
	rts 

L_BRS_305D_305A:

	lda #$30
	sta TableOne + 1
	lda #$31
	sta TableOne + 2

Check2:

	ldy #$00

L_BRS_3069_3070:

	iny 
	lda (ErrorMessVec),Y
	beq L_BRS_3080_306C
	cmp #$30
	bne L_BRS_3069_3070
	ldx #$00

L_BRS_3074_307D:

	iny 
	lda TableOne,X 
	beq L_BRS_307F_3078
	inx 
	cmp (ErrorMessVec),Y 
	beq L_BRS_3074_307D

L_BRS_307F_3078:

	rts 

L_BRS_3080_306C:

	lda #$01
	rts
TableOne:	
	.byte $2E,$31,$30,$00,$0D
DefHigh:
// $3088	hiscore_t[24]  Default high score
	.byte $00,$10,$00
	.byte $41,$63,$6F,$72,$6E,$73,$6F,$66
	.byte $74,$0D
	.byte $03,$06,$06,$06,$06,$03
	.byte $03,$F3,$03,$0C,$0E,$0E,$0C,$03
	.byte $03,$F3,$53,$53,$53,$53,$53,$02
	.byte $02,$00,$41,$C7,$41,$82,$C3,$C7
	.byte $C3,$00,$00,$82,$00,$AA,$AA,$FF
	.byte $FF,$FF,$FF,$00,$00,$05,$00,$05
	.byte $05,$05,$00,$00,$00,$0F,$05,$0F
	.byte $00,$0F,$00,$00,$00,$0C,$08,$0C
	.byte $00,$0C,$00,$00,$00,$09,$01,$09
	.byte _originp_h,$09,$00,$00,$00,$03,$01,$01
	.byte $01,$03,$00,$00,$00,$0F,$0A,$0A
	.byte $0A,$0F,$00,$00,$00,$0A,$0A,$0A
	.byte $0A,$0A,$00,$00,$09,$88,$09,$92
	.byte _originp_h,$9C,$09,$A6,$09

.pseudopc $0E00 {

SurfaceY:
//SurfaceY $3100-$3300 these three pages get moved to $0E00

	.byte $22,$26,$2A,$2C,$28,$24,$20,$1C,$19,$19,$19,$19,$19,$19,$19,$19
	.byte $19,$19,$1A,$1D,$1E,$21,$22,$25,$26,$2A,$2D,$2E,$31,$32,$36,$3A
	.byte $3C,$38,$34,$30,$2D,$2C,$28,$24,$20,$1D,$1C,$19,$19,$19,$19,$19
	.byte $19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$1A,$1E,$22,$26,$2A,$2C

	.byte $28,$24,$20,$1E,$22,$26,$2A,$2C,$28,$26,$28,$24,$22,$24,$20,$1D
	.byte $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1E,$21,$22,$25
	.byte $26,$29,$2A,$2D,$2E,$31,$32,$36,$3A,$3D,$3E,$42,$45,$46,$48,$44
	.byte $42,$44,$40,$3E,$40,$3C,$39,$39,$38,$34,$31,$30,$2D,$2C,$29,$28

	.byte $25,$24,$20,$1D,$1C,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19
	.byte $19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$1A,$1E,$22,$24
	.byte $20,$1E,$20,$1E,$20,$1E,$20,$1C,$18,$14,$11,$11,$11,$12,$16,$19
	.byte $19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19

	.byte $19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19,$19
	.byte $19,$1A,$1D,$1E,$21,$22,$26,$2A,$2D,$2E,$31,$32,$35,$36,$39,$3A
	.byte $3D,$3E,$41,$40,$3C,$38,$35,$35,$34,$30,$2C,$29,$28,$25,$25,$24
	.byte $20,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1D,$1E

imgDigit:
//imgDigit
	.byte $30,$20,$20,$20,$20,$20,$30,$00,$20,$20,$20,$20,$20,$20,$20,$00//0
	.byte $10,$30,$10,$10,$10,$10,$30,$00,$00,$00,$00,$00,$00,$00,$20,$00//1
	.byte $30,$00,$00,$30,$20,$20,$30,$00,$20,$20,$20,$20,$00,$00,$20,$00//2
	.byte $30,$00,$00,$30,$00,$00,$30,$00,$20,$20,$20,$20,$20,$20,$20,$00//3
	.byte $20,$20,$20,$30,$00,$00,$00,$00,$20,$20,$20,$20,$20,$20,$20,$00//4
	.byte $30,$20,$20,$30,$00,$00,$30,$00,$20,$00,$00,$20,$20,$20,$20,$00//5
	.byte $30,$20,$20,$30,$20,$20,$30,$00,$20,$00,$00,$20,$20,$20,$20,$00//6
	.byte $30,$00,$00,$00,$00,$00,$00,$00,$20,$20,$20,$20,$20,$20,$20,$00//7
	.byte $30,$20,$20,$30,$20,$20,$30,$00,$20,$20,$20,$20,$20,$20,$20,$00//8
	.byte $30,$20,$20,$30,$00,$00,$30,$00,$20,$20,$20,$20,$20,$20,$20,$00//9
imgMan:	
	.byte $CC,$CD,$CD,$CC,$F3,$51,$51,$51//$0FA0 human 
imgPod:	
	.byte $00,$10,$10,$C3,$C3,$10,$10,$00,$82,$92,$92,$C3,$C3,$92,$92,$82//$0FA8 Pod
	.byte $00,$00,$00,$82,$82,$00,$00,$00
imgShipR:
	.byte $15,$3F,$15,$11,$11,$11,$33,$11,$00,$2A,$3F,$3F,$37,$33,$33,$33//$0FC0 ship R
	.byte $00,$00,$00,$2A,$3F,$3F,$3F,$37,$00,$00,$00,$00,$00,$3F,$3F,$3F
	.byte $00,$00,$00,$00,$00,$07,$07,$3F,$00,$00,$00,$00,$00,$08,$1D,$3F
imgShipL:
	.byte $00,$00,$00,$00,$00,$04,$2E,$3F,$00,$00,$00,$00,$00,$0B,$0B,$3F//$0FF0 ship L
	.byte $00,$00,$00,$00,$00,$3F,$3F,$3F,$00,$00,$00,$15,$3F,$3F,$3F,$3B
	.byte $00,$15,$3F,$3F,$3B,$33,$33,$33,$2A,$3F,$2A,$22,$22,$22,$37,$22
imgSurface:
	.byte $28,$28,$14,$14// \ down slope ($1020 planet surface tiles)
	.byte $00,$28,$3C,$14// - flat
	.byte $14,$14,$28,$28// / up slope
imgLander:
	.byte $00,$45,$CC,$CC,$44,$00,$44,$88,$CF,$CF,$44,$44,$CC,$CE,$44,$44//$102C Lander
	.byte $8A,$CF,$44,$44,$CC,$8A,$44,$00,$00,$00,$88,$88,$00,$00,$00,$88
imgMutant:
	.byte $00,$51,$CC,$CC,$44,$00,$44,$88,$0C,$0C,$51,$51,$F3,$D9,$51,$51//$104C mutant
	.byte $88,$F6,$44,$44,$E6,$88,$44,$00,$00,$00,$88,$88,$00,$00,$00,$88
imgBaiter:
	.byte $00,$44,$CD,$44//$106C baiter
	.byte $CC,$C0,$CA,$CC
	.byte $CC,$C0,$CF,$CC
	.byte $CC,$C0,$C5,$CC
	.byte $00,$88,$CE,$88

	.byte $00,$00,$00,$00,$00//5 unused bytes

	.byte $50,$E5,$76,$A8,$A2,$01,$A5,$76,$20,$73,$1D,$4C,$FB,$20,$68//$1088 fragment
imgBomber:
	.byte $51,$03,$06,$06,$06,$06,$03,$03,$F3,$03,$0C,$0E,$0E,$0C,$03,$03//$1094 bomber
	.byte $F3,$53,$53,$53,$53,$53,$02,$02
imgSwarmer:
	.byte $00,$41,$C7,$41,$82,$C3,$C7,$C3,$00,$00,$82,$00//$10AC swarmer
imgKugel:
	.byte $AA,$AA//$10B8 Kugel (bullet/mine)
imgShrapnel:
	.byte $FF,$FF,$FF,$FF//$10BA shrapnel
img250:
	.byte $00,$00,$05,$00,$05,$05,$05,$00,$00,$00,$0F,$05,$0F,$00,$0F,$00//$10BE 250
img500:
	.byte $00,$00,$0C,$08,$0C,$00,$0C,$00,$00,$00,$09,$01,$09,$09,$09,$00//$10CE 500 (250/500)

	.byte $00,$00,$03,$01,$01,$01,$03,$00,$00,$00,$0F,$0A,$0A,$0A,$0F,$00
	.byte $00,$00,$0A,$0A,$0A,$0A,$0A,$00

	.byte $00,$09,$88,$09,$92,$09,$9C,$09,$A6,$09//unused
}