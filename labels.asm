#importonce

// vi: syntax=asmM6502 ts=4 sw=4

// Acornsoft Planetoid, BBC Micro
// Written by Neil Raine, 1982
// 6502 disassembly by rainbow
// 2020.02.08
// <djrainbow50@gmail.com>
// https://github.com/r41n60w/planetoid-disasm

//All labels

// Zero page variables (prefix _zp)

//BCD vars
.label _level		=	$16
.label _humanbonus  =	$17
.label _score_lsb	=	$30
.label _score_100	=	$31 // mmh,hll points
.label _score_msb	=	$32
.label _lives		=	$37
.label _bombs		=	$38
.label _high_rank	=	$43	// hiscores #1 to #8

//Counters
.label _framec_l	=	$10	
.label _framec_h	=	$11	
.label _count		=	$12
.label _enemyc		=	$13	// not baiters/humans
.label _squaddelay	=	$14
.label _humanc		=	$15
.label _baitdelay_l =	$18
.label _baitdelay_h =	$19
.label _hikerc		=	$2d //hitchhikers(rescuees)
.label _flpalc		=	$35
.label _flpalframes =	$36
.label _shootspeed  =   $3a
.label _rotpalc	    =	$3d

//Sprite/id
.label _id_alt		=	$22
.label _batch		=	$25
.label _batchc		=	$26
.label _spawn_spr	=	$27 
.label _id			=	$89

//Palette
.label _bgpal		=	$0f	// logical colour 0
.label _shippal	    =	$3c		// " 7
.label _surfpal	    =	$3e		// " 6
.label _flashc		=	$34

//Blit/Print
.label _leading0	=	$33	// 0: leading blanks
.label _strlen		=	$44
.label _dest_crow	=	$74  // vram cell row 0-7
.label _imglen		=	$75
.label _heightmask	=	$84
.label _paintmask	=	$8a
.label _collision	=	$8b

//Keycode
.label _inkey_tab	= 	$0e
.label _inkey_space = 	$23
.label _inkey_enter = 	$2b

//Pointers + ptr offsets
.label _scrolloff_l =	$02
.label _scrolloff_h =	$03
.label _oldorgp	    =	$00
.label _oldorgp_l	=	$00
.label _oldorgp_h	=	$01
.label _originp	    =	$08
.label _originp_l	=	$08	
.label _originp_h	=	$09	
.label _digitp		=	$2e	// start of digit row
.label _digitp_l	=	$2e // in vram
.label _digitp_h	=	$2f
.label _destptr	    =	$70
.label _destptr_l	=	$70
.label _destptr_h	=	$71
.label _srcptr		=	$72
.label _srcptr_l	=	$72
.label _srcptr_h	=	$73

//Screen coords
.label _min_xscr	=	$28
.label _max_xscr	=	$29
.label _ship_xscr	=	$2c
.label _anim_xscr	=	$7a
.label _beam_yscr	=	$7c
.label _xscrc		= 	$7e
//Scaled coords
.label _xwin		=	$0a
.label _xwinedge	=	$0c		// [2]
.label _xwinleft	=	$0c		// " + LEFT
.label _xwinright	=	$0d		// " + RIGHT
.label _dxwin		=	$2a
.label _dxwinc		=	$78
.label _dxedge		=	$88	// laser L=-_dxwin,R
// Raw coords
.label _ddx_l		=	$1c
.label _ddx_h		=	$1d
.label _dxrel_l 	=	$1e
.label _dxrel_h	    =	$1f
.label _xrel_l		=	$20
.label _xrel_h		=	$21

//Booleans
.label _no_planet	=	$1a		//0/1
.label _dead		=	$24		//FALSE/TRUE
.label _bomb_pass2	=	$3b
.label _is_spawning=	$40

//Laser tables
.label _Laser		=	$46		//[4] $47,$48,$49
.label _Tail		=	$4a		//[4] imgLaser[x]
.label _Head		=	$4e		//[4] "
.label _BeamX		=	$52		//[4]
.label _BeamY		=	$56 	//[4]
.label _pTail_l	    =	$5a		//[4] laser @vram
.label _pTail_h	    =	$5e		//[4]
.label _pHead_l	    =	$62		//[4]
.label _pHead_h	    =	$66		//[4]
.label _laserc		=	$87

//Misc
.label _gameover_sp =	$39		//
.label _nextlvl_sp	=	$3f
.label _irq1v		=	$8c		//*(IRQ1V)
.label _vsync0		=	$1b		//last vsync ctr
.label _savedx		=	$41
.label _savedy		=	$42
.label _xreg		=	$85
.label _yreg		=	$86
.label _rand_h		=	$80		//random buffer
.label _rand_m		=	$81
.label _rand_l		=	$82
.label ErrorMessVec =   $fd

//Temp
.label _temp		=	$76
.label _temp_l		=	$76
.label _temp_h		=	$77
.label _temp2		=	$77
.label _offset_l	=	$76
.label _offset_h	=	$77
// REVERSED already
.label BRKVector    =   $202
.label X_l			=	$400	//[37]
.label X_h			=	$425	//[37]
.label Y_l			=	$44a	//[37]
.label Y_h			=	$46f 	//[37]
.label dX_l		    =	$494	//[37]
.label dX_h		    =	$4b9	//[37]
.label dY_l		    =	$4de	//[37]
.label dY_h		    =	$503 	//[37]
.label pSprite_l	=	$528	//(void *)[37]
.label pSprite_h	=	$54d	//sprite ptr @vram
.label pNext_l		=	$572	//(void *)[37]
.label pNext_h		=	$597	//next spr pos@vram
.label Unit		    =	$5bc	//sprite_t[37]
.label Param		=	$5e1	//count[37], flags
.label pDot_l		=	$606	//[32]
.label pDot_h		=	$626	//[32]
.label Anim		    =	$646	//flags[37]
.label Dot			=	$66b	//idx[37] spr#x2
.label HiScore		=	$700	//hiscore_t[7] =168

//.label SurfaceY	    =	$e00	//[256]
//.label imgDigit	    =	$f00	//[10][16]
//.label imgMan		=	$fa0	//[8]
//.label imgShipR	    =	$fc0	//[48]
//.label imgShipL	    =	$ff0	//[48]
//.label imgSurface	=	$1020	//[3][4]
//.label imgLander	=	$102c	//[32]
//.label imgMutant	=	$104c	//[32]
//.label imgBaiter	=	$106c	//[20]
//.label imgBomber	=	$1094	//[24]
//.label imgSwarmer	=	$10ac	//[12]
//.label imgKugel	    =	$10b8	//[2]
//.label imgShrapnel	=	$10ba	//[4]
//.label img250		=	$10be	//[40]
//.label img500		=	$10ce	//[40] overlaps

//.label SurfQuad	    =	$2bc0	//[64]4x2bit packed
//.label imgLaser	    =	$2bff	//[81]
//.label WarpX		=	$2c50	//[8]
//.label WarpY		=	$2c58	//[8]
//.label BlastX		=	$2c60	//[8]
//.label BlastY		=	$2c68	//[8]
//.label FlashPal	    =	$2c70	//[8] $4<colour>
//.label HyperKeys	=	$2c78	//hypersp kcodes[7]
//.label ParamBlk 	=	$2c80	//[8] for OSWORD
//.label HoldSync	    =	$2c88	//[20] # of voices
//.label FlushChan	=	$2c9c	//[20] chan #0-3
//.label AmplEnvel	=	$2cb0	//[-15,0] or envel#
//.label Pitch		=	$2cc4	//[20] 0-255
//.label Duration 	=	$2cd8	//[20] 0-255

//.label SpriteLen	=	$2d00
//.label SpriteV_l	=	$2d0b
//.label SpriteV_h	=	$2d16
//.label imgDot		=	$2d21	//[2][11]
//.label SpriteMaxY	=	$2d4d
//.label Points_l	    =	$2d58
//.label Points_h	    =	$2d63
//.label DoWarp		=	$2d6e	// bool[11]
//.label vsync		=	$2e00	//vsync counter
//.label rotatec		=	$2e01
//.label RotColour	=	$2e02	// [3]
//.label AiVector	    =	$2e05	//void (*)(int)[11]
//.label Spawnc		=	$2e1d	//[8]
//.label XMinInit	    =	$2e25
//.label YMinInit	    =	$2e35
//.label dXMinInit	=	$2e45
//.label dYMinInit	=	$2e55
//.label XRangeInit	=	$2e2d
//.label YRangeInit	=	$2e3d
//.label dXRangeInit	=	$2e4d
//.label dYRangeInit	=	$2e5d
//.label StringV_l	=	$2e65	//[7]
//.label StringV_h	=	$2e79	//[7]
//.label string0		=	$2e8d
//.label string1		=	$2e90
//.label string2		=	$2ea9
//.label string3		=	$2eb5
//.label string4		=	$2ef5
//.label string5		=	$2f39
//.label string6		=	$2f3f
//.label DefHigh		=	$3088