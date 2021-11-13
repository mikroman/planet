//November 11, 2021
#import "constants.asm"
#import "labels.asm"


*=$1100 "Game"
	jmp Boot
IRQHook:	
	lda #$02
	bit $FE4D		//systemVIAInterruptFlagRegister
	beq L_BRS_110D_1108
	inc vsync 

L_BRS_110D_1108:


	jmp ($008C) 	//old IRQ

WaitVSync:

	lda vsync 
	cmp $1B 
	beq WaitVSync
	sta $1B 
	rts 

IsVSync:

	lda vsync 
	cmp $1B 
	rts 

SetPallette:

	pha 
	eor #$07		//top four bits define logical colour field, bottom four bits are the physical colour EOR 7.
	sta ULAPALETTE		//videoULAPaletteRegister
	pla 
	rts 

Out6845:

	stx SHEILA		//crtcAddressRegister
	sta $FE01		//crtcAddressWrite
	rts 

StartTimer:

	lda #$80		//one shot mode
	sta $FE6B		//userVIAAuxiliaryControlRegister:
	stx $FE64		//userVIATimer1CounterLow=#$80
	sty $FE65		//userVIATimer1CounterHigh=#$14
	rts 

TimerState:

	bit USR6522		//userVIARegisterB (input/output)
	rts 

AIBatch:

	ldx #$00
	jsr GetXScreen
	sta $2C 
	lda #$00
	sta $28 
	lda #$4D
	sta $29 
	lda $02 
	bpl L_BRS_1159_1150
	clc 
	adc #$4D
	sta $29 
	bne L_BRS_115B_1157

L_BRS_1159_1150:

	sta $28 

L_BRS_115B_1157:

	lda $25 
	sta $26 
	ldx $89 

L_BRS_1161_117F:

	jsr AIUnit
	ldx $89 

L_BRS_1166_1169:

	inx 
	cpx #$01
	beq L_BRS_1166_1169
	cpx #$20
	bne L_BRS_1178_116D
	ldx #$02
	lda Anim 
	beq L_BRS_1178_1174
	ldx #$00

L_BRS_1178_116D:
L_BRS_1178_1174:

	stx $89 
	jsr IsVSync
	dec $26 
	bne L_BRS_1161_117F
	rts 

AIAlt:

	ldx $22 
	jsr AIUnit
	inx 
	cpx #$25
	bne L_BRS_118E_118A
	ldx #$22

L_BRS_118E_118A:

	stx $22 
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
	sta $70 
	lda $2E06,Y 
	sta $71 
	jmp ($0070) 

L_BRS_11BB_1194:
L_BRS_11BB_1198:

	rts

AIShip:	 

	jmp MoveUnit

AIKudgel:
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

	lda $15 
	bne L_BRS_11E9_11DC
	jsr EraseUnit
	lda #$02
	sta Unit,X 
	jmp AIMutant

L_BRS_11E9_11DC:

	lda #$0A
	jsr ShootChance
	lda Param,X 
	pha 
	and #$3F
	tay 
	pla 
	bne L_BRS_11FB_11F6
	jmp J1VE

L_BRS_11FB_11F6:

	bmi L_BRS_1235_11FB
	lda $046F,X 
	cmp #$BE
	bcc L_BRS_1227_1202
	lda #$06
	jsr IsLinked
	bne L_BRS_122A_1209
	tya 
	tax 
	jsr KillUnit
	ldx $89 
	jsr EraseUnit
	lda #$02
	sta Unit,X 
	jmp AIMutant

L_BRS_121D_126D:
L_BRS_121D_1274:

	ldy #$01
	jsr InitDXY

L_BRS_1222_1240:

	lda #$00
	sta Param,X 

L_BRS_1227_1202:

	jmp AIUpdate

L_BRS_122A_1209:

	jsr EraseUnit
	lda #$01
	sta Unit,X 
	jmp InitUnit

L_BRS_1235_11FB:

	lda Param,X 
	asl 
	bmi L_BRS_1266_1239
	lda #$06
	jsr IsUnlinked
	bne L_BRS_1222_1240
	lda $0425,X 
	cmp $0425,Y 
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
	ora #$40
	sta Param,X 

L_BRS_1266_1239:

	lda Unit,Y 
	and #$7F
	cmp #$06
	bne L_BRS_121D_126D
	lda Param,Y 
	and #$C0
	bne L_BRS_121D_1274
	lda Param,Y 
	beq L_BRS_1286_1279
	lda #$00
	sta dY_l,X 
	sta dY_h,X 
	jmp AIUpdate

L_BRS_1286_1279:

	lda $046F,X 
	sec 
	sbc #$0A
	cmp $046F,Y 
	bcs L_BRS_12CF_128F
	sta $046F,Y 
	lda $2E46 
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
	lda $0425,X 
	adc #$00
	sta $0425,Y 
	tya 
	sta Param,X 
	txa 
	sta Param,Y 

L_BRS_12CF_128F:

	jmp AIUpdate

J1VE:

	jsr Random
	and #$1F
	cmp #$20
	bcs J1VE
	cmp #$02
	bcc J1VE
	tay 
	lda #$06
	jsr IsUnlinked
	bne J1VF
	sec 
	lda $0425,Y 
	sbc $0425,X 
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
	ora #$80
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
	lda $046F,X 
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
	lda $044A,X 
	sbc _temp_l 
	sta $044A,X 
	lda $046F,X 
	sbc _temp_h 
	sta $046F,X 
	jmp AIUpdate

L_BRS_134D_1331:
L_BRS_134D_1337:

	clc 
	lda $044A,X 
	adc _temp_l 
	sta $044A,X 
	lda $046F,X 
	adc _temp_h 
	sta $046F,X 
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
	lda $0425 
	sbc $0425,X 
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
	eor #$01
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

	ldy $0425 
	lda $1D 
	asl 
	lda $0425,X 
	bcc L_BRS_13E3_13DD
	tya 
	ldy $0425,X 

L_BRS_13E3_13DD:

	sty _temp 
	sec 
	sbc _temp 
	rts 

ABSYDisp:

	sec 
	lda $046F,X 
	sbc $046F 
	pha 
	asl 
	pla 
	bpl L_BRS_13F7_13F3
	eor #$FF

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
	and #$07
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
	lda $0425,X 
	sbc $0425 
	sta _temp 
	eor dX_h,X 
	bmi L_BRS_1457_1445
	lda _temp 
	bpl L_BRS_144D_1449
	eor #$FF

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
	lda $046F,X 
	sec 
	sbc #$62
	bcs L_BRS_1497_147A
	eor #$FF
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
	lda #$01
	jsr IsLinked
	bne L_BRS_14FC_14C1
	jmp AIUpdate

L_BRS_14C6_14B9:

	asl 
	bmi L_BRS_1509_14C7
	stx $85 
	ldx #$01
	jsr GetYSurf
	ldx $85 
	cmp $0470 
	bcs L_BRS_14D8_14D5
	rts 

L_BRS_14D8_14D5:

	dec $2D 
	lda $0426 
	sta $0425,X 
	lda $0470 
	sta $046F,X 
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
	cmp $046F,X 
	bcc AIUpdate
	lda dY_h,X 
	cmp #$FB
	bcs L_BRS_152C_1527
	jmp KillUnit

L_BRS_152C_1527:

	lda #$00
	sta Param,X 
	ldy #$06
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
	sbc $046F,X 
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

	ldx $89 
	jsr MoveUnit
	ldx $89 
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
	sta $2C81 
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

	lda $28 
	pha 
	lda $29 
	pha 
	lda #$00
	sta $28 
	lda #$50
	sta $29 
	ldx #$1F

L_BRS_15D6_161D:

	stx $85 
	lda Unit,X 
	bpl L_BRS_161A_15DB
	asl 
	bmi L_BRS_161A_15DE
	ldy pDot_l,X 
	sty $70 
	ldy pDot_h,X 
	beq L_BRS_161A_15E8
	sty $71 
	lda Dot,X 
	tax 
	stx $86 
	jsr MMBlit
	ldx $85 
	clc 
	lda $70 
	adc $02 
	sta $70 
	sta pDot_l,X 
	lda $71 
	adc $03 
	bpl L_BRS_160A_1605
	sec 
	sbc #$50

L_BRS_160A_1605:

	cmp #$30
	bcs L_BRS_1610_160C
	adc #$50

L_BRS_1610_160C:

	sta $71 
	sta pDot_h,X 
	ldx $86 
	jsr MMBlit

L_BRS_161A_15DB:
L_BRS_161A_15DE:
L_BRS_161A_15E8:

	ldx $85 
	dex 
	bpl L_BRS_15D6_161D
	pla 
	sta $29 
	pla 
	sta $28 
	rts 

MMBlit:

	lda $71 
	bne L_BRS_162B_1628
	rts 

L_BRS_162B_1628:

	ldy #$00
	lda ($70),Y 
	eor imgDot,X 
	sta ($70),Y 
	lda $71 
	sta $73 
	lda $70 
	sta $72 
	and #$07
	cmp #$07
	bne L_BRS_1654_1640
	clc 
	lda $72 
	adc #$78
	sta $72 
	lda $73 
	adc #$02
	bpl L_BRS_1652_164D
	sec 
	sbc #$50

L_BRS_1652_164D:

	sta $73 

L_BRS_1654_1640:

	iny 
	lda ($72),Y 
	eor $2D22,X 
	sta ($72),Y 
	rts 

MMUpdate:

	jsr TimerState
	bpl MMUpdate
	cpx #$20
	bcc L_BRS_1667_1664
	rts 

L_BRS_1667_1664:

	lda $28 
	pha 
	lda $29 
	pha 
	txa 
	pha 
	lda #$00
	sta $28 
	lda #$50
	sta $29 
	lda pDot_l,X 
	sta $70 
	lda pDot_h,X 
	sta $71 
	lda Dot,X 
	tax 
	jsr MMBlit
	pla 
	pha 
	tax 
	lda $046F,X 
	lsr 
	lsr 
	clc 
	adc #$C4
	tay 
	sec 
	lda X_l,X 
	sbc $20 
	lda $0425,X 
	sbc $21 
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
	lda $70 
	sta pDot_l,X 
	lda $71 
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
	sta $29 
	pla 
	sta $28 
	rts 

KeyFire:

	ldx #$B6		//Return key
	jsr ScanInkey
	beq L_BRS_16DA_16D6
	eor $2B 

L_BRS_16DA_16D6:

	stx $2B 
	beq L_BRS_16E7_16DC
	ldx #$03

L_BRS_16E0_16E5:

	lda $46,X 
	beq L_BRS_16E8_16E2
	dex 
	bpl L_BRS_16E0_16E5

L_BRS_16E7_16DC:

	rts 

L_BRS_16E8_16E2:

	stx $85 
	lda $046F 
	sec 
	sbc #$06
	tay 
	ldx #$00
	jsr GetXScreen
	tax 
	dex 
	lda #$81
	bit $1D 
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
	ldx $85 
	lda $70 
	sta $5A,X 
	sta $62,X 
	lda $71 
	sta $5E,X 
	sta $66,X 
	pla 
	sta $56,X 
	pla 
	sta $52,X 
	pla 
	sta $46,X 
	lda #$00
	sta $4A,X 
	sta $4E,X 
	lda #$04
	jmp PlaySound

DoLaser:

	ldx #$03

LZRight:

	lda #$08
	sta _offset_l 
	lda #$00
	sta _offset_h 
	lda $2A 
	ldy $46,X 
	bpl L_BRS_174C_173D
	lda #$F8
	sta _offset_l 
	lda #$FF
	sta _offset_h 
	sec 
	lda #$00
	sbc $2A 

L_BRS_174C_173D:

	sta $88 
	sec 
	lda $52,X 
	sbc $2A 
	sta $52,X 
	lda $46,X 
	bne L_BRS_175C_1757
	jmp LaserNext

L_BRS_175C_1757:

	lda $62,X 
	sta $70 
	lda $66,X 
	sta $71 
	clc 
	lda #$04
	adc $88 
	sta $87 

L_BRS_176B_1799:

	lda $52,X 
	ldy $46,X 
	bmi L_BRS_1779_176F
	cmp $29 
	bpl EraseLaser
	inc $52,X 
	bne L_BRS_177F_1777

L_BRS_1779_176F:

	cmp $28 
	bmi EraseLaser
	dec $52,X 

L_BRS_177F_1777:

	ldy $4E,X 
	jsr BlitLaser
	sta $4E,X 
	jsr NextPtr
	ldy #$00
	lda ($70),Y 
	and #$C0
	beq L_BRS_1797_178F
	jsr LaserHit
	bcs L_BRS_1797_1794
	rts 

L_BRS_1797_178F:
L_BRS_1797_1794:

	dec $87 
	bne L_BRS_176B_1799
	lda $70 
	sta $62,X 
	lda $71 
	sta $66,X 
	bne L_BRS_17DC_17A3

EraseLaser:

	lda $70 
	sta $72 
	lda $71 
	sta $73 
	lda $5A,X 
	sta $70 
	lda $5E,X 
	sta $71 
	lda #$00
	sta $46,X 
	lda $4A,X 
	tax 
	ldy #$00

L_BRS_17BE_17D3:
L_BRS_17BE_17D9:

	inx 
	lda imgLaser,X 
	eor ($70),Y 
	sta ($70),Y 
	cpx #$50
	bne L_BRS_17CC_17C8
	ldx #$4F

L_BRS_17CC_17C8:

	jsr NextPtr
	lda $70 
	cmp $72 
	bne L_BRS_17BE_17D3
	lda $71 
	cmp $73 
	bne L_BRS_17BE_17D9
	rts 

L_BRS_17DC_17A3:

	lda $5A,X 
	sta $70 
	lda $5E,X 
	sta $71 
	clc 
	lda #$01
	adc $88 
	sta $87 
	beq LaserNext
	bmi LaserNext

L_BRS_17EF_17FB:

	ldy $4A,X 
	jsr BlitLaser
	sta $4A,X 
	jsr NextPtr
	dec $87 
	bne L_BRS_17EF_17FB
	lda $70 
	sta $5A,X 
	lda $71 
	sta $5E,X 

LaserNext:

	dex 
	bmi L_BRS_180B_1806
	jmp LZRight

L_BRS_180B_1806:

	rts 

LaserHit:

	lda $70 
	pha 
	lda $71 
	pha 
	lda _offset_l 
	pha 
	lda _offset_h 
	pha 
	lda $52,X 
	jsr LZCollide
	pla 
	sta _offset_h 
	pla 
	sta _offset_l 
	pla 
	sta $71 
	pla 
	sta $70 
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
	lda imgLaser,Y 
	ldy #$00
	eor ($70),Y 
	sta ($70),Y 
	pla 
	cmp #$50
	bne L_BRS_1847_1843
	lda #$4F

L_BRS_1847_1843:

	rts 

NextPtr:

	clc 
	lda $70 
	adc _offset_l 
	sta $70 
	lda $71 
	adc _offset_h 
	bpl L_BRS_1857_1853
	lda #$30

L_BRS_1857_1853:

	cmp #$30
	bcs L_BRS_185D_1859
	adc #$50

L_BRS_185D_1859:

	sta $71 
	rts 

LZCollide:

	cmp #$50
	bcc L_BRS_1865_1862
	rts 

L_BRS_1865_1862:

	stx $85 
	sta $7A 
	lda $56,X 
	sta $7C 
	ldx #$02

L_BRS_186F_18E3:

	lda pSprite_h,X 
	beq L_BRS_18E0_1872
	lda $046F,X 
	sec 
	sbc $7C 
	cmp #$08
	bcs L_BRS_18E0_187C
	lda pSprite_l,X 
	and #$F8
	sta _temp 
	sec 
	lda $70 
	and #$F8
	sbc _temp 
	sta _offset_l 
	lda $71 
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
	cmp #$06
	bne L_BRS_18D1_18C8
	lda Param,X 
	cmp #$80
	beq L_BRS_18E0_18CF

L_BRS_18D1_18C8:

	lda #$03
	jsr PlaySound
	jsr ScoreUnit
	jsr KillUnit
	ldx $85 
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
	ldx $85 
	sec 
	rts 

KillUnit:

	lda Unit,X 
	and #$7F
	cmp #$08
	bcs EraseUnit
	cmp #$03
	beq KillU2
	pha 
	jsr KillU2
	pla 
	bcs L_BRS_1903_18FB
	cmp #$06
	beq L_BRS_1904_18FF
	dec $13 

L_BRS_1903_18FB:
L_BRS_1903_190B:
L_BRS_1903_1918:

	rts 

L_BRS_1904_18FF:

	lda #$0A
	jsr PlaySound
	dec $15 
	bne L_BRS_1903_190B
	jmp RMSurface

KillU2:

	lda Unit,X 
	pha 
	jsr EraseUnit
	pla 
	bcs L_BRS_1903_1918
	sta Unit,X 
	lda #$FF
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
	sty $70 
	ldy pDot_h,X 
	sty $71 
	beq L_BRS_194C_193E
	lda #$00
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
	sta $70 
	lda pSprite_h,X 
	sta $71 
	lda Unit,X 
	and #$7F
	tax 
	jsr XBLTSprite

L_BRS_1967_1952:

	pla 
	tax 
	jsr ClearData
	lda Unit,X 
	and #$7F
	cmp #$07
	bne L_BRS_1998_1973
	lda $0425,X 
	sta $2E2A 
	lda $046F,X 
	sec 
	sbc #$08
	sta $2E3A 
	jsr Random
	and #$07
	clc 
	adc #$05
	sta $2E22 
	txa 
	pha 
	lda #$85
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

	sta $27 
	and #$7F
	tay 
	lda Spawnc,Y 
	beq L_BRS_19F0_19AB
	sta $12 
	cpy #$01
	bne L_BRS_19B9_19B1
	lda $15 
	bne L_BRS_19B9_19B5
	ldy #$02

L_BRS_19B9_19B1:
L_BRS_19B9_19B5:
L_BRS_19B9_19EE:

	jsr MSPWFrame
	ldx #$02

L_BRS_19BE_19E2:
L_BRS_19BE_19EA:

	lda Unit,X 
	asl 
	bpl L_BRS_19DB_19C2
	tya 
	ora #$80
	sta Unit,X 
	jsr InitUnit
	cpy #$03
	beq L_BRS_19D7_19CF
	cpy #$06
	beq L_BRS_19D7_19D3
	inc $13 

L_BRS_19D7_19CF:
L_BRS_19D7_19D3:

	dec $12 
	beq L_BRS_19F0_19D9

L_BRS_19DB_19C2:

	txa 
	clc 
	adc #$05
	tax 
	cpx #$20
	bcc L_BRS_19BE_19E2
	sec 
	sbc #$1D
	tax 
	cpx #$07
	bne L_BRS_19BE_19EA
	bit $27 
	bpl L_BRS_19B9_19EE

L_BRS_19F0_19AB:
L_BRS_19F0_19D9:

	rts 

MSPWFrame:

	lda $27 
	bmi L_BRS_1A06_19F3
	pha 
	lda $12 
	pha 
	tya 
	pha 
	jsr Frame
	pla 
	tay 
	pla 
	sta $12 
	pla 
	sta $27 

L_BRS_1A06_19F3:

	rts 

SpawnBait:

	dec $18 
	bne L_BRS_1A23_1A09
	dec $19 
	bne L_BRS_1A23_1A0D
	lda #$01
	sta $2E20 
	lda $0425 
	sta $2E28 
	lda #$83
	jsr MSpawn
	lda #$02
	sta $19 

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
	sta $0425,X 
	jsr Random
	and YRangeInit,Y 
	clc 
	adc YMinInit,Y 
	cmp #$C0
	bcc L_BRS_1A61_1A5D
	sbc #$C0

L_BRS_1A61_1A5D:

	sta $046F,X 

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
	cpx #$08
	bne L_BRS_1AB3_1ABD
	rts 

SmartBomb:

	lda $38 
	bne L_BRS_1AC5_1AC2
	rts 

L_BRS_1AC5_1AC2:

	sed
	sec 
	lda $38 
	sbc #$01
	sta $38 
	cld 
	ldx #$00
	ldy #$00
	jsr AddScore
	lda #$00
	jsr Deteonate
	lda #$01

Deteonate:

	sta $3B 
	lda #$07
	sta $0F 
	ldx #$02
	jsr DoNFrames
	jsr BombScreen
	lda #$00
	sta $0F 
	ldx #$02
	jsr DoNFrames
	rts 

BombScreen:

	ldx #$02

L_BRS_1AF6_1B32:

	lda Unit,X 
	asl 
	bmi BombNext
	lsr 
	cmp #$06
	beq BombNext
	lda Anim,X 
	bne BombNext
	lda pSprite_h,X 
	bne L_BRS_1B29_1B09
	lda $3B 
	beq BombNext
	lda Unit,X 
	and #$7F
	cmp #$05
	bne BombNext
	jsr GetXScreen
	cmp #$50
	bcs BombNext
	lda $0425,X 
	eor #$80
	sta $0425,X 
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

	stx $85 
	lda HyperKeys,X 
	tax 
	jsr ScanInkey
	bne L_BRS_1B48_1B40
	ldx $85 
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
	ldx #$01
	cmp #$28
	bcs L_BRS_1B65_1B61
	ldx #$41

L_BRS_1B65_1B61:

	stx Anim 
	lda #$08
	sta Param 
	rts 

FrameNoCheck:

	lda $1A 
	ora $15
	bne L_BRS_1B97_1B72
	lda #$01
	sta $1A 

L_BRS_1B78_1B95:

	iny 
	tya 
	and #$07
	pha 
	tay 
	lda FlashPal,Y 
	and #$0F
	sta $0F 
	ldx #$03
	jsr DoNFrames
	lda #$00
	sta $0F 
	ldx #$04
	jsr DoNFrames
	pla 
	tay 
	bne L_BRS_1B78_1B95

L_BRS_1B97_1B72:

	jmp FrameAll

ShootChance:

	sta _temp 
	lda $24 
	beq L_BRS_1BA1_1B9E
	rts 

L_BRS_1BA1_1B9E:

	jsr Random
	cmp _temp 
	bcs L_BRS_1BC1_1BA6
	sec 
	lda $0425 
	sbc $0425,X 
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
	lda $0425 
	sbc $0425,X 
	jsr DistDiv64
	sta $73 
	clc 
	lda _temp_l 
	sta $72 
	adc dX_l 
	sta dX_l,Y 
	lda _temp_h 
	adc dX_h 
	sta dX_h,Y 
	sec 
	lda $046F 
	sbc $046F,X 
	jsr DistDiv64
	sta $71 
	sta dY_h,Y 
	lda _temp_l 
	sta $70 
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

	lda $72 
	ora $73
	beq L_BRS_1C4B_1C1D
	lda dX_l,Y 

ShootSpeed:

	cmp $3A 
	bcs L_BRS_1C4B_1C24
	clc 
	lda dX_l,Y 
	adc $72 
	sta dX_l,Y 
	lda dX_h,Y 
	adc $73 
	sta dX_h,Y 
	clc 
	lda dY_l,Y 
	adc $70 
	sta dY_l,Y 
	lda dY_h,Y 
	adc $71 
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

	ldy #$20
	bne L_BRS_1C8A_1C86

SpawnMisc:

	ldy #$22

L_BRS_1C8A_1C86:
L_BRS_1C8A_1C92:

	jsr ShootID
	bcc L_BRS_1C94_1C8D
	iny 
	cpy #$25
	bne L_BRS_1C8A_1C92

L_BRS_1C94_1C8D:

	rts 

ShootID:

	lda Unit,Y 
	eor #$C0
	asl 
	asl 
	bcs L_BRS_1CCA_1C9C
	lda #$88
	sta Unit,Y 
	lda X_l,X 
	sta X_l,Y 
	clc 
	lda $0425,X 
	adc #$01
	sta $0425,Y 
	lda $044A,X 
	sta $044A,Y 
	sec 
	lda $046F,X 
	sbc #$04
	sta $046F,Y 
	lda #$00
	sta Param,Y 
	sta Anim,Y 
	clc 

L_BRS_1CCA_1C9C:

	rts 

Frame:

	ldx #$9F		//Space bar
	jsr ScanInkey
	beq L_BRS_1CD4_1CD0
	eor $0E 

L_BRS_1CD4_1CD0:

	stx $0E 
	beq L_BRS_1CDB_1CD6
	jsr SmartBomb

L_BRS_1CDB_1CD6:

	jsr KeysHyper
	jsr FrameNoCheck
	lda $24 
	bne L_BRS_1CE6_1CE3
	rts 

L_BRS_1CE6_1CE3:

	lda #$07
	sta $0F 
	jsr FrameAll
	lda #$00
	sta $0F 
	ldx #$32
	jsr DoNFrames
	ldx #$00
	stx $24 
	jsr EraseUnit
	lda #$0C
	jsr PlaySound
	ldx #$1F

L_BRS_1D04_1D41:

	jsr ClearSPtrs
	lda Unit,X 
	sta Param,X 
	lda Anim,X 
	sta pDot_l,X 
	lda #$80
	sta Unit,X 
	lda #$00
	sta Anim,X 
	sta pDot_h,X 
	lda $0425 
	clc 
	adc #$02
	sta $0425,X 
	lda X_l 
	sta X_l,X 
	lda $046F 
	sta $046F,X 
	lda $044A 
	sta $044A,X 
	ldy #$00
	jsr InitDXY
	dex 
	bpl L_BRS_1D04_1D41
	lda #$BA
	sta SpriteV_l 
	lda #$10
	sta SpriteV_h 
	lda #$04
	sta SpriteLen 
	lda $25 
	pha 
	lda #$1E
	sta $25 
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
	lda #$F1
	jsr SetPallette

L_BRS_1D71_1D6A:

	dex 
	bne L_BRS_1D5B_1D72
	ldx #$1F

L_BRS_1D76_1D83:

	lda Param,X 
	sta Unit,X 
	lda pDot_l,X 
	sta Anim,X 
	dex 
	bpl L_BRS_1D76_1D83
	pla 
	sta $25 
	ldx #$64
	jsr Delay
	sed
	sec 
	lda $37 
	sbc #$01
	sta $37 
	cld 
	lda $40 
	ora $13
	beq L_BRS_1DA4_1D9A
	lda $37 
	bne L_BRS_1DA8_1D9E
	ldx $39 
	txs 
	rts 

L_BRS_1DA4_1D9A:

	ldx $3F 
	txs 
	rts 

L_BRS_1DA8_1D9E:

	jsr ContLevel
	ldx #$32
	jsr Delay
	rts 

Game:

	tsx 
	stx $3F 
	lda #$01
	sta $40 
	lda #$06
	jsr MSpawn
	lda #$00
	sta $2E23 
	ldx #$14
	jsr DoNFrames
	jsr MSpawnAll
	jsr SpawnSquad
	jsr SpawnSquad
	lda $16 
	cmp #$06
	bcc L_BRS_1DD9_1DD4
	jsr SpawnSquad

L_BRS_1DD9_1DD4:

	lda #$00
	sta $40 

L_BRS_1DDD_1DE2:

	jsr Frame
	lda $13 
	bne L_BRS_1DDD_1DE2
	rts 

SpawnSquad:

	lda #$00
	sta $10 
	sta $11 

L_BRS_1DEB_1E00:

	jsr Frame
	lda $13 
	beq L_BRS_1E02_1DF0
	lda $15 
	beq L_BRS_1E02_1DF4
	inc $10 
	bne L_BRS_1DFC_1DF8
	inc $11 

L_BRS_1DFC_1DF8:

	lda $11 
	cmp $14 
	bne L_BRS_1DEB_1E00

L_BRS_1E02_1DF0:
L_BRS_1E02_1DF4:

	lda #$01
	jsr MSpawn
	rts 

RMSurface:

	txa 
	pha 
	lda #$60
	sta $3E 
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
	cmp #$20
	bne L_BRS_1E24_1E2E
	rts 

XYToVidP:

	lda #$00
	sta $71 
	cpx $28 
	bcc L_BRS_1E7D_1E37
	cpx $29 
	bcs L_BRS_1E7D_1E3B
	tya 
	eor #$FF
	pha 
	lsr 
	lsr 
	lsr 
	tay 
	lsr 
	sta _temp 
	lda #$00
	ror 
	adc $08 
	php 
	sta $70 
	tya 
	asl 
	adc _temp 
	plp 
	adc $09 
	sta $71 
	lda #$00
	sta _temp 
	txa 
	asl 
	rol _temp 
	asl 
	rol _temp 
	asl 
	rol _temp 
	adc $70 
	sta $70 
	lda _temp 
	adc $71 
	bpl L_BRS_1E74_1E6F
	sec 
	sbc #$50

L_BRS_1E74_1E6F:

	sta $71 
	pla 
	and #$07
	ora $70
	sta $70 

L_BRS_1E7D_1E37:
L_BRS_1E7D_1E3B:

	rts 

XORBlit:

	lda $71 
	bne L_BRS_1E83_1E80
	rts 

L_BRS_1E83_1E80:

	lda #$00
	sta $8A 
	lda $75 
	pha 
	ldy #$00

L_BRS_1E8C_1EF1:

	lda $71 
	pha 
	lda $70 
	pha 
	lda $70 
	and #$07
	sta $74 
	lda $70 
	and #$F8
	sta $70 

L_BRS_1E9E_1EC1:

	lda ($72),Y 
	php 
	iny 
	sty _temp 
	ldy $74 
	eor ($70),Y 
	sta ($70),Y 
	iny 
	plp 
	beq L_BRS_1EB2_1EAC
	ora $8A
	sta $8A 

L_BRS_1EB2_1EAC:

	cpy #$08
	beq L_BRS_1EC9_1EB4

L_BRS_1EB6_1EDD:

	sty $74 
	ldy _temp 
	tya 
	and $84
	beq L_BRS_1EDF_1EBD
	dec $75 
	bne L_BRS_1E9E_1EC1
	pla 
	pla 
	pla 
	sta $75 
	rts 

L_BRS_1EC9_1EB4:

	ldy #$00
	clc 
	lda $70 
	adc #$80
	sta $70 
	lda $71 
	adc #$02
	bpl L_BRS_1EDB_1ED6
	sec 
	sbc #$50

L_BRS_1EDB_1ED6:

	sta $71 
	bne L_BRS_1EB6_1EDD

L_BRS_1EDF_1EBD:

	clc 
	pla 
	adc #$08
	sta $70 
	pla 
	adc #$00
	bpl L_BRS_1EED_1EE8
	sec 
	sbc #$50

L_BRS_1EED_1EE8:

	sta $71 
	dec $75 
	bne L_BRS_1E8C_1EF1
	pla 
	sta $75 
	rts 

ScreenStart:

	lda $08 
	sta _temp 
	lda $09 
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
	lda $0F 
	jsr SetPallette
	lda $15 
	bne L_BRS_1F2F_1F26
	lda $0F 
	ora #$60
	jsr SetPallette

L_BRS_1F2F_1F26:

	dec $35 
	bne L_BRS_1F46_1F31
	lda $36 
	sta $35 
	inc $34 
	lda $34 
	and #$07
	sta $34 
	tax 
	lda FlashPal,X 
	jsr SetPallette

L_BRS_1F46_1F31:

	inc $3D 
	lda $3D 
	and #$03
	bne L_BRS_1F70_1F4C
	ldx rotatec 
	lda #$10

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
	sta $78 
	sty $7E 
	ldy $0C,X 

L_BRS_1F78_1F80:

	jsr XBltSurface
	inc $7E 
	iny 
	dec $78 
	bne L_BRS_1F78_1F80
	tya 
	sta $0C,X 
	pla 
	rts 

PSurfLeft:

	pha 
	sta $78 
	sty $7E 
	ldy $0C,X 

L_BRS_1F8E_1F96:

	dec $7E 
	dey 
	jsr XBltSurface
	inc $78 
	bne L_BRS_1F8E_1F96
	tya 
	sta $0C,X 
	pla 
	rts 

XBltSurface:

	stx $85 
	sty $86 
	tya 
	and #$03
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

	and #$03
	asl 
	asl 
	adc #$20
	sta $72 
	lda #$10
	sta $73 
	ldx $7E 
	ldy $86 
	lda SurfaceY,Y
	tay 
	jsr XYToVidP
	lda #$04
	sta $75 
	lda #$07
	sta $84 
	jsr XORBlit
	ldx $7E 
	ldy #$C4
	jsr XYToVidP
	ldy #$00
	lda #$F0
	eor ($70),Y 
	sta ($70),Y 
	iny 
	lda #$F0
	eor ($70),Y 
	sta ($70),Y 
	ldx $85 
	ldy $86 
	rts 

ShipAll:

	lda Anim 
	beq L_BRS_1FF8_1FF3
	jmp ScrollScreen

L_BRS_1FF8_1FF3:

	lda $24 
	beq L_BRS_2016_1FFA
	lda $3C 
	eor #$80
	sta $3C 
	bmi L_BRS_200B_2002
	eor #$06
	sta $3C 
	jsr SetPallette

L_BRS_200B_2002:

	lda #$00
	sta dX_l 
	sta dX_h 
	jmp UpdateShip

L_BRS_2016_1FFA:

	jsr KeyFire
	ldx #$BE		//A key
	jsr ScanInkey
	beq L_BRS_202D_201E
	clc 
	lda $046F 
	adc #$02
	cmp #$C3
	bcs L_BRS_202D_2028
	sta $046F 

L_BRS_202D_201E:
L_BRS_202D_2028:

	ldx #$9E		//Z key
	jsr ScanInkey
	beq L_BRS_2041_2032
	sec 
	lda $046F 
	sbc #$02
	cmp #$09
	bcc L_BRS_2041_203C
	sta $046F 

L_BRS_2041_2032:
L_BRS_2041_203C:

	ldx #$9D		//TAB key
	jsr ScanInkey
	beq L_BRS_204A_2046
	eor $23 

L_BRS_204A_2046:

	stx $23 
	beq L_BRS_2077_204C
	lda pSprite_l 
	sta $70 
	lda pSprite_h 
	sta $71 
	ldx #$00
	jsr XBLTSprite
	lda SpriteV_l 
	eor #$30
	sta SpriteV_l 
	lda #$00
	sta pSprite_h 
	sec 
	lda #$00
	sbc $1C 
	sta $1C 
	lda #$00
	sbc $1D 
	sta $1D 

L_BRS_2077_204C:

	ldx #$FF		//Shift key
	jsr ScanInkey
	beq L_BRS_208F_207C
	clc 
	lda dX_l 
	adc $1C 
	sta dX_l 
	lda dX_h 
	adc $1D 
	sta dX_h 

L_BRS_208F_207C:

	lda dX_h 
	ora dX_l
	beq L_BRS_20EB_2095
	lda dX_h 
	bpl L_BRS_20C2_209A
	clc 
	lda dX_l 
	adc #$03
	sta dX_l 
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
	sta dX_l 
	beq L_BRS_20EB_20C0

L_BRS_20C2_209A:

	sec 
	lda dX_l 
	sbc #$03
	sta dX_l 
	lda dX_h 
	sbc #$00
	sta dX_h 
	bcc L_BRS_20E3_20D3
	lda dX_h 
	cmp #$01
	bmi L_BRS_20EB_20DA
	lda #$00
	sta dX_l 
	beq L_BRS_20EB_20E1

L_BRS_20E3_20AD:
L_BRS_20E3_20D3:

	lda #$00
	sta dX_l 
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
	lda $1D 
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
	adc dX_l 
	sta $1E 
	tya 
	adc dX_h 
	sta $1F 
	clc 
	lda $1E 
	adc $20 
	sta $20 
	lda $1F 
	adc $21 
	sta $21 

UpdateShip:

	jsr ScrollScreen
	ldx #$00
	jsr MoveXUnit
	ldx #$00
	jsr MMUpdate
	rts 

Hitchhiker:

	lda $2D 
	beq L_BRS_215D_2134
	lda #$06
	sta $05BD 
	lda X_l 
	clc 
	adc #$80
	sta $0401 
	lda #$00
	adc $0425 
	sta $0426 
	lda $046F 
	sec 
	sbc #$0A
	sta $0470 
	ldx #$01
	jsr NextVidP
	jmp MMUpdate

L_BRS_215D_2134:

	ldx #$01
	jmp EraseUnit

MoveUnit:

	lda Unit,X 
	and #$77
	tay 
	clc 
	lda dY_l,X 
	adc $044A,X 
	sta $044A,X 
	lda dY_h,X 
	adc $046F,X 
	cmp #$C3
	bcc L_BRS_2182_217A
	cpy #$00
	beq L_BRS_21D1_217E
	lda #$09

L_BRS_2182_217A:

	cmp #$09
	bcs L_BRS_219A_2184
	cpy #$00
	bne L_BRS_2190_2188
	cmp #$04
	bcs L_BRS_219A_218C
	bcc L_BRS_21D1_218E

L_BRS_2190_2188:

	cpy #$06
	php 
	lda #$C2
	plp 
	bne L_BRS_219A_2196
	lda #$09

L_BRS_219A_2184:
L_BRS_219A_218C:
L_BRS_219A_2196:

	sta $046F,X 

MoveXUnit:

	clc 
	lda dX_l,X 
	adc X_l,X 
	sta X_l,X 
	lda dX_h,X 
	adc $0425,X 
	sta $0425,X 

NextVidP:

	ldy $046F,X 
	txa 
	pha 
	jsr GetXScreen
	tax 
	jsr XYToVidP
	pla 
	tax 

L_BRS_21BE_21D5:

	lda $70 
	sta pNext_l,X 
	lda $71 
	sta pNext_h,X 
	lda Unit,X 
	and #$7F
	sta Unit,X 
	rts 

L_BRS_21D1_217E:
L_BRS_21D1_218E:

	lda #$00
	sta $71 
	beq L_BRS_21BE_21D5

GetXScreen:

	sec 
	lda X_l,X 
	sbc $20 
	sta _offset_l 
	lda $0425,X 
	sbc $21 
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

	ldx #$00

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
	cpx #$00
	bne L_BRS_2246_221A

L_BRS_221C_220E:
L_BRS_221C_2216:

	lda pSprite_l,X 
	sta $70 
	lda pSprite_h,X 
	sta $71 
	lda Unit,X 
	and #$7F
	tax 
	jsr XBLTSprite
	pla 
	tax 
	lda pNext_l,X 
	sta pSprite_l,X 
	sta $70 
	lda pNext_h,X 
	sta pSprite_h,X 
	sta $71 
	txa 
	pha 
	jsr XORBlit

L_BRS_2246_21FC:
L_BRS_2246_2206:
L_BRS_2246_221A:

	pla 
	tax 
	inx 
	cpx #$25
	bne L_BRS_21F7_224B
	rts 

XBLTSprite:

	lda $2D4D,X //$07,$07,$07,$03,$07,$03,$0F,$07,$03,$07,$07
	sta $84 
	lda SpriteLen,X //$30,$20,$20,$14,$18,$0C,$08,$18,$02,$28,$28
	sta $75 
	lda SpriteV_l,X //$C0,$2C,$4C,$6C,$94,$AC,$A0,$A8,$B8,$BE,$CE
	sta $72 
	lda SpriteV_h,X //$0F,$10,$10,$10,$10,$10,$0F,$0F,$10,$10,$10
	sta $73 
	jsr XORBlit
	cpx #$00
	bne L_BRS_226D_2267
	lda $8A 
	sta $8B 

L_BRS_226D_2267:

	rts 

ScrollSurface:

	lda #$00
	sta $28 
	lda #$50
	sta $29 
	lda $08 
	pha 
	lda $09 
	pha 
	lda $00 
	sta $08 
	lda $01 
	sta $09 
	lda $2A 
	beq L_BRS_22C8_2286
	bpl L_BRS_22A9_2288
	ldx #$01
	ldy #$50
	jsr PSurfLeft
	sta _temp 
	pla 
	sta $09 
	pla 
	sta $08 
	sec 
	lda #$00
	sbc _temp 
	tay 
	ldx #$00
	lda _temp 
	jsr PSurfLeft
	jmp SSurfRTS

L_BRS_22A9_2288:

	ldx #$00
	ldy #$00
	jsr PSurfRight
	sta _temp 
	pla 
	sta $09 
	pla 
	sta $08 
	sec 
	lda #$50
	sbc _temp 
	tay 
	ldx #$01
	lda _temp 
	jsr PSurfRight
	jmp SSurfRTS

L_BRS_22C8_2286:

	pla 
	sta $09 
	pla 
	sta $08 

SSurfRTS:

	rts 

ScrollScreen:

	lda $08 
	sta $00 
	lda $09 
	sta $01 
	lda $20 
	asl 
	lda $21 
	rol 
	pha 
	sec 
	sbc $0A 
	sta $2A 
	asl 
	asl 
	asl 
	ldy #$00
	bcc L_BRS_22EC_22E8
	ldy #$FF

L_BRS_22EC_22E8:

	sta $02 
	clc 
	adc $08 
	sta $08 
	tya 
	sta $03 
	adc $09 
	bpl L_BRS_22FD_22F8
	sec 
	sbc #$50

L_BRS_22FD_22F8:

	cmp #$30
	bcs L_BRS_2303_22FF
	adc #$50

L_BRS_2303_22FF:

	sta $09 
	pla 
	sta $0A 
	jmp ScreenStart

Collision:

	lda $8B 
	and #$C0
	beq L_BRS_2315_230F
	lda $24 
	beq L_BRS_2316_2313

L_BRS_2315_230F:

	rts 

L_BRS_2316_2313:

	ldx #$00
	jsr GetXScreen
	sta $2C 
	ldx #$24

L_BRS_231F_2389:

	lda Unit,X 
	asl 
	bmi CollideNext
	cmp #$12
	bcs CollideNext
	lda Anim,X 
	bne CollideNext
	lda $046F,X 
	sec 
	sbc $046F 
	cmp #$08
	bpl CollideNext
	cmp #$F9
	bmi CollideNext
	jsr GetXScreen
	cmp #$50
	bcs CollideNext
	sec 
	sbc $2C 
	cmp #$06
	bpl CollideNext
	cmp #$FD
	bmi CollideNext
	lda Unit,X 
	and #$7F
	cmp #$06
	beq L_BRS_2366_2356
	jsr ScoreUnit
	jsr KillUnit
	lda #$01
	sta $24 
	lda #$77
	sta $3C 

L_BRS_2366_2356:

	lda Param,X 
	bpl CollideNext
	cmp #$80
	beq CollideNext
	jsr EraseUnit
	lda #$80
	sta Param,X 
	lda #$86
	sta Unit,X 
	inc $2D 
	lda #$0E
	jsr PlaySound
	jsr Score500

CollideNext:

	dex 
	cpx #$02
	bcs L_BRS_231F_2389
	rts 

Random:

	txa 
	pha 
	ldx #$08

L_BRS_2390_239F:

	lda $80 
	and #$48
	adc #$38
	asl 
	asl 
	rol $82 
	rol $81 
	rol $80 
	dex 
	bne L_BRS_2390_239F
	pla 
	tax 
	lda $80 
	rts 

NextLevel:

	sed
	lda $16 
	clc 
	adc #$01
	sta $16 
	cmp #$05
	bcc L_BRS_23B4_23B0
	lda #$05

L_BRS_23B4_23B0:

	sta $17 
	lda $16 
	sec 
	ldx #$65		//pallete colour(terrain)

L_BRS_23BB_23BD:

	sbc #$05
	bcs L_BRS_23BB_23BD
	cmp #$95
	bne L_BRS_23CF_23C1
	lda #$A		//#of humanoids
	sta $15 
	lda #$00
	sta $1A 
	ldx #$62
	inc $25 

L_BRS_23CF_23C1:

	cld 
	lda $15 
	bne L_BRS_23D6_23D2
	ldx #$60

L_BRS_23D6_23D2:

	stx $3E 
	clc 
	lda $3A 
	adc #$08
	sta $3A 
	lda #$0A
	sta $19 
	lda #$00
	sta $2E20 
	lda $15 
	sta $2E23 
	ldx #$1F
	lda #$FF

L_BRS_23F1_23F5:

	sta Unit,X 
	dex 
	bpl L_BRS_23F1_23F5
	lda #$00
	sta $2D 
	lda #$22
	sta $22 
	lda #$00
	sta rotatec 
	sta $34 
	lda #$06
	sta $36 
	sta $35 
	lda #$00
	sta $13 
	lda #$02
	sta $14 
	lda #$00
	sta $2E22 
	ldx #$00
	lda $16 
	cmp #$01
	beq L_BRS_2429_241F
	ldx #$04
	cmp #$04
	bcc L_BRS_2429_2425
	ldx #$07

L_BRS_2429_241F:
L_BRS_2429_2425:

	stx $2E21 
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

	stx $2E24 
	lda $2E46 
	clc 
	adc #$02
	cmp #$18		//progressive difficulty
	bcs L_BRS_244E_2449
	sta $2E46 

L_BRS_244E_2449:

	lda #$00
	sta $0F 

ContLevel:

	lda #$80
	sta $2E2A 
	ldx #$1F

L_BRS_2459_246E:

	lda Unit,X 
	and #$7F
	cmp #$03
	bne L_BRS_2467_2460
	lda #$FF
	sta Unit,X 

L_BRS_2467_2460:

	jsr resetUnit
	jsr InitUnit
	dex 
	bpl L_BRS_2459_246E
	lda #$02
	sta $89 
	lda #$00
	sta $2D 
	lda #$FF
	sta $23 
	sta $2B 
	sta $0E 

NewScreen:

	sta $21 
	asl 
	sta $0A 
	lda #$00
	sta $20 
	lda #$80
	sta X_l 
	clc 
	lda $21 
	adc #$07
	sta X_h 
	lda #$00
	sta $044A 
	lda #$64
	sta $046F 
	lda #$07
	sta $1C 
	lda #$00
	sta $1D 
	lda #$00
	ldx #$03

L_BRS_24AC_24AF:

	sta $46,X 
	dex 
	bpl L_BRS_24AC_24AF
	lda #$FF
	sta $05BD 
	ldx #$24

L_BRS_24B8_24C3:

	lda #$FF
	sta Unit,X 
	jsr ClearData
	dex 
	cpx #$20
	bpl L_BRS_24B8_24C3

L_BRS_24C5_24C9:

	jsr resetUnit
	dex 
	bpl L_BRS_24C5_24C9
	lda #$80
	sta $05E2 
	lda #$00
	sta Unit 
	sta dX_l 
	sta dX_h 
	sta Anim 
	sta $24 
	sta $8B 
	lda #$C0
	sta SpriteV_l 
	lda #$0F
	sta SpriteV_h 
	lda #$30
	sta SpriteLen 
	lda #$00
	sta $2A 
	sta $02 
	sta $03 
	lda #<VRAM
	sta $08 
	sta $00 
	lda #>VRAM
	sta $09 
	sta $01 
	sta $2F 
	lda #<VRAM + (26*8)
	sta $2E 
	jsr WaitVSync
	lda #$00

L_BRS_2510_2516:

	jsr SetPallette
	clc 
	adc #$10
	bne L_BRS_2510_2516
	lda #$00
	jsr PrintN
	lda #$80

L_BRS_251F_2525:

	jsr SetPallette
	clc 
	adc #$11
	bcc L_BRS_251F_2525
	lda #$47
	jsr SetPallette
	lda $3E 
	jsr SetPallette
	lda #$00
	sta $28 
	lda #$50
	sta $29 
	lda $0A 
	sta _xwinleft 
	sta $0D 
	ldx #$01
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
	lda #$FF
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

	lda #$00
	sta pNext_h,X 
	sta pSprite_h,X 
	rts 

PrintN:

	stx $41 
	sty $42 
	tax 
	lda StringV_l,X 
	sta $70 
	lda StringV_h,X 
	sta $71 
	ldy #$00
	lda ($70),Y 
	sta $44 

L_BRS_258F_2597:

	iny 
	lda ($70),Y 
	jsr OSWRCH
	cpy $44 
	bne L_BRS_258F_2597
	ldx $41 
	ldy $42 
	rts 

ScoreUnit:

	txa 
	pha 
	tya 
	pha 
	lda Unit,X 
	cmp #$FF
	beq L_BRS_25B7_25A7
	and #$7F
	tax 
	lda Points_h,X 
	tay 
	lda $2D58,X 
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
	lda #$8A
	sta Unit,Y 

L_BRS_25D3_2619:

	clc 
	lda $046F,Y 
	adc #$0C
	sta $046F,Y 
	lda dX_h 
	asl 
	lda dX_h 
	ror 
	sta dX_h,Y 
	lda dX_l 
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
	lda #$89
	sta Unit,Y 
	bne L_BRS_25D3_2619

AddScore:

	sed
	clc 
	txa 
	adc $30 
	sta $30 
	tya 
	adc $31 
	sta $31 
	php 
	lda #$00
	adc $32 
	sta $32 
	plp 
	cld 
	bcc L_BRS_2635_2630
	jsr Reward

L_BRS_2635_2630:

	lda $2E 
	sta $70 
	lda $2F 
	sta $71 
	lda #$00
	sta $33 
	ldx #$02

L_BRS_2643_2649:

	lda $30,X 
	jsr PaintBCD
	dex 
	bpl L_BRS_2643_2649
	lda #$00
	sta $33 
	jsr PaintDigit
	ldx #$00
	lda $37 
	jsr PaintBCD
	lda #$00
	sta $33 
	jsr PaintDigit
	ldx #$00
	lda $38 

PaintBCD:

	pha 
	and #$F0
	jsr PaintDigit
	cpx #$00
	bne L_BRS_2672_266C
	lda #$01
	sta $33 

L_BRS_2672_266C:

	pla 
	asl 
	asl 
	asl 
	asl 

PaintDigit:

	stx _temp 
	tax 
	ora $33
	sta $33 
	ldy #$00

L_BRS_2680_26A8:

	lda $33 
	beq L_BRS_2689_2682
	lda imgDigit,X 		//HUD numbers
	sta ($70),Y 

L_BRS_2689_2682:

	iny 
	inx 
	tya 
	and #$07
	tay 
	bne L_BRS_26A5_268F
	clc 
	lda $70 
	adc #$08
	sta $70 
	bcc L_BRS_26A5_2698
	inc $71 
	bpl L_BRS_26A5_269C
	lda $71 
	sec 
	sbc #$50
	sta $71 

L_BRS_26A5_268F:
L_BRS_26A5_2698:
L_BRS_26A5_269C:

	txa 
	and #$0F
	bne L_BRS_2680_26A8
	ldx _temp 
	rts 

RepaintDigit:

	ldy #$00
	lda $02 
	bpl L_BRS_26B5_26B1
	ldy #$FF

L_BRS_26B5_26B1:

	sty _temp 
	clc 
	lda $2E 
	sta $72 
	adc $02 
	sta $70 
	sta $2E 
	lda $2F 
	sta $73 
	adc _temp 
	bpl L_BRS_26CD_26C8
	sec 
	sbc #$50

L_BRS_26CD_26C8:

	cmp #$30
	bcs L_BRS_26D3_26CF
	adc #$50

L_BRS_26D3_26CF:

	sta $71 
	sta $2F 
	lda #$FF
	eor _temp 
	sta _temp_h 
	lda #$08
	sta _temp_l 
	sec 
	lda #$18
	sbc $2A 
	bit $2A 
	bmi L_BRS_271B_26E8
	clc 
	lda $70 
	adc #$B8
	sta $70 
	bcc L_BRS_26FE_26F1
	inc $71 
	bpl L_BRS_26FE_26F5
	sec 
	lda $71 
	sbc #$50
	sta $71 

L_BRS_26FE_26F1:
L_BRS_26FE_26F5:

	clc 
	lda $72 
	adc #$B8
	sta $72 
	bcc L_BRS_2712_2705
	inc $73 
	bpl L_BRS_2712_2709
	sec 
	lda $73 
	sbc #$50
	sta $73 

L_BRS_2712_2705:
L_BRS_2712_2709:

	lda #$F8
	sta _temp_l 
	clc 
	lda #$18
	adc $2A 

L_BRS_271B_26E8:

	tax 

L_BRS_271C_2756:

	ldy #$07

L_BRS_271E_2723:

	lda ($72),Y 
	sta ($70),Y 
	dey 
	bpl L_BRS_271E_2723
	clc 
	lda $72 
	adc _temp_l 
	sta $72 
	lda _temp_h 
	adc $73 
	bpl L_BRS_2735_2730
	sec 
	sbc #$50

L_BRS_2735_2730:

	cmp #$30
	bcs L_BRS_273B_2737
	adc #$50

L_BRS_273B_2737:

	sta $73 
	clc 
	lda $70 
	adc _temp_l 
	sta $70 
	lda _temp_h 
	adc $71 
	bpl L_BRS_274D_2748
	sec 
	sbc #$50

L_BRS_274D_2748:

	cmp #$30
	bcs L_BRS_2753_274F
	adc #$50

L_BRS_2753_274F:

	sta $71 
	dex 
	bne L_BRS_271C_2756
	rts 

InitZP:

	lda #$0A		//#of humanoids
	sta $15 
	lda #$08		//starting difficulty
	sta $2E46 
	lda #$00
	sta $3A 
	lda #$05		//game speed
	sta $25 
	lda #$03		//ships per game
	sta $37 
	sta $38 
	lda #$00
	sta $30 
	sta $31 
	sta $32 
	sta $16 
	sta $1A 
	rts 

Reward:

	sed
	clc 
	lda $37 
	adc #$01
	sta $37 
	clc 
	lda $38 
	adc #$01
	sta $38 
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
	ldx #$20
	jsr AIUnit
	ldx #$21
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
	lda #$72
	jmp Out6845

CursorOff:

	lda #$04		//enable/disable cursor editing keys
	ldx #$01		//disable
	jsr OSBYTE
	ldx #$0A
	lda #$20
	jmp Out6845
	lda #$00
	sta $33 
	ldx #$02
	ldy #$00
	jsr CursorXY
	ldx #$02

L_BRS_27FF_2805:

	lda $30,X 
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
	and #$0F

PrintDigit:

	stx $85 
	tax 
	ora $33
	sta $33 
	bne L_BRS_281E_281A
	ldx #$F0

L_BRS_281E_281A:

	txa 
	clc 
	adc #$30
	ldx $85 
	jmp OSWRCH

RJustBCD:

	pha 
	lda #$00
	sta $33 
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
	cmp $30 
	lda $0701,X 
	sbc $31 
	lda $0702,X 
	sbc $32 
	bcc L_BRS_2860_2853
	txa 
	clc 
	adc #$18
	tax 
	cpx #$A9
	bcc L_BRS_2844_285C
	bcs PrintHighs

L_BRS_2860_2853:

	stx _temp 
	cpx #$A8
	beq L_BRS_2873_2864
	ldx #$A8

L_BRS_2868_2871:

	dex 
	lda HiScore,X 
	sta $0718,X 
	cpx _temp 
	bne L_BRS_2868_2871

L_BRS_2873_2864:

	lda #$0D
	sta $0703,X 
	lda $30 
	sta HiScore,X 
	lda $31 
	sta $0701,X 
	lda $32 
	sta $0702,X 
	jsr PrintHighs
	jsr InputName

PrintHighs:

	lda #$03
	jsr PrintN
	jsr CursorOff
	ldx #$00
	stx $43 
	ldy #$06

L_BRS_289B_28F1:

	txa 
	pha 
	pha 
	sed
	clc 
	lda $43 
	adc #$01
	sta $43 
	cld 
	ldx #$03
	jsr CursorXY
	lda $43 
	jsr RJustBCD
	lda #$2E
	jsr OSWRCH
	ldx #$07
	jsr CursorXY
	pla 
	tax 
	lda $0702,X 
	jsr RJustBCD
	lda $0701,X 
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
	sta $2C81 
	lda #$14
	sta $2C82 
	lda #$20
	sta $2C83 
	lda #$7E
	sta $2C84 
	ldx #$80
	ldy #$2C
	lda #$00		//input line
	jsr OSWORD
	bcc L_BRS_293A_2931
	ldx _temp 
	lda #$0D
	sta $0703,X 

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

	lda $21 
	jsr NewScreen
	lda #$01
	jsr PrintN
	ldx #$28
	ldy #$9F
	jsr XYToVidP
	lda #$00
	sta $33 
	lda $16 
	jsr PaintBCD
	ldx #$2A
	ldy #$87
	jsr XYToVidP
	lda #$00
	sta $33 
	lda $17 
	jsr PaintBCD
	lda #$00
	jsr PaintBCD
	lda $15 
	beq L_BRS_29A9_2982
	sta $12 
	ldx #$19

BonusLoop:

	ldy #$77
	txa 
	pha 
	jsr XYToVidP
	ldx #$06
	jsr XBLTSprite
	ldy $17 
	ldx #$00
	jsr AddScore
	ldx #$04
	jsr Delay
	pla 
	clc 
	adc #$03
	tax 
	dec $12 
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
	lda $21 
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
	stx $39 
	lda #$00
	jsr PlaySound
	jsr InitZP

L_BRS_29E8_29F3:

	jsr NextLevel
	jsr Game
	jsr DoneLevel
	lda $37 
	bne L_BRS_29E8_29F3
	rts 

AnimFrame:

	lda Param,X 
	cmp #$08
	beq L_BRS_2A2C_29FB
	lda $08 
	pha 
	lda $09 
	pha 
	lda $20 
	pha 
	lda $21 
	pha 
	lda pNext_l,X 
	sta $08 
	lda pNext_h,X 
	sta $09 
	lda pSprite_l,X 
	sta $20 
	lda pSprite_h,X 
	sta $21 
	jsr XORAnimate
	pla 
	sta $21 
	pla 
	sta $20 
	pla 
	sta $09 
	pla 
	sta $08 

L_BRS_2A2C_29FB:

	ldy Param,X 
	dey 
	tya 
	sta Param,X 
	beq L_BRS_2A4D_2A34
	lda $08 
	sta pNext_l,X 
	lda $09 
	sta pNext_h,X 
	lda $20 
	sta pSprite_l,X 
	lda $21 
	sta pSprite_h,X 
	jmp XORAnimate

L_BRS_2A4D_2A34:

	lda Anim,X 
	bmi L_BRS_2A69_2A50
	cpx #$00
	bne L_BRS_2A5D_2A54
	asl 
	bpl L_BRS_2A5D_2A57
	lda #$01
	sta $24 

L_BRS_2A5D_2A54:
L_BRS_2A5D_2A57:

	lda #$00
	sta Anim,X 
	sta pSprite_h,X 
	sta pNext_h,X 
	rts 

L_BRS_2A69_2A50:

	lda #$FF
	sta Unit,X 
	jmp InitUnit

XORAnimate:

	lda $28 
	pha 
	lda $29 
	pha 
	lda #$00
	sta $28 
	lda #$50
	sta $29 
	jsr GetXScreen
	cmp #$64
	bpl XAnimRet
	cmp #$EC
	bmi XAnimRet
	sta $7A 
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

	sty $86 
	ldx $7A 
	lda WarpX,Y 
	jsr WarpCoord
	pha 
	ldx $89 
	lda $046F,X 
	tax 
	lda $2C58,Y 
	jsr WarpCoord
	tay 
	pla 
	tax 
	jsr XYToVidP
	lda $71 
	beq L_BRS_2AD0_2ABE
	ldy #$00
	ldx $89 
	lda Unit,X 
	asl 
	tax 
	lda imgDot,X 
	eor ($70),Y 
	sta ($70),Y 

L_BRS_2AD0_2ABE:

	ldy $86 
	dey 
	bpl L_BRS_2A9F_2AD3
	ldx $89 

XAnimRet:

	pla 
	sta $29 
	pla 
	sta $28 
	rts 

L_BRS_2ADE_2A8F:

	ldy #$07

L_BRS_2AE0_2B19:

	lda $7A 
	ldx BlastX,Y 
	jsr BlastCoord
	pha 
	lda $046F,X 
	ldx BlastY,Y 
	jsr BlastCoord
	tay 
	pla 
	tax 
	cpy #$C0
	bcs BlastNext
	jsr XYToVidP
	lda $71 
	beq BlastNext
	ldy #$00
	ldx $89 
	lda Unit,X 
	asl 
	tax 
	lda imgDot,X 
	eor ($70),Y 
	sta ($70),Y 
	jmp BlastNext
	pla 

BlastNext:

	ldx $89 
	ldy $86 
	dey 
	bpl L_BRS_2AE0_2B19
	jmp XAnimRet

BlastCoord:

	sty $86 
	stx _temp 
	ldx $89 
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
	ldy $86 
	ldx $89 
	plp 
	rts 

WarpCoord:

	stx $85 
	sec 
	sbc $85 
	sta _offset_l 
	lda #$00
	sbc #$00
	sta _offset_h 
	lda #$00
	sta $72 
	sta $73 
	ldx $89 
	lda Param,X 
	tax 

L_BRS_2B53_2B61:

	clc 
	lda $72 
	adc _offset_l 
	sta $72 
	lda $73 
	adc _offset_h 
	sta $73 
	dex 
	bne L_BRS_2B53_2B61
	lda $72 
	lsr $73 
	ror 
	lsr $73 
	ror 
	lsr $73 
	ror 
	clc 
	adc $85 
	rts 
	rts 

GetYSurf:

	lda X_l,X 
	asl 
	lda $0425,X 
	rol 
	tay 
	lda SurfaceY,Y
	rts 

IsUnlinked:

	stx _temp_h 
	ldx #$00
	jsr IsLinked
	php 
	ldx _temp_h 
	plp 
	rts 

IsLinked:

	eor Unit,Y 
	and #$7F
	bne L_BRS_2B9F_2B91
	stx _temp_l
	lda Param,Y 
	cmp _temp_l
	bne L_BRS_2B9F_2B9A
	lda Anim,Y 

L_BRS_2B9F_2B91:
L_BRS_2B9F_2B9A:

	rts 

		//colour data?
	.byte $00,$08,$00,$08,$00,$08,$00,$00
	.byte $00,$00,$04,$04,$04,$08,$08,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $2A,$00,$55,$55,$65,$66,$9A,$A9
	.byte $00,$01,$44,$55,$55,$55,$A5,$2A
	.byte $80,$2A,$08,$42,$55,$55,$55,$66
	.byte $66,$A6,$A6,$09,$82,$50,$10,$11
	.byte $41,$54,$55,$55,$55,$55,$55,$2A
	.byte $88,$08,$50,$69,$55,$55,$55,$55
	.byte $55,$55,$55,$55,$99,$A9,$99,$99
	.byte $19,$50,$40,$14,$54,$55,$55,$95
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
	.byte $50,$50,$28,$00,$00,$00,$28,$50
	.byte $60,$C0,$C0,$C0,$60,$00,$00,$00
	.byte $02,$04,$00,$FC,$FE,$FC,$00,$04
	.byte $00,$0C,$06,$0C,$00,$F4,$FA,$F4
	.byte $45,$42,$46,$43,$47,$43,$46,$42
//$2C78	
	.byte $AC,$BB,$CA,$BA,$AA,$9B,$AB,$28
	//     G   Y   U   J   N   B   H
//$2C80	
	.byte $25,$24,$20,$1D,$1C,$19,$19,$19

//$2C88	
	.byte $02,$02,$02,$00,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$00,$00
	.byte $01,$01,$00,$00
//$2C9C	
	.byte $11,$12,$13,$10
	.byte $11,$10,$11,$10,$11,$10,$11,$10
	.byte $11,$10,$12,$12,$11,$10,$13,$12
//$2CB0	
	.byte $F6,$F6,$F6,$00,$01,$F4,$02,$F6
	.byte $01,$F6,$01,$F1,$01,$F1,$03,$03
	.byte $01,$F1,$04,$03
//$2CC4	
	.byte $00,$00,$00,$00
	.byte $E6,$07,$64,$07,$FF,$07,$B4,$07
	.byte $82,$07,$32,$14,$FF,$03,$00,$AA
//$2CD8	
	.byte $32,$32,$32,$00,$FF,$1E,$FF,$0C
	.byte $FF,$02,$FF,$11,$FF,$28,$08,$08
	.byte $FF,$3C,$23,$08
//$2CEC	
	.byte $28,$25,$25,$24
	.byte $20,$1D,$1D,$1D,$1D,$1D,$1D,$1D
	.byte $1D,$1D,$1D,$1D,$1D,$1D,$1D,$1E
//$2D00
.import binary "2D00.bin"

Boot:

	tsx 
	stx $39			//Length of variable name
	lda #<NewBRKVector
	sta $0202		//BRK vector(BRKV)
	lda #<NewBRKVector+1
	sta $0203 
	lda #$00		//00 Read host OS
	jsr OSBYTE

NewBRKVector:		//$3012

	ldx $39 
	txs 
	jsr L_JSR_3057_3015
	bne Hook
	lda #$24
	sta $1111 
	sta $111B 
	lda #$02
	sta $1112 
	sta $111C 

Hook:

	sei 
	lda IRQ1V		//IRQ1V - Main interrupt vector
	sta $8C 
	lda IRQ1V+1 
	sta $8D 
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

	lda $3088,Y 
	sta HiScore,X 
	inx 
	iny 
	cpy #$18
	bcc mkScLoop
	cpx #$A9
	bcc YReset
	jmp Main

L_JSR_3057_3015:

	jsr L_JSR_3067_3057
	bne L_BRS_305D_305A
	rts 

L_BRS_305D_305A:

	lda #$30
	sta $3084 
	lda #$31
	sta $3085 

L_JSR_3067_3057:

	ldy #$00

L_BRS_3069_3070:

	iny 
	lda ($FD),Y 
	beq L_BRS_3080_306C
	cmp #$30
	bne L_BRS_3069_3070
	ldx #$00

L_BRS_3074_307D:

	iny 
	lda TableOne,X 
	beq L_BRS_307F_3078
	inx 
	cmp ($FD),Y 
	beq L_BRS_3074_307D

L_BRS_307F_3078:

	rts 

L_BRS_3080_306C:

	lda #$01
	rts
TableOne:	
	.byte $2E,$31,$30,$00,$0D
// $3088

	.byte $00,$10,$00
	.byte $41,$63,$6F,$72,$6E,$73,$6F,$66
	.byte $74,$0D,$03,$06,$06,$06,$06,$03
	.byte $03,$F3,$03,$0C,$0E,$0E,$0C,$03
	.byte $03,$F3,$53,$53,$53,$53,$53,$02
	.byte $02,$00,$41,$C7,$41,$82,$C3,$C7
	.byte $C3,$00,$00,$82,$00,$AA,$AA,$FF
	.byte $FF,$FF,$FF,$00,$00,$05,$00,$05
	.byte $05,$05,$00,$00,$00,$0F,$05,$0F
	.byte $00,$0F,$00,$00,$00,$0C,$08,$0C
	.byte $00,$0C,$00,$00,$00,$09,$01,$09
	.byte $09,$09,$00,$00,$00,$03,$01,$01
	.byte $01,$03,$00,$00,$00,$0F,$0A,$0A
	.byte $0A,$0F,$00,$00,$00,$0A,$0A,$0A
	.byte $0A,$0A,$00,$00,$09,$88,$09,$92
	.byte $09,$9C,$09,$A6,$09


//SurfaceY $3100-$3300 these three pages get moved to SurfaceY

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
	.byte $CC,$CD,$CD,$CC,$F3,$51,$51,$51//$0FA0 human 
	.byte $00,$10,$10,$C3,$C3,$10,$10,$00,$82,$92,$92,$C3,$C3,$92,$92,$82//$0FA8 Pod
	.byte $00,$00,$00,$82,$82,$00,$00,$00	
	.byte $15,$3F,$15,$11,$11,$11,$33,$11,$00,$2A,$3F,$3F,$37,$33,$33,$33//$0FC0 ship R
	.byte $00,$00,$00,$2A,$3F,$3F,$3F,$37,$00,$00,$00,$00,$00,$3F,$3F,$3F
	.byte $00,$00,$00,$00,$00,$07,$07,$3F,$00,$00,$00,$00,$00,$08,$1D,$3F
	.byte $00,$00,$00,$00,$00,$04,$2E,$3F,$00,$00,$00,$00,$00,$0B,$0B,$3F//$0FF0 ship L
	.byte $00,$00,$00,$00,$00,$3F,$3F,$3F,$00,$00,$00,$15,$3F,$3F,$3F,$3B
	.byte $00,$15,$3F,$3F,$3B,$33,$33,$33,$2A,$3F,$2A,$22,$22,$22,$37,$22
	.byte $28,$28,$14,$14// \ down slope ($1020 planet surface tiles)
	.byte $00,$28,$3C,$14// - flat
	.byte $14,$14,$28,$28// / up slope
	.byte $00,$45,$CC,$CC,$44,$00,$44,$88,$CF,$CF,$44,$44,$CC,$CE,$44,$44//$102C Lander
	.byte $8A,$CF,$44,$44,$CC,$8A,$44,$00,$00,$00,$88,$88,$00,$00,$00,$88
	.byte $00,$51,$CC,$CC,$44,$00,$44,$88,$0C,$0C,$51,$51,$F3,$D9,$51,$51//$104C mutant
	.byte $88,$F6,$44,$44,$E6,$88,$44,$00,$00,$00,$88,$88,$00,$00,$00,$88
	.byte $00,$44,$CD,$44//$106C baiter
	.byte $CC,$C0,$CA,$CC
	.byte $CC,$C0,$CF,$CC
	.byte $CC,$C0,$C5,$CC
	.byte $00,$88,$CE,$88
	.byte $00,$00,$00,$00,$00//5 unused bytes
	.byte $50,$E5,$76,$A8,$A2,$01,$A5,$76,$20,$73,$1D,$4C,$FB,$20,$68//$1088 fragment
	.byte $51,$03,$06,$06,$06,$06,$03,$03,$F3,$03,$0C,$0E,$0E,$0C,$03,$03//$1094 bomber
	.byte $F3,$53,$53,$53,$53,$53,$02,$02
	.byte $00,$41,$C7,$41,$82,$C3,$C7,$C3,$00,$00,$82,$00//$10AC swarmer
	.byte $AA,$AA//$10B8 Kudgel (bullet/mine)
	.byte $FF,$FF,$FF,$FF//$10BA shrapnel
	.byte $00,$00,$05,$00,$05,$05,$05,$00,$00,$00,$0F,$05,$0F,$00,$0F,$00//$10BE 250
	.byte $00,$00,$0C,$08,$0C,$00,$0C,$00,$00,$00,$09,$01,$09,$09,$09,$00//$10CE 500 (250/500)
	.byte $00,$00,$03,$01,$01,$01,$03,$00,$00,$00,$0F,$0A,$0A,$0A,$0F,$00
	.byte $00,$00,$0A,$0A,$0A,$0A,$0A,$00
	.byte $00,$09,$88,$09,$92,$09,$9C,$09,$A6,$09//unused