#BitMap Project: Creative Bit Painting Canvas
#Thiago Ciriaco
#April 25 2021

#THIS PROGRAM REQUIRES THE MACROS IN THE ZIP FOLDER IN ORDER TO FUNCTION CORRECTLY

#Draws a white canvas onto a bitmap display
#uses keyboard WASD to draw a trail of pixels, space to exit
#use 1-9 to choose colors
#use q and e to change brush size
#use c to reset the canvas to selected bg color
#use r to change movement modes (paint vs cursor)

#Feel free to spam the keyboard simulator. 
#This version of mars does not crash with kb spam.

#pixel dimensions: 8x8
#screen dimensions in pixels: 64x32
.include	"bitmapMacros.asm"
.data
		.space	8196	#space for the paint
colors:		.word	RED, MAGENTA, CYAN, YELLOW, BLUE, WHITE, GREEN, ORANGE
current:	.word	RED	#current color being used
savedCLR:	.word	RED	#color used BEFORE switching to cursor mode
size:		.word	1
.globl main
.text
j	main

	#{---------------
drawLoop: #main loop function that takes in keyboard input for user to draw
	sleep(5)	#small sleep make program a little less heavy
	
	addi	$s6, $s6, 1	#increment counter for cursor blink
	beq	$a3, 1, onDrawMode
	li	$s6, 50	#if not on draw mode, cursor doesn't blink
	onDrawMode:
	beq	$s6, 100, reset
	beq	$s6, 50, blink
	j 	cursorSkip
	reset:			#reset timer every 100 ticks
	drawPixelBS($s4)
	li	$s6, 0
	j	cursorSkip
	blink:			#blink cursor if over 50 on timer
	beq	$a3, 0, cursorSkip
	addi	$sp, $sp, -4	# push $a2 to preserve
	sw	$a2, 0($sp)
	
	li	$a2, DARK_GRAY
	drawPixelBS($s4)
	
	lw	$a2, 0($sp)	# pop $a2 back
	addi	$sp, $sp, 4
	
cursorSkip:
	lw	$t7, current
	beq	$a3, -1, drawSkip	#if not in drawMode, skip
	bne	$t7, $a2, noDrawSkip #if pixel different color, noskip
	beq	$s5, 0, drawSkip #if position has not changed, skip.
	
noDrawSkip:
	sw	$a2, current	#record the new current color
	lw	$s4, size	#draw if position or color has changed
	drawPixelBS($s4)
	li	$s5, 0
	
drawSkip:
	lw	$s7, INPUT_MEM
	beq	$s7, 0, drawLoop	#get input, if any
	
	bne	$a3, 0, stillDrawing	#continue if user is still drawing
	
	#pick ending filter before exiting
	beq	$s7, 49, goAgain	#0= no filter
	beq	$s7, 50, grayscale	#1= grayscale filter
	beq	$s7, 51, inverted	#2= inverted color filter
	beq	$s7, 52, desaturated	#3= desaturated/colder color filter
	beq	$s7, 53, warmer		#4= warmer color filter
	j drawLoop			#else-> continue if invalid
	grayscale:
		filterGray
		j	goAgain
	inverted:
		filterInvert
		j	goAgain
	desaturated:
		filterCool
		j	goAgain
	warmer:
		filterWarm
		j	goAgain
	
	stillDrawing:
	beq	$s7, 32, doneDraw	#exit if space
	beq	$s7, 114, toggleDraw	#r to toggle draw/cursor modes
	beq	$s7, 119, up		#w for up
	beq	$s7, 115, down		#s for down
	beq	$s7, 97, left		#a for left
	beq	$s7, 100, right		#d for right
	
	beq	$s7, 113, sizedown	#q for brush size up
	beq	$s7, 101, sizeup	#e for brush size down
	
	beq	$a3, -1, drawLoop	#if not on drawmode,
					#don't check for illegal changes
					
	beq	$s7, 99, resetBG	#c for clear w/ color
	
	
	beq	$s7, 49, red		#1 = red
	beq	$s7, 50, magenta	#2 = magenta
	beq	$s7, 51, cyan		#3 = cyan
	beq	$s7, 52, yellow		#4 = yellow
	beq	$s7, 53, blue		#5 = blue
	beq	$s7, 54, black		#6 = black
	beq	$s7, 55, white		#7 = white
	beq	$s7, 56, green		#8 = green
	beq	$s7, 57, orange		#9 = orange
	
	j	drawLoop		#continue as normal if invalid

toggleDraw:
	beq	$s4, 1, continueToggle
	printString("Please change brush size to 1 to toggle draw state.\n\n")	
	sw	$0, INPUT_MEM
	j drawLoop
continueToggle:
	lw	$t0, current
	move	$a2, $t0 	#store current color in case of gray
	lw	$a2, savedCLR	#store prev selected color
	sw	$0, INPUT_MEM
	mul	$a3, $a3, -1 	#swap state of draw
	changeDrawState		#update UI
	beq	$a2, -1, noRestore
	lw	$a2, savedCLR
	sw	$a2, current
noRestore:
	j	drawLoop

doneDraw:	
	drawPixelBS($s4)	#drawpixel to clean possible blinking gray
	printString("Done? Enter the filter you would like to apply: \n")
	printString("1:\tNone\n")
	printString("2:\tGrayscale\n")
	printString("3:\tInverted Colors\n")
	printString("4:\tCooler Colors\n")
	printString("5:\tWarmer Colors\n\n")
	li	$a3, 0 		#set drawstate to DONE
	j	drawLoop
up:	
	beq	$a3, -1, upCursor	
	drawPixelBS($s4)	#drawpixel to clean possible blinking gray
	beq	$a1, 3, drawLoop
	addi	$a1, $a1, -1
	sw	$0, INPUT_MEM
	li	$s5, 1
	j	drawLoop
upCursor:
	lw	$a2, current
	drawPixel		#restore original pixel
	beq	$a1, 3, drawLoop	
	addi	$a1, $a1, -1	#move up
	getPixelColor		#get new pixel color, in v1
	sw	$v1, current 	#save new original pixel color
	sw	$0, INPUT_MEM
	j drawLoop
	
down:
	beq	$a3, -1, downCursor
	drawPixelBS($s4)	#drawpixel to clean possible blinking gray
	beq	$a1, 31, drawLoop
	addi	$a1, $a1, 1
	sw	$0, INPUT_MEM
	li	$s5, 1
	j	drawLoop
downCursor:
	lw	$a2, current
	drawPixel		#restore original pixel
	beq	$a1, 31, drawLoop	
	addi	$a1, $a1, 1	#move down
	getPixelColor		#get new pixel color, in v1
	sw	$v1, current 	#save new original pixel color
	sw	$0, INPUT_MEM
	j drawLoop
	
left:
	beq	$a3, -1, leftCursor
	drawPixelBS($s4)	#drawpixel to clean possible blinking gray
	beq	$a0, 0, drawLoop
	addi	$a0, $a0, -1
	sw	$0, INPUT_MEM
	li	$s5, 1
	j	drawLoop
leftCursor:
	lw	$a2, current
	drawPixel		#restore original pixel
	beq	$a0, 0, drawLoop	
	addi	$a0, $a0, -1	#move left
	getPixelColor		#get new pixel color, in v1
	sw	$v1, current 	#save new original pixel color
	sw	$0, INPUT_MEM
	j drawLoop
right:
	beq	$a3, -1, rightCursor
	drawPixelBS($s4)	#drawpixel to clean possible blinking gray
	beq	$a0, 63, drawLoop
	addi	$a0, $a0, 1
	sw	$0, INPUT_MEM
	li	$s5, 1
	j	drawLoop
rightCursor:
	lw	$a2, current
	drawPixel		#restore original pixel
	beq	$a0, 63, drawLoop	
	addi	$a0, $a0, 1	#move right
	getPixelColor		#get new pixel color, in v1
	sw	$v1, current 	#save new original pixel color
	sw	$0, INPUT_MEM
	j drawLoop
	
sizedown:
	drawPixelBS($s4)	 #drawpixel to clean possible blinking gray
	sw	$0, INPUT_MEM
	lw	$s4, size	 #get current brush size
	beq	$s4, 1, drawLoop #cant go smaller
	addi	$s4, $s4, -1
	sw	$s4, size
	changeSize
	j	drawLoop	 #update new size
	
sizeup:
	beq	$a3, 1, contsizeUp
	printString("Please change draw state to \"Draw\" to change brush size.\n\n")
	sw	$0, INPUT_MEM
	j	drawLoop
	
contsizeUp:
	drawPixelBS($s4)	 #drawpixel to clean possible blinking gray
	sw	$0, INPUT_MEM
	lw	$s4, size	 #get current brush size
	beq	$s4, 3, drawLoop #cant go bigger
	addi	$s4, $s4, 1
	sw	$s4, size
	changeSize
	j	drawLoop
	
resetBG:
	sw	$0, INPUT_MEM
	changeBG
	j	drawLoop
	
red:			#switch color
	sw	$a2, current
	addi	$a2, $0, RED
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
magenta:		#switch color
	sw	$a2, current
	addi	$a2, $0, MAGENTA
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
cyan:			#switch color
	sw	$a2, current
	addi	$a2, $0, CYAN
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
yellow:			#switch color
	sw	$a2, current
	addi	$a2, $0, YELLOW
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
blue:			#switch color
	sw	$a2, current
	addi	$a2, $0, BLUE
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
black:			#switch color
	sw	$a2, current
	add 	$a2, $0, $0
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
white:			#switch color
	sw	$a2, current
	addi	$a2, $0, WHITE
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
green:			#switch color
	sw	$a2, current
	addi	$a2, $0, GREEN
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
orange:			#switch color
	sw	$a2, current
	addi	$a2, $0, ORANGE
	sw	$a2, savedCLR
	sw	$0, INPUT_MEM
	changeColor
	j	drawLoop
	#------------}
	
	#{------------
drawUI:	#function to draw the base for the UI

	addi	$s0, $0, COLOR_MEM #set-up for clear
	addi	$s1, $0, GRAY
	addi	$s2, $0, WIDTH
	addi	$s3, $0, HEIGHT
	
	mul	$s2, $s2, 3
	addi	$s2, $s2, -1	#s2 = total pixels to draw
	
	
	move	$t0, $0		#t0 = counter
bgLoop:
	mul	$t3, $t0, 4
	add	$t2, $t3, $s0	#t2 = address of next pixel to draw 
	sw	$s1, 0($t2)	#"draw" ui pixel by saving gray to pixel
	
	addi	$t0, $t0, 1	#increment counter
	ble	$t0, $s2, bgLoop
	
	#draws the colors in UI so user can see selected color
	addi	$a0, $0, 1
	addi	$a1, $0, 0
	addi	$a2, $0, DARK_GRAY
	drawPixel
		#red is initially selected
	addi	$a1, $0, 1
	addi	$a2, $0, RED	
	drawPixel
		#1 = red
	addi	$a0, $a0, 3
	addi	$a2, $0, MAGENTA
	drawPixel
		#2 = magenta
	addi	$a0, $a0, 3
	addi	$a2, $0, CYAN
	drawPixel
		#3 = cyan
	addi	$a0, $a0, 3
	addi	$a2, $0, YELLOW
	drawPixel
		#4 = yellow
	addi	$a0, $a0, 3
	addi	$a2, $0, BLUE
	drawPixel
		#5 = blue
	addi	$a0, $a0, 3
	addi	$a2, $0, 0
	drawPixel
		#6 = black
	addi	$a0, $a0, 3
	addi	$a2, $0, WHITE
	drawPixel
		#7 = white
	addi	$a0, $a0, 3
	addi	$a2, $0, GREEN
	drawPixel
		#8 = green
	addi	$a0, $a0, 3
	addi	$a2, $0, ORANGE
	drawPixel
		#9 = orange

	#draws the word "Draw" for UI
	addi	$a0, $a0, 3		#OOX XXX XXXX XXXXXX
	li	$a2, DARK_GRAY		#OXO XOO XOOX XOXOXO
					#OOX XOX XOOO XXOXOX
	#Draws D
	drawPixel			
	addi	$a1, $a1, 1
	drawPixel
	addi	$a1, $a1, -2
	drawPixel
	addi	$a0, $a0, 1 
	drawPixel
	addi	$a1, $a1, 2
	drawPixel
	addi	$a1, $a1, -1
	addi	$a0, $a0, 1
	drawPixel
	
	#Draws r
	addi	$a0, $a0, 2
	drawPixel
	addi	$a1, $a1, 1
	drawPixel
	addi	$a1, $a1, -1
	addi	$a0, $a0, 1
	drawPixel
	
	#Draws a
	addi	$a0, $a0, 2
	drawPixel
	addi	$a1, $a1, 1
	drawPixel
	addi	$a1, $a1, -1
	addi	$a0, $a0, 1
	drawPixel
	addi	$a1, $a1, 1
	drawPixel
	addi	$a0, $a0, 1
	drawPixel
	
	#Draws w
	addi	$a0, $a0, 2
	addi	$a1, $a1, -1
	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1
	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, -1
	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, 1
	drawPixel
	addi	$a0, $a0, 1
	addi	$a1, $a1, -1
	drawPixel
	
	jr	$ra
	#------------}
#{-------------
main:
	printString("\n\n\nWelcome! Make your own Drawing.\n\n")
	printString("WASD - Move Cursor\nQ/E - Change Brush Size (top right)\n")
	printString("C - Paint entire screen (with selected color)\n")
	printString("1-9 - Change color\nR - Toggle Draw/Move (must use brush size 1)\n")
	printString("Space - Done Drawing\n\n")
	
	sw	$0, INPUT_MEM #reset input mem if user forgot to to avoid crashes
	blackout
	resetScreen
	jal drawUI
	
	addi	$a0, $0, 30	#inital coordinates for the drawing cursor
	addi	$a1, $0, 14
	lw	$a2, colors
	#drawPixel
	
	li	$s4, 1
	changeSize		#display initial UI size setting
	
	addi	$a0, $0, 30	#inital coordinates for the drawing cursor
	addi	$a1, $0, 14
	
	li	$s6, 0		#reset counter for cursor blinking
	li	$a3, 1		#begin on draw mode
	changeDrawState()
	j drawLoop
#--------}
goAgain:
	printString("Wow! A masterpiece... take a screenshot to record it!\n")
	printString("Windows: (WindowsKey+Shift+S)\nMac: (Shift+Command+4)\n\n")
	printString("Press -Space- to start a NEW drawing.\nExit with 0.\n\n")
askNewDraw:
	lw	$s7, INPUT_MEM
	beq	$s7, 0, askNewDraw	#get input, if any
	beq	$s7, 32, main		#restart main if new drawing
	beq	$s7, 48, exit
	
	j	askNewDraw		#continue if invalid
exit:
	sw	$0, INPUT_MEM 		#reset input mem if user forgot to to avoid crashes
	addi	$v0, $0, 10
	syscall
