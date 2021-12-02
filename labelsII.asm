#importonce

//.label _oldorgp	    =	$00
.label _oldorgp_l	=	$00

.label _oldorgp_h	=	$01
.label _scrolloff_l =	$02
.label _scrolloff_h =	$03

//.label _originp	    =	$08
.label _originp_l	=	$08	

.label _originp_h	=	$09	
.label _xwin		=	$0a

.label _xwinedge	=	$0c		// [2]
.label _xwinleft	=	$0c		// " + LEFT

.label _xwinright	=	$0d		// " + RIGHT
.label _inkey_tab	= 	$0e
.label _bgpal		=	$0f	// logical colour 0
.label _framec_l	=	$10	
.label _framec_h	=	$11
.label _count		=	$12
.label _enemyc		=	$13	// not baiters/humans
.label _squaddelay	=	$14
.label _humanc		=	$15
.label _level		=	$16
.label _humanbonus  =	$17
.label _baitdelay_l =	$18
.label _baitdelay_h =	$19
.label _no_planet	=	$1a		//0/1
.label _vsync0		=	$1b		//last vsync ctr
.label _ddx_l		=	$1c
.label _ddx_h		=	$1d
.label _dxrel_l 	=	$1e
.label _dxrel_h	    =	$1f
.label _xrel_l		=	$20
.label _xrel_h		=	$21
.label _id_alt		=	$22
.label _inkey_space = 	$23
.label _dead		=	$24		//FALSE/TRUE
.label _batch		=	$25
.label _batchc		=	$26
.label _spawn_spr	=	$27
.label _min_xscr	=	$28
.label _max_xscr	=	$29
.label _dxwin		=	$2a
.label _inkey_enter = 	$2b
.label _ship_xscr	=	$2c
.label _hikerc		=	$2d //hitchhikers(rescuees)
.label _digitp		=	$2e	// start of digit row
.label _digitp_l	=	$2e // in vram
.label _digitp_h	=	$2f
.label _score_lsb	=	$30
.label _score_100	=	$31 // mmh,hll points
.label _score_msb	=	$32
.label _leading0	=	$33	// 0: leading blanks
.label _flashc		=	$34
.label _flpalc		=	$35
.label _flpalframes =	$36
.label _lives		=	$37
.label _bombs		=	$38
.label _gameover_sp =	$39		//
.label _shootspeed  =   $3a
.label _bomb_pass2	=	$3b
.label _shippal	    =	$3c		// " 7
.label _rotpalc	    =	$3d
.label _surfpal	    =	$3e		// " 6
.label _nextlvl_sp	=	$3f
.label _is_spawning =	$40
.label _savedx		=	$41
.label _savedy		=	$42
.label _high_rank	=	$43	// hiscores #1 to #8
.label _strlen		=	$44
.label _Laser		=	$46		//[4] $47,$48,$49
.label _Tail		=	$4a		//[4] imgLaser[x]
.label _Head		=	$4e		//[4] "
.label _BeamX		=	$52		//[4]
.label _BeamY		=	$56 	//[4]
.label _pTail_l	    =	$5a		//[4] laser @vram
.label _pTail_h	    =	$5e		//[4]
.label _pHead_l	    =	$62		//[4]
.label _pHead_h	    =	$66		//[4]

.label _destptr	    =	$70
.label _destptr_l	=	$70

.label _destptr_h	=	$71

.label _srcptr		=	$72
.label _srcptr_l	=	$72
.label _srcptr_h	=	$73
.label _dest_crow	=	$74  // vram cell row 0-7
.label _imglen		=	$75

.label _temp		=	$76
.label _temp_l		=	$76
.label _offset_l	=	$76

.label _temp_h		=	$77//check
.label _temp2		=	$77
.label _offset_h	=	$77//check

.label _dxwinc		=	$78
.label _anim_xscr	=	$7a
.label _beam_yscr	=	$7c
.label _xscrc		= 	$7e
.label _rand_h		=	$80		//random buffer
.label _rand_m		=	$81
.label _rand_l		=	$82
.label _heightmask	=	$84
.label _xreg		=	$85
.label _yreg		=	$86
.label _laserc		=	$87
.label _dxedge		=	$88	// laser L=-_dxwin,R
.label _id			=	$89
.label _paintmask	=	$8a
.label _collision	=	$8b
.label _irq1v		=	$8c		//*(IRQ1V)
.label ErrorMessVec =   $fd

.label BRKVector    =   $0202
.label X_l			=	$0400	//[37]
.label X_h			=	$0425	//[37]
.label Y_l			=	$044a	//[37]
.label Y_h			=	$046f 	//[37]
.label dX_l		    =	$0494	//[37]
.label dX_h		    =	$04b9	//[37]
.label dY_l		    =	$04de	//[37]
.label dY_h		    =	$0503 	//[37]
.label pSprite_l	=	$0528	//(void *)[37]
.label pSprite_h	=	$054d	//sprite ptr @vram
.label pNext_l		=	$0572	//(void *)[37]
.label pNext_h		=	$0597	//next spr pos@vram
.label Unit		    =	$05bc	//sprite_t[37]
.label Param		=	$05e1	//count[37], flags
.label pDot_l		=	$0606	//[32]
.label pDot_h		=	$0626	//[32]
.label Anim		    =	$0646	//flags[37]
.label Dot			=	$066b	//idx[37] spr#x2
.label HiScore		=	$0700	//hiscore_t[7] =168
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

//Address equates
.label SHEILA		=	$fe00
.label ULAPALETTE	=	$fe21
.label SYS6522		=	$fe40
.label USR6522		=	$fe60
.label OSRDCH		=	$ffe0
.label OSWRCH		=	$ffee
.label OSWORD		=	$fff1
.label OSBYTE		=	$fff4
.label IRQ1V		=	$204
.label VRAM		    =	$3000