#importonce
// vi: syntax=asmM6502 ts=4 sw=4

// Acornsoft Planetoid, BBC Micro
// Written by Neil Raine, 1982
// 6502 disassembly by rainbow
// 2020.02.08
// <djrainbow50@gmail.com>
// https://github.com/r41n60w/planetoid-disasm

// Constants/equates

.const ALT_VSYNC_LB =   $24
.const ALT_VSYNC_HB =   $02
.const NULL		    =	0
.const FALSE		=	0
.const TRUE		    =	1
.const LEFT		    =	0	//_xwinedge[2]
.const RIGHT		=	1	// "

.const KEYUP		=	0		//$00
.const KEYDOWN		=	-1		//$ff
//typedef	int	inkey_t//
.const KEY_SHIFT	=	-1		//$ff
.const KEY_P		=	-56		//$c8
.const KEY_A		=	-66		//$be
.const KEY_AT		=	-72		//$b8
.const KEY_RETURN	=	-74		//$b6
.const KEY_TAB		=	-97		//$9f
.const KEY_Z		=	-98		//$9e
.const KEY_SPACE	=	-99		//$9d
.const KEY_ESCAPE	=	-113	//$8f

//typedef unsigned	colour_t//
//typedef struct	{
//	colour_t	logical		: 4//
//	colour_t	physical	: 4//
//} palette_t//
//enum palettes	{
.const PAL_BG		=	$00 // bomb -> flash white
.const PAL_ROT1	    =	$10 // [ x3
.const PAL_ROT2	    =	$20 // [ rotate b/w
.const PAL_ROT3	    =	$30 // [ red, yellow, blue
.const PAL_FLASH	=	$40 // mutant, pod, digits
.const PAL_SHIP2	=	$50 // magenta
.const PAL_SURF	    =	$60 // red, green lvl x5
.const PAL_SHIP	    =	$70 // ship hit ->flash red
.const PALX_CLEAR	=	$80 // centre of baiter
.const PALX_ENEMYB  =   $80 // added by mikroman
.const PALX_UNITR	=	$90 // pod, swarmer
.const PALX_UNITG	=	$a0 //[ land/mut,bait,human
.const PALX_UNITY	=	$b0 //[ above x4 + swarmer
.const PALX_UNITB	=	$c0 // bomber?
.const PALX_UNITM	=	$d0
.const PALX_UNITC	=	$e0
.const PALX_METAL	=	$f0 //bullet/mine,ship hull
//}//

//enum colours	{
.const BLACK		=	0
.const RED			=	1
.const GREEN		=	2
.const YELLOW		=	3
.const BLUE		    =	4
.const MAGENTA		=	5
.const CYAN		    =	6
.const WHITE		=	7
//}//

//typedef int8_t id_t//
//enum ids	{
.const SHIP		    =	0	//ship slot	
.const HITCH		=	1	//hitch hiker(s) slot
.const ID_MIN		=	2	//U0  first unit slot
.const ID_MAX		=	31	//Uf  last  unit slot
.const ID_BULLET1	=	32	//O
.const ID_BULLET2	=	33
.const ID_ALT1		=	34
.const ID_ALT2		=	35
.const ID_ALT3		=	36
//}//

//typedef int	sprite_t//
//typedef struct {
//	unsigned	state	: 1//
//	sprite_t	sprite	: 7:
//} unit_t//
//extern unit_t	Unit[37]//
.const BLIT		    =	$00			//bit 7 clear
.const UPDATE		=	$80			//bit 7 set
//enum sprites	{
.const EMPTY		=	-1			//$ff,bit 6 set
.const U_SHIP		=	0
.const LANDER		=	1	//+ man -> mutant
.const MUTANT		=	2
.const BAITER		=	3
.const BOMBER		=	4
.const SWARMER		=	5	//spawned on Pod death
.const MAN			=	6	
.const POD			=	7
.const KUGEL		=	8	//bullet or mine
.const S250		    =	9	//flashing '250' points
.const S500		    =	10	//         '500'
//}//

//extern	int8_t	Anim[37]//
//enum anims	{
.const WARP		    =	1			//$01 +hyperspc
.const HAL			=	(1 << 6)	//$40 hyper die
.const BLAST		=	-1			//$ff
//}//