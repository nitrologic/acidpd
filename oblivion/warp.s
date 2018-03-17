
	section	name,CODE_C

	;Let's try a-fuckin'-gain
	;
	;This time, StarGate 2!
	;

	jmp	main

maxobjs	equ	128		;different alien types!
shell	equ	-1		;for shell

restx	equ	48
copnop	equ	$01fe0000
sly	equ	28
testmode	equ	0	;-1
gamemod	equ	44*3
thrust	equ	$3000 ;$3000
thrust2	equ	$4000 ;$5000
friction	equ	$1000
yacc	equ	$2000
maxthrust	equ	12<<16
minyspeed	equ	1
maxyspeed	equ	3
maxy	equ	512
maxy2	equ	maxy-16
numstars	equ	61
maxlasers	equ	4
lasersize	equ	14
maxfrags	equ	256+64
fragssize	equ	30
maxaliens	equ	192
aliensize	equ	128
maxbulls	equ	192
bullsize	equ	26
	;
con0	equ	$040
con1	equ	$042
fwm	equ	$044
lwm	equ	$046
cpth	equ	$048
bpth	equ	$04c
apth	equ	$050
dpth	equ	$054
size	equ	$058
cmod	equ	$060
bmod	equ	$062
amod	equ	$064
dmod	equ	$066
adat	equ	$074
bdat	equ	$072
cdat	equ	$070

	rsreset	;audio stuff...1 for each channel
	;
status	rs.b	1	;2  = started, no int
			;1  = started, 1 int
			;0  = dma turned off, vol to 0.
			;-1 = ready for more...
			;
pri	rs.b	1
vol	rs.w	1	;volume to playe at
sfxreq	rs.l	1	;sample to play upon request
			;(0 for none)
audiosize	rs.b	0

	rsreset
	rs.l	1
xa	rs.l	1
xs	rs.l	1
x	rs.l	1	*
ya	rs.l	1
ys	rs.l	1
y	rs.l	1	*
frame	rs.l	1
flags	rs.b	1	;bit 7 = 1 = imploding!
			;bit 6 = 1 = important! always draw me!
			;bit 5 = 1 = smart/inviso invincible.
			;bit 4 = 1 = slow coll chk.
			;bit 0 = 1 = exists! flags  = 0 = dead	
id	rs.b	1	
anims	rs.l	1
animf	rs.l	1
anim	rs.l	1	*
facing	rs.w	1	;plus=use rightwards shapes
loop	rs.l	1
collide	rs.l	1
shot	rs.l	1
	;
	;scanner stuff
	;
old	rs.w	1	;pos of old plot
olds	rs.b	1	;old plot shift
col	rs.b	1	;col1 (top half of blip=high 4 bits)
	;
	;bullet stuff
	;
bullt	rs.w	1
bullr	rs.w	1
	;
	;user stuff...
	;

macros

test	macro
	ifne	testmode
	move	\1,$dff180
	endc
	endm

vwait	macro
	move	#$20,$09c(a6)
.vloop\@	btst	#5,$01f(a6)
	beq.s	.vloop\@
	endm

bwait	macro
	btst	#6,$002(a6)
.bloop\@	btst	#6,$002(a6)
	bne.s	.bloop\@
	endm

mwait	macro
.mwait\@	btst	#6,$bfe001
	bne.s	.mwait\@
	endm

prepblit1	macro
	move	#$9f0,con0(a6)
	move.l	#-1,$044(a6)
	move	#0,$064(a6)
	move	#88-2,$066(a6)
	endm

alloclist	macro
	;
	;\1 = name of list (eg 'lasers')
	;\2 = max items
	;\3 = item size (don't forget + 4 for link)
	;
	move	\2,\1.max
	move	\3,\1.size
	;
	move	\2,d0
	mulu	\3,d0
	move.l	#$10002,d1
	jsr	-198(a6)
	move.l	d0,\1.ds
	bra.s	alistskip\@
	;
\1	dc.l	0
\1.free	dc.l	0
\1.max	dc	0
\1.size	dc	0
\1.ds	dc.l	0
	;
alistskip\@
	endm

freelist	macro
	;
	move.l	\1.ds(pc),a1
	move	\1.max(pc),d0
	mulu	\1.size(pc),d0
	jsr	-210(a6)
	;
	endm

clearlist	macro
	;
	;\1=list name
	;
	lea	\1(pc),a0
	bsr	clearlist
	endm

clearlist	;a0=pointer to list
	;
	move	8(a0),d0
	subq	#1,d0
	move	10(a0),d1
	clr.l	(a0)
	lea	4(a0),a1
	move.l	12(a0),a0
	;
.loop	move.l	a0,(a1)
	move.l	a0,a1
	add	d1,a0
	dbf	d0,.loop
	clr.l	(a1)
	rts

killitem	macro
	;
	;a0=current item, a1=previous
	;\1=name of list
	;
	;don't try proccessing a0 after this!
	;
	move.l	(a0),(a1)
	move.l	\1.free(pc),(a0)
	move.l	a0,\1.free
	move.l	a1,a0
	endm

additem	macro
	;
	;\1=name of list ; return a0, new item.
	;
	;a1 should normally point to previous item, so
	;move.l (a1),a0 should bring you back to the item you
	;were on!
	;
	move.l	\1.free(pc),a0
	move.l	(a0),\1.free
	move.l	\1(pc),(a0)
	move.l	a0,\1
	endm

additem2	macro
	;
	;\1=name of list ; return a0, new item, or z=1 if none.
	;
	;a1 should normally point to previous item, so
	;move.l (a1),a0 should bring you back to the item you
	;were on!
	;
	move.l	\1.free(pc),d0
	beq.s	.done\@
	move.l	d0,a0
	move.l	(a0),\1.free
	move.l	\1(pc),(a0)
	move.l	a0,\1
.done\@	;
	endm

inton	macro
	move.l	#l3int\1,$6c
	endm

makesafe	macro
	move.l	#\1,safeint
	endm

makedef	macro
	move.l	#\1,defint
	endm

usesafe	macro
	move.l	safeint(pc),$6c
	endm

usedef	macro
	move.l	defint(pc),$6c
	endm

chkkey	macro
	btst	#(\1&7),rawmat+(\1>>3)
	endm

;********** MAIN ************************************************

initsp	ds.l	1

main	move.l	a7,initsp
	bsr	wbkludge
	bsr	loadaliens
	bsr	loadhis
	bsr	allocstuff
	;
	move.l	4.w,a6
	alloclist	lasers,#maxlasers,#lasersize
	alloclist	frags,#maxfrags,#fragssize
	alloclist	aliens,#maxaliens,#aliensize
	alloclist	bulls,#maxbulls,#bullsize
	;
	bsr	sysoff
	bsr	setupall
	;
everything	;
	bra	intro
	;
newgame	;new game...
	;
	clr	introon
	bsr	initworks
	bsr	initgscan
	clr	messx
	bsr	showmess
	moveq	#10,d0
	moveq	#1,d1
	bsr	makeswaits
	;
	bsr	swapplayer
	bne.s	.skip
	bsr	initplayer
	bsr	swapplayer
.skip	bsr	initplayer
	;
newpattern	;new pattern...
	;
	addq	#1,pattern
	clr	tokill
	clr.l	patmess
	clr	bomode
	bsr	perpattern
	bsr	dopatmess
	;
newlife	;new life...
	;
	bsr	frontcls
	bsr	initship
	bsr	initmounts
	bsr	initaliens
	bsr	perlife
	;
	;make it all happen!
	;
	bsr	initgame
	;
actiondo	bsr	displayon
	bsr	doloops
	bsr	initthrust
	bsr	initgscan
	clr.l	stextstuff
	;
actiondone	move	warpx(pc),d0
	beq.s	.nowarp
	bsr	warpover
	bra	newpattern
.nowarp	move	tokill(pc),d0
	bne.s	.nopatover
	bsr	patover
.nopatover	move	playerdie(pc),d0
	bne.s	.skip
	;
	move	tokill(pc),d0
	beq	newpattern
	bra	byebye
	;
.skip	bsr	hidescore
	move	ships(pc),d0
	bne.s	.skip2
	bsr	gameover
	bsr	swapplayer
	bne	allover
	move	ships(pc),d0
	bne.s	.skip3
	move	playerup(pc),d0
	beq	allover
	bsr	swapplayer
	bra	allover
	;
.skip2	bsr	swapplayer
	bne.s	.skip3
	move	ships(pc),d0
	bne.s	.skip3
	bsr	swapplayer
	;
.skip3	move	tokill(pc),d0
	beq	newpattern
	bra	newlife
	;
byebye	move.l	4.w,a6
	;
	freelist	bulls
	freelist	aliens
	freelist	frags
	freelist	lasers
	;
	bsr	syson
	bsr	freestuff
	bsr	savehis
	bsr	freealiens
	bsr	wbkludge2
	moveq	#0,d0
	rts

;********** SUBROUTINES *****************************************

wbmess	dc.l	0

wbkludge	movem.l	d0/a0,-(a7)
	;
	move.l	4.w,a6
	sub.l	a1,a1
	jsr	-294(a6)	;findtask
	move.l	d0,a2
	;
	movem.l	(a7)+,d0/a0
	;
	tst.l	$ac(a2)
	bne	susspattern
	lea	$5c(a2),a0
	jsr	-384(a6)	;waitport
	jsr	-372(a6)	;getmsg
	move.l	d0,wbmess
	lea	dosname(pc),a1
	jsr	-408(a6)
	move.l	d0,a6
	;
	move.l	wbmess(pc),a0
	move.l	$24(a0),a0
	move.l	(a0),d1
	jmp	-126(a6)

wbkludge2	move.l	wbmess(pc),d0
	beq.s	.done
	move.l	4.w,a6
	move.l	d0,a1
	jmp	-378(a6)	;rplymsg
.done	rts

flash	move	d0,-(a7)
	move	#-1,d0
.loop	move	d0,$dff180
	dbf	d0,.loop
	move	(a7)+,d0
	rts

numhis	equ	20
hichars	equ	16	;characters in name
hichars2	equ	hichars+4

hiscores	;
	rept	numhis
	dc.l	0
	dcb.b	16,32
	endr
hiscoresf	dc.l	0
	dcb.b	16,32

hisc1	dc.b	11,'PLAYER '
hisc2	dc.b	'1',0
hisc3	dc.b	13,'NEW HIGH SCORE!',0
hisc4	dc.b	15,'PLEASE ENTER YOUR NAME',0
	even
hiname	dc.b	'oblivion.heroes',0
	even

codehis	lea	hiscores(pc),a0
	move	#hiscoresf-hiscores-1,d0
.loop	move.b	(a0),d1
	not.b	d1
	rol.b	#4,d1
	move.b	d1,(a0)+
	dbf	d0,.loop
	rts

loadhis	;load hi scores.
	lea	dosname(pc),a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,a6
	move.l	#hiname,d1
	move.l	#1005,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq.s	.done
	move.l	d0,d1
	move.l	#hiscores,d2
	move.l	#hiscoresf-hiscores,d3
	jsr	-42(a6)
	move.l	d7,d1
	jsr	-36(a6)
	bra	codehis
.done	rts

savehis	;save hi scores.
	bsr	codehis
	lea	dosname(pc),a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,a6
	move.l	#hiname,d1
	move.l	#1006,d2
	jsr	-30(a6)
	move.l	d0,d7
	beq.s	.done
	move.l	d0,d1
	move.l	#hiscores,d2
	move.l	#hiscoresf-hiscores,d3
	jsr	-48(a6)
	move.l	d7,d1
	jmp	-36(a6)
.done	rts

allover	;game over for everyone!
	;
	bsr	checkhi
	bsr	swapplayer
	bne.s	.skip
	bsr	checkhi
.skip	move	#1,introon
	bsr	initscmess
	bsr	starson
	bra	ihiscores

checkhi	move.l	score(pc),d0
	moveq	#numhis-1,d1
	lea	hiscores(pc),a0
.loop	cmp.l	(a0),d0
	bhi.s	.here
	lea	hichars2(a0),a0
	dbf	d1,.loop
	rts
	;
.here	;insert here
	lea	hiscoresf(pc),a1
	;
.loop2	lea	-hichars2(a1),a1
	move.l	(a1),hichars2(a1)
	;
	move.l	4(a1),hichars2+4(a1)
	move.l	8(a1),hichars2+8(a1)
	move.l	12(a1),hichars2+12(a1)
	move.l	16(a1),hichars2+16(a1)
	;
	cmp.l	a0,a1
	bhi.s	.loop2
	;
	move.l	#$20202020,d0
	;
	move.l	d0,4(a0)
	move.l	d0,8(a0)
	move.l	d0,12(a0)
	move.l	d0,16(a0)
	;
	move.l	a0,-(a7)
	bsr	inittext
	;
	move	playerup(pc),d0
	bmi.s	.skip
	lea	hisc2(pc),a0
	add	#49,d0
	move.b	d0,(a0)
	lea	hisc1(pc),a0
	bsr	printit
.skip	lea	hisc3(pc),a0
	bsr	printit
	lea	hisc4(pc),a0
	bsr	printit
	;
	not	getasc
	bsr	doloops
	move	#$8020,$09a(a6)
	;
	move.l	(a7)+,a4	;hi score entry
	move.l	score(pc),(a4)+
	;
	moveq	#hichars-1,d7
.usloop	bsr	calctpos
	move.b	#$aa,8*gamemod(a0)
	move.b	#$55,8*gamemod+44(a0)
	move.b	#$aa,8*gamemod(a1)
	move.b	#$55,8*gamemod+44(a1)
	dbf	d7,.usloop
	;
	moveq	#0,d7	;cursx
	lea	asciis(pc),a5
	clr	asciig
	clr	asciip
	;
.tloop	bsr	docurs
.tlp	move	asciig(pc),d0
	cmp	asciip(pc),d0
	beq.s	.tlp
	moveq	#0,d6
	move.b	0(a5,d0),d6	;ascii char.
	addq	#1,d0
	and	#15,d0
	move	d0,asciig
	cmp	#13,d6
	beq	.tdone
	cmp	#8,d6
	bne.s	.notback
	;
	;backspace
	tst	d7
	beq.s	.tlp
	;
	move.b	#32,0(a4,d7)
	bsr	docurs
	subq	#1,d7
	move.b	#32,0(a4,d7)
	bsr	calctpos
	moveq	#7,d0
.bsloop	clr.b	(a0)+
	clr.b	(a0)
	clr.b	(a1)+
	clr.b	(a1)
	lea	gamemod-1(a0),a0
	lea	gamemod-1(a1),a1
	dbf	d0,.bsloop
	;
	bra.s	.tloop	
	;
.notback	cmp	#32,d6
	bcs.s	.tlp
	cmp	#127,d6
	bcc.s	.tlp
	;
	move.b	d6,0(a4,d7)
	;
	bsr	docurs
	move.l	font(pc),a2
	lsl	#4,d6
	add	d6,a2
	bsr	calctpos
	moveq	#6,d0
.tloop2	move.b	(a2),(a0)
	move.b	(a2),(a1)
	addq	#2,a2
	lea	gamemod(a0),a0
	lea	gamemod(a1),a1
	dbf	d0,.tloop2
	cmp	#hichars-1,d7
	bcc	.tloop
	addq	#1,d7
	bra	.tloop
.tdone	not	getasc
	;
	;check at least 14 aliens for not cheating!
	;
	cmp	#14,numaliens
	bcs	.cheat
	rts
	;
.cheat	;they cheated!
	;
	move.l	#'CHEA',(a4)
	move.l	#'T!  ',4(a4)
	move.l	#'    ',8(a4)
	move.l	#'    ',12(a4)
	rts	

docurs	bsr	calctpos
	moveq	#6,d0
.loop	not.b	44(a0)
	not.b	44(a1)
	lea	gamemod(a0),a0
	lea	gamemod(a1),a1
	dbf	d0,.loop
	rts

calctpos	move.l	front1(pc),a0
	lea	17*8*gamemod+22-hichars/2(a0),a0
	add	d7,a0
	move.l	front2(pc),a1
	lea	17*8*gamemod+22-hichars/2(a1),a1
	add	d7,a1
	rts

loopsubs

beginvb	macro
	movem.l	a0-a5/d0-d7,-(a7)
	bsr	vbstuff
	endm

endvb	macro
	move	#$20,$09c(a6)
	movem.l	(a7)+,a0-a5/d0-d7
	rte
	endm

vbstuff	st	vflag
	move	$00e(a6),d0
	or	d0,clxdat2
	bsr	updatesfx
	move	introon(pc),d0
	beq.s	.done
	bmi.s	.skip
	bsr	introscroll
	move	#4,xspeed
	bsr	dostars
	clr	xspeed
	bsr	doglow12
	bsr	dosglow1
.skip	bsr	checkkeys
.done	rts

checkkeys	chkkey	$50	;F1
	beq.s	.notf1
	move	#-1,playerup
	;
.bye	move.l	#newgame,d0
	;
.bye2	move.l	initsp(pc),a0
	move.l	a0,usp
	addq	#8,a7
	move.l	d0,14*4+2(a7)
	endvb
	;
.notf1	chkkey	$51	;F2
	beq.s	.notf2
	clr	playerup
	bra.s	.bye
.notf2	chkkey	$52	;F3
	beq.s	.notf3
	move.b	lastf3(pc),d0
	bne.s	.notf32
	not.b	lastf3
	not	cmode
	bsr	showkeys2
	bra.s	.notf32
.notf3	clr.b	lastf3
.notf32	chkkey	$53	;F4
	beq.s	.notf4
	move.b	lastf4(pc),d0
	bne.s	.notf42
	not.b	lastf4
	not	cmode-playerdat+playerdat2
	bsr	showkeys2
	bra.s	.notf42
.notf4	clr.b	lastf4
.notf42	chkkey	$54	;F5
	beq.s	.notf5
	move.b	lastf5(pc),d0
	bne.s	.notf52
	not.b	lastf5
	move.l	#inthis,d0
	bra	.bye2
.notf5	clr.b	lastf5
.notf52	chkkey	$55	;F6 - exit...
	beq.s	.notf6
	move.b	lastf6(pc),d0
	bne.s	.notf62
	not.b	lastf6
	move.l	#byebye,d0
	bra	.bye2
.notf6	clr.b	lastf6
.notf62	;
.done	rts

loop1	;normal game loop	
	;
	move	clxdat2(pc),d0
	and	#2,d0
	move	d0,clxdat
	clr	clxdat2
	;
	;handle smart bomb...
	;
	clr.b	smarton
	chkkey	$40
	beq.s	.skip0
	move.b	lastsmart(pc),d0
	bne.s	.doinviso
	move	smarts(pc),d0
	beq.s	.doinviso
	;
	move	#$fff,smartcol
	move	#$111,smartsub
	subq	#1,smarts
	st	upsmarts
	st	smarton
	st	lastsmart
	bra.s	.doinviso
	;
.skip0	clr.b	lastsmart
	;
.doinviso	;handle inviso...
	;
	chkkey	$61
	beq.s	.noinviso
	;
	move.l	inviso(pc),d0
	beq.s	.noinviso
	;
	move.b	invisoon(pc),d0
	bne.s	.ison
	;
	not.b	invisoon
	lea	shiprgbs(pc),a0
	clr	6(a0)
	clr	10(a0)
	clr	14(a0)
	bsr	blowship
	;
.ison	sub.l	#$2000,inviso
	st.b	upinviso
	cmp	#8,inviso
	bcc.s	.doall
	move	#$c00,d1
	move	inviso+2(pc),d0
	and	#$8000,d0
	beq.s	.icol
	move	#$c60,d1
.icol	move	d1,scrnrgb+2
	bra.s	.doall
	;
.noinviso	move.b	invisoon(pc),d0
	beq.s	.doall
	clr	scrnrgb+2
	clr.b	invisoon
	lea	shiprgbs(pc),a0
	move	shippal+6(pc),6(a0)
	move	shippal+10(pc),10(a0)
	move	shippal+14(pc),14(a0)
	;
.doall	bsr	perloop
	bsr	showscan
	bsr	doglow1
	bsr	mountglow
	bsr	scanglow
	bsr	procaliens
	bsr	procbulls
	bsr	showstats
	;
	move	tokill(pc),d0
	beq.s	.end
	btst	#6,$bfe001
	bne.s	.skip
	;
.end	clr.l	loopcode
	;
.skip	rts

blinship	move.l	front1(pc),a0
	move	screenx(pc),x(a0)
	addq	#8,x(a0)
	move	shipy(pc),y(a0)
	move.l	shipblow(pc),a2
	bra	implode

blowship	move.l	shipblow(pc),a2
	move	screenx(pc),d2
	addq	#8,d2
	move	shipy(pc),d3
	bra	explode2

loop6	;player warping out baby!
	;
	move	#0,$0d8(a6)
	move	#$8,$096(a6)
	;
	bsr	doglow1
	subq	#1,playerwarp
	beq	.warp
	rts
	;
	;all warped out...
	;
	;OK, work out a warpx value which leaves ship X a multiple
	;of sixteen with no fraction!
	;
.warp	inton	0
	clearlist	bulls
	clearlist	lasers
	;
	moveq	#0,d0
	move	warpx(pc),d0
	bpl.s	.xwarp
	;
	;warp to a pattern!
	;
	move.l	warp.sfx(pc),$0d0(a6)
	move	#$8008,$096(a6)
	move	#1024,warpper
	;
	bsr	starsoff
	bsr	scancls2
	clr	mounty
	bsr	showback
	;
	clr	playerwarp
	move	#16,scant1
	clr	scant2
	move.l	#loop8,loopcode
	inton	6
	rts
	;
.xwarp	sub	screenx(pc),d0
	swap	d0
	add.l	d0,shipx
	move.l	shipx(pc),d1
	and.l	#$fffff,d1
	sub.l	d1,d0
	sub.l	d1,shipx
	and	#4095,shipx 
	;
	move.l	d0,-(a7)
	;
	lea	aliens(pc),a0
.loop	move.l	(a0),d0
	beq.s	.skip
	move.l	d0,a0
	move.l	(a7),d0
	sub.l	d0,x(a0)
	and	#$0ff0,x(a0)
	bsr	scanplot
	bra.s	.loop
.skip	addq	#4,a7
	bsr	showscan
	bsr	initmounts
	bsr	showback
	bsr	mountglow
	bsr	blinship
	clr	warpx
	move	#48,playerwarp
	move.l	#loop7,loopcode
	inton	6
.done	rts

loop7	;warping in!
	;
	bsr	doglow1
	subq	#1,playerwarp
	bne.s	.done
	;
	move.l	#loop1,loopcode
	inton	1
	makesafe	l3int2
	makedef	l3int1
	;
.done	rts

warpper	dc	428

loop8	;warp to pattern !...
	;
	bsr	doglow1
	;
	subq	#6,warpper
	move	warpper(pc),$0d6(a6)
	move	#64,$0d8(a6)
	;
	subq	#1,scant2
	bpl.s	.done
	subq	#1,scant1
	bne.s	.skip
	move	#$fff,smartcol
	move	#$111,smartsub
.skip	cmp	#-24,scant1
	beq.s	.exit
	move	scant1(pc),scant2
	bmi.s	.done
	addq	#1,playerwarp
	move	playerwarp(pc),d0
	and	#3,d0
	lsl	#2,d0
	lea	warps(pc),a0
	move.l	0(a0,d0),a2
	move	#176+4,d2
	move	#120,d3
	bra	explode2
.exit	clr.l	loopcode
.done	rts

loop2	;player about to die!
	;
	bsr	doglow1
	clr	$0d8(a6)
	clr.l	sxspeed
	clr.l	syspeed
	clr.l	xspeed
	lea	shiprgbs(pc),a0
	move	playerdie(pc),d0
	and	#4,d0
	beq.s	.skip
	move	shippal+6(pc),6(a0)
	move	shippal+10(pc),10(a0)
	move	shippal+14(pc),14(a0)
	bra.s	.skip2
.skip	move	#$fff,6(a0)
	move	#$fff,10(a0)
	move	#$fff,14(a0)
.skip2	subq	#1,playerdie
	bne	.skip3
	;
	;ship really dead!
	;
	move	#$20,$09a(a6)
	clearlist	bulls
	move	screenx(pc),d6
	addq	#7,d6
	move	shipy(pc),d7
	addq	#2,d7
	lea	diebulls(pc),a2
	move.l	blowup(pc),a3
.loop	additem2	bulls
	beq.s	.done
	move.l	(a3)+,4(a0)
	move	d6,8(a0)
	move.l	(a3)+,12(a0)
	move	d7,16(a0)
	move	#96,20(a0)
	move.l	a2,22(a0)
	bra.s	.loop
.done	bsr	frontcls
	move.l	#loop3,loopcode
	move	#96,playerdie
	inton	4
	bsr	shipoff
	;
	move.l	shipdie.sfx(pc),a2
	moveq	#127,d0
	moveq	#64,d1
	bsr	playsfx
	;
	move	#$20,$09c(a6)
	move	#$8020,$09a(a6)
	;
.skip3	rts

diebulls	dc	%0000001111000000
	dc	%0000001111000000
	dc	%0000001111000000

loop3	;player dying...
	;
	bsr	doglow1
	subq	#1,playerdie
	bne.s	.done
	not	playerdie
	clr.l	loopcode
	rts
.done	move	playerdie(pc),d0
	and	#3,d0
	bne.s	.done2
	move	diebulls+2(pc),d1
	move	diebulls(pc),d0
	beq.s	.skip
	moveq	#0,d1
.skip	move	d1,diebulls
	move	d1,diebulls+4
.done2	rts

fctime	dc	64

loop4	;flying characters...
	bsr	doglow1
	move	letters(pc),d0
	bne.s	.done
	move	fctime(pc),scant1
	move	getasc(pc),d0
	beq.s	.skip
	move	#4,scant1
.skip	move.l	#loop5,loopcode
.done	rts

l3int8	beginvb
	;
	bsr	doglow1
	;
	endvb

loop5	;
	bsr	doglow1
	subq	#1,scant1
	bne.s	.done
	clr.l	loopcode
	move	getasc(pc),d0
	beq.s	.skip
	inton	8
	rts
.skip	inton	0
.done	rts

player	bsr	showship
	bsr	moveship
	bsr	showback
	bsr	moveback
	bsr	dostars
	bsr	addlasers
	bra	dolasers

other	bsr	doaliens
	bsr	dobulls
	bra	dofrags

l3int0	beginvb
	endvb

l3int1	beginvb
	;
	bsr	dodb
	bsr	player
	bsr	other
	;
	endvb

l3int2	beginvb
	;
	bsr	player
	;
	endvb

l3int3	beginvb
	;
	bsr	dodb
	bsr	dolasers
	bsr	other
	;
	endvb

l3int4	beginvb
	;
	bsr	dodb
	bsr	dobulls
	;
.done	endvb

l3int5	beginvb
	;
	bsr	dodb
	bsr	dofchars
	bsr	doaliens
	bsr	animaliens
	;
	endvb

l3int6	beginvb
	;
	bsr	dodb
	bsr	dofrags
	;
	endvb

l3int7	beginvb
	;
	bsr	dodb
	bsr	doaliens
	bsr	animaliens
	bsr	dofrags
	;
	endvb
subs2

makeswaits	;d0=start y,d1=increment
	;
	add	#sly,d0
	lsl	#8,d0
	or	#1,d0
	lsl	#8,d1
	moveq	#6,d2
	lea	swait1(pc),a0
.loop	move	d0,(a0)
	add	d1,d0
	lea	swait2-swait1(a0),a0
	dbf	d2,.loop
	rts

dotitglow	add.l	#$8000,glow1
	move	glow1(pc),d0
	cmp	#66,d0
	bcs.s	.skip2
	sub	#66,d0
	move	d0,glow1
.skip2	move.l	glow(pc),a0
	move	#65,d1
	sub	d0,d1
	add	d0,d0
	move	0(a0,d0),titrgbs+34
	move.l	glow(pc),a0
	add	d1,d1
	move	0(a0,d1),titrgbs+2
	rts

l3intt1	beginvb
	;
	bsr	dotitglow
	;
	endvb

mess1	dc.b	'INITIAL TESTS INDICATE...',0
mess2	dc.b	'THAT YOU ARE ABOUT TO EXPERIENCE...',0
mess3	dc.b	'A SHAREWARE GAME BY MARK SIBLY.',0
	even

iprint	;a0=message, a1=dest.
	;
.loop	moveq	#0,d0
	move.b	(a0)+,d0
	beq.s	.done
	lsl	#4,d0
	move.l	font(pc),a2
	add	d0,a2
	moveq	#6,d1
	move.b	#-1,160*5(a1)
	move.b	#-1,160*6(a1)
	bsr	vwait1
.loop2	move.b	(a2),(a1)
	addq	#2,a2
	lea	160(a1),a1
	dbf	d1,.loop2
	lea	-160*7+1(a1),a1
	bra.s	.loop
.done	rts

vwait5	moveq	#8,d0
.loop	bsr	avwait
	dbf	d0,.loop
	rts

vwait4	move	#1999,d0
	bra	vwaitl

vwait3	move	#249,d0
	bra.s	vwaitl

vwait2	moveq	#74,d0
	;
vwaitl	btst	#6,$bfe001
	beq.s	.skip
	bsr	avwait
	dbf	d0,vwaitl
.skip	rts

vwait1	btst	#6,$bfe001
	bne.s	avwait
	rts
avwait	clr	vflag
.loop	tst	vflag
	beq.s	.loop
	rts

rndcrap	move.l	front1(pc),a0
	move.l	#40*4*(224+57)/2,d7
.loop	bsr	rnd1
	move	d0,(a0)+
	subq.l	#1,d7
	bne.s	.loop
	rts

showkeys	moveq	#0,d0
	moveq	#5,d1
	moveq	#0,d2
	bsr	showkey
	;
	moveq	#33,d0
	moveq	#5,d1
	moveq	#1,d2
	bsr	showkey
	;
	moveq	#0,d0
	moveq	#39,d1
	moveq	#6,d2
	bsr	showkey
	;
	moveq	#33,d0
	moveq	#39,d1
	moveq	#7,d2
	bsr	showkey
	;
showkeys2	moveq	#0,d0
	moveq	#22,d1
	moveq	#2,d2
	move	cmode(pc),d3
	bne.s	.skip
	moveq	#3,d2
.skip	bsr	showkey
	;
	moveq	#33,d0
	moveq	#22,d1
	moveq	#4,d2
	move	cmode-playerdat+playerdat2(pc),d3
	bne.s	showkey
	moveq	#5,d2
	;
showkey	;d0=x,d1=y,d2=key
	;
	mulu	#120,d1
	move.l	scan1(pc),a1
	add.l	d1,a1
	add	d0,a1
	move.l	keys(pc),a0
	mulu	#36*7,d2
	add	d2,a0
	;
	moveq	#12*3-1,d0	;hite
.loop	moveq	#6,d1
.loop2	move.b	(a0)+,(a1)+
	dbf	d1,.loop2
	lea	33(a1),a1
	dbf	d0,.loop
	rts

introscroll	bsr	showmess
	move.l	messx(pc),d0
	;
	and.l	#$7ffff,d0
	bne.s	.skip
	;
	;next char!
	;
	move.l	scan3(pc),a0
	add	#14*50-1,a0
	move	messx(pc),d0
	asr	#3,d0
	add	d0,a0
	move.l	messageat(pc),a1
	moveq	#0,d0
	move.b	(a1)+,d0	;char to print!
	bne.s	.ok
	move.l	message(pc),a1
	move.b	(a1)+,d0
.ok	;d0=char, a0=dest
	cmp.b	#97,d0
	bcs.s	.ok2
	and.b	#$ff-$20,d0
.ok2	move.l	a1,messageat
	move.l	font(pc),a1
	lsl	#4,d0
	add	d0,a1
	moveq	#6,d0
.loop	move.b	(a1),(a0)
	move.b	(a1),25(a0)
	addq	#2,a1
	lea	100(a0),a0
	dbf	d0,.loop
	;
.skip	add.l	#$10000,messx
	cmp	#26*8,messx
	bcs.s	.done
	move	#8,messx
.done	rts

initscmess	move.l	message(pc),messageat
	move	#8,messx
	bsr	showmess
	bra	initgscan

intro	bsr	displayoff
	bsr	initscmess
	;
iloop	bsr	displayoff
	move	#-1,introon
	bsr	inittitcop
	lea	rndpal(pc),a0
	lea	titrgbs(pc),a1
	bsr	putpal
	bsr	rndcrap
	bsr	displayon
	bsr	titcopon
	inton	0
	move	#$20,$09c(a6)
	move	#$8020,$09a(a6)
	bsr	rndcrap
	bsr	rndcrap
	bsr	frontcls
	lea	titpal(pc),a0
	lea	titrgbs(pc),a1
	bsr	putpal
	lea	mess1(pc),a0
	move.l	front1(pc),a1
	lea	160*64+8(a1),a1
	bsr	iprint
	bsr	vwait2
	lea	mess2(pc),a0
	move.l	front1(pc),a1
	lea	160*80+3(a1),a1
	bsr	iprint
	bsr	vwait2
	bsr	showtit
	bsr	vwait2
	lea	mess3(pc),a0
	move.l	front1(pc),a1
	lea	160*192+5(a1),a1
	bsr	iprint
	bsr	vwait2
	inton	t1
	bsr	vwait3
	;
	bsr	inititext
	;
	lea	sw(pc),a0
	bsr	printpage
	bsr	vwait4
	;
.aliens	bsr	frontcls
	bsr	initaliens
	inton	7
	makesafe	l3int0
	makedef	l3int7
	;
	lea	xys(pc),a4
	moveq	#0,d7
	;
.aloop	addq	#1,d7
	lea	objects(pc),a3
	;
.aloop2	move.l	(a3),d0
	beq	.adone
	move.l	d0,a3
	cmp.l	12(a3),d7
	bne.s	.aloop2
	lea	12+24(a3),a3
	;
.aloop3	move.l	(a3)+,d0
	beq.s	.aloop
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	move.l	(a3)+,-(a7)
	;
	bsr	beginadd
	move	(a4)+,x(a0)
	move	(a4)+,y(a0)
	move.l	(a7)+,a2
	move.l	a2,a3
	add.l	10(a2),a3
	move	#14,d0
	sub	2(a3),d0
	add	d0,y(a0)
	bsr	newanim
	move.l	(a7)+,a2
	bsr	implode
	bsr	endadd
	;
	moveq	#6,d0
.vv	bsr	avwait
	dbf	d0,.vv
	;
	move.l	(a7)+,a3
	addq	#8,a3
	bra.s	.aloop3
	;
.adone	cmp	#128,d7
	bcs	.aloop
	;
	;add text...
	;
.await	move.l	frags(pc),d0
	bne.s	.await
	bsr	avwait
	bsr	avwait
	;
	lea	xys(pc),a4
	moveq	#0,d7
	;
.tloop	addq	#1,d7
	lea	objects(pc),a3
	;
.tloop2	move.l	(a3),d0
	beq	.tdone
	move.l	d0,a3
	cmp.l	12(a3),d7
	bne.s	.tloop2
	lea	12+24(a3),a3
	;
.tloop3	move.l	(a3)+,d0
	beq.s	.tloop
	move.l	a3,-(a7)
	;
	addq	#4,a3
	move.l	(a3),a3	;text!
	moveq	#0,d2
.tloop4	addq	#1,d2
	tst.b	(a3)+
	bne.s	.tloop4	;d0=len
	sub	d2,a3
	lsr	#1,d2
	move	(a4)+,d0
	lsr	#3,d0
	sub	d2,d0	;x
	addq	#1,d0 
	move	(a4)+,d1
	add	#16,d1
	mulu	#gamemod,d1
	move.l	front1(pc),a0
	move.l	front2(pc),a1
	add.l	d1,a0
	add.l	d1,a1
	add	d0,a0
	add	d0,a1
	;
.tloop5	moveq	#0,d0
	move.b	(a3)+,d0
	beq.s	.tpdone
	lsl	#4,d0
	move.l	font(pc),a2
	add	d0,a2
	addq	#1,a2
	moveq	#4,d0
.tloop6	move.b	(a2),d1
	move.b	d1,(a0)
	move.b	d1,(a1)
	addq	#2,a2
	lea	gamemod(a0),a0
	lea	gamemod(a1),a1
	dbf	d0,.tloop6
	lea	-gamemod*5+1(a0),a0
	lea	-gamemod*5+1(a1),a1
	bra.s	.tloop5
	;
.tpdone	move.l	(a7)+,a3
	addq	#8,a3
	bra.s	.tloop3
	;
.tdone	cmp	#128,d7
	bcs	.tloop
	;
	bsr	vwait4
	;
ihiscores	inton	0
	bsr	frontcls
	bsr	initaliens
	clr	letters
	inton	5
	makesafe	l3int0
	makedef	l3int5
	move	#$20,$09c(a6)
	move	#$8020,$09a(a6)
	;
	move	#44,fcharoff
	lea	oh(pc),a0
	bsr	printit
.hjimi	move.l	bulls(pc),d0
	bne.s	.hjimi
	bsr	avwait
	bsr	avwait
	clr	fcharoff
	;
	moveq	#numhis-1,d0
	lea	hiscores(pc),a0
.hloop	move.l	(a0)+,d1
	lea	hsbufff(pc),a1
	move.b	#48,-(a1)
	moveq	#5,d2
	;
.hloop2	move	d1,d3
	and	#15,d3
	add	#48,d3
	move.b	d3,-(a1)
	lsr.l	#4,d1
	dbf	d2,.hloop2
	;
.hlz	cmp.b	#48,(a1)
	bne.s	.hlz2
	move.b	#32,(a1)+
	bra.s	.hlz
.hlz2	tst.b	(a1)
	bne.s	.hlz3
	move.b	#32,-(a1)
.hlz3	;
	lea	hsbuff(pc),a1
	move.b	#numhis-1+7,(a1)
	sub.b	d0,(a1)+
	;
	moveq	#hichars-1,d1
.copl	move.b	(a0)+,(a1)+
	dbf	d1,.copl
	;
	movem.l	a0/d0,-(a7)
	lea	hsbuff(pc),a0
	bsr	printit
	bsr	vwait5
	movem.l	(a7)+,a0/d0
	dbf	d0,.hloop
	;
.hdone	move.l	bulls(pc),d0
	bne.s	.hdone
	bsr	avwait
	bsr	avwait
	;
	bsr	vwait4
	bra	iloop

inthis	cmp	#1,introon
	beq	ihiscores
	bsr	inititext
	bra	ihiscores

oh	dc.b	4,'OBLIVIOUS HEROES',0

hsbuff	dcb.b	25,32
hsbufff	dc.b	0
	even

xys	dc	168,20,168-64,20,168+64,20
	dc	168,50,168-96,50,168+96,50
	dc	168-112,80,168-40,80,168+40,80,168+112,80
	dc	168-128,110,168-48,110,168+48,110,168+128,110
	dc	168-128,140,168-48,140,168+48,140,168+128,140
	dc	168-80,170,168,170,168+80,170
	dc	168-64,200,168,200,168+64,200

inititext	bsr	initworks
	move	#1,introon
	bsr	inittext
	bsr	scancls4
	clr	mounty
	clr.l	xspeed
	lea	keypal(pc),a0
	lea	scanrgbs(pc),a1
	bsr	putpal
	clr	kludge-scanpal+scanrgbs+6
	clr	kludge-scanpal+scanrgbs+10
	bsr	showkeys
	moveq	#14,d0
	moveq	#2,d1
	bsr	makeswaits
	bsr	spritesoff2
	bsr	starson
	bsr	displayon
	move	#$20,$09c(a6)
	move	#$8020,$09a(a6)
	rts

printpage	bsr	printit
	bsr	vwait5
	tst.b	(a0)
	bpl.s	printpage
.wait	move.l	bulls(pc),d0
	bne.s	.wait
	bsr	avwait
	bra	avwait

sw	dc.b	 5,'THIS GAME IS SHAREWARE. THE AUTHOR',0
	dc.b	 6,"(THAT'S ME!) HAS PUT A FAIR AMOUNT OF",0
	dc.b	 7,'OF TIME AND EFFORT INTO THIS GAME,',0
	dc.b	 8,'AND WOULD GREATLY APPRECIATE A',0
	dc.b	 9,'CONTRIBUTION OF SOME KIND (PREFERABLY',0
	dc.b	10,'MONETARY) IF YOU THINK HIS EFFORTS',0
	dc.b	11,'HAVE PROVED WORTHY. WHILE THIS IS IN',0
	dc.b	12,'NO WAY COMPULSORY, DOING SO WILL',0
	dc.b	13,'GREATLY IMPROVE THE CHANCES OF FUTURE',0
	dc.b	14,'SHAREWARE RELEASES, AND FURTHER THE',0
	dc.b	15,'CAUSE OF A FREE AND JUST WORLD IN',0
	dc.b	16,'GENERAL. IN THE MEAN TIME - ENJOY!',0
	dc.b	18,'DONATIONS TO: MARK SIBLY,   ',0
	dc.b	19,'              21 SEFTON AVE,',0
	dc.b	20,'              GREY LYNN,    ',0
	dc.b	21,'              AUCKLAND 5,   ',0
	dc.b	22,'              NEW ZEALAND.  ',0
	dc.b	-1
	even

showtit	move.l	oblivion(pc),a0
	move.l	front1(pc),a1
	moveq	#-1,d2
	add.l	#108*160,a1
	moveq	#59,d0	;hite
.loop	move	#10*4-1,d1
.loop1	move.l	d2,(a1)+
	dbf	d1,.loop1
	lea	-160(a1),a1
	bsr	vwait1
	move	#10*4-1,d1
.loop2	move.l	(a0)+,(a1)+
	dbf	d1,.loop2
	dbf	d0,.loop
	rts

subs

gospace	st	inspace
	move	#$f00,smartcol
	move	#$100,smartsub
	bra	calcscm

updatesfx	;call every vertb (or longer...)
	;
	move.l	audio(pc),a0
	move.l	a6,a1
	moveq	#1,d0	;dma bits
	move	#$80,d3	;int bits
	moveq	#2,d1
.loop	move.l	sfxreq(a0),d2
	beq.s	.next
	tst.b	status(a0)
	bpl.s	.skip2
	;
	clr.l	sfxreq(a0)
	move.l	d2,a2
	move	(a2)+,$0a6(a1)
	move	(a2)+,$0a4(a1)
	move.l	a2,$0a0(a1)
	move	vol(a0),$0a8(a1)
	move.b	#2,status(a0)
	and	#$7fff,d3
	or	#$8000,d0
	move	d0,$096(a6)
	move	d3,$09c(a6)
	or	#$8000,d3
	move	d3,$09a(a6)
	bra.s	.next
	;
.skip2	bne.s	.skip3
	subq.b	#1,status(a0)
	bra.s	.next
.skip3	;
	;last not finished yet...hurry up!
	;
	move	#0,$0a8(a1)
	and	#$f,d0
	and	#$7fff,d3
	move	d0,$096(a6)
	move	d3,$09a(a6)
	move	d3,$09c(a6)
	move.b	#-1,status(a0)
	;
.next	add	d0,d0
	add	d3,d3
	lea	16(a1),a1
	addq	#audiosize,a0
	dbf	d1,.loop
	rts


playsfx	;a2=sfx to play, d0=priority
	;
	move.l	audio(pc),a3
	;
.loop	cmp.b	pri(a3),d0
	bge.s	.ok
	addq	#audiosize,a3
	cmp.l	#audiof.ds,a3
	bcs.s	.loop
	rts
.ok	move.b	d0,pri(a3)
	move	d1,vol(a3)
	move.l	a2,sfxreq(a3)
	rts

l4int1	;audio interupt.
	;
	movem.l	d0-d7/a0-a5,-(a7)
	;
	move	$01e(a6),d0
	and	#$780,d0
	move	d0,$09c(a6)
	lsr	#7,d0		;int bits to check
	move	#$80,d3
	moveq	#1,d1		;dma bit to clear
	move.l	audio(pc),a0	;start of audio status
	move.l	a6,a1		;start of chip
	moveq	#2,d2		;how many voices
	;
.loop	lsr	#1,d0
	bcc.s	.skip		;no int from this channel!
	subq.b	#1,status(a0)
	bne.s	.skip		;2 ints = sfx done!
	clr.b	pri(a0)
	move	#0,$0a8(a1)		;vol off
	move	d1,$096(a6)		;dma off
	move	d3,$09a(a6)		;no interupts from this!
	move	d3,$09c(a6)
	;
.skip	add	d1,d1
	add	d3,d3
	lea	16(a1),a1
	addq	#audiosize,a0
	dbf	d2,.loop
	;
	movem.l	(a7)+,d0-d7/a0-a5
	rte

susspattern	;suss out starting pattern
	;
	clr	spattern
	cmp.b	#':',(a0)+
	bne.s	.skip
	moveq	#0,d0
	move.b	(a0)+,d0	;hi
	sub	#48,d0
	mulu	#10,d0
	moveq	#0,d1
	move.b	(a0)+,d1
	sub	#48,d1
	add	d1,d0
	subq	#1,d0
	move	d0,spattern
.skip	rts

initworks	bsr	displayoff
	bsr	initgamecop
	bsr	initdisp
	clr	fcharoff
	bra	scancls

initplayer	move	#-1,playerdie
	move	spattern(pc),pattern
	clr	tokill
	clr.l	score
	move	#3,ships
	move	#3,smarts
	move.l	#24<<16,inviso
	move.l	scoreten(pc),scoremore
	move.l	#-1,upall
	bsr	showstats
	bsr	hidescore
	bra	pergame

swapem	lsr	#1,d0
	beq.s	.done
	subq	#1,d0
.loop	move	(a0),d1
	move	(a1),(a0)+
	move	d1,(a1)+
	dbf	d0,.loop
.done	rts

swapplayer	;return ne if 1 player
	move.l	scan1(pc),scanu
	move	playerup(pc),d0
	bmi.s	.done
	moveq	#1,d1
	sub	d0,d1
	move	d1,playerup
	beq.s	.skip
	add.l	#33,scanu
.skip	lea	playerdat(pc),a0
	lea	playerdat2(pc),a1
	moveq	#playerdatf-playerdat,d0
	bsr	swapem
	lea	objects(pc),a2
.loop	move.l	(a2),d0
	beq.s	.done
	move.l	d0,a2
	move.l	8(a2),a0
	move.l	12+8(a2),a1
	move.l	12+4(a2),d0
	bsr	swapem
	bra.s	.loop
.done	rts

dosname	dc.b	'dos.library',0
	even

dirname	dc.b	'aliens',0
	even

filename	dc.b	'aliens/'
filename2	ds.b	33
	even

freealiens	move.l	4.w,a6
	move.l	objects(pc),d2
	beq.s	.done
.loop	move.l	d2,a2
	move.l	(a2),d2
	move.l	a2,a1
	move.l	4(a2),d0
	jsr	-210(a6)
	tst.l	d2
	bne.s	.loop
.done	clr.l	objects
	rts

numaliens	dc	0

loadaliens	lea	dosname(pc),a1
	move.l	4.w,a6
	move.l	a6,a4
	jsr	-408(a6)	;oldopenlib
	move.l	d0,a6
	move.l	#dirname,d1
	moveq	#-2,d2
	jsr	-84(a6)	;lock
	move.l	d0,d7
	;
	move.l	d7,d1
	move.l	#info,d2
	jsr	-102(a6)	;examine
	lea	objects(pc),a5
	clr	numaliens
	;
.loop	move.l	d7,d1
	move.l	#info,d2
	jsr	-108(a6)	;exnext
	tst.l	d0
	beq	.done
	;
	addq	#1,numaliens
	;
	move.l	#info+8,a0
	lea	filename2(pc),a1
.loop2	move.b	(a0)+,(a1)+
	bne.s	.loop2
	;
	move.l	#filename,d1
	move.l	#1005,d2
	jsr	-30(a6)	;open
	move.l	d0,d6
	;
	move.l	d6,d1
	move.l	#read,d2
	moveq	#32+72,d3
	jsr	-42(a6)	;read
	move.l	read+28,d5
	lsl.l	#2,d5	;bytes in executable
	;
	move.l	d5,d0
	add.l	read+32+4,d0
	add.l	#12,d0
	move.l	d0,d4
	moveq	#2,d1
	exg.l	a4,a6
	jsr	-198(a6)
	exg.l	a4,a6
	move.l	d0,a0
	;
	lea	12(a0),a1
	move.l	a0,(a5)
	move.l	a0,a5
	addq	#4,a0
	move.l	d4,(a0)+
	lea	0(a1,d5.l),a2
	move.l	a2,(a0)+
	move.l	#read+32,a2
	move.l	(a2)+,(a0)+
	move.l	(a2)+,(a0)+
	moveq	#15,d0
.loop3	move.l	(a2)+,d1
	beq.s	.skip
	add.l	a1,d1
.skip	move.l	d1,(a0)+
	dbf	d0,.loop3
	;
	move.l	d6,d1
	move.l	a0,d2
	move.l	d5,d3
	sub.l	#72,d3
	jsr	-42(a6)
	;
	move.l	d6,d1
	jsr	-36(a6)
	bra	.loop
	;
.done	clr.l	(a5)
	move.l	d7,d1
	jmp	-90(a6)

initgame	bsr	scancls3
	bsr	starson
	bsr	showscan
	move.l	#-1,upall
	move.l	#loop1,loopcode
	inton	1
	makesafe	l3int2
	makedef	l3int1
	bra	dodb

inittext	bsr	frontcls
	bsr	scancls2
	bsr	starsoff
	clr.l	xspeed
	clr	mounty
	bsr	showback
	bsr	initaliens
	clr	letters
	move	#96,fctime
	inton	5
	move.l	#loop4,loopcode
	makesafe	l3int0
	makedef	l3int5
	bsr	shipoff
	bra	dodb

patover1	dc.b	13,'ATTACK WAVE '
patover2	dc.b	' 1 COMPLETED',0
	even

make2digs	move	d0,d2
	divu	#10,d0
	move	d0,d1
	mulu	#10,d1
	bne.s	.skip
	moveq	#-49,d0
.skip	add	#48,d0
	move.b	d0,(a0)+
	sub	d1,d2
	add	#48,d2
	move.b	d2,(a0)+
	rts

patover	bsr	inittext
	lea	patover2(pc),a0
	moveq	#0,d0
	move	pattern(pc),d0
	bsr	make2digs
	;
	lea	patover1(pc),a0
	bsr	printit
	;
	st	bomode+1
	bsr	perpattern
	;
	bra	doloops

dobonus	;d0=bonus val, d1=multiplier
	;a0=name, a1=anim.
	;
	move	#192,fctime
	move.l	a1,boanm
	move	d0,-(a7)	;how much
	move	d1,-(a7)	;how many
	;
	lea	botext(pc),a2
	;
.loop	move.b	(a0)+,(a2)+
	bne.s	.loop
	move.b	#32,-1(a2)
	lea	botext2(pc),a0
.loop2	move.b	(a0)+,(a2)+
	bne.s	.loop2
	subq	#1,a2
	;
	;now to print d0, bonus value...
	;
	moveq	#0,d2	;no zero printed.
	moveq	#3,d4
.loop3	rol	#4,d0
	move	d0,d3
	and	#15,d3
	bne.s	.skip
	tst	d2
	beq.s	.skip2
.skip	add	#48,d3
	move.b	d3,(a2)+
	moveq	#-1,d2
.skip2	dbf	d4,.loop3
	move.b	#48,(a2)+
	clr.b	(a2)
	lea	botext-1(pc),a0
	addq.b	#3,(a0)
	bsr	printit
	;
	move	#176,d6
	move	(a7),d0
	lsl	#3,d0
	sub	d0,d6	;X of first
	;
	moveq	#0,d7
	move.b	botext-1(pc),d7
	lsl	#3,d7
	add	#10,d7
	;
.loop4	subq	#1,(a7)
	bmi.s	.loopd
	bsr	beginadd
	move	d6,x(a0)
	move	d7,y(a0)
	add	#16,d6
	clr	facing(a0)
	move.l	boanm(pc),a2
	bsr	newanim
	bsr	endadd
	move	2(a7),d0
	bsr	addscore
	bra	.loop4
	;
.loopd	addq	#4,a7
	bra	showstats

boanm	dc.l	0

	dc.b	13
botext	ds.b	80
botext2	dc.b	'BONUS X ',0
	even
bomode	dc	0

warpover1	dc.b	13,'...WARP TO WAVE '
warpover2	dc.b	'01!',0
	even

warpover	move	#$8,$096(a6)
	move	#0,$0d8(a6)
	bsr	inittext
	moveq	#0,d0
	move	warpx(pc),d0
	neg	d0
	subq	#1,d0
	move	d0,pattern
	addq	#1,d0
	lea	warpover2(pc),a0
	bsr	make2digs
	;
	lea	warpover1(pc),a0
	bsr	printit
	;
	move	#-1,bomode
	bsr	perpattern
	;
	bsr	doloops
	bra	initthrust

gameover1	dc.b	15,'GAME OVER',0
gameover2	dc.b	'PLAYER '
gameover3	dc.b	'1',0
	even

gameover	bsr	inittext
	move	playerup(pc),d0
	bmi.s	.skip
	add	#49,d0
	move.b	d0,gameover3
	move.b	#32,gameover2-1
	bra.s	.skip2
.skip	clr.b	gameover2-1
.skip2	lea	gameover1(pc),a0
	bsr	printit
	bra	doloops

printit	moveq	#0,d1
	move.b	(a0)+,d1
	lsl	#3,d1
	moveq	#0,d2
.loop	addq	#1,d2
	tst.b	(a0)+
	bne.s	.loop
	sub	d2,a0
	lsl	#2,d2
	move	#(22<<3)+4,d0
	sub	d2,d0	first X
	;
.loop2	moveq	#0,d2
	move.b	(a0)+,d2
	beq.s	.done
	bmi.s	.loop2
	movem.l	d0-d1/a0,-(a7)
	bsr	addfchar
	movem.l	(a7)+,d0-d1/a0
	addq	#8,d0
	bra.s	.loop2
	;
.done	rts

fcharoff	dc	0

dofchars	;do flying characters...
	;
	move.l	dbat(pc),a2
	move.l	16(a2),a5
	move	#(7<<6)+2,d7
	bwait
	move	#$100,con0(a6)
	move.l	#$ff000000,fwm(a6)
	move	#-2,amod(a6)
	move	#44*3-4,cmod(a6)
	move	#44*3-4,dmod(a6)
.loop	move.l	(a5)+,d0
	beq.s	funqdone
	bwait
	move.l	d0,dpth(a6)
	move	d7,size(a6)
	bra.s	.loop
	;
funqdone	move.l	16(a2),a5
	lea	bulls(pc),a0
	move	#4095,d4
	move	#336,d5
	move	#240,d6
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a1
	move.l	d0,a0
	;
	subq	#1,20(a0)
	bpl.s	.dong
	cmp	#-3,20(a0)
	bgt.s	.leave
	killitem	bulls
	bra.s	.loop
	;
.dong	bne.s	.skip
	subq	#1,letters
	;
.skip	move.l	4(a0),d0
	add.l	d0,8(a0)
	and	d4,8(a0)
	move.l	12(a0),d1
	add.l	d1,16(a0)
	;
.leave	move	8(a0),d0
	cmp	d5,d0
	bcc.s	.loop
	move	16(a0),d1
	cmp	d6,d1
	bcc.s	.loop
	;
	;OK to draw character...
	;
	move.l	(a2),a3
	mulu	#gamemod,d1
	lea	44(a3,d1.l),a3
	move	d0,d1
	asr	#3,d0
	add	d0,a3	;dest
	;
	sub	fcharoff(pc),a3
	;
	ror	#4,d1
	and	#$f000,d1
	or	#$bfa,d1	;con 0
	tst	20(a0)
	bmi.s	.there
	move.l	a3,(a5)+
.there	bwait
	move	d1,con0(a6)
	move.l	22(a0),apth(a6)
	move.l	a3,cpth(a6)
	move.l	a3,dpth(a6)
	move	d7,size(a6)
	bra	.loop
.done	clr.l	(a5)
	rts

addfchar2	;d0=char x,d1=char y,d2=char
	;
	lsl	#3,d0
	lsl	#3,d1
	;
addfchar	;add a flying character.
	;
	;d0=pixel x,d1=pixel y,d2=char
	;
	cmp	#32,d2
	bne.s	.jimi
	rts
.jimi	addq	#1,letters
	moveq	#0,d6
	move	d0,d6
	swap	d6
	moveq	#0,d7
	move	d1,d7
	swap	d7
	;
	move	introon(pc),d1
	beq.s	.nointro
	;
	move.l	#(((22<<3)+4)<<16),d1	;x centre
	sub.l	d6,d1
	asr.l	#4,d1
	neg.l	d1
	move.l	d1,d4		;xspeed
	lsl.l	#5,d1
	sub.l	d1,d6		;start x
	;
	move.l	#(((4<<3)+4)<<16),d1
	sub.l	d7,d1
	asr.l	#4,d1
	move.l	d1,d5		;y speed
	lsl.l	#5,d1
	sub.l	d1,d7		;start y
	bra.s	.intro2
	;
.nointro	move.l	#(((22<<3)+4)<<16),d1	;x centre
	sub.l	d6,d1
	asr.l	#1,d1
	move.l	d1,d4		;xspeed
	lsl.l	#5,d1
	sub.l	d1,d6		;start x
	;
	move.l	#(((15<<3)+4)<<16),d1	;y centre
	sub.l	d7,d1
	asr.l	#1,d1
	move.l	d1,d5		;y speed
	lsl.l	#5,d1
	sub.l	d1,d7		;start y
	;
.intro2	move.l	font(pc),a2
	lsl	#4,d2
	add	d2,a2
	;
	usesafe
	additem2	bulls
	beq.s	.out
	move.l	d4,4(a0)
	move.l	d6,8(a0)
	move.l	d5,12(a0)
	move.l	d7,16(a0)
	move	#32,20(a0)
	move.l	a2,22(a0)
.out	usedef
	rts

starson	move.l	starsp(pc),d0
	move	d0,sprites2+6
	swap	d0
	move	d0,sprites2+2
	rts

starsoff	move.l	#zero,d0
	move	d0,sprites2+6
	swap	d0
	move	d0,sprites2+2
	rts

spritesoff2	lea	sprites4(pc),a0
	moveq	#3,d2
	bra.s	spritesoffs
	;
spritesoff	lea	sprites8(pc),a0
	moveq	#7,d2
spritesoffs	move.l	#zero,d0
	move	d0,d1	;low
	swap	d0
.loop	move	d1,6(a0)
	move	d0,2(a0)
	addq	#8,a0
	dbf	d2,.loop
	bra	shipoff

spriteson	move.l	starsp(pc),d0
	move	d0,sprites2+6
	swap	d0
	move	d0,sprites2+2
	;
	move.l	scansprite(pc),d0
	move	d0,sprites3+6
	swap	d0
	move	d0,sprites3+2
	;
	move.l	shipsprite(pc),d0
	move	d0,sprites4+6
	swap	d0
	move	d0,sprites4+2
	;
	move.l	#edgesprite1,d0
	move	d0,sprites5+6
	swap	d0
	move	d0,sprites5+2
	;
	move.l	#edgesprite2,d0
	move	d0,sprites6+6
	swap	d0
	move	d0,sprites6+2
	;
	rts

putpal	;a0=src,a1=dest
	;
	moveq	#31,d0
.loop0	move.l	#copnop,(a1)+
	dbf	d0,.loop0
	lea	-128(a1),a1
.loop	tst	(a0)
	bmi.s	.done
	move.l	(a0)+,(a1)+
	bra.s	.loop
.done	rts

doloops	move	#$20,$09c(a6)
	clr	vflag
	move	#$8020,$09a(a6)
.loop	move	vflag(pc),d0
	beq.s	.loop
	clr	vflag
	move.l	loopcode(pc),d0
	beq.s	.done
	move.l	d0,a2
	jsr	(a2)
	bra.s	.loop
.done	move	#$20,$09a(a6)
	rts

initmounts	prepblit1
	moveq	#21,d7
	move	shipx(pc),d6
	lsr	#4,d6
.loop0	move	d7,d0
	add	d6,d0
	and	#255,d0
	move	d7,d1
	bsr	putmount
	move	d7,d0
	add	d6,d0
	and	#255,d0
	move	d7,d1
	add	#22,d1
	bsr	putmount
	dbf	d7,.loop0
	move.l	#352<<16,backx
	rts

initaliens	;clear all aliens...
	;
	clearlist	aliens
	clearlist	frags
	clearlist	bulls
	clearlist	lasers
	;
flushqs	clr.l	aliensq.ds
	clr.l	aliensq2.ds
	clr.l	fragsq.ds
	clr.l	fragsq2.ds
	clr.l	bullsq.ds
	clr.l	bullsq2.ds
	clr.l	lasersq.ds
	clr.l	lasersq2.ds
	rts

player1	dc.b	15,'PLAYER '
player2	dc.b	'1',0
	even

calcscm	tst	inspace
	beq.s	.skip
	;
	move	#$802,kludge2+6
	move	#$802,kludge2+10
	move	#$802,kludge3+6
	rts
	;
.skip	move	#$028,kludge2+6
	move	#$802,kludge2+10
	move	#$876,kludge3+6
	rts

patmess	dc.l	0

dopatmess	move.l	patmess(pc),d0
	beq.s	.done
	;
	bsr	frontcls
	bsr	inittext
	move	#128,fctime
	move.l	patmess(pc),a0
	bsr	printit
	bsr	displayon
	bsr	doloops
.done	rts

initship	lea	gamepal(pc),a0
	lea	gamergbs(pc),a1
	bsr	putpal
	;
	move	pattern(pc),d0
	divu	#5,d0
	swap	d0
	tst	d0
	beq.s	.usecol
	move	pattern(pc),d0
	mulu	#88,d0
	;
	divu	#132,d0
	swap	d0
	move.l	glow(pc),a0
	move	0(a0,d0),d0
	;
.usecol	move	d0,bdc1+2
	move	d0,bdc2+2
	move	d0,kludge-2
	move	d0,kludgez-2
	move	d0,kludge-2-scanpal+scanrgbs
	;
	bsr	calcscm
	;
	move	playerdie(pc),d0
	beq.s	.skip
	clr	playerdie
	subq	#1,ships
	;
	move	playerup(pc),d0
	bmi.s	.skip
	add	#49,d0
	move.b	d0,player2
	;
	bsr	inittext
	lea	player1(pc),a0
	bsr	printit
	bsr	displayon
	bsr	doloops
	bsr	frontcls
	;
.skip	clr.l	shipx
	move.l	#(288+112)<<16,shipy
	clr	playerwarp
	clr	warpx
	clr	smartcol
	clr.l	xspeed
	clr.l	sxspeed
	clr.l	syspeed
	clr.l	shipdir
	clr.l	shipframe
	clr	thrustframe
	move.l	#restx<<16,screenx
	move.l	#128<<16,screeny
	move.l	#(maxy2-224)<<16,mounty
	rts

makepc	add	#128,d0
	add	#sly+56,d1
	;
	moveq	#0,d3
	;
	move	d1,d2
	lsl	#8,d2
	lsr	#1,d0
	bcc.s	.skip
	moveq	#1,d3
.skip	move.b	d0,d2
	btst	#8,d1
	beq.s	.skip2
	bset	#2,d3
.skip2	addq	#1,d1
	btst	#8,d1
	beq.s	.skip3
	bset	#1,d3
.skip3	lsl	#8,d1
	or	d1,d3
	rts

inittitcop	move.l	front1(pc),d0
	lea	titbps(pc),a0
	moveq	#3,d1
.loop	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	#40,d0
	addq	#8,a0
	dbf	d1,.loop
	rts

initgamecop	move.l	scan1(pc),d0
	subq.l	#2,d0
	lea	scanfront(pc),a0
	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	#40,d0
	move	d0,8+6(a0)
	swap	d0
	move	d0,8+2(a0)
	swap	d0
	add.l	#40,d0
	move	d0,16+6(a0)
	swap	d0
	move	d0,16+2(a0)
	;
	move.l	scan2(pc),d0
	sub.l	#10,d0
	lea	scanback(pc),a0
	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	#48,d0
	move	d0,8+6(a0)
	swap	d0
	move	d0,8+2(a0)
	;
	rts

initgscan	move.l	scan3(pc),a0
	moveq	#0,d0
	move	#50*28/4-1,d1
.loop	move.l	d0,(a0)+
	dbf	d1,.loop
	rts

showmess	;at messx
	;
	move.l	scan3(pc),a0
	move	messx(pc),d0
	subq	#1,d0
	move	d0,d1
	asr	#3,d0
	lea	-8(a0,d0),a0
	not	d1
	and	#15,d1
	lsl	#4,d1
	move.l	a0,d0
	lea	backtext(pc),a0
	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	move	d0,8+6(a0)
	swap	d0
	move	d0,8+2(a0)
	move	d1,-(a0)
	rts

setupall	;duplicate start of glow table at end...
	;
	move.l	#glow.inc,a0
	move.l	#glowx.ds,a1
	moveq	#31,d0
.loop	move	(a0)+,(a1)+
	dbf	d0,.loop
	;
sua2	;make stars sprite table...
	;
	move.l	spxtable(pc),a0
	moveq	#0,d7
.loop	move	d7,d0
	bsr	makepc
	and	#$ff,d2
	and	#1,d3
	move	d2,(a0)+
	move	d3,(a0)+
	addq	#1,d7
	cmp	#320,d7
	bcs.s	.loop
	move.l	spytable(pc),a0
	moveq	#0,d7
.loop2	move	d7,d1
	bsr	makepc
	and	#$ff00,d2
	and	#$fffe,d3
	move	d2,(a0)+
	move	d3,(a0)+
	addq	#1,d7
	cmp	#224,d7
	bcs.s	.loop2
	;
sua3	;draw little mountains on scanner
	;
	move.l	hites(pc),a0
	lea	4096(a0),a0
	move	#4095,d7
;	moveq	#-1,d6
.loop0	move	d7,d0
	moveq	#0,d2
	move.b	-(a0),d2
	move	#maxy,d1
	sub	d2,d1
	;
	moveq	#2,d2
	cmp	#3072,d0
	bcc.s	.skip
	moveq	#3,d2
	cmp	#2048,d0
	bcc.s	.skip
	cmp	#1024,d0
	bcs.s	.skip
	moveq	#1,d2
	;
.skip	;d0=x, d1=y, d2=colour.
	;
	mulu	#3072,d0
	swap	d0
	mulu	#7168,d1
	swap	d1
	;
	btst	#0,d1
	bne.s	.mnext
	;
	sub	#29,d1
	mulu	#96,d1
	move.l	scan2(pc),a1
	add.l	d1,a1
	move	d0,d1
	asr	#3,d0
	add	d0,a1
	not	d1
	lsr	#1,d2
	bcc.s	.skip2
	bset	d1,(a1)
.skip2	lsr	#1,d2
	bcc.s	.skip3
	bset	d1,48(a1)
.skip3	move.b	(a1),24(a1)
	move.b	48(a1),48+24(a1)
.mnext	dbf	d7,.loop0
	;
	;collision reg.
	;
sua4	move	#$1041,$098(a6)
	;
	rts

displayoff	move	#$20,$09a(a6)
	move	#$20,$09c(a6)
.loop	btst	#5,$01f(a6)
	beq.s	.loop
	move	#$180,$096(a6)
	move	#0,$180(a6)
	rts

displayon	move	#$20,$09a(a6)
	move	#$20,$09c(a6)
.loop	btst	#5,$01f(a6)
	beq.s	.loop
	move	#$8180,$096(a6)
	rts

scancls	move.l	scan1(pc),a0
	move	#56*3-1,d0
	moveq	#-1,d1
	moveq	#0,d2
.loop	move.l	d1,(a0)+
	move.l	d1,(a0)+
	moveq	#5,d3
.loop2	move.l	d2,(a0)+
	dbf	d3,.loop2
	move.l	d1,(a0)+
	move.l	d1,(a0)+
	dbf	d0,.loop
	rts

scancls2	move.l	scan1(pc),a0
	move	#56*3-1,d0
	moveq	#-1,d1
.loop	addq	#8,a0
	moveq	#5,d2
.loop2	move.l	d1,(a0)+
	dbf	d2,.loop2
	addq	#8,a0
	dbf	d0,.loop
	rts

scancls3	move.l	scan1(pc),a0
	move	#56*3-1,d0
	moveq	#0,d2
.loop	addq	#8,a0
	moveq	#5,d3
.loop2	move.l	d2,(a0)+
	dbf	d3,.loop2
	addq	#8,a0
	dbf	d0,.loop
	rts

scancls4	move.l	scan1(pc),a0
	move	#28*3-1,d0
	moveq	#0,d2
.loop	addq	#8,a0
	moveq	#5,d3
.loop2	move.l	d2,(a0)+
	dbf	d3,.loop2
	addq	#8,a0
	dbf	d0,.loop
	rts

initdisp	;initialize display for game stuff
	;
	bsr	backcls
	bsr	frontcls
	bsr	scancls3
	lea	scanpal(pc),a0
	lea	scanrgbs(pc),a1
	bsr	putpal
	lea	gamepal(pc),a0
	lea	gamergbs(pc),a1
	bsr	putpal
	bsr	spriteson
	;
gamecopon	move.l	#coplist,$080(a6)
	rts

titcopon	move.l	#titlist,$080(a6)
	rts

warpplayer	;warp player to x position in d0
	;
	;if d0<0 then warp to pattern -d0
	;
	move	playerdie(pc),d1
	or	playerwarp(pc),d1
	bne.s	.done
	;
	movem.l	a0-a1,-(a7)
	inton	0
	clr.l	xspeed
	move	d0,warpx
	bsr	frontcls
	move	#48,playerwarp
	makesafe	l3int0
	makedef	l3int6
	move.l	#loop6,loopcode
	inton	6
	bsr	blowship
	bsr	shipoff
	movem.l	(a7)+,a0-a1
.done	rts

killplayer	;player has been demolished!
	;
	move	playerwarp(pc),d0
	or	playerdie(pc),d0
	bne.s	.done
	move	#32,playerdie
	move.l	#loop2,loopcode
	inton	3
	makedef	l3int3
	makesafe	l3int4
.done	rts

homecalc	;
	add	#2048-176,d0
	and	#4095,d0
	add	#2048-176,d2
	and	#4095,d2
	;
homecalc2	;d0,d1=src, d2,d3=dest
	;
	;calc x speed, y speed into d4,d5
	;
	sub	d0,d2
	move	d2,d4
	bpl.s	.skip
	neg	d4
.skip	sub	d1,d3
	move	d3,d5
	bpl.s	.skip2
	neg	d5
.skip2	cmp	d5,d4
	bcc.s	.xbig
	;
	swap	d4
	or	#1,d5
	divu	d5,d4
	and.l	#$ffff,d4
	tst	d2
	bpl.s	.yskip
	neg.l	d4
.yskip	moveq	#1,d5
	swap	d5
	tst	d3
	bpl.s	.ydone
	neg.l	d5
.ydone	rts
.xbig	;
	swap	d5
	or	#1,d4
	divu	d4,d5
	and.l	#$ffff,d5
	tst	d3
	bpl.s	.xskip
	neg.l	d5
.xskip	moveq	#1,d4
	swap	d4
	tst	d2
	bpl.s	.xdone
	neg.l	d4
.xdone	rts

sysinitbull	;system bullet initialization
	;
	moveq	#40,d0		;toughest!
	sub	pattern(pc),d0
	cmp	#12,d0
	bge.s	.skip
	moveq	#12,d0
.skip	lsl	#3,d0
	move	d0,-(a7)
	lsr	#1,d0
	bsr	rnd2
	add	(a7)+,d0	;my one!
	move	d0,bullr(a0)
	lsr	#1,d0
	move	d0,bullt(a0)
	rts

sysfirebull	;system fire bullet routine...
	;
	subq	#1,bullt(a0)
	bmi.s	.skip
	rts
.skip	move	bullr(a0),d0
	bsr	rnd2
	move	d0,bullt(a0)
	;
firebull1	;normal bullet fire routine...
	;
	move	onscreen(pc),d0
	beq	.done
	;
	move.l	alienfire.sfx(pc),a2
	moveq	#68,d0
	moveq	#32,d1	;volume...
	bsr	playsfx
	;
	inton	2
	move.l	a0,a2
	additem2	bulls
	beq.s	.done2
	move	x(a2),d0
	move	d0,8(a0)
	move	y(a2),d1
	move	d1,16(a0)
	move	screenx(pc),d2
	add	#16,d2
	move	shipy(pc),d3
	bsr	homecalc2
	add.l	d4,d4
	add.l	d5,d5
	add.l	sxspeed(pc),d4
	clr.b	d4		;not so accurate!
	clr.b	d5		;       "
	move.l	d4,4(a0)
	move.l	d5,12(a0)
	move	#128,20(a0)
	move.l	#bull1,22(a0)
	move.l	(a1),a0
.done2	inton	1
	;
.done	rts

bull1	dc	%0000000100000000
	dc	%0000001110000000
	dc	%0000000100000000

sysdropbomb	;system fire bullet routine...
	;
	subq	#1,bullt(a0)
	bmi.s	.skip
	rts
.skip	move	bullr(a0),d0
	bsr	rnd2
	move	d0,bullt(a0)
	;
dropbomb	;normal bullet fire routine...
	;
	move	onscreen(pc),d0
	beq.s	.done
	;
	inton	2
	move.l	a0,a2
	additem2	bulls
	beq.s	.done2
	move	x(a2),8(a0)
	move	y(a2),16(a0)
	clr.l	4(a0)
	clr.l	12(a0)
	move	#128,20(a0)
	move.l	#bomb,22(a0)
	move.l	(a1),a0
.done2	inton	1
.done	rts

bomb	dc	%0000001010000000
	dc	%0000000100000000
	dc	%0000001010000000

sysfiremiss	;
	subq	#1,bullt(a0)
	bmi.s	.skip
	rts
.skip	move	bullr(a0),d0
	bsr	rnd2
	move	d0,bullt(a0)
	;
firemiss	;fire a missile...d7=y offset
	;
	move	onscreen(pc),d0
	beq	.done
	;
	move.l	alienfire2.sfx(pc),a2
	moveq	#68,d0
	moveq	#64,d1	;volume...
	bsr	playsfx
	;
	inton	2
	move.l	a0,a2
	additem2	bulls
	beq.s	.done2
	move	x(a2),8(a0)
	move	y(a2),16(a0)
	add	d7,16(a0)
	;
	move.l	xs(a2),d0
	add.l	sxspeed(pc),d0
	move.l	d0,4(a0)
	;
	move	pattern(pc),d0
	lsr	#2,d0
	cmp	#5,d0
	bcs.s	.skipz
	moveq	#4,d0
.skipz	bsr	rnd2
	moveq	#0,d7
	move	d0,d7
	swap	d7
	bsr	rnd1
	move	d0,d7	;bull y speed...
	move	16(a0),d0
	cmp	shipy(pc),d0
	bcs.s	.skip
	neg.l	d7
.skip	move.l	d7,12(a0)
	move	#128,20(a0)
	move.l	#miss,22(a0)
	move.l	(a1),a0
.done2	inton	1
	;
.done	rts

miss	dc	%0000000000000000
	dc	%0000011111000000
	dc	%0000000000000000

sysfirekill	;system fire killerbullet routine...
	;
	subq	#1,bullt(a0)
	bmi.s	.skip
	rts
.skip	move	bullr(a0),d0
	bsr	rnd2
	move	d0,bullt(a0)
	;
	inton	2
	move.l	a0,a2
	additem2	bulls
	beq.s	.done2
	move	x(a2),d0
	move	d0,8(a0)
	move	y(a2),d1
	move	d1,16(a0)
	move	screenx(pc),d2
	add	#16,d2
	move	shipy(pc),d3
	bsr	homecalc
	lsl.l	#2,d4
	lsl.l	#2,d5
	add.l	sxspeed(pc),d4
	add.l	syspeed(pc),d5
	move.l	d4,4(a0)
	move.l	d5,12(a0)
	move	#128,20(a0)
	move.l	#kill,22(a0)
	move.l	(a1),a0
.done2	inton	1
	;
.done	rts

kill	dc	%0000001110000000
	dc	%0000001110000000
	dc	%0000001110000000

procbulls	lea	bulls(pc),a0
	move	clxdat(pc),d0
	beq.s	.loop
	move	screenx(pc),d2
	move	shipy(pc),d3
	move	d2,d4
	add	#31,d4
	;
	subq	#7,d2
	subq	#7,d4
	;
	move	d3,d5
	subq	#1,d3
	addq	#7,d5
	move	#352,d6
	move	#224+16,d7
	;
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a1
	move.l	d0,a0
	;
	subq	#1,20(a0)
	bne.s	.skip
	killitem	bulls
	bra.s	.loop
.skip	;
	;check for collision with ship.
	;
	move	clxdat(pc),d0
	beq.s	.loop
	;
	move	8(a0),d0
	cmp	d2,d0
	blt.s	.loop
	cmp	d4,d0
	bgt.s	.loop
	move	16(a0),d0
	cmp	d3,d0
	blt.s	.loop
	cmp	d5,d0
	bgt.s	.loop
	;
	move	8(a0),d2
	move	16(a0),d3
	move.b	invisoon(pc),d0
	beq.s	.noinv
	;
	;inviso that bullet!
	;
	movem	d2-d7,-(a7)
	move	8(a0),d2
	move	16(a0),d3
	killitem	bulls
	move.l	invblob(pc),a2
	bsr	explode2
	movem	(a7)+,d2-d7
	bra.s	.loop
	;
.noinv	killitem	bulls
	bsr	killplayer
	bra	.loop
	;
.done	rts

dobulls	move.l	dbat(pc),a2
	move.l	16(a2),a5	;bullsq
	move	#(3<<6)+2,d7
	bwait
	move	#$100,con0(a6)
	move.l	#$ffff0000,fwm(a6)
	move	#-2,amod(a6)
	move	#44*3-4,cmod(a6)
	move	#44*3-4,dmod(a6)
.loop	move.l	(a5)+,d0
	beq.s	bunqdone
	bwait
	move.l	d0,dpth(a6)
	move	d7,size(a6)
	bra.s	.loop
	;
bunqdone	move.l	16(a2),a5
	lea	bulls(pc),a0
	move	#224+16,d6
	move	mounty(pc),d5
	move.l	xspeed(pc),d4
	move	#4095,d3
	;
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a1
	move.l	d0,a0
	;
	move.l	4(a0),d0
	sub.l	d4,d0
	add.l	d0,8(a0)
	and	d3,8(a0)
	move.l	12(a0),d1
	add.l	d1,16(a0)
	;
	move	8(a0),d0
	cmp	#352,d0
	bcc.s	.loop
	move	16(a0),d1
	sub	d5,d1
	cmp	d6,d1
	bcc.s	.loop
	;
	move.l	(a2),a3
	mulu	#gamemod,d1
	add.l	d1,a3
	move	d0,d1
	asr	#3,d0
	add	d0,a3	;dest
	ror	#4,d1
	and	#$f000,d1
	or	#$bfa,d1	;con 0
	move.l	a3,(a5)+
	bwait
	move	d1,con0(a6)
	move.l	22(a0),apth(a6)
	move.l	a3,cpth(a6)
	move.l	a3,dpth(a6)
	move	d7,size(a6)
	bra	.loop
.done	clr.l	(a5)
	rts

scanglow	move.b	textpri(pc),d0
	beq.s	.done
	subq	#1,texttime
	bne.s	.doit
	clr.b	textpri
	bra	stextcls
.doit	move.b	texttype(pc),d0
	beq.s	dosglow1
	;
	;flashing!
	;
	lea	sglow1(pc),a1
	move	texttime(pc),d0
	and	#8,d0
	bne.s	dosglow1
	moveq	#0,d0
	move	d0,(a1)
	rept	7
	addq	#8,a1
	move	d0,(a1)
	endr
.done	rts
dosglow1	lea	sglow1(pc),a1
	addq	#1,glow2
	move	glow2(pc),d0
	cmp	#66,d0
	bcs.s	.skip
	sub	#66,d0
	move	d0,glow2
.skip	move.l	glow(pc),a0
	add	d0,d0
	add	d0,a0
	;
	move	(a0)+,(a1)
	rept	7
	addq	#8,a1
	move	(a0)+,(a1)
	endr
.done	rts

print	macro	\1=data reg char, \2=address reg dest, \3=mod
	;
	move.l	font(pc),a4
	lsl	#4,\1
	lea	1(a4,\1),a4
	;
	move.b	(a4),(\2)
	addq	#2,a4
	lea	\3(\2),\2
	;
	move.b	(a4),(\2)
	addq	#2,a4
	lea	\3(\2),\2
	;
	move.b	(a4),(\2)
	addq	#2,a4
	lea	\3(\2),\2
	;
	move.b	(a4),(\2)
	addq	#2,a4
	lea	\3(\2),\2
	;
	move.b	(a4),(\2)
	addq	#2,a4
	;
	lea	-\3*4+1(\2),\2
	;
	endm

showstats	move.b	upscore(pc),d0
	beq.s	.skip1
	clr.b	upscore
	bsr	showscore
.skip1	move.b	upships(pc),d0
	beq.s	.skip2
	clr.b	upships
	bsr	showships
.skip2	move.b	upsmarts(pc),d0
	beq.s	.skip3
	clr.b	upsmarts
	bsr	showsmarts
.skip3	move.b	upinviso(pc),d0
	beq.s	.skip4
	clr.b	upinviso
	bra	showinviso
.skip4	rts

showships	;
	move.l	scanu(pc),a3
	lea	120*28+6(a3),a3
	move	ships(pc),d7
	beq.s	.skip3
	move.l	little(pc),a2
	cmp	#7,d7
	bcc.s	.skip
	bsr.s	.skip2
.skip3	moveq	#11,d6
	moveq	#-1,d0
.loop3	move.b	d0,(a3)
	lea	40(a3),a3
	dbf	d6,.loop3
	rts
.skip	moveq	#7,d7
.skip2	subq	#1,d7
.loop	move.l	little(pc),a2
	moveq	#11,d6
.loop2	move.b	(a2)+,(a3)
	lea	40(a3),a3
	dbf	d6,.loop2
	lea	-40*12-1(a3),a3
	dbf	d7,.loop
	rts

showsmarts	;
	move.l	scanu(pc),a3
	lea	120*36+6(a3),a3
	move	smarts(pc),d7
	beq.s	.skip3
	move.l	little(pc),a2
	cmp	#7,d7
	bcc.s	.skip
	bsr.s	.skip2
.skip3	moveq	#11,d6
	moveq	#-1,d0
.loop3	move.b	d0,(a3)
	lea	40(a3),a3
	dbf	d6,.loop3
	rts
.skip	moveq	#7,d7
.skip2	subq	#1,d7
.loop	move.l	little(pc),a2
	lea	12(a2),a2
	moveq	#11,d6
.loop2	move.b	(a2)+,(a3)
	lea	40(a3),a3
	dbf	d6,.loop2
	lea	-40*12-1(a3),a3
	dbf	d7,.loop
	rts

showinviso	;
	move.l	scanu(pc),a3
	lea	120*44+6(a3),a3
	move	inviso(pc),d7
	beq	.skip3
	moveq	#0,d0
	cmp	#56,d7
	bcc.s	.skip
	bsr.s	.skip2
	bne.s	.done
.skip3	moveq	#-1,d1
	move.b	d1,80(a3)
	move.b	d1,120+80(a3)
	move.b	d1,240+80(a3)
	move.b	d1,360+80(a3)
	rts
.skip	moveq	#56,d7
.skip2	move	d7,d6
	lsr	#3,d7
	beq.s	.bye
	subq	#1,d7
.loop	move.b	d0,80(a3)
	move.b	d0,120+80(a3)
	move.b	d0,240+80(a3)
	move.b	d0,360+80(a3)
	subq	#1,a3
	dbf	d7,.loop
.bye	and	#7,d6
	beq.s	.done
	move.b	bits(pc,d6),d1
	move.b	d1,80(a3)
	move.b	d1,120+80(a3)
	move.b	d1,240+80(a3)
	move.b	d1,360+80(a3)
.done	rts

bits	dc.b	$ff,$fe,$fc,$f8,$f0,$e0,$c0,$80
	even

addscore	;d0.w=score to add
	;
	;eg. move.l #$100,d0 -> add 1000 points!
	;
	add	#0,d0	;clear extend flagaroonie
	;
	lea	newscore+2(pc),a3
	move	d0,(a3)+
	lea	score+4(pc),a2
	abcd	-(a3),-(a2)
	abcd	-(a3),-(a2)
	abcd	-(a3),-(a2)
	;
	move.l	-1(a2),d0
	cmp.l	scoremore(pc),d0
	bcs.s	.done
	;
	move.l	freelife.sfx(pc),a2
	moveq	#119,d0
	moveq	#64,d1
	bsr	playsfx
	;
	lea	scoreten+4(pc),a3
	lea	scoremore+4(pc),a2
	addq	#1,ships
	addq	#1,smarts
	addq	#4,inviso
	abcd	-(a3),-(a2)
	abcd	-(a3),-(a2)
	abcd	-(a3),-(a2)
	st	upships
	st	upsmarts
	st	upinviso
.done	st	upscore	
	rts

hidescore	;hide other players score
	;
	move	playerup(pc),d0
	bmi.s	.done
	move.l	scanu(pc),a3
	lea	120*12(a3),a3
	moveq	#-1,d2
	moveq	#6,d1
.loop0	moveq	#6,d0
.loop	move.b	d2,(a3)+
	dbf	d0,.loop
	lea	120-7(a3),a3
	dbf	d1,.loop0
.done	rts

showscore	;score is in BCD
	;
	lea	score+1(pc),a2
	move.l	scanu(pc),a3
	lea	120*12(a3),a3
	moveq	#0,d6
	moveq	#2,d7		;6 digits - 7th always 0!
.loop	move.b	(a2),d0
	lsr	#4,d0
	bsr.s	showsc2
	move.b	(a2)+,d0
	bsr.s	showsc2
	dbf	d7,.loop
	moveq	#0,d0
	;
scprint	add	#48,d0
	move.l	font(pc),a4
	lsl	#4,d0
	add	d0,a4
	moveq	#6,d5
.loop2	move.b	(a4),d0
	addq	#2,a4
	not	d0
	move.b	d0,(a3)
	move.b	d0,80(a3)
	lea	120(a3),a3
	dbf	d5,.loop2
	lea	-120*7(a3),a3
	rts
	;
showsc2	and	#15,d0
	bne.s	.skip
	tst	d6
	beq.s	.skip2
.skip	moveq	#-1,d6
	bsr	scprint
.skip2	addq	#1,a3
	rts

stextcls	;clear scanner text (if any)
	;
	move.l	scan3(pc),a3
	lea	10*50(a3),a3	;dest
	;usesafe
	move	#$4000,$09a(a6)	;no blits!
	bwait
	move	#$100,$040(a6)
	move	#50-24,dmod(a6)
	move.l	a3,dpth(a6)
	move	#(5<<6)+12,size(a6)
	;usedef
	move	#$c000,$09a(a6)	;no blits!
	;bwait
	rts

scanprint	;a2=string to print.
	;
	;first byte = priority : 64=norm, 1=low, 127=high
	;second     = method. 1=flash
	;
	move.b	textpri(pc),d0
	beq.s	.skip
	cmp.b	(a2),d0
	bge	.done
	bsr	stextcls
.skip	move.b	(a2)+,textpri
	move.b	(a2)+,texttype
	move	#128,texttime
	;
	move.l	scan3(pc),a3
	lea	10*50+12(a3),a3
	moveq	#0,d0
.loop	addq	#1,d0
	tst.b	(a2)+
	bne.s	.loop
	sub	d0,a2
	lsr	#1,d0
	sub	d0,a3
	;
.loop2	moveq	#0,d0
	move.b	(a2)+,d0
	beq.s	.done
	print 	d0,a3,50
	bra.s	.loop2
.done	rts

scanerase	move.l	scan1(pc),a2
	add	old(a0),a2		;dest
	moveq	#0,d0
	move.b	olds(a0),d0
	ror	#4,d0
	or	#$30a,d0
	moveq	#40-2,d7
	;
	move	#$4000,$09a(a6)
	bwait
	move	d0,con0(a6)
	move.l	#-1,fwm(a6)
	move	#$c000,adat(a6)
	move	d7,cmod(a6)
	move	d7,dmod(a6)
	move.l	a2,cpth(a6)
	move.l	a2,dpth(a6)
	move	#(6<<6)+1,size(a6)
	move	#$c000,$09a(a6)
	rts

scanplot	;plot current alien on scanner
	;
	;calc new old,olds into d4,d5
	;
	move	x(a0),d4
	add	#2048-160,d4
	and	#4095,d4
	mulu	#3072,d4
	swap	d4
	move	d4,d5
	and	#$e,d5
	asr	#3,d4
	addq	#8,d4
	;
	move	y(a0),d0
	mulu	#7168,d0
	swap	d0
	mulu	#120,d0
	add	d0,d4
	;
	cmp.b	olds(a0),d5
	bne.s	.doit
	cmp	old(a0),d4
	bne.s	.doit
	;
	rts
	;
.doit	bsr	scanerase
	;
	cmp	#56*120,d4
	bcs.s	.doit2
	;
	rts
	;
.doit2	move	d4,old(a0)
	move.b	d5,olds(a0)
	move.l	scan1(pc),a2
	add	d4,a2
	ror	#4,d5
	;
	move.l	scantab(pc),a3
	move.b	col(a0),d0
	lsr	#2,d0
	and	#$1c,d0
	move.l	0(a3,d0),a4
	;
	move	#$4000,$09a(a6)
	bwait
	move	d5,con1(a6)
	or	#$bf2,d5
	move	d5,con0(a6)
	move.l	#-1,fwm(a6)
	move	#$c000,bdat(a6)
	move	#0,amod(a6)
	move	d7,cmod(a6)
	move	d7,dmod(a6)
	move.l	a4,apth(a6)
	move.l	a2,cpth(a6)
	move.l	a2,dpth(a6)
	move	#(3<<6)+1,size(a6)
	;
	move.b	col(a0),d0
	lsl	#2,d0
	and	#$1c,d0
	move.l	0(a3,d0),a4
	;
	bwait
	move.l	a4,apth(a6)
	move	#(3<<6)+1,size(a6)
	move	#$c000,$09a(a6)
	;
	rts

showscan	;put mountains in correct position on scanner...
	;
	move	shipx(pc),d0
	add	#2048+160,d0
	and	#4095,d0
	mulu	#3072,d0
	swap	d0
	;
	move.l	scan2(pc),a0
	subq.l	#8,a0
	subq	#1,d0
	move	d0,d1
	and	#15,d1
	eor	#15,d1
	lsl	#4,d1
	asr	#3,d0
	add	d0,a0
	move.l	a0,d0
	lea	scanback(pc),a0
	move	d0,6(a0)
	swap	d0
	move	d0,2(a0)
	swap	d0
	add.l	#48,d0
	move	d0,8+6(a0)
	swap	d0
	move	d0,8+2(a0)
	move	d1,-(a0)
	;
	;put screen on scanner!
	;
	move	mounty(pc),d0
	addq	#8,d0
	mulu	#7168,d0
	swap	d0
	add	#sly,d0
	move.l	scansprite(pc),a0
	move.b	d0,(a0)+
	addq	#1,a0
	addq	#3,d0
	move.b	d0,(a0)
	addq	#2,a0
	lea	12(a0),a0
	add	#19,d0
	move.b	d0,(a0)+
	addq	#1,a0
	addq	#3,d0
	move.b	d0,(a0)
	;
	;now, put actual ship on scanner...
	;
	move	screenx(pc),d0
	add	#2048-160,d0
	mulu	#3072,d0
	swap	d0
	add	#128+64,d0
	lsr	#1,d0
	scs	d2
	and	#1,d2
	;
	move	shipy(pc),d1
	mulu	#7168,d1
	swap	d1
	add	#sly-2,d1
	;
	move.l	shipsprite(pc),a0
	move.b	d1,(a0)+
	move.b	d0,(a0)+
	addq	#3,d1
	move.b	d1,(a0)+
	move.b	d2,(a0)
	rts

space	move	#$a00,2(a0)
	move	#$500,10(a0)
	bsr	rnd1
	cmp	#$fc00,d0
	bcs.s	.skip
	move	#$f00,smartcol
	move	#$100,smartsub
.skip	rts


gs	equ	4
go	equ	10<<(gs-1)
	;
mountglow	;alter mountain colours for friendly/enemy/neutral position
	;
	lea	mrgbs+4(pc),a0
	;
	move	inspace(pc),d0
	bne	space
	;
	move	shipx(pc),d0
	add	screenx(pc),d0
	add	#16,d0
	and	#4095,d0
	;
	cmp	#4096-go,d0
	blt.s	.skip
	sub	#4096,d0
.skip	;
	cmp	#go,d0
	bgt.s	.skip2
	;
	;E->N
	;
	add	#go,d0
	lsr	#gs,d0
	moveq	#10,d1
	move	d0,d2
	move	d0,d3
	bra	.put
	;
.skip2	cmp	#1024-go,d0
	blt.s	.n
	sub	#1024,d0
	cmp	#go,d0
	bgt.s	.skip3
	;
	;N->F
	;
	add	#go,d0
	lsr	#gs,d0
	moveq	#10,d1
	sub	d0,d1
	moveq	#10,d2
	sub	d0,d2
	moveq	#10,d3
	bra	.put
	;
.skip3	cmp	#1024-go,d0
	blt.s	.f
	sub	#1024,d0
	cmp	#go,d0
	bgt.s	.skip4
	;
	;F->N
	;
	add	#go,d0
	lsr	#gs,d0
	move	d0,d1
	move	d0,d2
	moveq	#10,d3
	bra	.put
	;
.skip4	cmp	#1024-go,d0
	blt.s	.n
	sub	#1024,d0
	cmp	#go,d0
	bgt.s	.skip5
	;
	;N->E
	;
	add	#go,d0
	lsr	#gs,d0
	moveq	#10,d1
	moveq	#10,d2
	sub	d0,d2
	moveq	#10,d3
	sub	d0,d3
	bra	.put
	;
.skip5	rts

.n	move	#$aaa,2(a0)
	move	#$555,10(a0)
	rts
.f	move	#$00a,2(a0)
	move	#$005,10(a0)
	rts
.e	move	#$a00,2(a0)
	move	#$500,10(a0)
	rts
	;
.put	move	d1,d4
	lsl	#8,d4
	move.b	d2,d4
	lsl.b	#4,d4
	or	d3,d4
	move	d4,2(a0)
	lsr	#1,d1
	lsr	#1,d2
	lsr	#1,d3
	move	d1,d4
	lsl	#8,d4
	move.b	d2,d4
	lsl.b	#4,d4
	or	d3,d4
	move	d4,10(a0)
	rts

findid	;d1=flags/id to find, return in d0.
	;
	lea	aliens(pc),a2
.loop	move.l	(a2),d0
	beq.s	.done
	move.l	d0,a2
	tst.b	flags(a2)
	bmi.s	.loop
	cmp.b	id(a2),d1
	bne.s	.loop
.done	rts

getrealx	move	x(a0),d0
	add	shipx(pc),d0
	and	#4095,d0
	rts

getxdiff	move	x(a0),d0
	sub	screenx(pc),d0
	sub	#16,d0
	bpl.s	.skip
	neg	d0
.skip	rts

getydiff	move	y(a0),d0
	sub	shipy(pc),d0
	bpl.s	.skip
	neg	d0
.skip	rts

limitxs	;limit xspeed to d0
	;
	move.l	xs(a0),d1
	bmi.s	.skip
	cmp.l	d0,d1
	ble.s	.done
	move.l	d0,xs(a0)
	rts
.skip	neg.l	d0
	cmp.l	d0,d1
	bge.s	.done
	move.l	d0,xs(a0)
.done	rts

homeawayx	move	x(a0),d1
	sub	screenx(pc),d1
	and	#4095,d1
	cmp	#2048,d1
	bcs.s	.rite	;to rite of me!
	move.l	d0,xs(a0)
	bmi.s	.done
	neg.l	xs(a0)
.done	rts
.rite	move.l	d0,xs(a0)
	bpl.s	.done
	neg.l	xs(a0)
	rts

homeinx	move	x(a0),d1
	sub	screenx(pc),d1
	and	#4095,d1
	cmp	#2048,d1
	bcs.s	.rite	;to rite of me!
	move.l	d0,xs(a0)
	bpl.s	.done
	neg.l	xs(a0)
.done	rts
.rite	move.l	d0,xs(a0)
	bmi.s	.done
	neg.l	xs(a0)
	rts

homeawayxa	move	x(a0),d1
	sub	screenx(pc),d1
	and	#4095,d1
	cmp	#2048,d1
	bcs.s	.rite	;to rite of me!
	move.l	d0,xa(a0)
	bmi.s	.done
	neg.l	xa(a0)
.done	rts
.rite	move.l	d0,xa(a0)
	bpl.s	.done
	neg.l	xa(a0)
	rts

homeinxa	move	x(a0),d1
	sub	screenx(pc),d1
	and	#4095,d1
	cmp	#2048,d1
	bcs.s	.rite	;to rite of me!
	move.l	d0,xa(a0)
	bpl.s	.done
	neg.l	xa(a0)
.done	rts
.rite	move.l	d0,xa(a0)
	bmi.s	.done
	neg.l	xa(a0)
	rts

limitys	;limit yspeed to d0
	;
	move.l	ys(a0),d1
	bmi.s	.skip
	cmp.l	d0,d1
	ble.s	.done
	move.l	d0,ys(a0)
	rts
.skip	neg.l	d0
	cmp.l	d0,d1
	bge.s	.done
	move.l	d0,ys(a0)
.done	rts

homeawayy	move	y(a0),d1
	cmp	shipy(pc),d1
	bcs.s	.above
	move.l	d0,ys(a0)
	bpl.s	.skip
	neg.l	ys(a0)
	rts
.above	move.l	d0,ys(a0)
	bmi.s	.skip
	neg.l	ys(a0)
.skip	rts

homeiny	move	y(a0),d1
	cmp	shipy(pc),d1
	bcs.s	.above
	move.l	d0,ys(a0)
	bmi.s	.skip
	neg.l	ys(a0)
	rts
.above	move.l	d0,ys(a0)
	bpl.s	.skip
	neg.l	ys(a0)
.skip	rts

homeawayya	move	y(a0),d1
	cmp	shipy(pc),d1
	bcs.s	.above
	move.l	d0,ya(a0)
	bpl.s	.skip
	neg.l	ya(a0)
	rts
.above	move.l	d0,ya(a0)
	bmi.s	.skip
	neg.l	ya(a0)
.skip	rts

homeinya	move	y(a0),d1
	cmp	shipy(pc),d1
	bcs.s	.above
	move.l	d0,ya(a0)
	bmi.s	.skip
	neg.l	ya(a0)
	rts
.above	move.l	d0,ya(a0)
	bpl.s	.skip
	neg.l	ya(a0)
.skip	rts

chkinfront	;return ne if facing ship
	;
	move	x(a0),d0
	sub	screenx(pc),d0
	move	d0,d1
	bpl.s	.skip
	neg	d1	;abs difference in d1
.skip	and	#4095,d0
	cmp	#2048,d0
	bcs.s	.rite	;to rite of me!
	;
	;to left
	;
	move	shipdir(pc),d0
	bmi.s	.yes
	moveq	#0,d0
	rts
.yes	moveq	#-1,d0
	rts
.rite	move	shipdir(pc),d0
	beq.s	.yes
	moveq	#0,d0
	rts

kstack	dc.l	0

chkcollide	;check for collision with player. (player 28 pixels wide!)
	;
	btst	#4,flags(a0)
	bne.s	.slow
	;
	move	clxdat(pc),d0
	beq.s	.done
	;
.slow	;check x...
	;
	move	x(a0),d0		;left edge of alien.
	addq	#7,d0
	move	d0,d1
	move.l	frame(a0),a2
	move	(a2)+,d2
	lsr	#1,d2
	sub	d2,d0
	add	d2,d1
	move	screenx(pc),d2
	move	d2,d3
	addq	#5,d2
	add	#32-5,d3
	;
	cmp	d1,d2
	bge.s	.done
	cmp	d3,d0
	bge.s	.done
	;
	;now, y...
	;
	move	y(a0),d0
	move	d0,d1
	add	(a2),d1
	move	shipy(pc),d2
	move	d2,d3
	addq	#7,d3
	;
	cmp	d1,d2
	bge.s	.done
	cmp	d3,d0
	bge.s	.done
	;
	;OK, overlapping with ship - what do we do then...
	;
	move.b	invisoon(pc),d0
	beq.s	.norm
	btst	#5,flags(a0)
	bne.s	.norm
	;
	move.l	shot(a0),d0
	beq.s	.done
	move.l	d0,a2
	jsr	(a2)
	bra.s	.done
	;
.norm	move.l	collide(a0),d0
	beq.s	.done
	move.l	d0,a2
	jmp	(a2)
	;
.done	rts

chkshot	;now, check for collision with lasers
	;
	move.l	shot(a0),d0
	beq.s	.done		;no 'shot' routine
	;
	move.b	smarton(pc),d0
	beq.s	.nosmart
	;
	btst	#5,flags(a0)
	bne.s	.nosmart
	;
	move.l	shot(a0),a2
	jmp	(a2)
.nosmart	;
	move	x(a0),d0	;left x
	move	y(a0),d1
	move.l	frame(a0),a4
	move	d0,d2
	add	(a4)+,d2	;rite x
	move	d1,d3
	add	(a4)+,d3	;bot y
	;
	lea	lasers(pc),a2
	move	#$4000,$09a(a6)
	;
.loop	move.l	(a2),d4
	beq.s	.done
	move.l	a2,a3
	move.l	d4,a2
	;
	cmp	12(a2),d1
	bgt.s	.loop
	cmp	12(a2),d3
	ble.s	.loop
	;
	move	4(a2),d4
	move	d4,d5
	sub	6(a2),d5
	cmp	d5,d4
	ble.s	.skip
	exg	d4,d5
.skip	cmp	d0,d5
	blt.s	.loop
	cmp	d2,d4
	bge.s	.loop
	;
	;bangarooney! collision! - shoot it!
	;
	move.l	shot(a0),d0
	;
	move.l	(a2),(a3)
	move.l	lasers.free(pc),(a2)
	move.l	a2,lasers.free
	move	#$c000,$09a(a6)
	move.l	d0,a2
	jmp	(a2)	;only one thing shot per pass!
	;
.done	move	#$c000,$09a(a6)
	;
	rts

animaliens	lea	aliens(pc),a0
.loop	move.l	(a0),d0
	beq.s	.done
	move.l	d0,a0
	bsr.s	animate
	bra.s	.loop
.done	rts

animate	move.l	anim(a0),a2
	move.l	animf(a0),d0
	add.l	anims(a0),d0
	bmi.s	.under
	cmp.l	(a2),d0
	bcs.s	.done
	;
	move	8(a2),d1
	and	#3,d1
	bne.s	.now2
	sub.l	(a2),d0
	bra.s	.done
.now2	subq	#1,d1
	bne.s	.nopp2
	sub.l	anims(a0),d0
	neg.l	anims(a0)
	bra.s	.done
.nopp2	sub.l	anims(a0),d0
	clr.l	anims(a0)
	bra.s	.done
	;
.under	move	8(a2),d1
	and	#3,d1
	bne.s	.now1
	add.l	(a2),d0
	bra.s	.done
.now1	subq	#1,d1
	bne.s	.nopp1
	sub.l	anims(a0),d0
	neg.l	anims(a0)
	bra.s	.done
.nopp1	sub.l	anims(a0),d0
	clr.l	anims(a0)
	;
.done	move.l	d0,animf(a0)
	bra	makeframe

killme3	move.l	aliendie2.sfx(pc),a2
	moveq	#100,d0
	moveq	#64,d1
	bsr	playsfx
	bra.s	killme2

killme	move.l	aliendie.sfx(pc),a2
	moveq	#66,d0
	moveq	#64,d1
	bsr	playsfx
	;
killme2	bsr	scanerase
	clr	flags(a0)
	killitem	aliens
	move.l	kstack(pc),a7
	bra	procloop

procaliens	;process aliens...
	;
	addq	#1,scant1
	move	scant1(pc),scant2
	;
	lea	aliens(pc),a0
	lea	data(pc),a5
	move.l	a7,kstack
	;
procloop	move.l	(a0),d0
	beq	procdone
	move.l	a0,a1
	move.l	d0,a0
	move.b	flags(a0),d0
	bmi.s	procloop
	;
colchk	;check if alien's on-screen...
	;
	clr	onscreen	;not on screen.
	cmp	#352,x(a0)
	bcc	notonscreen
	move	y(a0),d0
	sub	mounty(pc),d0
	cmp	#256,d0
	bcc	notonscreen
	not	onscreen
	;
	;this stuff only called if alien on-screen...
	;
	bsr	chkcollide
	bsr	chkshot
	bsr	animate
	;
notonscreen	move.l	loop(a0),d0
	beq.s	.skip
	move.l	d0,a2
	jsr	(a2)
	;
.skip	;draw to scanner - only every 4'th alien!
	;
	addq	#1,scant2
	move	scant2(pc),d0
	and	#3,d0
	bne	procloop
	bsr	scanplot
	bra	procloop
	;
procdone	rts

doaliens	;OK, our super quick interupt driven move loop!
	;
	move.l	dbat(pc),a2
	move.l	12(a2),a5
	bwait
	move	#$100,con0(a6)
	move.l	#$ffff0000,fwm(a6)
	move	#-2,amod(a6)
	move	#44-4,cmod(a6)
	move	#44-4,dmod(a6)
.loop0	move	(a5)+,d0
	beq.s	.skip
	bwait
	move.l	(a5)+,dpth(a6)
	move	d0,size(a6)
	bra.s	.loop0
.skip	move.l	12(a2),a5
	lea	aliens(pc),a0
	move.l	xspeed(pc),d7
	move	#4095,d6
	move	#maxy-1,d5
	move	mounty(pc),d4
	move	#336,d2
	move	#240,d3
.loop	;cmp.b	#240,$006(a6)
	;bcc	.done
	move.l	(a0),d0
	beq	.done
	move.l	d0,a0
	;
	move.b	flags(a0),d0
	bpl.s	.noin
	;
	;warping in!
	;
	sub.l	d7,x(a0)
	and	d6,x(a0)
	bra.s	.loop
	;
.noin	move.l	xa(a0),d0
	add.l	d0,xs(a0)
	move.l	xs(a0),d0
	sub.l	d7,d0
	add.l	d0,x(a0)
	and	d6,x(a0)
	move	x(a0),d0
	;
	move.l	ya(a0),d1
	add.l	d1,ys(a0)
	move.l	ys(a0),d1
	add.l	d1,y(a0)
	and	d5,y(a0)
	;
	cmp	d2,d0
	bcc.s	.loop
	move	y(a0),d1
	sub	d4,d1
	cmp	d3,d1
	bcc.s	.loop
	;
	;draw it!
	;
	move.l	(a2),a1
	mulu	#gamemod,d1
	add.l	d1,a1
	move	d0,d1
	asr	#3,d0
	add	d0,a1	;dest
	ror	#4,d1
	and	#$f000,d1
	or	#$bfa,d1	;con 0
	move.l	frame(a0),a3
	move	4(a3),d0	;size
	move	d0,(a5)+
	move.l	a1,(a5)+
	addq	#6,a3
	bwait
	move	d1,con0(a6)
	move.l	a3,apth(a6)
	move.l	a1,cpth(a6)
	move.l	a1,dpth(a6)
	move	d0,size(a6)
	;
	bra	.loop
	;
.done	clr	(a5)
	rts

perlife	moveq	#20,d7
	bra.s	execobj

pergame	moveq	#12,d7
	;
execobj	lea	data(pc),a5
	lea	objects(pc),a0
.loop	move.l	(a0),d0
	beq.s	.done
	move.l	d0,a0
	move.l	12+8(a0),a2
	move.l	12(a0,d7),a3
	movem.l	a0/d7,-(a7)
	jsr	(a3)
	movem.l	(a7)+,a0/d7
	bra.s	.loop
.done	rts

perpattern	move.b	#13,botext-1
	move.l	perloops(pc),a4
	lea	data(pc),a5
	lea	objects(pc),a0
.loop	move.l	(a0),d0
	beq.s	.done
	move.l	d0,a0
	move.l	12+8(a0),a2
	move.l	12+16(a0),a3
	movem.l	a0/a4/d7,-(a7)
	move	pattern(pc),d0
	tst	bomode
	jsr	(a3)
	move.l	a0,d0
	movem.l	(a7)+,a0/a4/d7
	beq.s	.loop
	move.l	d0,(a4)+
	bra.s	.loop
.done	clr.l	(a4)
	rts

perloop	move.l	perloops(pc),a0
	lea	data(pc),a5
.loop	move.l	(a0)+,d0
	beq.s	.done
	move.l	d0,a1
	move.l	a0,-(a7)
	jsr	(a1)
	move.l	(a7)+,a0
	bra.s	.loop
.done	rts

beginadd	usesafe
	additem2	aliens
	bne.s	.ok
	;
	move	#4095,d0
.loop	move	d0,$dff180
	dbf	d0,.loop
	;
.ok	cmp.l	#aliens,a1	;was prev first?
	bne.s	.skip
	move.l	a0,a1	;help!!!! - mega kludge # $fa7
.skip	moveq	#0,d0
	move.l	d0,xa(a0)
	move.l	d0,xs(a0)
	move.l	d0,ya(a0)
	move.l	d0,ys(a0)
	move	#$100,flags(a0)
	move.l	d0,anim(a0)
	move.l	d0,loop(a0)
	move.l	d0,collide(a0)
	move.l	d0,shot(a0)
	rts

endadd	usedef
	move.l	(a1),a0
	rts

newanim	;a0=alien, a2=anim address
	;
	cmp.l	anim(a0),a2
	bne.s	.skip
	rts
.skip	move.l	anim(a0),d0
	beq.s	.skipz
	;
	;adjust so still on feet!
	;
	move.l	d0,a3	;old anim
	add.l	10(a3),a3
	move	(a3),d0
	add	d0,y(a0)
	move.l	a2,a3
	add.l	10(a3),a3
	move	(a3),d0
	sub	d0,y(a0)
	;
.skipz	move.l	a2,anim(a0)
	clr.l	animf(a0)
	move.l	4(a2),anims(a0)
	bpl.s	makeframe
	move	(a2),animf(a0)
	subq	#1,animf(a0)
	;
makeframe	;a0=alien, a2=anim
	;
	move	animf(a0),d0
	btst	#2,9(a2)
	beq.s	.skip
	tst	facing(a0)
	bpl.s	.skip
	add	(a2),d0
.skip	lsl	#2,d0
	add.l	10(a2,d0),a2
	move.l	a2,frame(a0)
.done	rts

calcnum	;calc how many aliens...
	;
	cmp	pattern(pc),d2
	ble.s	.skip
.done	moveq	#0,d0
	rts
.skip	moveq	#0,d7
	move	pattern(pc),d7
	divu	#5,d7
	swap	d7
	tst	d7
	beq.s	.skip2
	;
	;not a multiple of 5!
	;
	move	pattern(pc),d7
	sub	d2,d7
	add	d7,d0
	cmp	d1,d0
	bls.s	.skip3
	move	d1,d0
.skip3	cmp	d0,d0
	rts
	;
	;is a multiple of 5!
	;
.skip2	tst	d3
	bmi.s	.done
	move	pattern(pc),d7
.loop	cmp	#26,d7
	bcs.s	.skip4
	sub	#25,d7
	bra.s	.loop
.skip4	cmp	d7,d3
	bne.s	.done
	;
	move	d4,d0
	cmp	#0,a0
	beq.s	.skipz
	move.l	a0,patmess
.skipz	tst	d0
	rts

rndrange	;d0=low, d1=high, d2=pattern for high.
	;   3       8          10
	;
	move	d1,d3
	sub	d0,d3	;max range
	move	d0,d4
	swap	d4
	clr	d4
	move	pattern(pc),d5
	cmp	d2,d5
	bcs.s	.skip
	;
	;move	d2,d5
	;
	swap	d3
	clr	d3
	bra.s	.skip2
	;
.skip	swap	d5
	clr	d5
	divu	d2,d5
	mulu	d5,d3
	;
.skip2	;d3.q=range...get random number 0 -> d3
	;
	bsr	rnd1
	move.l	d3,d1
	mulu	d0,d3
	clr	d3
	swap	d3	;frac done
	;
	swap	d1
	mulu	d1,d0
	;
	add.l	d3,d0
	add.l	d4,d0	;add base var...
	;
	rts

rndoffsc	move	#4096-352*3-1024,d0
	bsr	rnd2
	move	d0,d6
	add	#352*2,d6
	rts

getoffsc	move	#1024,d0
	bsr	rnd2
	add	d6,d0
	and	#4095,d0
	move	d0,x(a0)
	rts

rnd1	;generate rnd word into d0
	;
	moveq	#0,d0
	move	$dff006,d0
	move	$dff00a,d1
	ror	#8,d1
	eor	d1,d0
	move.b	$bfe601,d1
	move	last(pc),d2
	rol	d2,d1
	eor	d1,d0
	eor	d2,d0
	move	sweor(pc),d1
	eor	#$aaaa,d1
	ror	#1,d1
	move	d1,sweor
	eor	d1,d0
	move	d0,last
	rts

rnd2	;rnd.w(0-d0.w)
	move	d0,-(a7)
	bsr	rnd1
	mulu	(a7)+,d0
	swap	d0
	rts

rnd3	move.l	d0,-(a7)
	bsr	rnd1
	tst	d0
	bpl.s	.skip
	move.l	(a7)+,d0
	neg.l	d0
	rts
.skip	move.l	(a7)+,d0
	rts

getmounty	;d0=x to get mounty of.
	;
	addq	#8,d0
	move.l	hites(pc),a2
	add	shipx(pc),d0
	sub	#16,d0
	and	#4095,d0
	moveq	#0,d1
	move.b	0(a2,d0),d1
	move	#maxy,d0
	sub	d1,d0
	rts

implode	;a0=alien, a2=frags
	;
	usesafe
	moveq	#48,d5
	move	(a2)+,d4
	;
	;add first by hand in case none left!
	;
	move.l	a0,a3
	additem2	frags
	beq.s	.done2
	bsr	addfrag
	;
	cmp	#352*2,x(a3)
	bcs.s	.doit
	cmp	#4096-352,x(a3)
	bcs.s	.done
	;
.doit	subq	#1,d4
.loop	additem2	frags
	beq.s	.done
	bsr	addfrag
	dbf	d4,.loop
	;
.done	move.l	a3,26(a0)
	move.l	a3,a0
	bset	#7,flags(a0)
	usedef
	rts
	;
.done2	usedef
	move.l	a3,a0
	rts

addfrag	move.l	x(a3),d2
	swap	d2
	add	(a2)+,d2
	swap	d2
	;
	move.l	y(a3),d3
	swap	d3
	add	(a2)+,d3
	swap	d3
	;
	move.l	(a2)+,d1	;xspeed
	move.l	d1,4(a0)
	neg.l	4(a0)
	;
	;*48 (32+16)
	;
	lsl.l	#4,d1
	move.l	d1,d0
	add.l	d1,d1
	add.l	d0,d1
	;
	add.l	d1,d2
	move.l	d2,8(a0)
	;
	move.l	(a2)+,d1	;yspeed
	move.l	d1,12(a0)
	neg.l	12(a0)
	;
	;*48
	;
	lsl.l	#4,d1
	move.l	d1,d0
	add.l	d1,d1
	add.l	d0,d1
	;
	add.l	d1,d3
	move.l	d3,16(a0)
	;
	move.l	a2,20(a0)
	move	d5,24(a0)
	clr.l	26(a0)
	;
	lea	12(a2),a2
	;
	rts

explode	;a0/a1=alien, a2=frags
	;
	move	x(a0),d2	;x,
	move	y(a0),d3	;y
explode2	move	(a2)+,d4
	moveq	#48,d5
	;
.loop	usesafe
	additem2	frags
	beq.s	.done2
	move	d2,d0
	move	d3,d1
	add	(a2)+,d0
	add	(a2)+,d1
	move	d0,8(a0)
	move	d1,16(a0)
	move.l	(a2)+,4(a0)
	move.l	(a2)+,12(a0)
	move.l	a2,20(a0)
	move	d5,24(a0)
	clr.l	26(a0)
	usedef
	;
	lea	12(a2),a2
	dbf	d4,.loop
.done	move.l	(a1),a0
	rts
.done2	usedef
	move.l	(a1),a0
	rts

dofrags	;first, unqueue all frags...
	;
	move.l	dbat(pc),a2
	move.l	8(a2),a5	;frags q
	bwait
	move	#$100,con0(a6)
	move	#44-2,dmod(a6)
	move	#6<<6+1,d7		;2 high, 3 deep
.loop	move.l	(a5)+,d0
	beq.s	.skip
	bwait
	move.l	d0,dpth(a6)
	move	d7,size(a6)
	bra.s	.loop
.skip	move.l	8(a2),a5
	lea	frags(pc),a0
	move.l	xspeed(pc),d6
	move	#336,d4		;x limit
	move	#240,d5
	bwait
	move.l	#-1,fwm(a6)
	move	#0,amod(a6)
	;
.loop2	btst	#0,$005(a6)
	beq.s	.vskip
	cmp.b	#32,$006(a6)
	bcc	.done
	;
.vskip	move.l	(a0),d0
	beq	.done
	move.l	a0,a1
	move.l	d0,a0
	;
	subq	#1,24(a0)
	bne.s	.skip2
	move.l	26(a0),d0
	killitem	frags
	tst.l	d0
	beq.s	.loop2	;alien to activate!
	move.l	d0,a3
	bclr	#7,flags(a3)
	bra.s	.loop2
	;
.skip2	move.l	4(a0),d0	;xspeed
	sub.l	d6,d0
	add.l	d0,8(a0)
	move.l	12(a0),d1
	add.l	d1,16(a0)
	;
	move	8(a0),d0
	cmp	d4,d0
	bcc.s	.loop2
	move	16(a0),d1
	sub	mounty(pc),d1
	cmp	d5,d1
	bcc.s	.loop2
	;
	;ok to draw...
	;
	move.l	(a2),a3
	mulu	#gamemod,d1
	add.l	d1,a3
	move	d0,d1
	asr	#3,d0
	add	d0,a3	;dest
	ror	#4,d1
	and	#$c000,d1
	or	#$9f0,d1	;con0
	move.l	a3,(a5)+
	;
	bwait
	move	d1,con0(a6)
	move.l	20(a0),apth(a6)
	move.l	a3,dpth(a6)
	move	d7,size(a6)
	bra	.loop2
	;
.done	clr.l	(a5)
	rts

doglow12	add.l	#$4000,glow1
	bra	doglow1s

doglow1	addq	#1,glow1
	move	smartcol(pc),d0
	beq.s	doglow1s
	move	d0,scrnrgb+2
	move	smartsub(pc),d0
	sub	d0,smartcol
	bne.s	doglow1s
	clr	scrnrgb+2
doglow1s	move	glow1(pc),d0
	cmp	#66,d0
	bcs.s	.skip
	sub	#66,d0
	move	d0,glow1
.skip	move.l	glow(pc),a0
	add	d0,d0
	move	0(a0,d0),d0
	move	d0,scanrgbs+10
	rts

firetime	dc	0

addlasers	;check if fire button hit, and add laser
	;
	move	cmode(pc),d0
	beq.s	.joystick
	chkkey	$3a
	beq.s	.skip0
	bra.s	.fire
.joystick	btst	#7,$bfe001
	bne.s	.skip0
.fire	move	firetime(pc),d0
	and	#3,d0
	bne.s	.done2
	;
	additem2	lasers
	beq.s	.done
	move	screenx(pc),d0
	moveq	#-10,d1
	moveq	#-3,d2
	move	shipdir(pc),d3
	bne.s	.skip
	add	#31,d0
	neg	d1
	neg	d2
.skip	move	d0,4(a0)
	move	d0,8(a0)
	move	d1,6(a0)
	move	d2,10(a0)
	move	shipy(pc),12(a0)
	addq	#4,12(a0)
	move.l	laser.sfx(pc),a2
	moveq	#64,d0
	moveq	#48,d1
	bsr	playsfx
.done2	addq	#1,firetime
	rts
.skip0	clr	firetime
.done	rts
	
dolasers	;erase old lasers from screen
	;
	move.l	dbat(pc),a2
	move.l	4(a2),a5
	bwait
	move	#$100,con0(a6)
.loop0	move	(a5)+,d0
	beq.s	drawlasers
	bwait
	move.l	(a5)+,dpth(a6)
	move	d0,size(a6)
	bra.s	.loop0
	;
drawlasers	;move and draw lasers at current position.
	;
	lea	lasers(pc),a0
	move.l	4(a2),a5
	bwait
	move	#$9f0,con0(a6)
	move.l	#-1,fwm(a6)
	move	#0,amod(a6)
	;
.loop	move.l	(a0),d0
	beq	.done
	move.l	a0,a1
	move.l	d0,a0
	;
	move	6(a0),d0
	add	d0,4(a0)
	move	4(a0),d0
	cmp	#352,d0
	bcs.s	.ok
.kill	killitem	lasers
	bra.s	.loop
.ok	move	10(a0),d2
	add	d2,8(a0)
	move	8(a0),d2
	cmp	#352,d2
	bcc.s	.kill
	;
	move	12(a0),d1
	sub	mounty(pc),d1
	cmp	#256,d1
	bcc.s	.kill
	;
	cmp	d2,d0
	ble.s	.skip
	exg	d0,d2
.skip	move.l	(a2),a3
	mulu	#gamemod,d1
	add.l	d1,a3	;dest
	lea	44(a3),a3	;second bp
	move	d0,d1
	move	d2,d3
	asr	#3,d0
	add	d0,a3
	move.l	beam(pc),a4
	add	d0,a4
	asr	#1,d0
	asr	#4,d2
	sub	d0,d2
	addq	#1,d2
	or	#64,d2
	;
	move	d2,(a5)+
	move.l	a3,(a5)+
	;
	and	#15,d1
	and	#15,d3
	add	d1,d1
	add	d3,d3
	move	fwms(pc,d1),d1	;fwm
	swap	d1
	move	lwms(pc,d3),d1	;lwm
	;
	bwait
	move.l	d1,fwm(a6)
	move.l	a4,apth(a6)
	move.l	a3,dpth(a6)
	move	d2,size(a6)
	;
	bra	.loop
	;
.done	clr	(a5)
	rts

fwms	dc	$ffff,$7fff,$3fff,$1fff
	dc	$0fff,$07ff,$03ff,$01ff
	dc	$00ff,$007f,$003f,$001f
	dc	$000f,$0007,$0003,$0001
	
lwms	dc	$8000,$c000,$e000,$f000
	dc	$f800,$fc00,$fe00,$ff00
	dc	$ff80,$ffc0,$ffe0,$fff0
	dc	$fff8,$fffc,$fffe,$ffff

minshy	equ	96
maxshy	equ	256-minshy

movey	move.l	syspeed(pc),d2
	add.l	d2,shipy
	move	shipy(pc),d1
	cmp	#maxy-7-maxyspeed,d1
	bcc.s	.undo
	cmp	#16,d1
	bcs.s	.undo
	add.l	d2,screeny
	move	screeny(pc),d1
	tst.l	d2
	bmi.s	.tst2
	cmp	#maxshy,d1
	bcc.s	.yover
	rts
.tst2	cmp	#minshy,d1
	bcs.s	.yunder
	rts
.undo	sub.l	d2,shipy
	rts
.yover	;y too much!
	add.l	d2,mounty
	cmp	#maxy2-224,mounty
	bcc.s	.undo2
	sub.l	d2,screeny
	rts
.undo2	sub.l	d2,mounty
	rts
.yunder	add.l	d2,mounty
	bmi.s	.undo2
	sub.l	d2,screeny
	rts

moveship	;get keyboard control into:
	;
	;d7 : -1 if thrust
	;d6 : -1 if reverse
	;d5 : -1 if up
	;d4 : -1 if down
	;
	move	cmode(pc),d0
	beq.s	.joystick
	chkkey	$63
	sne	d5
	chkkey	$60
	sne	d4
	moveq	#0,d6
	chkkey	$64
	beq.s	.norev
	move.b	lastrev(pc),d0
	bne.s	.rev2
	not.b	lastrev
	moveq	#-1,d6
	bra.s	.rev2
.norev	clr.b	lastrev
.rev2	chkkey	$39
	sne	d7
	;
	bra	.gotmove
	;
.joystick	move	$00c(a6),d0
	move	d0,d1
	add	d1,d1
	eor	d0,d1	;up down bits...
	btst	#9,d1
	sne	d5
	;
	btst	#1,d1
	sne	d4
	;
	move	shipdir(pc),d1
	bne.s	.left
	;
	;facing rite...
	;
	btst	#1,d0
	sne	d7
	btst	#9,d0
	sne	d6
	bra.s	.gotmove
	;
.left	btst	#9,d0
	sne	d7
	btst	#1,d0
	sne	d6
	;
.gotmove	;
	tst.b	d4
	bne	.movedown
	tst.b	d5
	beq	.nodown
	;
	;move upwards!
	;
	move	syspeed(pc),d0
	blt.s	.uptst
	move	#-minyspeed,syspeed
	bra.s	.moveud
.uptst	cmp	#-maxyspeed,syspeed
	bge.s	.subacc
	move	#-maxyspeed,syspeed
	bra.s	.moveud
.subacc	sub.l	#yacc,syspeed
.moveud	bsr	movey
	bra.s	.uddone
	;
.movedown	move	syspeed(pc),d0
	bgt.s	.downtst
	move	#minyspeed,syspeed
	bra.s	.moveud
.downtst	cmp	#maxyspeed,syspeed
	blt.s	.addacc
	move	#maxyspeed,syspeed
	bra.s	.moveud
.addacc	add.l	#yacc,syspeed
	bra	.moveud
	;
.undo	sub.l	d2,shipy
.nodown	clr.l	syspeed
.uddone	;
	eor.b	d6,shipdir
	move.l	sxspeed(pc),d5
	move	d7,d6
	and	#24,d6
	move	d6,$0d8(a6)
	and	#4,d7
	move	d7,thrustframe
	beq.s	.nothrust
	;
	;thrust!
	;
	move	shipdir(pc),d4
	bne.s	.left2
	;
	add.l	#thrust,d5
	bpl.s	.axe1
	add.l	#thrust2,d5
.axe1	cmp.l	#maxthrust,d5
	ble.s	tdone
	move.l	#maxthrust,d5
	bra	tdone
	;
.left2	sub.l	#thrust,d5
	bmi.s	.axe2
	sub.l	#thrust2,d5
.axe2	cmp.l	#-maxthrust,d5
	bge.s	tdone
	move.l	#-maxthrust,d5
	bra.s	tdone
	;
.nothrust	tst.l	d5
	bpl.s	.pos
	;
	add.l	#friction,d5
	bmi.s	tdone
	bra.s	.tclear
	;
.pos	sub.l	#friction,d5
	bpl.s	tdone
.tclear	moveq	#0,d5
tdone	;
	move.l	d5,sxspeed	;how fast ship is going
	move.l	d5,xspeed
	bpl.s	.skip
	neg.l	d5
.skip	lsl.l	#3,d5
	;
	move.l	#restx<<16,d0
	move	shipdir(pc),d1
	beq.s	.skip2
	move.l	#(320-restx)<<16,d0
	neg.l	d5
.skip2	;d0 is where we wanna be!
	add.l	d5,d0
	sub.l	screenx(pc),d0
	cmp.l	#2<<16,d0
	bgt.s	.fix1
	cmp.l	#-2<<16,d0
	bge.s	.ok
	move.l	#-2<<16,d0
	bra.s	.ok
.fix1	moveq	#2,d0
	swap	d0
.ok	sub.l	d0,xspeed
	add.l	d0,screenx
	;
	rts

shipoff	move	#-64,d0
	move	#112,d1
	moveq	#0,d2
	bra	showsprite

showship	;
	move	screenx(pc),d0
	move	screeny(pc),d1
	add.l	#$4000,shipframe
	move	shipframe(pc),d2
	and	#1,d2
	move	shipdir(pc),d3
	beq.s	.skip
	addq	#2,d2
.skip	add	thrustframe(pc),d2
	;
showsprite	;
	move.l	ship(pc),a0		;get sprite data
	;
	add	#128-16,d0
	add	#sly+56-16,d1
	;
	lsl	#2,d2
	add.l	0(a0,d2),a0		;correct frame
	lea	sprites8(pc),a1	;coplist
	lea	4(a0),a2		;first sprite start
	move.l	a2,a3
	add	2(a0),a3		;second sprite data
	;
	move	d1,d4
	add	(a0),d4
	;
	move.b	d1,(a2)
	move.b	d1,(a3)
	move.b	d4,2(a2)
	move.b	d4,2(a3)
	;
	moveq	#0,d5
	roxl	#8,d1
	roxl	#1,d5
	roxl	#8,d4
	roxl	#1,d5
	roxr	#1,d0
	roxl	#1,d5
	;
	move.b	d0,1(a2)
	addq	#8,d0
	move.b	d0,1(a3)
	move.b	d5,3(a2)
	move.b	d5,3(a3)
	;
	move.l	a2,d0
	move	d0,6(a1)
	swap	d0
	move	d0,2(a1)
	move.l	a3,d0
	move	d0,8+6(a1)
	swap	d0
	move	d0,8+2(a1)
	;
	rts

dostars	move.l	stars2(pc),a0
	move.l	starsp(pc),a1
	move.l	spxtable(pc),a2
	move.l	spytable(pc),a3
	;
	move.l	xspeed(pc),d0
	move	#320,d6
	move	#224,d5
	;
	move	#numstars-1,d7
	move	mounty(pc),d3
.loop0	lea	14(a0),a0
	cmp	4(a0),d3
	bgt.s	.loop0
	;
.loop	move	4(a0),d2
	sub	d3,d2
	cmp	d5,d2
	bcc.s	.done
	;
	move.l	d0,d1
	move	12(a0),d4
	asr.l	d4,d1
	sub.l	d1,(a0)
	bpl.s	.skip
	add	d6,(a0)
	bra.s	.skip2
.skip	cmp	(a0),d6
	bhi.s	.skip2
	sub	d6,(a0)
.skip2	;
	;now, make a sprite of this star!
	;
	move	(a0),d1
	lsl	#2,d1
	lsl	#2,d2
	move.l	0(a2,d1),d1
	or.l	0(a3,d2),d1
	move.l	d1,(a1)+
	move.l	8(a0),(a1)+
	;
.next	lea	14(a0),a0
	dbf	d7,.loop
	;
.done	clr.l	(a1)
	rts

moveback	prepblit1
	move	shipx(pc),d6
	lsr	#4,d6
	subq	#1,d6
	move.l	xspeed(pc),d7
	bmi.s	.doit
	add	#22,d6
.doit	and	#255,d6
	move	backx(pc),d5
	lsr	#4,d5
	move	d6,d0
	move	d5,d1
	subq	#1,d1
	bsr	putmount
	move	d6,d0
	move	d5,d1
	add	#21,d1
	bsr	putmount
.skip	add.l	d7,shipx
	and	#4095,shipx
	add.l	d7,backx
	move	backx(pc),d0
	cmp	#16,d0
	bcc.s	.ok1
	add	#352,d0
	move	d0,backx
	rts
.ok1	cmp	#368,d0
	bcs.s	.done
	sub	#352,d0
	move	d0,backx
.done	rts

showback	move	#7,mountwait
	move	#maxy2-224,d0
	sub	mounty(pc),d0
	add	#sly+56,d0
	cmp	#256,d0
	bcs.s	.skip
	move	#$ffe1,mountwait
.skip	move.b	d0,mountwait+4
	;
	lea	gameback(pc),a1
	move.l	back(pc),a0
	move	backx(pc),d0
	subq	#1,d0
	move	d0,d1
	and	#15,d1
	eor	#15,d1
	lsl	#4,d1
	asr	#3,d0
	add	d0,a0
	move.l	a0,d0
	move	d1,(a1)+
	moveq	#88,d1
	move	d0,6(a1)
	swap	d0
	move	d0,2(a1)
	swap	d0
	add.l	d1,d0
	move	d0,6+8(a1)
	swap	d0
	move	d0,2+8(a1)
	rts

putmount	;d0=mount block # (0-255),
	;d1=dest block (0-43).
	;
	;blitter already set up !
	;
	move.l	mounts(pc),a0
	lsl	#4,d0
	add	d0,a0
	move.l	mounttab(pc),a1
	add	d1,d1
	move	d1,d2
	lsl	#2,d1
	add	d1,a1
	move.l	back(pc),a2
	add	d2,a2
	move	2(a0),d2
	sub	2(a1),d2
	bls.s	.skip
	addq	#1,d2
	bwait
	move	#$100,$040(a6)
	move.l	4(a1),$054(a6)
	move	d2,$058(a6)
	;
.skip	move.l	(a0)+,(a1)+
	add.l	(a0)+,a2
	move.l	a2,(a1)
	move	(a0)+,d2
	add.l	(a0),a0
	lea	-10(a0),a0
	bwait
	move	#$9f0,$040(a6)
	move.l	a0,$050(a6)
	move.l	a2,$054(a6)
	move	d2,$058(a6)
	rts

backcls	move.l	mounttab(pc),a0
	moveq	#43,d0
.loop	move	#224,(a0)+
	move	#224*128,(a0)+
	move.l	#224*176,(a0)+
	dbf	d0,.loop
	;
	move.l	back(pc),a0
	move.l	#88*224*2,d0
	bra	clsa0d0

frontcls	move.l	front1(pc),a0
	move.l	#44*256*3*2,d0
	;
clsa0d0	lsr.l	#2,d0
	moveq	#0,d1
.loop	move.l	d1,(a0)+
	subq.l	#1,d0
	bne.s	.loop
	rts

dodb	;show db:db=1-db:unqueue db:use bitmap db
	;
	move.l	dbat(pc),a0
	;
	move.l	(a0),a1
	lea	gamemod*16(a1),a1
	move.l	a1,d0
	moveq	#44,d1
	lea	gamefront(pc),a1
	move	d0,6(a1)
	swap	d0
	move	d0,2(a1)
	swap	d0
	add.l	d1,d0
	move	d0,6+8(a1)
	swap	d0
	move	d0,2+8(a1)
	swap	d0
	add.l	d1,d0
	move	d0,6+16(a1)
	swap	d0
	move	d0,2+16(a1)
	;
	lea	front1(pc),a1
	cmp.l	a1,a0
	bne.s	.skip
	lea	front2(pc),a1
.skip	move.l	a1,dbat
	rts

allocstuff	move.l	4.w,a6
	move.l	#88*224*2,d0
	moveq	#2,d1
	jsr	-198(a6)
	move.l	d0,back
	move.l	#44*272*3*2,d0
	moveq	#2,d1
	jsr	-198(a6)
	move.l	d0,front1
	add.l	#44*272*3,d0
	move.l	d0,front2
	rts

freestuff	move.l	4.w,a6
	move.l	front1(pc),a1
	move.l	#44*272*3*2,d0
	jsr	-210(a6)
	move.l	back(pc),a1
	move.l	#88*224*2,d0
	jmp	-210(a6)

ICR	equ	$bfed01
BICR	equ	$bfdd00
CRA	equ	$bfee01
SDR	equ	$bfec01
TAHI	equ	$bfe501
TALO	equ	$bfe401

l2int1	;handle interupt - either timer done or serial got...
	;
	move	#8,$dff09c
	;
	btst	#3,ICR	;serial done?
	beq	l2int2	;no!
	;
	or.b	#$41,CRA	;serial output/start timer
	;
	movem.l	a0/d0-d1,-(a7)
	;
	moveq	#0,d0
	move.b	SDR,d0
	not.b	d0
	ror.b	#1,d0	;to normal raws
	;
	;Set our raw matrix flags...
	;
	move	d0,d1
	lsr	#3,d1
	cmp	#32,d1
	bcc.s	.skip2
	;
	lea	rawmat(pc),a0
	bclr	#4,d1
	bne.s	.skip
	bset	d0,0(a0,d1)
	move	getasc(pc),d1
	beq.s	.skip2	;no ascii conversion.
	;
	lea	raws(pc),a0
.loop	tst.b	(a0)
	bmi.s	.skip2
	cmp.b	(a0)+,d0
	beq.s	.found
	addq	#1,a0
	bra.s	.loop
.found	;(a0)=ascii code.
	move.b	(a0),d0
	move	asciip(pc),d1
	lea	asciis(pc),a0
	move.b	d0,0(a0,d1)
	addq	#1,asciip
	and	#15,asciip
	bra.s	.skip2
	;
.skip	bclr	d0,0(a0,d1)
	;
.skip2	movem.l	(a7)+,d0-d1/a0
	;
	rte

l2int2	and.b	#$be,CRA	;serial back to input. stop timer.
	;
	rte

l2setup	move.l	#l2int1,$68
	move.b	#$7f,ICR
	move.b	#$7f,BICR
	move.b	#$89,ICR
	move.b	#8,CRA	;one shot!
	move.b	#64,TALO
	move.b	#0,TAHI
	rts

rawmat	ds.b	16  ;raw key matrix.

asciig	dc	0	;get asciis from here.
asciip	dc	0	;put ascii from here.
asciis	ds.b	16	;16 ascii codes.

raws	incbin	raw.bin
getasc	dc	0	;set to -1 to read ascii vals.

intname	dc.b	'intuition.library',0
	even

sysoff	lea	intname(pc),a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,d6
	lea	dosname(pc),a1
	jsr	-408(a6)
	move.l	d0,a6
	moveq	#99,d7
	;
.closewb	exg	a6,d6
	jsr	-78(a6)		;closewb
	exg	a6,d6
	moveq	#1,d1
	jsr	-198(a6)		;delay
	move	d7,$dff180
	dbf	d7,.closewb
	;
	move.l	#$dff000,a6
	;
	move	$01c(a6),intena
	or	#$c000,intena
	move	#$3fff,$09a(a6)
	move	#$0400,$096(a6)
	;
	move.l	$70,oldl4int
	move.l	$6c,oldl3int
	move.l	$68,oldl2int
	;
	bsr	l2setup
	;
	move.l	#l4int1,$70
	move	#$3fff,$09c(a6)
	move	#$c008,$09a(a6)
	move	#0,con1(a6)
	move	#$f,$096(a6)
	;
initthrust	move	#0,$0d8(a6)		;vol 3 off.
	lea	thrust.inc,a0
	move	(a0)+,$0d6(a6)
	move	(a0)+,$0d4(a6)
	move.l	a0,$0d0(a6)
	move	#$8068,$096(a6)
	;
	rts

grname	dc.b	'graphics.library',0
	even

syson	bwait
	move	#$7fff,$dff09a
	move.l	oldl2int(pc),$68
	move.l	oldl3int(pc),$6c
	move.l	oldl4int(pc),$70
	lea	grname(pc),a1
	move.l	4.w,a6
	jsr	-408(a6)
	move.l	d0,a0
	move.l	38(a0),$dff080
	move	d0,$dff088
	move	#$7fff,$dff09c
	move	intena(pc),$dff09a
	rts

;********** DATA - POINTERS FIRST *******************************

data	;4 bytes and under
	;
playerdat
tokill	dc	0	aliens left to kill
inspace	dc	-1
playerdie	dc	0	;non zero if player killed!
pattern	dc	0
scoremore	dc.l	$00001000	;to get free man score.
score	dc.l	0	;BCD!
ships	dc	3
smarts	dc	3
inviso	dc	24,0
cmode	dc	-1	;non zero=keyboard
playerdatf	;
	bra	beginadd
	bra	endadd
	bra	implode
	bra	explode
	bra	rnd1
	bra	rnd2
	bra	getmounty
	bra	newanim
	bra	killme
	bra	rnd3
	bra	chkinfront
shipx	dc.l	0
shipy	dc.l	(288+112)<<16
sxspeed	dc.l	0		;ship x speed
syspeed	dc.l	0
shipdir	dc.l	0		;plus=rite
	bra	homeawayy
	bra	homeiny
	bra	homeawayya
	bra	homeinya
	bra	limitys
screenx	dc.l	160<<16
screeny	dc.l	128<<16
	bra	getxdiff
	bra	findid
	dc.l	0
	bra	scanprint
	bra	firebull1
	bra	addscore
	bra	killplayer
	bra	warpplayer
	bra	homeawayx
	bra	homeinx
	bra	homeawayxa
	bra	homeinxa
	bra	limitxs
	bra	rndrange
	bra	getydiff
	bra	getrealx
smarton	dc.b	0
invisoon	dc.b	0
lastsmart	dc.b	0
lastrev	dc.b	0
lastfire	dc.b	0
	even
	bra	sysfirebull
	bra	dropbomb
	bra	sysinitbull
	bra	sysdropbomb
onscreen	dc	0
	bra	firemiss
	bra	sysfiremiss
	bra	homecalc
	bra	sysfirekill
	bra	calcnum
	bra	rndoffsc
	bra	getoffsc
	bra	killme2
	bra	playsfx
	bra	gospace
	bra	dobonus
	bra	killme3
	
hites	dc.l	mounts.inc
xspeed	dc.l	0		;actual x speed
shipframe	dc.l	0		;frame - 0 to 3
thrustframe	dc	0	;4=thrusting...
mounty	dc.l	(maxy2-224)<<16
back	dc.l	0
backx	dc.l	352<<16
vflag	dc	0
	;
dbat	dc.l	front1	;used bitmap
front1	dc.l	0
	dc.l	lasersq.ds
	dc.l	fragsq.ds
	dc.l	aliensq.ds
	dc.l	bullsq.ds
front2	dc.l	0
	dc.l	lasersq2.ds
	dc.l	fragsq2.ds
	dc.l	aliensq2.ds
	dc.l	bullsq2.ds

spattern	dc	0	;start pattern

oldl2int	dc.l	0	;old ports int
oldl3int	dc.l	0	;old vertb int
oldl4int	dc.l	0	;old audio int

objects	dc.l	0
perloops	dc.l	perloops.ds

last	dc	0
sweor	dc	0
intena	dc	0

mounts	dc.l	mounts.inc+4096
mounttab	dc.l	mounttab.ds

ship	dc.l	ship.inc

spxtable	dc.l	spxtable.ds
spytable	dc.l	spytable.ds
stars	dc.l	stars.dc
stars2	dc.l	stars.dc-14
starsp	dc.l	starsp.ds

beam	dc.l	beam.ds

glow	dc.l	glow.inc

glow1	dc.l	0
glow2	dc.l	0

scan1	dc.l	scan1.ds	;for scanner details...
scan2	dc.l	scan2.ds	;for mountains on scanner...
scan3	dc.l	scan3.ds

scantab	dc.l	scantab.dc
scant1	dc	0
scant2	dc	0

font	dc.l	font.inc-512

stextstuff	;
textpri	dc.b	0	;priority of scanner text.
texttype	dc.b	0
texttime	dc	0

scansprite	dc.l	scansprite.dc
shipsprite	dc.l	shipsprite.dc

little	dc.l	little.inc
clxdat	dc	0
clxdat2	dc	0
loopcode	dc.l	0
whydone	dc	0	;0 = player killed, else pattern over
blowup	dc.l	blowup.inc
	;
upall	;
upscore	dc.b	0	;flag for update score
upships	dc.b	0
upsmarts	dc.b	0
upinviso	dc.b	0
	;
newscore	dc.l	0
scoreten	dc.l	$00001000	;ten grand!

playerdat2	ds.b	playerdatf-playerdat
	;
	;
safeint	dc.l	0	;safe int.
defint	dc.l	0	;default int routine

shipblow	dc.l	shipblow.inc

letters	dc	0	;letters left

smartcol	dc	0	;color for smart bomb!
smartsub	dc	0
scanu	dc.l	0
playerup	dc	-1	;0=player 1, 1=player 2
			;<0=1 player game
playerwarp	dc	0
warpx	dc	0

oblivion	dc.l	oblivion.inc
introon	dc	0
keys	dc.l	keys.inc
lastf3	dc.b	0
lastf4	dc.b	0
lastf5	dc.b	0
lastf6	dc.b	0
messx	dc.l	0

message	dc.l	message.inc
messageat	dc.l	message.inc

invblob	dc.l	invblob.inc

warps	dc.l	warp2.inc,warp.inc,warp3.inc,warp4.inc

audio	dc.l	audio.ds
laser.sfx	dc.l	laser.inc
aliendie.sfx	dc.l	aliendie.inc
aliendie2.sfx	dc.l	aliendie2.inc
alienfire.sfx	dc.l	alienfire.inc
shipdie.sfx	dc.l	shipdie.inc
alienfire2.sfx	dc.l	alienfire2.inc
warp.sfx	dc.l	warpsfx.inc
freelife.sfx	dc.l	freelife.inc

;********** COPPER LIST *****************************************

rndpal	dc	$180,$000,$182,$f00,$184,$0f0,$186,$00f
	dc	$188,$ff0,$18a,$f0f,$18c,$0ff,$18e,$fff
	dc	-1

scanpal	dc	$180,$000,$182,$fff,$184,$0ff,$186,$fc0
	dc	$188,$4b0,$18a,$08f,$18c,$f20,$18e,$000
	dc	$190,$000,$192,$028,$194,$802,$196,$876
	dc	$1a8,$000,$1aa,$fff
kludge	dc	$1b0,$000,$1b2,$008,$1b4,$fff
	dc	-1

gamepal	dc	$182,$fff,$186,$fc0
	dc	$188,$f20,$18a,$08f,$18c,$f09,$18e,$4b0
	dc	$190,$000,$192,$aaa,$194,$000,$196,$555
	dc	$198,$000,$19a,$aaa,$19c,$000,$19e,$555
shippal	dc	$1a0,$000,$1a2,$fff,$1a4,$f90,$1a6,$c00
	dc	$1a8,$000,$1aa,$088,$1ac,$f08,$1ae,$002
	dc	$1b0,$000,$1b2,$888,$1b4,$008,$1b6,$808
	dc	$1b8,$000,$1ba,$ccc,$1bc,$888,$1be,$444
	dc	-1

keypal	dc	$180,$000,$182,$b74,$184,$000,$186,$853
	dc	$188,$0c0,$18a,$fc0,$18c,$000,$18e,$000
	dc	$190,$000,$192,$060,$194,$600,$196,$666
	dc	$1a8,$000,$1aa,$fff
kludgez	dc	$1b0,$000,$1b2,$008,$1b4,$fff
	dc	-1

coplist	;
	;common display setup...
	;
	dc	$1fc,0
	dc	$100,$5600,$102,0,$104,%0011010
	dc	$8e,(sly<<8)+$81,$90,$34c1,$92,$0030,$94,$00d0
	;
	;scanner information...
	;
scanfront	dc	$e0,0,$e2,0,$e8,0,$ea,0,$f0,0,$f2,0
	dc	$102,0
backtext	dc	$e4,0,$e6,0,$ec,0,$ee,0
	dc	$108,120-42,$10a,50-42
	;
scanrgbs	dcb.l	32,$01fe0000
kludge2	equ	scanrgbs+32
	;
	dc	(24<<8)+1,$fffe
	;
sprites8	dc	$120,0,$122,0
sprites7	dc	$124,0,$126,0
sprites6	dc	$128,0,$12a,0
sprites5	dc	$12c,0,$12e,0
sprites4	dc	$130,0,$132,0
sprites3	dc	$134,0,$136,0
sprites2	dc	$138,0,$13a,0
sprites1	dc	$13c,0,$13e,0
	;
	dc	((sly-1)<<8)+7,$fffe
bdc1	dc	$180,$fff
	dc	(sly<<8)+7,$fffe,$180,0
	;
swait1	dc	(10+sly)<<8+1,$fffe,$196
sglow1	dc	0
swait2	dc	(11+sly)<<8+1,$fffe,$196
	dc	0
	dc	(12+sly)<<8+1,$fffe,$196
	dc	0
	dc	(13+sly)<<8+1,$fffe,$196
	dc	0
	dc	(14+sly)<<8+1,$fffe,$196
	dc	0
	dc	(15+sly)<<8+1,$fffe,$196
	dc	0
	dc	(16+sly)<<8+1,$fffe,$196
	dc	0
	dc	(17+sly)<<8+1,$fffe,$196
	dc	0
	;
	dc	(28+sly)<<8+1,$fffe
	;
	dc	$102,0
scanback	dc	$e4,0,$e6,0,$ec,0,$ee,0
kludge3	dc	$10a,96-42,$196,$888
	;
	;game information...
	;
	dc	(55+sly)<<8+7,$fffe
bdc2	dc	$180,$fff,$096,$0100
	;
gamefront	dc	$e0,0,$e2,0,$e8,0,$ea,0,$f0,0,$f2,0
	dc	$102
gameback	dc	0,$e4,0,$e6,0,$ec,0,$ee,0
	dc	$108,gamemod-42,$10a,-42
	;
gamergbs	dcb.l	6,copnop
mrgbs	dcb.l	8,copnop
shiprgbs	dcb.l	32-14,copnop
	;
	dc	(56+sly)<<8+7,$fffe
scrnrgb	dc	$180,$000,$096,$8100
	;
	;sprites...
	;
mountwait	dc	7,$fffe	;for line 255 wait...
	dc	(56+sly)<<8+7,$fffe
	dc	$10a,176-42
	;
	dc	$ffff,$fffe

titpal	incbin	tit.pal
	dc	-1

titlist	dc	$1fc,0
	dc	$100,$4200,$102,0,$104,0
	dc	$8e,(sly<<8)+$81,$90,$34c1,$92,$0038,$94,$00d0
	dc	$108,160-40,$10a,160-40
	;
titbps	dc	$e0,0,$e2,0,$e4,0,$e6,0,$e8,0,$ea,0,$ec,0,$ee,0
	;
titrgbs	dcb.l	32,copnop
	;
	dc	(26<<8)+1,$fffe
	dc	$140,0,$142,0,$148,0,$14a,0
	dc	$150,0,$152,0,$158,0,$15a,0
	dc	$160,0,$162,0,$168,0,$16a,0
	dc	$170,0,$172,0,$178,0,$17a,0
	;
	dc	$ffff,$fffe

;********** TABLES **********************************************

tables
mounts.inc	incbin	mounts.bin
stars.dc	incbin	stars.bin
glow.inc	incbin	glow.bin
glowx.ds	ds	32	;extra 32
blowup.inc	incbin	blowup.bin
audio.ds	ds.b	audiosize*3
audiof.ds	;

;********** BUFFERS *********************************************

buffers	;
	;
mounttab.ds	ds.b	44*8
spxtable.ds	ds.l	320
spytable.ds	ds.l	224
starsp.ds	ds.l	numstars*2+1
perloops.ds	ds.l	maxobjs+1
beam.ds	incbin	beam.bin
	;
	cnop	0,4
info	;
read	equ	info+260
	;
lasersq.ds	ds.b	6*maxlasers+2
lasersq2.ds	ds.b	6*maxlasers+2
fragsq.ds	ds.l	maxfrags+1
fragsq2.ds	ds.l	maxfrags+1
aliensq.ds	ds.b	6*maxaliens+2
aliensq2.ds	ds.b	6*maxaliens+2
bullsq.ds	ds.l	maxbulls+1
bullsq2.ds	ds.l	maxbulls+1
scan1.ds	ds.b	40*57*3	;front panel
scan2.ds	ds.b	48*28*2	;mounts
scan3.ds	ds.b	50*28	;text in scanner (24 wide!)
scantab.dc	dc.l	scanc0,scanc1,scanc2,scanc3
	dc.l	scanc4,scanc5,scanc6,scanc7
	;
scanc0	dc	$0000,$0000,$0000
scanc1	dc	$c000,$0000,$0000
scanc2	dc	$0000,$c000,$0000
scanc3	dc	$c000,$c000,$0000
scanc4	dc	$0000,$0000,$c000
scanc5	dc	$c000,$0000,$c000
scanc6	dc	$0000,$c000,$c000
scanc7	dc	$c000,$c000,$c000

;********** SOUND EFFECTS ***************************************

sfx

warpsfx.inc	incbin	warp.bsx
shipdie.inc	incbin	shipdie.bsx
alienfire2.inc	incbin	alienfire2.bsx
laser.inc	incbin	laser.bsx
aliendie.inc	incbin	aliendie.bsx
aliendie2.inc	incbin	aliendie2.bsx
alienfire.inc	incbin	alienfire.bsx
thrust.inc	incbin	thrust.bsx
freelife.inc	incbin	freelife.bsx

;********** GRAFIX **********************************************

grafix

warp.inc	incbin	warp.frags
warp2.inc	incbin	warp2.frags
warp3.inc	incbin	warp3.frags
warp4.inc	incbin	warp4.frags
	;
invblob.inc	incbin	invblob.frags
keys.inc	incbin	keys.bin
oblivion.inc	incbin	oblivion.bin
shipblow.inc	incbin	shipblow.frags
little.inc	incbin	little.bin
ship.inc	incbin	ship.bin
font.inc	incbin	font.bin
	;
scansprite.dc	
	dc	(sly<<8)+(280>>1),((sly+3)<<8)+1
	dc	$ffff,0
	dc	$c003,0
	dc	$8001,0
scansprite2.dc
	dc	((sly+52)<<8)+(280>>1),((sly+55)<<8)+1
	dc	$8001,0
	dc	$c003,0
	dc	$ffff,0

	dc.l	0
shipsprite.dc	dc	0,0
	dc	0,$4000
	dc	0,$e000
	dc	0,$4000
	dc.l	0

edgesprite1	dc	(sly<<8)+((7*8+128)>>1),(sly+56)<<8
	rept	56	;getting lazy!
	dc	%0000001000000000,0
	endr
zero	dc.l	0

edgesprite2	dc	(sly<<8)+((31*8+128)>>1),(sly+56)<<8
	rept	56
	dc	%0000000001000000,0
	endr
	dc.l	0

message.inc	incbin	blurb.bin
	dc.b	0
	even

