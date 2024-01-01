#Macros for use in BitMap Proj
#Thiago Ciriaco
#April 25 2021

.eqv 	WIDTH 	64
.eqv 	HEIGHT 	32
#pixel (0,0) mem address
.eqv 	COLOR_MEM 	0x10010000
.eqv	INPUT_MEM	0xffff0004
#all colors used
.eqv	RED		0x00FF0000
.eqv	GREEN		0x0000FF00
.eqv	BLUE		0x000000FF	
.eqv	WHITE		0x00FFFFFF
.eqv	YELLOW		0x00FFFF00
.eqv	CYAN		0x0000FFFF
.eqv	MAGENTA		0x00FF00FF
.eqv	GRAY		0x00818181
.eqv	DARK_GRAY	0x00515151
.eqv	ORANGE		0x00FF6600

#macros to print int, char, and string, get string from user,

.macro sleep(%n) #implements a sleep for n ms
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)
	
	addi	$a0, $0, %n
	addi	$v0, $0, 32
	syscall
	
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4

.end_macro
	
	
.macro	printInt (%n) #takes register or immediate and prints int value
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)

	li	$v0, 1
	add	$a0, $zero, %n
	syscall
	
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
.end_macro 


.macro	printString (%str) #takes a string in quotes to print
	.data
	string:	.asciiz %str
	.text
	
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)
	
	li	$v0, 4
	la	$a0, string
	syscall
	
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
.end_macro


.macro	printChar (%c) #takes register or immediate and prints char value
	li	$v0, 11
	add	$a0, $zero, %c
	syscall
.end_macro
	

.macro drawPixel() #a0 = x, $a1 = y, $a2 = color; 
	   #Draws a pixel at the x,y position
	
	mul	$s1, $a1, WIDTH
	
	bge	$a0, WIDTH, noDraw #dont draw if out of bounds
	bge	$a1, HEIGHT, noDraw
	
	add	$s1, $s1, $a0
	mul	$s1, $s1, 4
	add	$s1, $s1, COLOR_MEM
	sw	$a2, 0($s1)
	
	noDraw:
.end_macro

 
.macro getPixelColor() #a0 = x, $a1 = y 
	   #returns a pixel value from the x,y position -> v1
	
	mul	$s1, $a1, WIDTH
	
	bge	$a0, WIDTH, invalid #dont grab pixel if OOB
	bge	$a1, HEIGHT, invalid
	
	add	$s1, $s1, $a0
	mul	$s1, $s1, 4
	add	$s1, $s1, COLOR_MEM
	lw	$v1, 0($s1)
	
	invalid:
.end_macro

.macro drawPixelBS(%n) #a0 = x, $a1 = y, $a2 = color, brush size %n
	   #Draws pixel(s) at the x,y position, with brush size n x n up to 3x3
	     
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)
	addi	$sp, $sp, -4	# push $a1 to preserve
	sw	$a1, 0($sp)
	
	add	$t6, $0, %n	#t6 contains brush size
	blt	$t6, 3, lt3
	
	#size 3 outer L
	addi	$a0, $a0, 2
	drawPixel
	addi	$a1, $a1, 1
	drawPixel			#XXO
	addi	$a1, $a1, 1		#XXO	O=drawn, cursor at top left
	drawPixel			#OOO
	addi	$a0, $a0, -1
	drawPixel
	addi	$a0, $a0, -1
	drawPixel
	
	#reset pos
	addi	$a1, $a1, -2
lt3:
	blt	$t6, 2, lt2		
	#size 2 outer L
	addi	$a0, $a0, 1		#XOX
	drawPixel			#OOX	O=drawn, cursor at top left
	addi	$a1, $a1, 1		#XXX
	drawPixel
	addi	$a0, $a0, -1
	drawPixel
	
	#reset pos
	addi	$a1, $a1, -1
lt2:
	drawPixel			#draws just origin	#OXX
								#XXX
								#XXX		
	lw	$a1, 0($sp)	# pop $a1 back
	addi	$sp, $sp, 4
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
	
.end_macro

.macro	blackout() #resets all bitmap pixels to 0 for a hard reset (avoids crashes)
	addi	$s0, $0, COLOR_MEM #set-up for clear
	addi	$s1, $0, 0
	addi	$s2, $0, WIDTH
	addi	$s3, $0, HEIGHT
	
	mul	$s2, $s2, $s3	#s2 = total pixels to clear
	
	move	$t0, $0		#t0 = counter
clearLoop:
	mul	$t3, $t0, 4
	add	$t2, $t3, $s0	#t2 = address of next pixel to clear 
	sw	$s1, 0($t2)	#"clear" paint by saving white to pixel
	
	addi	$t0, $t0, 1	#increment counter
	ble	$t0, $s2, clearLoop
.end_macro

.macro	resetScreen() #resets all bitmap pixels to white for a clean drawing slate
	addi	$s0, $0, COLOR_MEM #set-up for clear
	addi	$s1, $0, WHITE
	addi	$s2, $0, WIDTH
	addi	$s3, $0, HEIGHT
	
	mul	$s2, $s2, $s3	#s2 = total pixels to clear
	move	$t0, $0		#t0 = counter
clearLoop:
	mul	$t3, $t0, 4
	add	$t2, $t3, $s0	#t2 = address of next pixel to clear 
	sw	$s1, 0($t2)	#"clear" paint by saving white to pixel
	
	addi	$t0, $t0, 1	#increment counter
	ble	$t0, $s2, clearLoop
.end_macro

.macro	changeColor() #deselects current color and visually switches to another color in the UI, takes color a2
	addi	$sp, $sp, -4		# push $a0 to preserve
	sw	$a0, 0($sp)
	
	addi	$s0, $0, COLOR_MEM 	#set-up for select clear
	addi	$s1, $0, GRAY
	addi	$s2, $0, 28
	addi	$s3, $0, HEIGHT
	
	addi	$s2, $s2, -1	#s2 = total pixels to draw
	move	$t0, $0		#t0 = counter
	
clearSelect:
	mul	$t3, $t0, 4
	add	$t2, $t3, $s0	#t2 = address of next pixel to clear 
	sw	$s1, 0($t2)	#"draw" ui pixel by saving gray to pixel
	
	addi	$t0, $t0, 1	#increment counter
	ble	$t0, $s2, clearSelect

	
	addi	$a0, $0, 4	#reset a0 for algorithm
	
	beq	$a2, RED, redC			#1 = red
	beq	$a2, MAGENTA, magentaC		#2 = magenta
	beq	$a2, CYAN, cyanC		#3 = cyan
	beq	$a2, YELLOW, yellowC		#4 = yellow
	beq	$a2, BLUE, blueC		#5 = blue
	beq	$a2, 0, blackC			#6 = black
	beq	$a2, WHITE, whiteC		#7 = white
	beq	$a2, GREEN, greenC		#8 = green
	beq	$a2, ORANGE, orangeC		#9 = pink
	
	orangeC:			#adds 3 n times based on nth position in color display
	addi	$a0, $a0, 12		#fall thru is intentional, like switch with no break
	greenC:
	addi	$a0, $a0, 12
	whiteC:
	addi	$a0, $a0, 12
	blackC:
	addi	$a0, $a0, 12
	blueC:
	addi	$a0, $a0, 12
	yellowC:
	addi	$a0, $a0, 12
	cyanC:
	addi	$a0, $a0, 12
	magentaC:
	addi	$a0, $a0, 12
	redC:
	#addi	$t1, $0, 0
	addi	$t0, $0, DARK_GRAY
	addi	$t2, $a0, COLOR_MEM
	sw	$t0, 0($t2)	#select color by saving dark gray to pixel above it

	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
.end_macro

.macro	changeSize()		#VISUALLY indicates change to brush size in UI
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)
	addi	$sp, $sp, -4	# push $a1 to preserve
	sw	$a1, 0($sp)
	addi	$sp, $sp, -4	# push $a2 to preserve
	sw	$a2, 0($sp)
	
	li	$a0, 58		#clear prev setting
	li	$a1, 0
	li	$a2, GRAY
	li	$t0, 3
	drawPixelBS($t0)
	
	li	$a0, 58		#draw new UI size setting
	li	$a1, 0
	
	li	$a2, DARK_GRAY
	lw	$t0, size
	drawPixelBS($t0)
	
	lw	$a2, 0($sp)	# pop $a2 back
	addi	$sp, $sp, 4
	lw	$a1, 0($sp)	# pop $a1 back
	addi	$sp, $sp, 4
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
.end_macro

.macro	changeBG() #changes all canvas pixels to selected color, takes color $a2
	addi	$s0, $0, COLOR_MEM #set-up for clear
	li	$t2, WIDTH
	mul	$t0, $t2, 12 	#t0 contains starting address for bg change
	add	$t0, $t0, $s0
	
	li	$t1, HEIGHT
	mul	$t1, $t2, $t1	
	mul	$t1, $t1, 4
	add	$s0, $s0, $t1 	#s0 contains final address
loopBG:	
	beq	$s0, $t0, exitLoopBG
	sw	$a2, ($t0)
	addi	$t0, $t0, 4
	j	loopBG
exitLoopBG:
	
.end_macro

.macro	changeDrawState() #VISUALLY changes draw state from cursor to paint (x-pos47)
	
	#takes state -1 or 1 in a3 for move or draw respectively
	addi	$sp, $sp, -4	# push $a0 to preserve
	sw	$a0, 0($sp)
	addi	$sp, $sp, -4	# push $a1 to preserve
	sw	$a1, 0($sp)
	addi	$sp, $sp, -4	# push $a2 to preserve
	sw	$a2, 0($sp)
	
continueDrawState:

	#clear current:
	li	$a0, 46
	li	$a1, 0
	li	$a2, GRAY
	
	drawPixel
	addi	$a0, $a0, 1	#
	drawPixel		#
	addi	$a0, $a0, 1	#
	drawPixel		#
	addi	$a0, $a0, 1	#
	drawPixel		#
	addi	$a0, $a0, -3	#
	addi	$a1, $a1, 1	#
	drawPixel		#
	addi	$a0, $a0, 1	#clearing current X or Check
	drawPixel		#
	addi	$a0, $a0, 1	#
	drawPixel		#
	addi	$a0, $a0, -2	#
	addi	$a1, $a1, 1	#
	drawPixel		#
	addi	$a0, $a0, 1	#
	drawPixel		#
	addi	$a0, $a0, 1	#
	drawPixel		#
		
	#branch based on new state
	beq	$a3, 1, drawCheck
	
	#drawX
	li	$a0, 47
	li	$a1, 1
	li	$a2, RED
	drawPixel
	addi	$a1, $a1, -1
	addi	$a0, $a0, -1
	drawPixel
	addi	$a0, $a0, 2
	drawPixel
	addi	$a1, $a1, 2
	drawPixel
	addi	$a0, $a0, -2
	drawPixel
	addi	$a1, $a1, -2
	drawPixel
	j drawStateChanged

drawCheck:
	li	$a0, 47
	li	$a1, 2
	li	$a2, GREEN
	drawPixel
	addi	$a1, $a1, -1
	addi	$a0, $a0, -1
	drawPixel
	addi	$a0, $a0, 2
	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, -1
	drawPixel
drawStateChanged:
	lw	$a2, 0($sp)	# pop $a2 back
	addi	$sp, $sp, 4
	lw	$a1, 0($sp)	# pop $a1 back
	addi	$sp, $sp, 4
	lw	$a0, 0($sp)	# pop $a0 back
	addi	$sp, $sp, 4
.end_macro

.macro	filterGray
	addi	$s0, $0, COLOR_MEM #set-up for filter
	li	$t2, WIDTH
	mul	$t0, $t2, 12 	#t0 contains starting address for color change
	add	$t0, $t0, $s0
	
	li	$t1, HEIGHT
	mul	$t1, $t2, $t1	
	mul	$t1, $t1, 4
	add	$s0, $s0, $t1 	#s0 contains final address
loopGray:	
	beq	$s0, $t0, exitLoopGray
	lw	$t3, ($t0)	#t3 contains current pixel color
	beq	$t3, RED, redToGray
	beq	$t3, MAGENTA, magToGray
	beq	$t3, CYAN, cyaToGray
	beq	$t3, YELLOW, yelToGray
	beq	$t3, BLUE, bluToGray
	beq	$t3, 0, blaToGray
	beq	$t3, WHITE, whiToGray
	beq	$t3, GREEN, greToGray
	beq	$t3, ORANGE, oraToGray
next:
	addi	$t0, $t0, 4
	j	loopGray
redToGray:
	li	$t4, 0x004D4D4D
	sw	$t4, ($t0)
	j next
magToGray:
	li	$t4, 0x00696969
	sw	$t4, ($t0)
	j next
cyaToGray:
	li	$t4, 0x00B3B3B3
	sw	$t4, ($t0)
	j next
yelToGray:
	li	$t4, 0x00E3E3E3
	sw	$t4, ($t0)
	j next
bluToGray:
	li	$t4, 0x001C1C1C
	sw	$t4, ($t0)
	j next
blaToGray:	
		#black is already grayscaled
	j next
whiToGray:
		#white is already grayscaled
	j next
greToGray:
	li	$t4, 0x00969696
	sw	$t4, ($t0)
	j next
oraToGray:
	li	$t4, 0x00898989
	sw	$t4, ($t0)
	j next
exitLoopGray:
.end_macro

.macro	filterInvert
	addi	$s0, $0, COLOR_MEM #set-up for filter
	li	$t2, WIDTH
	mul	$t0, $t2, 12 	#t0 contains starting address for color change
	add	$t0, $t0, $s0
	
	li	$t1, HEIGHT
	mul	$t1, $t2, $t1	
	mul	$t1, $t1, 4
	add	$s0, $s0, $t1 	#s0 contains final address
loopInv:	
	beq	$s0, $t0, exitLoopInv
	lw	$t3, ($t0)	#t3 contains current pixel color
	beq	$t3, RED, redToInv
	beq	$t3, MAGENTA, magToInv
	beq	$t3, CYAN, cyaToInv
	beq	$t3, YELLOW, yelToInv
	beq	$t3, BLUE, bluToInv
	beq	$t3, 0, blaToInv
	beq	$t3, WHITE, whiToInv
	beq	$t3, GREEN, greToInv
	beq	$t3, ORANGE, oraToInv
next1:
	addi	$t0, $t0, 4
	j	loopInv
redToInv:
	li	$t4, CYAN
	sw	$t4, ($t0)
	j next1
magToInv:
	li	$t4, GREEN
	sw	$t4, ($t0)
	j next1
cyaToInv:
	li	$t4, RED
	sw	$t4, ($t0)
	j next1
yelToInv:
	li	$t4, BLUE
	sw	$t4, ($t0)
	j next1
bluToInv:
	li	$t4, YELLOW
	sw	$t4, ($t0)
	j next1
blaToInv:	
	li	$t4, WHITE
	sw	$t4, ($t0)
	j next1
whiToInv:
	li	$t4, 0
	sw	$t4, ($t0)
	j next1
greToInv:
	li	$t4, MAGENTA
	sw	$t4, ($t0)
	j next1
oraToInv:
	li	$t4, 0x000099FF
	sw	$t4, ($t0)
	j next1
exitLoopInv:
.end_macro

.macro	filterCool
	addi	$s0, $0, COLOR_MEM #set-up for filter
	li	$t2, WIDTH
	mul	$t0, $t2, 12 	#t0 contains starting address for color change
	add	$t0, $t0, $s0
	
	li	$t1, HEIGHT
	mul	$t1, $t2, $t1	
	mul	$t1, $t1, 4
	add	$s0, $s0, $t1 	#s0 contains final address
loopCool:	
	beq	$s0, $t0, exitLoopCool
	lw	$t3, ($t0)	#t3 contains current pixel color
	beq	$t3, RED, redToCool
	beq	$t3, MAGENTA, magToCool
	beq	$t3, CYAN, cyaToCool
	beq	$t3, YELLOW, yelToCool
	beq	$t3, BLUE, bluToCool
	beq	$t3, 0, blaToCool
	beq	$t3, WHITE, whiToCool
	beq	$t3, GREEN, greToCool
	beq	$t3, ORANGE, oraToCool
next2:
	addi	$t0, $t0, 4
	j	loopCool
redToCool:
	li	$t4, 0x00D06092
	sw	$t4, ($t0)
	j next2
magToCool:
	li	$t4, 0x00A260D0
	sw	$t4, ($t0)
	j next2
cyaToCool:
	#cant get cooler than cyan
	j next2
yelToCool:
	li	$t4, 0x0089D060
	sw	$t4, ($t0)
	j next2
bluToCool:
	li	$t4, 0x005E00FF
	sw	$t4, ($t0)
	j next2
blaToCool:	
	li	$t4, 0x001B0442
	sw	$t4, ($t0)
	j next2
whiToCool:
	li	$t4, 0x00CDECEC
	sw	$t4, ($t0)
	j next2
greToCool:
	li	$t4, 0x0000FF6D
	sw	$t4, ($t0)
	j next2
oraToCool:
	li	$t4, 0x00AC7652
	sw	$t4, ($t0)
	j next2
exitLoopCool:
.end_macro

.macro	filterWarm
	addi	$s0, $0, COLOR_MEM #set-up for filter
	li	$t2, WIDTH
	mul	$t0, $t2, 12 #t0 contains starting address for color change
	add	$t0, $t0, $s0
	
	li	$t1, HEIGHT
	mul	$t1, $t2, $t1	
	mul	$t1, $t1, 4
	add	$s0, $s0, $t1 	#s0 contains final address
loopWarm:	
	beq	$s0, $t0, exitLoopWarm
	lw	$t3, ($t0)	#t3 contains current pixel color
	beq	$t3, RED, redToWarm
	beq	$t3, MAGENTA, magToWarm
	beq	$t3, CYAN, cyaToWarm
	beq	$t3, YELLOW, yelToWarm
	beq	$t3, BLUE, bluToWarm
	beq	$t3, 0, blaToWarm
	beq	$t3, WHITE, whiToWarm
	beq	$t3, GREEN, greToWarm
	beq	$t3, ORANGE, oraToWarm
next3:
	addi	$t0, $t0, 4
	j	loopWarm
redToWarm:
	#as warm as red can be
	j next3
magToWarm:
	li	$t4, 0x00FF0087
	sw	$t4, ($t0)
	j next3
cyaToWarm:
	li	$t4, 0x00B800FF
	sw	$t4, ($t0)
	j next3
yelToWarm:
	li	$t4, 0x00FF4F00
	sw	$t4, ($t0)
	j next3
bluToWarm:
	li	$t4, 0x00A627FF
	sw	$t4, ($t0)
	j next3
blaToWarm:	
	#cannot make black warmer
	j next3
whiToWarm:
	li	$t4, 0x00F4b7b7
	sw	$t4, ($t0)
	j next3
greToWarm:
	li	$t4, 0x004B870F
	sw	$t4, ($t0)
	j next3
oraToWarm:
	li	$t4, 0x00FF5a00
	sw	$t4, ($t0)
	j next3
exitLoopWarm:
.end_macro
