#import "constants.asm"
#import "labelsII.asm"

*=$1100 "Game"

	jmp Boot

IRQHook:

	lda #%00000010		//check if vertical sync occurred
	bit SYS6522 + 13	//systemVIA Interrupt Flag Register
	beq !+

VsyncAddress1:

	inc vsync

!:

	jmp (_irq1v)		//Enter IRQ in ROM

WaitVSync:

	lda vsync 
	cmp _vsync0
	beq WaitVSync
	sta _vsync0			//vblank has begun
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
	sta USR6522 + 11	//userVIAAuxiliaryControlRegister
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
	lda _scrolloff_l
	bpl rrange
	clc 
	adc #$4D
	sta _max_xscr
	bne batchinit

rrange:

	sta _min_xscr

batchinit:

	lda _batch
	sta _batchc
	ldx _id

batchloop:

	jsr ai_unit
	ldx _id

nextid:

	inx 
	cpx #HITCH
	beq nextid
	cpx #ID_MAX + 1
	bne batchid
	ldx #ID_MIN
	lda Anim 
	beq batchid
	ldx #SHIP

batchid:

	stx _id
	jsr IsVSync
	dec _batchc
	bne batchloop
	rts 

ai_alt:

	ldx _id_alt
	jsr ai_unit
	inx 
	cpx #ID_ALT3 + 1
	bne altid
	ldx #ID_ALT1

altid:

	stx _id_alt
	rts 

ai_unit:

	lda Unit,X 
	bpl noai
	asl 
	tay 
	bmi noai
	lsr 
	sta Unit,X 
	lda Anim,X 
	beq aijump
	bmi aiexplode
	jsr AnimFrame
	jmp MMUpdate

aiexplode:

	jmp AnimFrame

aijump:

	lda AiVector,Y 
	sta _destptr_l 
	lda AiVector + 1,Y 
	sta _destptr_h 
	jmp (_destptr) 

noai:

	rts

ai_ship:	 

	jmp MoveUnit

ai_kugel:
ai_250:
ai_500:
ai_object:

	ldy Param,X 
	iny 
	tya 
	sta Param,X 
	cpy #$A0
	bne aisprmove
	jmp EraseUnit

aisprmove:

	jsr MoveUnit
	lda pNext_h,X 
	bne aispr_ret
	jmp EraseUnit

aispr_ret:

	rts

ai_lander:

	lda _humanc
	bne ldrshoot
	jsr EraseUnit
	lda #MUTANT
	sta Unit,X 
	jmp ai_mutant

ldrshoot:

	lda #$0A
	jsr ShootChance
	lda Param,X 
	pha 
	and #%00111111
	tay 
	pla 
	bne param_maybe
	jmp J1VE

param_maybe:

	bmi j1v_c
	lda Y_h,X 
	cmp #$BE
	bcc toj7v_0
	lda #MAN
	jsr IsLinked
	bne j1v_b
	tya 
	tax 
	jsr KillUnit
	ldx _id
	jsr EraseUnit
	lda #MUTANT
	sta Unit,X 
	jmp ai_mutant

j1v_a:

	ldy #LANDER
	jsr InitDXY

BackParamx:

	lda #$00
	sta Param,X 

toj7v_0:

	jmp ai_update

j1v_b:

	jsr EraseUnit
	lda #LANDER
	sta Unit,X 
	jmp InitUnit

j1v_c:

	lda Param,X 
	asl 
	bmi j1v_d
	lda #MAN
	jsr IsUnlinked
	bne BackParamx
	lda X_h,X 
	cmp X_h,Y 
	beq !+
	jmp J1VF

!:

	lda #$FC
	sta dY_h,X 
	lda dX_l,Y 
	sta dX_l,X 
	lda dX_h,Y 
	sta dX_h,X 
	lda Param,X 
	ora #%01000000
	sta Param,X 

j1v_d:

	lda Unit,Y 
	and #%01111111
	cmp #MAN
	bne j1v_a
	lda Param,Y 
	and #%11000000
	bne j1v_a
	lda Param,Y 
	beq !+
	lda #$00
	sta dY_l,X 
	sta dY_h,X 
	jmp ai_update

!:

	lda Y_h,X 
	sec 
	sbc #$0A
	cmp Y_h,Y 
	bcs toj7v_1
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

toj7v_1:

	jmp ai_update

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
	bcc !+
	lda #$00
	sbc _temp 

!:

	cmp #$32
	bcs J1VF
	tya 
	ora #%10000000
	sta Param,X 

J1VF:

	lda dX_l,X 
	sta _temp_l 
	lda dX_h,X
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
	jmp ai_update

MoveUp:

	bit _temp_h 
	bpl yadd
	bmi ysub

MoveDown:

	bit _temp_h 
	bmi yadd

ysub:

	sec 
	lda Y_l,X 
	sbc _temp_l 
	sta Y_l,X 
	lda Y_h,X 
	sbc _temp_h 
	sta Y_h,X 
	jmp ai_update

yadd:

	clc 
	lda Y_l,X 
	adc _temp_l 
	sta Y_l,X 
	lda Y_h,X 
	adc _temp_h 
	sta Y_h,X 
	jmp ai_update

ai_mutant:

	lda #$19
	jsr ShootChance	//1:10 odds
	lda pSprite_h,X 
	beq !+
	jsr Random
	cmp #$14
	bcs !+	//1:13 odds
	lda #$10
	jsr PlaySound

!:

	jsr GetXDisph
	cmp #$0A
	bpl !++
	cmp #$EC
	bmi NearShip

j1382:

	jsr ABSYDisp

J1385:

	ldy #$06
	lda #$00
	bcs !+
	ldy #$FA
	lda #$00

!:

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
	bpl !+
	ldy #$FD
	lda #$B0

!:

	sta dX_l,X 
	tya 
	sta dX_h,X 
	jmp ai_update

!:

	cmp #$32
	bpl NearShip
	jsr ABSYDisp
	cmp #$28
	bcs j1382
	jsr ABSYDisp
	php 
	pla 
	eor #%00000001
	pha 
	plp 
	jmp J1385

NearShip:

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
	bcc FacingLeft
	tya 
	ldy X_h,X 

FacingLeft:

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
	bpl Negative
	eor #%11111111

Negative:

	rts

ai_baiter:	 

	lda #$28
	jsr ShootChance	//1:6 odds
	lda Param,X 
	beq Baitcount
	dec Param,X 
	jmp ai_update

Baitcount:

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
	jmp ai_update

ai_bomber:

	jsr MineChance
	jsr DYSine
	jmp ai_update

ai_swarmer:	

	jsr DYSine
	sec 
	lda X_h,X 
	sbc X_h + SHIP 
	sta _temp 
	eor dX_h,X 
	bmi !++
	lda _temp 
	bpl !+
	eor #%11111111

!:

	cmp #$14
	bcs !+
	jmp ai_update

!:

	jmp J1396

!:

	lda pSprite_h,X 
	beq !+
	jsr Random
	cmp #$0F
	bcs !+
	lda #$13
	jsr PlaySound

!:
	lda #$1E
	jsr ShootChance
	jmp ai_update

DYSine:

	lda #$00
	sta _temp 
	lda Y_h,X 
	sec 
	sbc #$62
	bcs uppersine
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

uppersine:

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

ai_human:	 

	lda Param,X 
	bne manlink
	jmp Walk

manlink:

	bmi manfall
	tay 
	lda #LANDER
	jsr IsLinked
	bne startfall
	jmp ai_update

manfall:

	asl 
	bmi falling
	stx _xreg
	ldx #HITCH
	jsr GetYSurf
	ldx _xreg
	cmp Y_h + HITCH 
	bcs rescued
	rts 

rescued:

	dec _hikerc
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
	jmp ai_update

startfall:

	lda #$FF
	sta Param,X 
	lda #$00
	sta dY_l,X 
	sta dY_h,X 

falling:

	sec 
	lda dY_l,X 
	sbc #$40
	sta dY_l,X 
	lda dY_h,X 
	sbc #$00
	sta dY_h,X 
	jsr GetYSurf
	cmp Y_h,X 
	bcc ai_update
	lda dY_h,X 
	cmp #$FB
	bcs landsafe
	jmp KillUnit

landsafe:

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
	bmi walkdown
	cmp #$08
	bpl walkup
	bmi ai_update

walkup:

	jmp MoveUp

walkdown:

	jmp MoveDown

ai_update:
ai_pod:

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

sndloop:

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
	ldx #<ParamBlk
	ldy #>ParamBlk		//8 byte parameter block
	lda #$07		//short tone
	jsr OSWORD
	pla 
	tax 
	inx 
	dec _temp 
	bpl sndloop
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
	bcc insmsb
	lda #$FF

insmsb:

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

rpmaploop:

	stx _xreg
	lda Unit,X 
	bpl rpmapnext
	asl 
	bmi rpmapnext
	ldy pDot_l,X 
	sty _destptr_l 
	ldy pDot_h,X 
	beq rpmapnext
	sty _destptr_h 
	lda Dot,X 
	tax 
	stx _yreg
	jsr MMBlit
	ldx _xreg
	clc 
	lda _destptr_l 
	adc _scrolloff_l
	sta _destptr_l 
	sta pDot_l,X 
	lda _destptr_h 
	adc _scrolloff_h 
	bpl !+
	sec 
	sbc #$50

!:

	cmp #$30
	bcs !+
	adc #$50

!:

	sta _destptr_h 
	sta pDot_h,X 
	ldx _yreg
	jsr MMBlit

rpmapnext:

	ldx _xreg
	dex 
	bpl rpmaploop
	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

MMBlit:

	lda _destptr_h 
	bne hiblit
	rts 

hiblit:

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
	bne loblit
	clc 
	lda _srcptr_l 
	adc #$78
	sta _srcptr_l 
	lda _srcptr_h 
	adc #$02
	bpl loptr
	sec 
	sbc #$50

loptr:

	sta _srcptr_h 

loblit:

	iny 
	lda (_srcptr),Y 
	eor imgDot + 1,X 
	sta (_srcptr),Y 
	rts 

MMUpdate:

	jsr TimerState	//wait for raster
	bpl MMUpdate
	cpx #ID_MAX + 1
	bcc mmupd2
	rts 

mmupd2:

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
	bcc aligned
	adc #$15

aligned:

	sta Dot,X 
	tax 
	jsr MMBlit
	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

KeyFire:

	ldx #KEY_RETURN
	jsr ScanInkey
	beq kfire2
	eor _inkey_enter

kfire2:

	stx _inkey_enter
	beq kfire_ret
	ldx #$03

kfireloop:

	lda _Laser,X 
	beq fire_laser
	dex 
	bpl kfireloop

kfire_ret:

	rts 

fire_laser:

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
	bmi !+
	txa 
	clc 
	adc #$07
	tax 
	lda #$01

!:

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
	bpl lzedge
	lda #$F8
	sta _offset_l 
	lda #$FF
	sta _offset_h 
	sec 
	lda #$00
	sbc _dxwin

lzedge:

	sta _dxedge
	sec 
	lda _BeamX,X 
	sbc _dxwin
	sta _BeamX,X 
	lda _Laser,X 
	bne !+
	jmp LaserNext

!:

	lda _pHead_l,X 
	sta _destptr_l 
	lda _pHead_h,X 
	sta _destptr_h 
	clc 
	lda #$04
	adc _dxedge
	sta _laserc

lzloop:

	lda _BeamX,X 
	ldy _Laser,X 
	bmi llpleft

llpright:

	cmp _max_xscr
	bpl EraseLaser
	inc _BeamX,X 
	bne llppaint

llpleft:

	cmp _min_xscr
	bmi EraseLaser
	dec _BeamX,X 

llppaint:

	ldy _Head,X 
	jsr BlitLaser
	sta _Head,X 
	jsr NextPtr
	ldy #$00
	lda (_destptr),Y 
	and #%11000000
	beq lznext
	jsr LaserHit
	bcs lznext
	rts 

lznext:

	dec _laserc
	bne lzloop
	lda _destptr_l 
	sta _pHead_l,X 
	lda _destptr_h 
	sta _pHead_h,X 
	bne lzscroll

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

elzloop:
	inx 
	lda ImgLaser,X 
	eor (_destptr),Y 
	sta (_destptr),Y 
	cpx #$50
	bne elznext
	ldx #$4F

elznext:

	jsr NextPtr
	lda _destptr_l 
	cmp _srcptr_l 
	bne elzloop
	lda _destptr_h 
	cmp _srcptr_h 
	bne elzloop
	rts 

lzscroll:

	lda _pTail_l,X 
	sta _destptr_l 
	lda _pTail_h,X 
	sta _destptr_h 
	clc 
	lda #$01
	adc _dxedge
	sta _laserc
	beq LaserNext
	bmi LaserNext

tailloop:

	ldy _Tail,X 
	jsr BlitLaser
	sta _Tail,X 
	jsr NextPtr
	dec _laserc
	bne tailloop
	lda _destptr_l 
	sta _pTail_l,X 
	lda _destptr_h 
	sta _pTail_h,X 

LaserNext:

	dex 
	bmi !+
	jmp LZRight

!:

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
	bcs lzhit_ret
	txa 
	pha 
	jsr EraseLaser
	pla 
	tax 
	clc 

lzhit_ret:

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
	bne !+
	lda #$4F

!:

	rts 

NextPtr:

	clc 
	lda _destptr_l 
	adc _offset_l 
	sta _destptr_l 
	lda _destptr_h 
	adc _offset_h 
	bpl !+
	lda #$30

!:

	cmp #$30
	bcs !+
	adc #$50

!:

	sta _destptr_h 
	rts 

LZCollide:

	cmp #$50
	bcc lzcdinit
	rts 

lzcdinit:

	stx _xreg
	sta _anim_xscr 
	lda _BeamY,X 
	sta _beam_yscr
	ldx #$02

lzcdloop:

	lda pSprite_h,X 
	beq lzcdnext
	lda Y_h,X 
	sec 
	sbc _beam_yscr
	cmp #$08
	bcs lzcdnext
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
	bpl !+
	clc 
	adc #$50

!:

	lsr 
	ror _offset_l 
	lsr 
	ror _offset_l 
	lsr 
	ror _offset_l 
	sta _offset_h 
	sec 

!:

	lda _offset_l 
	sbc #$50
	sta _offset_l 
	lda _offset_h 
	sbc #$00
	sta _offset_h 
	bcs !-
	lda _offset_l 
	adc #$50
	cmp #$04
	bcs lzcdnext
	lda Anim,X 
	bne lzcdnext
	lda Unit,X 
	asl 
	bmi lzcdnext
	lsr 
	cmp #MAN
	bne hitfound
	lda Param,X 
	cmp #$80
	beq lzcdnext

hitfound:

	lda #$03
	jsr PlaySound
	jsr ScoreUnit
	jsr KillUnit
	ldx _xreg
	clc 
	rts 

lzcdnext:
	inx 
	cpx #$20
	bne lzcdloop
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
	bcs killu_ret
	cmp #MAN
	beq !+
	dec _enemyc

killu_ret:
	rts 

!:

	lda #$0A
	jsr PlaySound
	dec _humanc
	bne killu_ret
	jmp RMSurface

KillU2:

	lda Unit,X 
	pha 
	jsr EraseUnit
	pla 
	bcs killu_ret
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
	bmi erasefail
	cpx #$20
	bcs skipdot
	ldy pDot_l,X 
	sty _destptr_l 
	ldy pDot_h,X 
	sty _destptr_h 
	beq skipdot
	lda #NULL
	sta pDot_h,X 
	lda Dot,X 
	tax 
	jsr MMBlit

skipdot:
	pla 
	pha 
	tax 
	lda Anim,X 
	bne nosprite
	lda pSprite_l,X 
	sta _destptr_l 
	lda pSprite_h,X 
	sta _destptr_h 
	lda Unit,X 
	and #%01111111
	tax 
	jsr XBLTSprite

nosprite:

	pla 
	tax 
	jsr ClearData
	lda Unit,X 
	and #%01111111
	cmp #POD
	bne erasesucc
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

erasesucc:

	lda #$FF
	sta Unit,X 
	clc 
	rts 

erasefail:

	pla 
	tax 
	sec 
	rts 

MSpawn:

	sta _spawn_spr
	and #%01111111
	tay 
	lda Spawnc,Y 
	beq mspw_ret
	sta _count
	cpy #LANDER
	bne mspwinit
	lda _humanc
	bne mspwinit
	ldy #MUTANT

mspwinit:
	jsr MSPWFrame
	ldx #ID_MIN

mspwloop:
	lda Unit,X 
	asl 
	bpl mspwnext
	tya 
	ora #$80
	sta Unit,X 
	jsr InitUnit
	cpy #BAITER
	beq !+
	cpy #MAN
	beq !+
	inc _enemyc

!:
	dec _count
	beq mspw_ret

mspwnext:

	txa 
	clc 
	adc #$05
	tax 
	cpx #ID_MAX + 1
	bcc mspwloop
	sec 
	sbc #$1D
	tax 
	cpx #$07
	bne mspwloop
	bit _spawn_spr
	bpl mspwinit

mspw_ret:
	rts 

MSPWFrame:

	lda _spawn_spr
	bmi noframe
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

noframe:

	rts 

SpawnBait:

	dec _baitdelay_l
	bne bait_ret
	dec _baitdelay_h
	bne bait_ret
	lda #$01
	sta Spawnc + BAITER 
	lda X_h + SHIP 
	sta XMinInit +  BAITER
	lda #($80|BAITER)
	jsr MSpawn
	lda #$02
	sta _baitdelay_h

bait_ret:
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
	bpl !+
	rts 

!:

	lda DoWarp,Y 
	beq !+
	lda #$01
	sta Anim,X 
	lda #$08
	sta Param,X 

!:

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
	bcc !+
	sbc #$C0

!:

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
	bpl !+
	sec 
	lda #$00
	sbc _temp_l 
	sta _temp_l 
	bcs !+
	dec _temp_h 

!:
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

!:

	txa 
	pha 
	jsr MSpawn
	pla 
	tax 
	inx 
	cpx #POD + 1
	bne !-
	rts 

SmartBomb:

	lda _bombs
	bne !+
	rts 

!:

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

bombloop:

	lda Unit,X 
	asl 
	bmi BombNext
	lsr 
	cmp #MAN
	beq BombNext
	lda Anim,X 
	bne BombNext
	lda pSprite_h,X 
	bne blowup
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

blowup:

	jsr ScoreUnit
	jsr KillUnit

BombNext:

	inx 
	cpx #$20
	bne bombloop
	rts 

KeysHyper:

	ldx #$06

khyploop:

	stx _xreg
	lda HyperKeys,X 
	tax 
	jsr ScanInkey
	bne hyperspace
	ldx _xreg
	dex 
	bpl khyploop

khyp_ret:
	rts 

hyperspace:

	bit Anim 
	bvs khyp_ret
	lda Param 
	cmp #$05
	bcs khyp_ret
	jsr Random
	jsr NewScreen
	jsr Random
	ldx #WARP
	cmp #$28
	bcs hypvars
	ldx #(WARP|HAL)

hypvars:

	stx Anim + SHIP
	lda #$08
	sta Param + SHIP
	rts 

FrameNoCheck:

	lda _no_planet
	ora _humanc
	bne to_frameall
	lda #TRUE
	sta _no_planet

flbgloop:

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
	bne flbgloop

to_frameall:

	jmp FrameAll

ShootChance:

	sta _temp 
	lda _dead
	beq !+
	rts 

!:

	jsr Random
	cmp _temp 
	bcs shtch_ret
	sec 
	lda X_h + SHIP 
	sbc X_h,X 
	bpl !+
	sta _temp 
	sec 
	lda #$00
	sbc _temp 

!:

	cmp #$28
	bcs shtch_ret
	jsr Shoot
	bcc !+

shtch_ret:
	rts 

!:

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
	bcc !+
	cmp #$FE
	bcc target_ret

!:

	lda dX_h,Y 
	beq !+
	cmp #$FF
	bne target_ret
	sec 
	lda #$00
	sbc dX_l,Y 
	jmp ShootSpeed

!:

	lda _srcptr_l 
	ora _srcptr_h
	beq target_ret
	lda dX_l,Y 

ShootSpeed:

	cmp _shootspeed
	bcs target_ret
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

target_ret:
	rts 
	lda #$08
	jmp PlaySound

MineChance:

	lda pNext_h,X 
	beq mine_ret
	jsr Random
	cmp #$3C
	bcs mine_ret
	jsr SpawnMisc
	bcs mine_ret
	lda #$00
	sta dY_l,Y 
	sta dY_h,Y 
	sta dX_l,Y 
	sta dX_h,Y 

mine_ret:
	rts 

DistDiv64:

	sta _temp_l 
	php 
	lda #$00
	plp 
	bpl distdiv2
	lda #$FF

distdiv2:

	asl _temp_l 
	rol 
	asl _temp_l 
	rol 
	sta _temp_h 
	rts 

Shoot:

	ldy #ID_BULLET1
	bne shootloop

SpawnMisc:

	ldy #ID_ALT1

shootloop:
	jsr ShootID
	bcc shoot_ret
	iny 
	cpy #ID_ALT3 + 1
	bne shootloop

shoot_ret:

	rts 

ShootID:

	lda Unit,Y 
	eor #%11000000
	asl 
	asl 
	bcs shtid_ret
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

shtid_ret:

	rts 

Frame:

	ldx #KEY_TAB
	jsr ScanInkey
	beq tab0
	eor _inkey_tab

tab0:

	stx _inkey_tab
	beq frame2
	jsr SmartBomb

frame2:

	jsr KeysHyper
	jsr FrameNoCheck
	lda _dead
	bne do_death
	rts 

do_death:

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

shrapsetup:

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
	bpl shrapsetup
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

shrapnel:

	txa 
	pha 
	jsr AIBatch
	jsr NextFrame
	jsr RepaintAll
	pla 
	tax 
	cpx #$12
	bne shrapnext
	lda #(PALX_METAL|RED)
	jsr SetPallette

shrapnext:

	dex 
	bne shrapnel
	ldx #ID_MAX

unbackup:

	lda Param,X 
	sta Unit,X 
	lda pDot_l,X 
	sta Anim,X 
	dex 
	bpl unbackup
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
	beq tonextlvl
	lda _lives
	bne continue
	ldx _gameover_sp 
	txs 
	rts 

tonextlvl:

	ldx _nextlvl_sp
	txs 
	rts 

continue:

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
	bcc spawned
	jsr SpawnSquad

spawned:

	lda #FALSE
	sta _is_spawning

gameframe:

	jsr Frame
	lda _enemyc
	bne gameframe
	rts 

SpawnSquad:

	lda #$00
	sta _framec_l
	sta _framec_h

squadloop:

	jsr Frame
	lda _enemyc
	beq newsquad
	lda _humanc
	beq newsquad
	inc _framec_l
	bne squadnext
	inc _framec_h

squadnext:

	lda _framec_h
	cmp _squaddelay
	bne squadloop

newsquad:
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
	lda #$81
	jsr OSBYTE
	txa 
	rts 

WaitSpaceBar:

	lda #$0F		//Flush all buffers/input buffer
	ldx #$01
	jsr OSBYTE

spcloop:

	lda #$7E		//Acknowledge ESCAPE Condition
	jsr OSBYTE
	jsr OSRDCH		//OSRDCH Read character (from keyboard) to A
	cmp #$20		//is space pressed
	bne spcloop
	rts 

XYToVidP:

	lda #NULL
	sta _destptr_h 
	cpx _min_xscr
	bcc xytop_ret
	cpx _max_xscr
	bcs xytop_ret
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
	bpl setrow
	sec 
	sbc #$50

setrow:

	sta _destptr_h 
	pla 
	and #%00000111
	ora _destptr_l
	sta _destptr_l 

xytop_ret:

	rts 

XORBlit:

	lda _destptr_h 
	bne xblt1
	rts 

xblt1:

	lda #$00
	sta _paintmask
	lda _imglen 
	pha 
	ldy #$00

xorpinit:

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

xorploop:

	lda (_srcptr),Y 
	php 
	iny 
	sty _temp 
	ldy _dest_crow 
	eor (_destptr),Y 
	sta (_destptr),Y 
	iny 
	plp 
	beq xblt2
	ora _paintmask
	sta _paintmask

xblt2:

	cpy #$08
	beq cellbelow

xorpnext:

	sty _dest_crow 
	ldy _temp 
	tya 
	and _heightmask
	beq cellright
	dec _imglen 
	bne xorploop
	pla 
	pla 
	pla 
	sta _imglen 
	rts 

cellbelow:

	ldy #$00
	clc 
	lda _destptr_l 
	adc #$80
	sta _destptr_l 
	lda _destptr_h 
	adc #$02
	bpl xblt3
	sec 
	sbc #$50

xblt3:

	sta _destptr_h 
	bne xorpnext

cellright:

	clc 
	pla 
	adc #$08
	sta _destptr_l 
	pla 
	adc #$00
	bpl xblt4
	sec 
	sbc #$50

xblt4:

	sta _destptr_h 
	dec _imglen 
	bne xorpinit
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
	ldy #$14		//HI
	ldx #$80		//LO
	jsr StartTimer	//$1480 or 5248 cycles
	lda _bgpal
	jsr SetPallette
	lda _humanc
	bne palette2
	lda _bgpal
	ora #PAL_SURF
	jsr SetPallette

palette2:

	dec _flpalc
	bne palette3
	lda _flpalframes
	sta _flpalc
	inc _flashc
	lda _flashc
	and #%00000111
	sta _flashc
	tax 
	lda FlashPal,X 
	jsr SetPallette

palette3:

	inc _rotpalc
	lda _rotpalc
	and #%00000011
	bne nxfrm_ret
	ldx rotatec 
	lda #PAL_ROT1

rotloop:

	sta _temp 
	stx rotatec 
	lda RotColour,X 
	ora _temp
	jsr SetPallette
	inx 
	cpx #$03
	bne palnext
	ldx #$00

palnext:

	lda _temp 
	clc 
	adc #$10
	cmp #$40
	bne rotloop

nxfrm_ret:

	rts 

PSurfRight:

	pha 
	sta _dxwinc
	sty _xscrc
	ldy _xwinedge,X 

rsurfloop:

	jsr XBltSurface
	inc _xscrc
	iny 
	dec _dxwinc
	bne rsurfloop
	tya 
	sta _xwinedge,X 
	pla 
	rts 

PSurfLeft:

	pha 
	sta _dxwinc
	sty _xscrc
	ldy _xwinedge,X 

lsurfloop:

	dec _xscrc
	dey 
	jsr XBltSurface
	inc _dxwinc
	bne lsurfloop
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

unpakq:

	dex 
	bmi gettile
	lsr 
	lsr 
	bne unpakq

gettile:

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
	beq nohyper
	jmp ScrollScreen

nohyper:

	lda _dead
	beq to_pausquit
	lda _shippal
	eor #$80
	sta _shippal
	bmi flashframe
	eor #%00000110
	sta _shippal
	jsr SetPallette

flashframe:

	lda #$00
	sta dX_l + SHIP
	sta dX_h 
	jmp UpdateShip

to_pausquit:

	jsr KeyFire
	ldx #KEY_A
	jsr ScanInkey
	beq key_down
	clc 
	lda Y_h + SHIP 
	adc #$02
	cmp #$C3
	bcs key_down
	sta Y_h + SHIP 

key_down:

	ldx #KEY_Z
	jsr ScanInkey
	beq keys_nav
	sec 
	lda Y_h + SHIP 
	sbc #$02
	cmp #$09
	bcc keys_nav
	sta Y_h + SHIP 

keys_nav:

	ldx #KEY_SPACE
	jsr ScanInkey
	beq space0
	eor _inkey_space

space0:

	stx _inkey_space
	beq key_thrust
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

key_thrust:

	ldx #KEY_SHIFT
	jsr ScanInkey
	beq shipdrag
	clc 
	lda dX_l + SHIP
	adc _ddx_l
	sta dX_l + SHIP
	lda dX_h 
	adc _ddx_h
	sta dX_h 

shipdrag:

	lda dX_h 
	ora dX_l + SHIP
	beq dragdone
	lda dX_h 
	bpl rdrag
	clc 
	lda dX_l + SHIP
	adc #$03
	sta dX_l + SHIP
	lda dX_h 
	adc #$00
	sta dX_h 
	bcs stopship
	lda dX_h 
	cmp #$FF
	bpl dragdone
	lda #$FF
	sta dX_h 
	lda #$00
	sta dX_l + SHIP
	beq dragdone

rdrag:

	sec 
	lda dX_l + SHIP
	sbc #$03
	sta dX_l + SHIP
	lda dX_h 
	sbc #$00
	sta dX_h 
	bcc stopship
	lda dX_h 
	cmp #$01
	bmi dragdone
	lda #$00
	sta dX_l + SHIP
	beq dragdone

stopship:
	lda #$00
	sta dX_l + SHIP
	sta dX_h 

dragdone:

	ldx #$00
	jsr GetXScreen
	tax 
	ldy #$0F
	lda _ddx_h
	bpl xscrnew
	ldy #$3B

xscrnew:

	sty _temp 
	lda #$00
	ldy #$00
	cpx _temp 
	beq dxrel
	lda #$80
	bcs dxrel
	lda #$80
	ldy #$FF

dxrel:
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

	lda _hikerc
	beq hherase
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

hherase:

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
	bcc ybottom
	cpy #(U_SHIP&KUGEL)
	beq offscreen
	lda #$09

ybottom:

	cmp #$09
	bcs ymove
	cpy #(U_SHIP&KUGEL)
	bne yminunit
	cmp #$04
	bcs ymove
	bcc offscreen

yminunit:

	cpy #MAN
	php 
	lda #$C2
	plp 
	bne ymove
	lda #$09

ymove:
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

setnextp:

	lda _destptr_l 
	sta pNext_l,X 
	lda _destptr_h 
	sta pNext_h,X 
	lda Unit,X 
	and #%01111111
	sta Unit,X 
	rts 

offscreen:
	lda #NULL
	sta _destptr_h 
	beq setnextp

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
	bmi isoffscreen
	lda _temp 
	rts 

isoffscreen:

	lda #$80
	rts 

RepaintAll:

	ldx #SHIP

rpaloop:

	txa
	pha 
	lda Unit,X 
	bmi rpanext
	ora #$80
	sta Unit,X 
	lda Anim,X 
	bne rpanext
	lda pSprite_l,X 
	cmp pNext_l,X 
	bne rpaerase
	lda pSprite_h,X 
	cmp pNext_h,X 
	bne rpaerase
	cpx #SHIP
	bne rpanext

rpaerase:

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

rpanext:

	pla 
	tax 
	inx 
	cpx #ID_ALT3 + 1
	bne rpaloop
	rts 

XBLTSprite:

	lda SpriteMaxY,X
	sta _heightmask
	lda SpriteLen,X
	sta _imglen 
	lda SpriteV_l,X
	sta _srcptr_l 
	lda SpriteV_h,X
	sta _srcptr_h 
	jsr XORBlit
	cpx #U_SHIP
	bne xbspr_ret
	lda _paintmask
	sta _collision

xbspr_ret:

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
	beq ssurfstill
	bpl ssurfright
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

ssurfright:

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

ssurfstill:

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
	bcc !+
	ldy #$FF

!:

	sta _scrolloff_l
	clc 
	adc _originp_l
	sta _originp_l
	tya 
	sta _scrolloff_h 
	adc _originp_h
	bpl !+
	sec 
	sbc #$50

!:

	cmp #$30
	bcs !+
	adc #$50

!:

	sta _originp_h
	pla 
	sta _xwin
	jmp ScreenStart

Collision:

	lda _collision
	and #%11000000
	beq nocollide
	lda _dead
	beq cllshipx

nocollide:

	rts 

cllshipx:

	ldx #SHIP
	jsr GetXScreen
	sta _ship_xscr
	ldx #ID_ALT3

cllloop:

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
	beq cllman
	jsr ScoreUnit
	jsr KillUnit
	lda #TRUE
	sta _dead
	lda #(PAL_SHIP|WHITE)
	sta _shippal

cllman:

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
	bcs cllloop
	rts 

Random:

	txa 
	pha 
	ldx #$08

randgen:

	lda _rand_h
	and #%01001000
	adc #%00111000
	asl 
	asl 
	rol _rand_l
	rol _rand_m
	rol _rand_h
	dex 
	bne randgen
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
	bcc manbonus
	lda #$05

manbonus:

	sta _humanbonus
	lda _level 
	sec 
	ldx #(PAL_SURF|RED)		//pallete colour(terrain)

modulo5:

	sbc #$05
	bcs modulo5
	cmp #$95
	bne notbonus
	lda #$A		//#of humanoids
	sta _humanc
	lda #FALSE
	sta _no_planet
	ldx #(PAL_SURF|GREEN)
	inc _batch

notbonus:

	cld 
	lda _humanc
	bne setsurface
	ldx #(PAL_SURF|BLACK)

setsurface:

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

nlclrslots:

	sta Unit,X 
	dex 
	bpl nlclrslots
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
	beq bomberc
	ldx #$04
	cmp #$04
	bcc bomberc
	ldx #$07

bomberc:

	stx Spawnc +  BOMBER
	ldx #$04
	cmp #$04
	bcs podc
	dex 
	cmp #$03
	beq podc
	dex 
	dex 
	cmp #$02
	beq podc
	dex 

podc:
	stx Spawnc + POD
	lda dXMinInit + LANDER
	clc 
	adc #$02
	cmp #$18
	bcs nxlev8
	sta dXMinInit + LANDER

nxlev8:

	lda #(PAL_BG|BLACK)
	sta _bgpal

ContLevel:

	lda #$80
	sta XMinInit + SWARMER
	ldx #ID_MAX + 1

contloop:

	lda Unit,X 
	and #%01111111
	cmp #BAITER
	bne notbaiter
	lda #EMPTY
	sta Unit,X 

notbaiter:

	jsr resetUnit
	jsr InitUnit
	dex 
	bpl contloop
	lda #ID_MIN
	sta _id
	lda #$00
	sta _hikerc
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

clrbeams:

	sta _Laser,X 
	dex 
	bpl clrbeams
	lda #EMPTY
	sta Unit + HITCH 
	ldx #ID_ALT3

freeobjs:

	lda #EMPTY
	sta Unit,X 
	jsr ClearData
	dex 
	cpx #ID_BULLET1
	bpl freeobjs

resetus:

	jsr resetUnit
	dex 
	bpl resetus
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

blackpal:

	jsr SetPallette
	clc 
	adc #$10
	bne blackpal
	lda #$00
	jsr PrintN
	lda #(PALX_ENEMYB|BLACK)

setpalx:

	jsr SetPallette
	clc 
	adc #$11
	bcc setpalx
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
	beq !++
	bpl !+
	lda #EMPTY
	sta Unit,X 
	bne !++

!:

	lda #$08
	sta Param,X 

!:
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
	tax			// message#
	lda StringV_l,X 
	sta _destptr_l 
	lda StringV_h,X 
	sta _destptr_h 
	ldy #$00
	lda (_destptr),Y 
	sta _strlen

coutlp:

	iny 
	lda (_destptr),Y 
	jsr OSWRCH	//print character
	cpy _strlen	//} while
	bne coutlp
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
	beq !+
	and #%01111111
	tax 
	lda Points_h,X 
	tay 
	lda Points_l,X 
	tax 
	jsr AddScore

!:

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
	bcs sc500_ret
	lda #(UPDATE|S500)
	sta Unit,Y 

spawn_score:

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

sc500_ret:

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
	bcs sc500_ret
	lda #(UPDATE|S250)
	sta Unit,Y 
	bne spawn_score

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
	bcc !+
	jsr Reward

!:

	lda _digitp_l
	sta _destptr_l 
	lda _digitp_h
	sta _destptr_h 
	lda #FALSE
	sta _leading0
	ldx #$02

!:

	lda _score_lsb,X 
	jsr PaintBCD
	dex 
	bpl !-
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
	bne !+
	lda #TRUE
	sta _leading0

!:

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

pdigloop:

	lda _leading0
	beq !+
	lda imgDigit,X 		//HUD numbers
	sta (_destptr),Y 

!:

	iny 
	inx 
	tya 
	and #%00000111
	tay 
	bne plnext
	clc 
	lda _destptr_l 
	adc #$08
	sta _destptr_l 
	bcc plnext
	inc _destptr_h 
	bpl plnext
	lda _destptr_h 
	sec 
	sbc #$50
	sta _destptr_h 

plnext:

	txa 
	and #%00001111
	bne pdigloop
	ldx _temp 
	rts 

RepaintDigit:

	ldy #$00
	lda _scrolloff_l
	bpl !+
	ldy #$FF

!:

	sty _temp 
	clc 
	lda _digitp_l
	sta _srcptr_l 
	adc _scrolloff_l
	sta _destptr_l 
	sta _digitp_l
	lda _digitp_h
	sta _srcptr_h 
	adc _temp 
	bpl !+
	sec 
	sbc #$50

!:

	cmp #$30
	bcs !+
	adc #$50

!:

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
	bmi rpdig0
	clc 
	lda _destptr_l 
	adc #$B8
	sta _destptr_l 
	bcc !+
	inc _destptr_h 
	bpl !+
	sec 
	lda _destptr_h 
	sbc #$50
	sta _destptr_h 

!:
	clc 
	lda _srcptr_l 
	adc #$B8
	sta _srcptr_l 
	bcc !+
	inc _srcptr_h 
	bpl !+
	sec 
	lda _srcptr_h 
	sbc #$50
	sta _srcptr_h 

!:
	lda #$F8
	sta _temp_l 
	clc 
	lda #$18
	adc _dxwin

rpdig0:

	tax 

rpdigloop:

	ldy #$07

!:

	lda (_srcptr),Y 
	sta (_destptr),Y 
	dey 
	bpl !-
	clc 
	lda _srcptr_l 
	adc _temp_l 
	sta _srcptr_l 
	lda _temp_h 
	adc _srcptr_h 
	bpl !+
	sec 
	sbc #$50

!:

	cmp #$30
	bcs !+
	adc #$50

!:

	sta _srcptr_h 
	clc 
	lda _destptr_l 
	adc _temp_l 
	sta _destptr_l 
	lda _temp_h 
	adc _destptr_h 
	bpl !+
	sec 
	sbc #$50

!:

	cmp #$30
	bcs !+
	adc #$50

!:

	sta _destptr_h 
	dex 
	bne rpdigloop
	rts 

InitZP:

	lda #$0A		//#of humanoids
	sta _humanc
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
	jsr ai_unit
	ldx #ID_BULLET2
	jsr ai_unit
	jsr ai_alt
	jsr ai_alt
	jsr ai_alt
	jsr AIBatch
	jsr NextFrame
	jsr ScrollSurface
	jsr RepaintAll
	jsr Collision
	jsr SpawnBait
	lda #$7E		//Acknowledge ESCAPE Condition
	jmp OSBYTE

CursorOn:

	lda #$04
	ldx #$00
	jsr OSBYTE
	ldx #$0A
	lda #_srcptr_l
	jmp Out6845

CursorOff:

	lda #$04
	ldx #$01
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

!:

	lda _score_lsb,X 
	jsr PrintBCD
	dex 
	bpl !-
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
	bne !+
	ldx #(' '-'0')	//$f0

!:

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

	lda #$7E
	jsr OSBYTE
	ldx #$00

highloop:

	lda HiScore,X 
	cmp _score_lsb
	lda HiScore + 1,X 
	sbc _score_100
	lda HiScore + 2,X 
	sbc _score_msb
	bcc newhigh3
	txa 
	clc 
	adc #$18
	tax 
	cpx #$A9		//#(24*7 + 1)
	bcc highloop
	bcs PrintHighs

newhigh3:

	stx _temp 
	cpx #$A8		//#(24*7)
	beq !++
	ldx #$A8

!:

	dex 
	lda HiScore,X 
	sta $0718,X 
	cpx _temp 
	bne !-

!:

	lda #$0D
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

prhiloop:

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
	bne !+
	sty _temp2 

!:

	lda #$05
	jsr PrintN
	inx 
	inx 
	inx 

!:

	lda HiScore,X 
	jsr OSWRCH
	inx 
	cmp #$0D
	bne !-
	iny 
	iny 
	pla 
	clc 
	adc #$18
	tax 
	cpx #$C0
	bne prhiloop
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
	adc #>HiScore
	sta ParamBlk + 1 
	lda #$14
	sta ParamBlk + 2 
	lda #$20
	sta ParamBlk + 3 
	lda #$7E
	sta ParamBlk + 4 
	ldx #<ParamBlk
	ldy #>ParamBlk
	lda #$00
	jsr OSWORD		//input line
	bcc !+
	ldx _temp 
	lda #$0D
	sta HiScore + 3,X 

!:

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
	lda _humanbonus
	jsr PaintBCD
	lda #$00
	jsr PaintBCD
	lda _humanc
	beq lvldone
	sta _count
	ldx #$19

BonusLoop:

	ldy #$77
	txa 
	pha 
	jsr XYToVidP
	ldx #MAN
	jsr XBLTSprite
	ldy _humanbonus
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

lvldone:

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
	lda #$00		//Start-up hum sound
	jsr PlaySound
	jsr InitZP

planetloop:

	jsr NextLevel
	jsr Game
	jsr DoneLevel
	lda _lives
	bne planetloop
	rts 

AnimFrame:

	lda Param,X 
	cmp #$08
	beq !+
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

!:

	ldy Param,X 
	dey 
	tya 
	sta Param,X 
	beq !+
	lda _originp_l
	sta pNext_l,X 
	lda _originp_h
	sta pNext_h,X 
	lda _xrel_l
	sta pSprite_l,X 
	lda _xrel_h
	sta pSprite_h,X 
	jmp XORAnimate

!:

	lda Anim,X 
	bmi !++
	cpx #SHIP
	bne !+
	asl 
	bpl !+
	lda #TRUE
	sta _dead

!:
	lda #$00
	sta Anim,X 
	sta pSprite_h,X 
	sta pNext_h,X 
	rts 

!:

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
	bmi anim_blast
	lda Param,X 
	cmp #$07
	bne !+
	lda #$06
	jsr PlaySound

!:

	ldy #$07

warploop:

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
	beq warpnext
	ldy #$00
	ldx _id
	lda Unit,X 
	asl 
	tax 
	lda imgDot,X 
	eor (_destptr),Y 
	sta (_destptr),Y 

warpnext:

	ldy _yreg
	dey 
	bpl warploop
	ldx _id

XAnimRet:

	pla 
	sta _max_xscr
	pla 
	sta _min_xscr
	rts 

anim_blast:

	ldy #$07

blastloop:

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
	bpl blastloop
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

!:

	clc 
	adc _temp 
	dey 
	bne !-
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

!:

	clc 
	lda _srcptr_l 
	adc _offset_l 
	sta _srcptr_l 
	lda _srcptr_h 
	adc _offset_h 
	sta _srcptr_h 
	dex 
	bne !-
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
	bne linkerr
	stx _temp_l
	lda Param,Y 
	cmp _temp_l
	bne linkerr
	lda Anim,Y 

linkerr:
	rts

#import "Sound.asm"
#import "SpriteTileAnim.asm"
#import "Strings.asm"
#import "UnitData.asm"
#import "relocater.asm"

* = $3000 "BOOT"

Boot:
	jsr Relocate	//LINE 120 REM:FOR I% = 0 TO &2FC STEP4 :I%!&E00 = I%!&3100:NEXT
	jsr SetUpEnvelopes
	lda #$ce
	sta _rand_h
	lda #$ad
	sta _rand_m
	lda #$02
	sta _rand_l
	lda #$00
	ldx #$01
	jsr OSBYTE
	ldx #$FF
	txs

Hook:
	sei 
	lda IRQ1V		//IRQ1V - Main interrupt vector
	sta _irq1v 
	lda IRQ1V + 1 
	sta _irq1v + 1
	lda #<IRQHook	//New IRQ = $1103
	sta IRQ1V 
	lda #>IRQHook + 1
	sta IRQ1V + 1 
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
	
ENVELOPE1:
    .byte 1,4, -4,-1,-1,20,20,20, 1,0,0,0,1,1
ENVELOPE2:
    .byte 2,1, 2,2,2,20,20,20, 1,0,0,0,1,1
ENVELOPE3:
    .byte 3,1, 3,2,-2,6,6,6, 100,0,0,-5, 100,0
ENVELOPE4:
    .byte 4,1, -15,-15,-15,240,240,240, 20,0,0,-20, 126,126

DefHigh:
		//hiscore_t[24]  Default high score
	.byte $00,$10,$00,$41,$63,$6F,$72,$6E
	.byte $73,$6F,$66,$74,$0D,$03,$06,$06
	.byte $06,$06,$03,$03,$F3,$03,$0C,$0E

	.fill $42,0

#import "0E00.asm"