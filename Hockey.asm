JUMPS
IDEAL
MODEL small
STACK 200h

;---------
; DATASEG
;---------
DATASEG  


; *******************************************************************************
;																				*
;							-----  constants  --------							*
;																				*
; p1 - left player (blue)												        *
; p2 - right player (red)												        *
;																				*
; Position of the ball after a victory(round) of one of the players				*
;																				*
BALL_P1_WIN_X	equ		188 		;											*
BALL_P2_WIN_X	equ		113	 		;											*
BALL_START_Y	equ		95 			;									    	*
;																				*
P1_START_X		equ		56    		;											*
P1_START_Y		equ		86 			;									    	*
;																				*
P2_START_X		equ		230 		;											*
P2_START_Y		equ 	86 			;									    	*
;																				*
; colors                                                                        *
P1_COLOR_BLUE 		    equ 88h		;											*
P2_COLOR_RED 			equ 0Dh		;										    *
BOUNDARY_COLOR_WHITE    equ 0FFh	;											*
BACKGROUND_COLOR		equ	0Ch		;										 	*
;																				*
; score to win                                                                  *
WINNER_SCORE    equ     "7"			;											*
;																				*
;																				*
; *******************************************************************************

; *******************************************************************************
;																				*
;							-----  pictures  --------							*
;																				*
filehandle dw ?							;										*
Header db 54 dup (0)					;								    	*
Palette db 256*4 dup (0)				;								    	*
ScrLine db 320 dup (0)  				;								    	*
background	db	?						;						    			*
ErrorMsg db 'Error', 13, 10,'$' 		;										*																			
;																				*
;																				*
; windows - (before the game) 											    	*
homeFileName     db 'deskID.bmp',0		;										*
instructFileName db 'instruct.bmp', 0	;										*
;																				*
; Windows - win (after the game)												*
p1WinFileName    db 'p1Won.bmp', 0		;										*
p2WinFileName    db 'p2Won.bmp',0		;										*
;																				*
; Game tools																	*
areaFileName     db 'area2.bmp',0		;										*
p1FileName       db 'p1.bmp', 0			;										*
p2FileName       db 'p2.bmp',0			;										*
ballFileName     db 'ball.bmp', 0		;										*
;																				*
;																				*
; Arrays that hold color palettes 												*
ballBackground		dw		400   dup (?)     ;			     					*
player1Background	dw		1296  dup (?)     ;			     					*
player2Background	dw		1296  dup (?)     ;			     					*
;																				*
ballPixels			dw		400   dup (?)     ;			     					*
player1Pixels    	dw		1296  dup (?)     ;			     					*
player2Pixels   	dw		1296  dup (?)     ;			     					*		
;																				*
;																				*
; *******************************************************************************


; *******************************************************************************
;																				*
;							-----  variables  --------							*
;																				*
formerXBall		dw		149	               ;			     					*
formerYBall		dw		95	               ;			     					*
;																				*
formerXPlayer1	dw		?	               ;			     					*
formerYPlayer1	dw		?	               ;			     					*
;																				*
formerXPlayer2	dw		?	               ;			     					*
formerYPlayer2	dw		?	               ;			     					*
;																				*
ballX		    dw		149		           ;			     					*
ballY		    dw		95	               ;			     					*
;																				*
p1X		        dw		56		           ;			     					*
p1Y		        dw		86	               ;			     					*	
;																				*
p2X		        dw		230	               ;			     					*
p2Y		        dw		86	               ;			     					*
;																				*
;																				*
; ball speed                                                                    *
speedX 			dw 		0                  ;			     					*
speedY 			dw 		0                  ;			     					*
;																				*
; Score                                                                         *
p1Score 		db 		"0"				   ; score of player1 (0)               *
p2Score 		db 		"0"				   ; score of player2 (0)               *
hyphen  		db 		"-"                ;			     					*
;																				*
playerGoal		dw		?                  ;			     					*
holdColor		dw      ?                  ;			     					*
;																				*
; boolean parameters															*
doMoveBall   	db		1                  ;			     					*
doMovePlayer1	db		1                  ;			     					*
doMovePlayer2	db		1                  ;			     					*
getKeyboardInput dw     1				   ;								    * 
;																				*
; time - delay parameters							     					    *
first_tick					dw		?      ;			     					*
first_tick_dx				dw		?      ;			     					*
;																				*
;																				*
; *******************************************************************************


;---------
; CODESEG
;---------

CODESEG

;***********************************************************
; Procedure: OpenFile                                      *
;                                                          *
;  This procedure opens a file and save it in filehandle   *
;                                                          *
;  Input parameter:                                        *
;   [bp + 4] - file's name                                 *
;                                                          *
;***********************************************************

proc OpenFile

	; Handle stack
	push bp
	mov bp, sp
	
	; Parameters
	current_filename equ [bp + 4]
	
	; Open file
	mov ah, 3Dh
	xor al, al
	mov dx, current_filename
	int 21h
	jc openerror
	mov [filehandle], ax

	pop bp
	ret 2
openerror:
	mov dx, offset ErrorMsg
	mov ah, 9h
	int 21h
	pop bp
	ret 2
endp OpenFile



;***********************************************************
; Procedure: ReadHeader                                    *
;                                                          *
;  This procedure Read BMP file header, 54 bytes.          *
;                                                          *
;***********************************************************

proc ReadHeader
	; Read BMP file header, 54 bytes
	mov ah,3fh
	mov bx, [filehandle]
	mov cx,54
	mov dx,offset Header
	int 21h	
	ret
endp ReadHeader



;***********************************************************
; Procedure: ReadPalette                                   *
;                                                          *
;  This procedure Read BMP file color palette,             *
;  256 colors * 4 bytes (400h)                             *
;                                                          *
;***********************************************************

proc ReadPalette
	; Read BMP file color palette, 256 colors * 4 bytes (400h)
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	ret
endp ReadPalette



;***********************************************************
; Procedure: CopyPal                                       *
;                                                          *
;  Copy the colors palette to the video memory.            *
;  The number of the first color should be sent to port    *
;  3C8h.                                                   *
;  The palette is sent to port 3C9h.                       *
;                                                          *
;***********************************************************

proc CopyPal
	; Copy the colors palette to the video memory
	; The number of the first color should be sent to port 3C8h
	; The palette is sent to port 3C9h
	
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0
	
	; Copy starting color to port 3C8h
	out dx,al
	
	; Copy palette itself to port 3C9h
	inc dx
	
PalLoop:
	; Note: Colors in a BMP file are saved as BGR values rather than RGB.
	mov al,[si+2] 															; Get red value.
	shr al,2															    ; Max. is 255, but video palette maximal
	
	; value is 63. Therefore dividing by 4.

	out dx,al 															    ; Send it.
	mov al,[si+1] 															; Get green value.
	shr al,2
	out dx,al 																; Send it.
	mov al,[si] 															; Get blue value.
	shr al,2
	out dx,al 																; Send it.
	add si,4 																; Point to next color.

	; (There is a null chr. after every color.)

	loop PalLoop
	ret
endp CopyPal



;***********************************************************
; Procedure: CopyBitmap                                    *
;                                                          *
;  BMP graphics are saved upside-down.                     *
;  Read the graphic line by line (200 lines in VGA format),*
;  displaying the lines from bottom to top.                *
;                                                          *
;  * Images that need background removal                   *
;                                                          *
;  Input parameters:                                       *
;   [bp + 10] - Horizontal position                        *
;   [bp + 8] - Vertical position                           *
;   [bp + 6] - Image width                                 *
;   [bp + 4] - Image height                                *
;                                                          *
;***********************************************************

proc CopyBitmap

	; Handle stack
	push bp
	mov bp, sp

	; Parameters
	CURRENT_X			equ [bp + 10]
	CURRENT_Y			equ [bp + 8]
	CURRENT_IMG_WIDTH	equ [bp + 6]
	CURRENT_IMG_HEIGHT	equ [bp + 4]
	
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,CURRENT_IMG_HEIGHT					; Height
	
PrintBMPLoop:
	add cx, CURRENT_Y							; Y start
	push cx
	
	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx
	
	; Read one line
	mov ah,3fh
	mov cx,CURRENT_IMG_WIDTH				  ; Width
	mov dx,offset ScrLine
	int 21h
	
	mov al, [byte ptr ScrLine]
	mov [background], al
	
	; Copy one line into video memory
	cld 									; Clear direction flag, for movsb
	mov cx,CURRENT_IMG_WIDTH				; Width
	mov si,offset ScrLine

	;rep movsb ; Copy line to the screen

	;rep movsb is same as the following code:
	add di, CURRENT_X 						; x start ************************
	rows:
		push ax								; Save ax
		mov ax, [ds:si]						; Read from memory
		cmp [background], al
		je skipPixel
		mov [es:di], ax						; Write to screen
		
		skipPixel:
		pop ax								; Load ax
		inc si								; Next pixel
		inc di								; Next pixel
		
		;dec cx
		loop rows							; Loop
	sub di, CURRENT_X						; Change di back

 ;loop until cx=0

	pop cx
	sub cx, CURRENT_Y					; Restore cx
	loop PrintBMPLoop
	pop bp
	ret 8
endp CopyBitmap



;***********************************************************
; Procedure: CopyBitmap2                                   *
;                                                          *
;  BMP graphics are saved upside-down.                     *
;  Read the graphic line by line (200 lines in VGA format),*
;  displaying the lines from bottom to top.                *
;                                                          *
;  Input parameters:                                       *
;   [bp + 10] - Horizontal position                        *
;   [bp + 8] - Vertical position                           *
;   [bp + 6] - Image width                                 *
;   [bp + 4] - Image height                                *
;                                                          *
;***********************************************************

proc CopyBitmap2

	; Handle stack
	push bp
	mov bp, sp

	; Parameters
	CURRENT_X			equ [bp + 10]
	CURRENT_Y			equ [bp + 8]
	CURRENT_IMG_WIDTH	equ [bp + 6]
	CURRENT_IMG_HEIGHT	equ [bp + 4]
	
	; BMP graphics are saved upside-down.
	; Read the graphic line by line (200 lines in VGA format),
	; displaying the lines from bottom to top.
	mov ax, 0A000h
	mov es, ax
	mov cx,CURRENT_IMG_HEIGHT													   ; Height
	

PrintBMPLoop2:
	add cx, CURRENT_Y															   ; Y start
	push cx

	; di = cx*320, point to the correct screen line
	mov di,cx
	shl cx,6
	shl di,8
	add di,cx

	; Read one line
	mov ah,3fh
	mov cx,CURRENT_IMG_WIDTH													   ; Width
	mov dx,offset ScrLine
	int 21h
	
	; Copy one line into video memory
	cld 																		   ; Clear direction flag, for movsb
	mov cx,CURRENT_IMG_WIDTH													   ; Width
	mov si,offset ScrLine

	;rep movsb ; Copy line to the screen

	;rep movsb is same as the following code:
	add di, CURRENT_X 															   ; x start
	rows2:
		push ax																	   ; Save ax
		mov ax, [ds:si]															   ; Read from memory
		mov [es:di], ax															   ; Write to screen
		pop ax																	   ; Load ax
		inc si																	   ; Next pixel
		inc di																	   ; Next pixel

		loop rows2														   		   ; Loop

	sub di, CURRENT_X														       ; Change di back

 ;loop until cx = 0

	pop cx
	sub cx, CURRENT_Y															   ; Restore cx
	loop PrintBMPLoop2
	pop bp
	ret 8
endp CopyBitmap2



;***********************************************************
; Procedure: displayImage                                  *
;                                                          *
; This procedure displays a bitmap file                    *
;  										                   *
; * Images that need background removal                    *
;                                                          *
;  Input parameters:                                       *
;   [bp + 12] - filename                       			   *
;   [bp + 10] - Horizontal position                        *
;   [bp + 8] - Vertical position                           *
;   [bp + 6] - Image width                                 *
;   [bp + 4] - Image height                                *
;  										                   *
;***********************************************************

proc displayImage

	; Handle stack 
	push bp
	mov bp, sp
	
	; Parameters	
	FILENAME 	equ [bp + 12]
	X_VALUE	 	equ [bp + 10]
	Y_VALUE	 	equ [bp + 8]
	IMG_WIDTH	equ [bp + 6]
	IMG_HEIGHT	equ [bp + 4]
	
	; Process BMP file
	push FILENAME
	call OpenFile
	
	call ReadHeader
	call ReadPalette
	call CopyPal
	
	push X_VALUE
	push Y_VALUE
	push IMG_WIDTH
	push IMG_HEIGHT
	call CopyBitmap
	call CloseFile
	
	pop bp
	ret 10
endp displayImage



;***********************************************************
; Procedure: displayImage2                                 *
;                                                          *
; This procedure displays a bitmap file                    *
;                                                          *
;  Input parameters:                                       *
;   [bp + 12] - filename                       			   *
;   [bp + 10] - Horizontal position                        *
;   [bp + 8] - Vertical position                           *
;   [bp + 6] - Image width                                 *
;   [bp + 4] - Image height                                *
;                                                          *
;***********************************************************

proc displayImage2 

	; Handle stack
	push bp
	mov bp, sp
	
	; Parameters
	FILENAME 	equ [bp + 12]
	X_VALUE	 	equ [bp + 10]
	Y_VALUE	 	equ [bp + 8]
	IMG_WIDTH	equ [bp + 6]
	IMG_HEIGHT	equ [bp + 4]
	
	; Process BMP file
	push FILENAME
	call OpenFile
	
	call ReadHeader
	call ReadPalette
	call CopyPal
	
	push X_VALUE
	push Y_VALUE
	push IMG_WIDTH
	push IMG_HEIGHT
	call CopyBitmap2
	call CloseFile
	
	pop bp
	ret 10
endp displayImage2



;***********************************************************
; Procedure: CloseFile                                     *
;                                                          *
;  This procedure close a file.                            *
;                                                          *                                                
;***********************************************************

proc CloseFile
	mov ah,3Eh
	mov bx, [filehandle]
	int 21h
	ret
endp CloseFile



;************************************************************************
; Procedure: writePixel                                    				*
;                                                          				*
;  This procedure paints one pixel on the screen           				*
;                                                          				*  
;  Input parameters:                                       				*
;   [bp + 10] - Boolean variable whether to delete the background   	*
;   [bp + 8] - Image width                           	   				*
;   [bp + 6] - Image height                                				*
;   [bp + 4] - background color                            				*
;                                                          				*
;************************************************************************

proc writePixel

	; Handle stack
	push bp
	mov bp, sp
	
	; Save registers which are used in the procedure
	push ax
	push bx
	push cx
	push dx
	
	; Parameters
	OBJECT_SKIP	equ		[bp + 10]
	X_VALUE		equ		[bp + 8]
	Y_VALUE		equ		[bp + 6]
	COLOR		equ		[bp + 4]
	
	
	; Check that the color is not black, if it is - do not print it
	; This procedure does not paint pixels in black in order to enable printing images without their background
	; The background of the image should be painted in black and than the procedure does not print it
	mov ax, COLOR
	cmp ax, 0
	JE skipPixelWrite
	; 04h, 0C6h
	
	mov ah, 0Dh
	mov bh, 0
	mov cx, X_VALUE
	mov dx, Y_VALUE
	int 10h
	
	; 1 - blue
	; 2 - red
	
	cmp OBJECT_SKIP, 1
	JE checkRed
	
	cmp OBJECT_SKIP, 2
	JE paintPixel
	
checkBlue:
	cmp al, P1_COLOR_BLUE
	JE skipPixelWrite
	
checkRed:
	cmp al, P2_COLOR_RED
	JE skipPixelWrite
	
paintPixel:
	
	mov ah, 0Ch													; ah = 0Ch for changing a pixel
	mov al, COLOR												; The color
	xor bx, bx													; page = 0
	mov cx, X_VALUE												; x value			
	mov dx, Y_VALUE												; y value	
	int 10h														; ; Call interrupt that paints the pixel
	
; Skip the whole procedure
skipPixelWrite:
	
	; Restore registers
	pop dx
	pop cx
	pop bx
	pop ax
	
	; End procedure
	pop bp
	ret 8														; The procedure used 3 parameters
endp writePixel



;************************************************************************
; Procedure: writeRow                                      				*
;                                                          				*
;  This procedure prints a line of pixels from an array    				*
;  which holds the colors of the pixels.  				   				*		
;                                                          				*  
;  Input parameters:                                       				*
;   [bp + 12] - Boolean variable whether to delete the background   	*
;   [bp + 10] - Pointer to the array with the pixels of the image   	*
;   [bp + 8] - Horizontal position                        				*
;   [bp + 6] - Vertical position                           				*
;   [bp + 4] - The length of the line                            		*
;                                                          				*
;************************************************************************

proc writeRow

	; Handle stack
	push bp
	mov bp, sp
	
	;Save registers which are used in the procedure
	push ax
	push bx
	push cx
	push si
	
	; Parameters
	OBJECT_SKIP		equ		[bp + 12]
	POINTER			equ		[bp + 10]								; Holds the starting point of the array
	X_VALUE			equ		[bp + 8]								; Holds the x value where the array starts
	Y_VALUE			equ		[bp + 6]								; Holds the y value where the array starts
	ROW_WIDTH		equ		[bp + 4]								; Holds the length of the row (width looking at the entire screen)
	
	xor bx, bx														; Zero bx
	mov cx, ROW_WIDTH												; Restart loop variable
	mov si, POINTER													; Restart pointer for array


; This loop goes over the pixels of the row and paints them
writeRowLoop:

	; Calculate the x value of the pixel
	mov ax, X_VALUE													; AX = x value of start of the row
	add ax, bx														; AX = start of the row + the current pixel
	
	; Call the procedure which paints the current pixel
	push OBJECT_SKIP
	push ax															; Push x value
	push Y_VALUE													; Push y value
	mov al, [byte ptr si + bx]										; al = color (pointer to the start of the array + current pixel)
	xor ah, ah														; ah = 0 (so ax = 00:color)
	push ax															; Push the color
	call writePixel													; Call the procedure that paints the pixel
		
	; Reiterate the loop
	inc bx
	loop writeRowLoop
	
	; Restore the registers to the state they were before the procedure started
	pop si
	pop cx
	pop bx
	pop ax

	; End procedure
	pop bp
	ret 10														    ; The procedure has 4 parameters
endp writeRow



;************************************************************************
; Procedure: writeArray                                    				*
;                                                          				*
;  This procedure paints a picture from an array		   				*	
;  of pixel colors.										   				*
;                                                          				*  
;  Input parameters:                                       				*
;   [bp + 14] - Boolean variable whether to delete the background   	*
;   [bp + 12] - Pointer to the array with the pixels of the image   	*
;   [bp + 10] - Horizontal position                        				*
;   [bp + 8] - Vertical position                           				*
;   [bp + 6] - Image width                            					*
;   [bp + 4] - Image height			                            		*
;                                                          				*
;************************************************************************

proc writeArray

	; Handle stack
	push bp
	mov bp, sp
	
	; Save registers that will be used in the procedure
	push cx
	push si
	
	; Parameters
	OBJECT_SKIP		equ		[bp + 14]
	POINTER			equ		[bp + 12]
	X_VALUE			equ		[bp + 10]
	Y_VALUE			equ 	[word ptr bp + 8]
	PIC_WIDTH		equ		[bp + 6]
	PIC_HEIGHT		equ		[bp + 4]
	
	mov si, POINTER												; Move the pointer to si
	mov cx, PIC_HEIGHT											; Restart the loop variable (The height of the picture)
	
; This loop goes over the rows of the picture and paints them
writeArrayLoop:

	; Call the procedure to print the current row
	push OBJECT_SKIP
	push si														; Push the pointer of the array
	push X_VALUE												; Push the x value
	push Y_VALUE												; Push the y value
	push PIC_WIDTH												; Push the width of the picture (length of the row)
	call writeRow												; Call the procedure to print the row
		
	; Continue to next iteration
	inc Y_VALUE													; Continue the y value of the next row
	add si, PIC_WIDTH											; Continue to next row
	loop writeArrayLoop											; Reiterate the loop if needed
	
	; Restore the registers to their state before the procedure
	pop si
	pop cx
	
	; End the procedure
	pop bp
	ret 14														; The procedure has 5 parameters
endp writeArray







;***********************************************************
; Procedure: readPixel                                     *
;                                                          *
; This procedure reads a pixel into an array.              *
;                                                          *  
;  Input parameters:                                       *
;   [bp + 6] -  Horizontal position						   *
;   [bp + 4] - Vertical position						   *
;                                                          *
;***********************************************************

proc readPixel

	; Handle stack
	push bp
	mov bp, sp

	; Save the registers that the procedure uses
	push ax
	push bx
	push cx
	push dx

	; Parameters
	X_VALUE		equ		[bp + 6]
	Y_VALUE		equ		[bp + 4]
	
	; Read the pixel
	mov ah, 0Dh													; ah = 0Dh for reading pixels
	xor bh, bh													; bh = 0 = page
	mov cx, X_VALUE												; cx = x value
	mov dx, Y_VALUE												; dx = y value
	int 10h														; Read the pixel
	
	xor ah, ah													; ah = 0 (ax = 00:color)
	mov [holdColor], ax										; Return ax (color)

	; Restore registers to state they were before the procedure
	pop dx
	pop cx
	pop bx
	pop ax
	
	; End procedure
	pop bp
	ret 4														; The procedure uses 2 parameters
endp readPixel



;************************************************************************
; Procedure: readRow                                  	   				*
;                                                          				*
; This procedure reads a row of pixels from the screen.    				*
;                                                          				*
;  Input parameters:                                       				*
;   [bp + 10] - Pointer to the array with the pixels of the image   	*
;   [bp + 8] - Horizontal position                        				*
;   [bp + 8] - Vertical position                           				*
;   [bp + 6] - The length of the line                            		*
;                                                          				*
;************************************************************************

proc readRow

	; Handle stack
	push bp
	mov bp, sp

	; Save the registers that are used in the procedure
	push ax														; Used for holding the color from the time the pixel is read until it is saved in memory
	push cx														; Used as a loop variable for going over the pixels in the row
	push si														; Points to the current place at the array in which the color should be saved

	; Parameters
	POINTER		equ		[bp + 10]								; The array that holds the colors for the pixels in the row
	X_VALUE		equ		[word ptr bp + 8]						; X value of the start of the row
	Y_VALUE		equ		[bp + 6]								; Y value of the row
	ROW_WIDTH	equ		[bp + 4]								; Row length (width relative to the screen)
	
	mov cx, ROW_WIDTH											; Restart loop variable
	mov si, POINTER												; Restart si to the pointer of the first element in the array

; This loop goes over the pixels in the row and saves them in the array
readRowLoop:

	; Read the pixel
	push X_VALUE												; Push x value of the current pixel
	push Y_VALUE												; Push y value of the current pixel
	call readPixel												; Call the procedure which reads the pixel	
		
	; Save the color
	mov ax, [holdColor]										; Enter the value that was returned (the color) to ax
	mov [byte ptr si], al										; Enter the color into the current place in memory
		
	; Continue to next iteration
	inc si														; Move to the next address in memory
	inc X_VALUE													; Increase the x value of the pixel for next iteration
	loop readRowLoop											; Reiterate the loop
	
	; Restore the registers to their state before the procedure
	pop si
	pop cx
	pop ax
	
	; End procedure
	pop bp
	ret 8														; This procedure uses 4 parameters
endp readRow



;************************************************************************
; Procedure: readArray                                     				*
;                                                         			    *
; This procedure reads a rectangle from the screen		   				*
; and puts it in an array.								   				*
;                                                          				*
;  Input parameters:                                       				*
;   [bp + 12] - Pointer to the array with the pixels of the image   	*
;   [bp + 10] - Horizontal position                        				*
;   [bp + 8] - Vertical position                           				*
;   [bp + 6] - Image width			                            		*
;   [bp + 4] - Image height			                            		*
;                                                          				*
;************************************************************************

proc readArray

	; Handle stack
	push bp
	mov bp, sp
	
	; Save registers that are used in the procedure
	push cx														; Loop variable for the loop that goes over the rows
	push si														; Points to the current place in memory for which the pixels should be written
	
	; Parameters
	POINTER			equ		[bp + 12]							; The starting point of the array
	X_VALUE			equ		[bp + 10]							; X value of the first pixel in the rectangle
	Y_VALUE			equ		[word ptr bp + 8]					; Y value of the first pixel in the rectangle
	PIC_WIDTH		equ		[bp + 6]							; Width of the rectangle
	PIC_HEIGHT		equ		[bp + 4]							; Height of the rectangle
	
	mov cx, PIC_HEIGHT											; Restart loop variable to the height of the rectangle
	
	; (the loop repeats once for each pixel of height)
	
	mov si, POINTER												; Restart si to point to the start of the array
	
; This loop goes over each row of the rectangle and reads its pixels into the array
readArrayLoop:

	; Read the current row
	push si														; Push the first address into which the row should be written
	push X_VALUE												; Push the x value where the row starts
	push Y_VALUE												; Push the y value of the row
	push PIC_WIDTH												; Push the length of the row (width relative to the screen)
	call readRow												; Call the procedure which reads the row
		
	; Continue for next iteration
	inc Y_VALUE													; Move to next y value for next row (a row down)
	add si, PIC_WIDTH											; Move to the next empty address in the array
	loop readArrayLoop											; Return to head of the loop
	
	; Restore registers to their original state before the procedure
	pop si
	pop cx
	
	; End procedure
	pop bp
	ret 10														; The procedure uses 5 parameters
endp readArray



;********************************************************************************************
; Procedure: deleteBackground					           									*
;                                                          									*
; This method deletes the background from a picture which 									*
; is copied from the screen. The pixels that remain are    									*
; only of characters and objects. When a pixel is deleted, 									*
; it is written as 0 in the array (BLACK)				   									*
;                                                          									*
;  Input parameters:                                       									*
;   [bp + 8] - Pointer to the array with the pixels of the character and the background   	*
;   [bp + 6] - Pointer to the array with the pixels of the background   					*
;   [bp + 4] - The length of the array		                            					*
;                                                          									*
;********************************************************************************************

proc deleteBackground

	; Handle stack
	push bp
	mov bp, sp
	
	; Save registers that are used in the procedure in the stack
	push ax
	push bx
	push cx
	push si
	push di
	
	; Parameters
	FIRST_POINTER		equ		[bp + 8]											; The pointer to the first array (Holds the background and the character)
	SECOND_POINTER		equ		[bp + 6]											; The pointer to the second array (Holds the background only)
	ARR_LEN				equ		[bp + 4]											; The length of the arrays
	
	mov cx, ARR_LEN 																; length of the arrays ---> cx - loop variable
	xor bx, bx																		; bx = 0 (this registers is added to the pointers to get a different element each iteration)
	mov si, FIRST_POINTER															; si points to the first array
	mov di, SECOND_POINTER															; si points to the second array


; This loop iterates once for each element of the loops
; The loop deletes every element from the first array which is the same as the element in the same place in the second array
deleteBackgroundLoop:

	; Check if needs to be deleted
	mov al, [byte ptr di + bx]														; al = color in the first array
	mov ah, [byte ptr si + bx]														; ah = color in the second array
	cmp ah, al																		; Check if they are euqal
	JNE nextIteration																; If they are not equal - don't delete the element and jump to next iteration
	mov [byte ptr si + bx], 0														; Delete the element if needed

; End the loop	
nextIteration:
	inc bx																			; Move one element forward
	loop deleteBackgroundLoop														; loop
	
	; Restore registers
	pop di
	pop si
	pop cx
	pop bx
	pop ax
	
	; End procedure
	pop bp
	ret 6																			; The procedure uses 3 parameters
endp deleteBackground



;***********************************************************
; Procedure: keyboardInputGame                             *
;                                                          *
; A procedure that sets a delay in each iteration of	   *
; the main loop.								   		   *
;                                                          *
; During the time of the delay, the procedure deals 	   *
; with the keyboard. (movementPlayers and exit from app)   *
;                                                          *
;***********************************************************

proc keyboardInputGame
	
	push ax
	push cx
	
	; Get the first time measurement
	mov ah, 0
	int 1Ah
	mov [first_tick], cx
	sub [first_tick], 5			; Set the duration of the timer to 5 ticks
	mov [first_tick_dx], dx		; Dx is saved and the timer intantly finishes when it changes
								; (otherwise when it changes the timer will take a lot of time to stop)
								
								
	; A loop that goes on until the right time have passed
	delayLoop:
	 
		; Get keyboard
		; Check if there is something to read from the keyboard
		mov ah,1
		int 16h
		JZ timeHandle	; Move to the part when you check the time and return to the head of the loop if nothing was pressed
		
		; Read the key pressed
		mov ah, 0
		int 16h
		
		; Check if there is something to be done with the key
		
		cmp [getKeyboardInput], 0
		je timeHandle
		
; ================================================
;				  movement player1
; ================================================		

		; Move left (A)
		cmp ah, 1Eh
		JE movePlayer1Left
		
		; Move right (D)
		cmp ah, 20h
		JE movePlayer1Right
		
		; Move up (W)
		cmp ah, 11h
		JE movePlayer1Up
		
		; Move down (S)
		cmp ah, 1Fh
		JE movePlayer1Down
		
; ================================================
; ================================================


; ================================================
;				  movement player2
; ================================================		

		; Move left
		cmp ah, 4Bh
		JE movePlayer2Left
		
		; Move right
		cmp ah, 4Dh
		JE movePlayer2Right
		
		; Move up
		cmp ah, 48h
		JE movePlayer2Up
		
		; Move down
		cmp ah, 50h
		JE movePlayer2Down
		
; ================================================
; ================================================


; ================================================
;				  exit from game
; ================================================		

		; exit
		cmp ah, 1h
		JE endProgram
		
; ================================================
; ================================================
	
		; Move to the part where you check the time and return to head of the loop if there is nothing to be done with the key pressed
		jmp timeHandle
		
		; Move the player1 left
		movePlayer1Left:
			cmp [p1X], 17		; Check that player1 does not leave the screen
			JBE timeHandle
			
			sub [p1X], 3
			
			mov [getKeyboardInput], 0
			
			jmp timeHandle
		
		; Move the player1 right
		movePlayer1Right:
			cmp [p1X], 121		; Check that player1 does not leave the screen
			JAE timeHandle
			
			add [p1X], 3
			
			mov [getKeyboardInput], 0
			
			jmp timeHandle
			
	    ; Move the player1 up
		movePlayer1Up:
			cmp [p1Y], 20		; Check that player1 does not leave the screen
			JBE timeHandle
			
			sub [p1Y], 3
			
			mov [getKeyboardInput], 0
			
			jmp timeHandle
			
		; Move the player1 down
		movePlayer1Down:
			cmp [p1Y], 156		; Check that player1 does not leave the screen
			JAE timeHandle
			
			add [p1Y], 3
			mov [getKeyboardInput], 0
			
			jmp timeHandle
		
; ================================================
; ================================================
		
		; Move the player2 left
		movePlayer2Left:
			cmp [p2X], 162		; Check that player2 does not leave the screen
			JBE timeHandle
			
			sub [p2X], 3
			mov [getKeyboardInput], 0
			
			jmp timeHandle
		
		; Move the player2 right
		movePlayer2Right:
			cmp [p2X], 270		; Check that player2 does not leave the screen
			JAE timeHandle
			
			add [p2X], 3
			mov [getKeyboardInput], 0
			
			jmp timeHandle
			
	    ; Move the player2 up
		movePlayer2Up:
			cmp [p2Y], 20		; Check that player2 does not leave the screen
			JBE timeHandle
			
			sub [p2Y], 3
			mov [getKeyboardInput], 0
			
			jmp timeHandle
		
		; Move the basket down
		movePlayer2Down:
			cmp [p2Y], 156		; Check that player2 does not leave the screen
			JAE timeHandle
			
			add [p2Y], 3
			mov [getKeyboardInput], 0
			
	
; Check the time
timeHandle:

		; Check the clock again
		mov ah, 0
		int 1Ah
		
		; Break the loop if the right time passed
		cmp [first_tick], cx
		JAE endDelay
		cmp [first_tick_dx], dx 		; This part checks if dx changes, it happens once every few seconds
		JNE endDelay
		
		; Continue the loop
		jmp delayLoop
		
endDelay:		; When the times ends - jmp to here
	mov [getKeyboardInput], 1
	pop cx
    pop ax
	ret
endp keyboardInputGame



;***********************************************************
; Procedure: checkGoal					           		   *
;                                                          *
; Checks whether one of the players scored a goal, 		   *
; then which of the players scored. 					   *
; 												     	   *
;***********************************************************

proc checkGoal
	push ax

	mov ax, [ballX]
	cmp ax, 10
	JA checkPlayer1Goal
	mov [playerGoal], 2
	jmp checkYball
	
checkPlayer1Goal:
	mov [playerGoal], 1
	cmp ax, 284
	JB returnNoGoal
	
; Checks whether the ball has hit the boundaries or whether it is a goal
checkYball:
	mov ax, [ballY]
	cmp ax, 73
	JL returnNoGoal
	cmp ax, 116
	JL returnGoal
	
returnNoGoal:
	mov [playerGoal], 0
	
returnGoal:
	pop ax
	ret

endp checkGoal



;***********************************************************
; Procedure: ResetPlayersPositionsRound					   *
;                                                          *
; Initializes the positions of the players      		   *
; and the ball after scoring a goal.  					   *
; 												     	   *
;***********************************************************

proc ResetPlayersPositionsRound

	; save register
	push ax
	
	; Resets player positions
	mov ax, [playerGoal]
	cmp ax, 0
	je continueReset
	
	mov ax, P1_START_X
	mov [p1X], ax
	
	mov ax, P1_START_Y
	mov [p1Y], ax
	
	mov ax, P2_START_X
	mov [p2X], ax
	
	mov ax, P2_START_Y
	mov [p2Y], ax
	
	; Resets the ball speed
	mov [speedX], 0
	mov [speedY], 0
	
	mov ax, [playerGoal]
	cmp ax, 1
	je player1Won
	jmp player2Won

; Resets the ball positions according to who scored the goal
player1Won:
	mov ax, BALL_P1_WIN_X
	mov [ballX], ax
	
	mov ax, BALL_START_Y
	mov [ballY], ax
	
	inc [p1Score]
	
	mov [doMovePlayer1], 0
	mov [doMovePlayer2], 0
	mov [doMoveBall], 0
	
	jmp continueReset
	
player2Won:
	mov ax, BALL_P2_WIN_X
	mov [ballX], ax
	
	mov ax, BALL_START_Y
	mov [ballY], ax
	
	inc [p2Score]
	
	mov [doMovePlayer1], 0
	mov [doMovePlayer2], 0
	mov [doMoveBall], 0
	
continueReset:
    pop ax
	ret
		
endp ResetPlayersPositionsRound



;***********************************************************
; Procedure: movementBallByColor     					   *
;                                                          *
; Checks whether the ball has hit the object,  			   *
; accordingly changes the speed.						   *
;                                                          *
;***********************************************************

proc movementBallByColor
	
	; save registers
	push ax
	push cx
	push dx
	
	;  -------- check upper boundry --------
	 
	mov dx, [ballY]
	sub dx, 3
	mov cx, [ballX]

	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitUpperBoundry
	
	
	;  -------- check buttom boundry --------
	
	mov dx, [ballY]
	add dx, 23
	mov cx, [ballX]
	
	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitButtomBoundry
	
	
	;  -------- check left boundry --------
	
	mov dx, [ballY]
	mov cx, [ballX]
	sub cx, 3
	
	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitLeftBoundry
	
	mov dx, [ballY]
	add dx, 20
	mov cx, [ballX]
	sub cx, 3

	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitLeftBoundry
	
	;  -------- check right boundry --------
	
	mov dx, [ballY]
	mov cx, [ballX]
	add cx, 23
	
	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitRightBoundry

	mov dx, [ballY]
	add dx, 20
	mov cx, [ballX]
	add cx, 23

	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al , BOUNDARY_COLOR_WHITE
	JE hitRightBoundry

	
	
	;  -------- check hit ball & players (upper hit) --------
	
	mov dx, [ballY]
	sub dx, 3
	mov cx, [ballX]

	; get color pixel
	mov ah, 0Dh
	int 10h

	cmp al, P1_COLOR_BLUE
	JE hitUpperPlayer1
	cmp al, P2_COLOR_RED
	JE hitUpperPlayer2
	
	
	;  -------- check hit ball & players (buttom hit) --------
	
	mov dx, [ballY]
	add dx, 23
	mov cx, [ballX]
	
	; get color pixel
	mov ah, 0Dh
	int 10h

	cmp al, P1_COLOR_BLUE
	JE hitButtomPlayer1
	cmp al, P2_COLOR_RED
	JE hitButtomPlayer2
	
	
	;  -------- check hit ball & players (left hit) --------
	
	mov dx, [ballY]
	mov cx, [ballX]
	sub cx, 3
	
	; get color pixel
	mov ah, 0Dh
	int 10h
	
	cmp al, P1_COLOR_BLUE
	JE hitLeftPlayer1
	cmp al, P2_COLOR_RED
	JE hitLeftPlayer2
	
	mov dx, [ballY]
	add dx, 20
	mov cx, [ballX]
	sub cx, 3

	; get color pixel
	mov ah, 0Dh
	int 10h

	cmp al, P1_COLOR_BLUE
	JE hitLeftPlayer1
	cmp al, P2_COLOR_RED
	JE hitLeftPlayer2
	
	
	;  -------- check hit ball & players (right hit) --------
	
	mov dx, [ballY]
	mov cx, [ballX]
	add cx, 23
	
	; get color pixel
	mov ah, 0Dh
	int 10h

	cmp al, P1_COLOR_BLUE
	JE hitRightPlayer1
	cmp al, P2_COLOR_RED
	JE hitRightPlayer2
	
	mov dx, [ballY]
	add dx, 20
	mov cx, [ballX]
	add cx, 23

	; get color pixel
	mov ah, 0Dh
	int 10h

	cmp al, P1_COLOR_BLUE
	JE hitRightPlayer1
	cmp al, P2_COLOR_RED
	JE hitRightPlayer2
	jmp endChecking
	
	
	
;********************* BOUNDARIES ***********************	
	
	
hitUpperBoundry:
	mov [speedY], 3
	jmp endChecking

hitButtomBoundry:
	mov [speedY], -3
	jmp endChecking

hitLeftBoundry:
	mov [speedX], 3
	jmp endChecking

hitRightBoundry:
	mov [speedX], -3
	jmp endChecking


;********************* move right - hit left ***********************	
hitLeftPlayer1:
	mov ax,[p1Y]
	add ax, 5
	cmp [ballY], ax
	JLE part1Left
	add ax, 10
	cmp [ballY], ax
	Jle part2Left
	add ax, 21
	cmp [ballY], ax
	jle part3Left
	jmp endChecking
	
	
part1Left:
	mov [speedX], 3
	mov [speedY], -3
	jmp endChecking

part2Left:
	mov [speedX], 3
	mov [speedY], 0
	jmp endChecking

part3Left:
	mov [speedX], 3
	mov [speedY], 3
	jmp endChecking
	
	
hitLeftPlayer2:
	mov ax,[p2Y]
	add ax, 5
	cmp [ballY], ax
	JLE part1Left2
	add ax, 10
	cmp [ballY], ax
	Jle part2Left2
	add ax, 21
	cmp [ballY], ax
	jle part3Left2
	jmp endChecking
	
	
part1Left2:
	mov [speedX], 3
	mov [speedY], -3
	jmp endChecking

part2Left2:
	mov [speedX], 3
	mov [speedY], 0
	jmp endChecking

part3Left2:
	mov [speedX], 3
	mov [speedY], 3
	jmp endChecking

;***********************************************************	

;********************* move left - hit right **************************	
hitRightPlayer1:
	mov ax,[p1Y]
	add ax, 5
	cmp [ballY], ax
	JLE part1Right1
	add ax, 10
	cmp [ballY], ax
	Jle part2Right1
	add ax, 21
	cmp [ballY], ax
	jle part3Right1
	jmp endChecking

part1Right1:
	mov [speedX], -3
	mov [speedY], -3
	jmp endChecking

part2Right1:
	mov [speedX], -3
	mov [speedY], 0
	jmp endChecking

part3Right1:
	mov [speedX], -3
	mov [speedY], 3
	jmp endChecking
	
	
hitRightPlayer2:
	mov ax,[p2Y]
	add ax, 5
	cmp [ballY], ax
	JLE part1Right2
	add ax, 10
	cmp [ballY], ax
	Jle part2Right2
	add ax, 21
	cmp [ballY], ax
	jle part3Right2
	jmp endChecking

part1Right2:
	mov [speedX], -3
	mov [speedY], -3
	jmp endChecking

part2Right2:
	mov [speedX], -3
	mov [speedY], 0
	jmp endChecking

part3Right2:
	mov [speedX], -3
	mov [speedY], 3
	jmp endChecking

;***********************************************************

;********************* move down - hit upper *****************************
hitUpperPlayer1:
	mov ax,[p1X]
	add ax, 5
	cmp [ballX], ax
	JLE part1Up1
	add ax, 10
	cmp [ballX], ax
	Jle part2Up1
	add ax, 21
	cmp [ballX], ax
	jle part3Up1
	jmp endChecking
	
part1Up1:
	mov [speedX], -3
	mov [speedY], 3
	jmp endChecking

part2Up1:
	mov [speedX], 0
	mov [speedY], 3
	jmp endChecking

part3Up1:
	mov [speedX], 3
	mov [speedY], 3
	jmp endChecking
	
	
hitUpperPlayer2:
	mov ax,[p2X]
	add ax, 5
	cmp [ballX], ax
	JLE part1Up2
	add ax, 10
	cmp [ballX], ax
	Jle part2Up2
	add ax, 21
	cmp [ballX], ax
	jle part3Up2
	jmp endChecking
	
part1Up2:
	mov [speedX], -3
	mov [speedY], 3
	jmp endChecking

part2Up2:
	mov [speedX], 0
	mov [speedY], 3
	jmp endChecking

part3Up2:
	mov [speedX], 3
	mov [speedY], 3
	jmp endChecking
	
;***********************************************************

;********************* move up - hit buttom ***************************

hitButtomPlayer1:
	mov ax,[p1X]
	add ax, 5
	cmp [ballX], ax
	JLE part1Down1
	add ax, 10
	cmp [ballX], ax
	Jle part2Down1
	add ax, 21
	cmp [ballX], ax
	jle part3Down1
	jmp endChecking
	
part1Down1:
	mov [speedX], -3
	mov [speedY], -3
	jmp endChecking

part2Down1:
	mov [speedX], 0
	mov [speedY], -3
	jmp endChecking

part3Down1:
	mov [speedX], 3
	mov [speedY], -3
	jmp endChecking
	
hitButtomPlayer2:
	mov ax,[p2X]
	add ax, 5
	cmp [ballX], ax
	JLE part1Down2
	add ax, 10
	cmp [ballX], ax
	Jle part2Down2
	add ax, 21
	cmp [ballX], ax
	jle part3Down2
	jmp endChecking
	
part1Down2:
	mov [speedX], -3
	mov [speedY], -3
	jmp endChecking

part2Down2:
	mov [speedX], 0
	mov [speedY], -3
	jmp endChecking

part3Down2:
	mov [speedX], 3
	mov [speedY], -3
	jmp endChecking
	
;***********************************************************

endChecking:
	pop dx
	pop cx
	pop ax
	ret
endp movementBallByColor



;***********************************************************
; Procedure: printScore                                    *
;                                                          *
; Prints the two-player score on the screen  			   *
;                                                          *
;***********************************************************

proc printScore

	; save registers
	push ax
	push bx
	push cx
	push dx
	
	; Write score text
    mov al, 0                                    ; Write mode
    xor bh, bh                                   ; Page number
    mov bl, BOUNDARY_COLOR_WHITE                 ; Text color

    mov cx, 1                                    ; Text length
    mov dl, 15                                   ; Text x position
    mov dh, 0									 ; Text y position


    ; es - text segmant
    push ds
    pop es

    mov bp, offset p1Score                   ; Text offset
    ; Write score
    mov ah, 13h
    int 10h
	
	;-------------------------------------------------------------
	
	; *** If you want to make a dash between the scores of the two players ***
	
	; Write score text
    ;mov al, 0                                    ; Write mode
    ;xor bh, bh                                   ; Page number
    ;mov bl, BOUNDARY_COLOR_WHITE                   ; Text color

    ;mov cx, 1                                    ; Text length
    ;mov dl, 19                                   ; Text x position
    ;mov dh, 0									 ; Text y position



    ; es - text segmant
    ;push ds
    ;pop es

    ;mov bp, offset hyphen                   ; Text offset
    ; Write score
    ;mov ah, 13h
    ;int 10h
	
	;-------------------------------------------------------------
	
	; Write score text
    mov al, 0                                    ; Write mode
    xor bh, bh                                   ; Page number
    mov bl, BOUNDARY_COLOR_WHITE                   ; Text color

    mov cx, 1                                    ; Text length
    mov dl, 23                                   ; Text x position
    mov dh, 0									 ; Text y position



    ; es - text segmant
    push ds
    pop es

    mov bp, offset p2Score                   ; Text offset
    ; Write score
    mov ah, 13h
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret

endp printScore



;*******************************************
; 			    Main		               *
;******************************************* 

start :
	mov ax, @data
	mov ds, ax

	; Graphic mode
	mov ax, 13h
	int 10h



;*******************************************
; 			    Home Window                *
;******************************************* 

homeWin:
	push offset homeFileName
	push 0
	push 0
	push 320
	push 200
	call displayImage2
	
Wait4DataHome:
	mov ah, 1
	int 16h
	jz Wait4DataHome
	
	mov ah, 0
	int 16h
	
	cmp ah, 1h													; check if the user clicked "ESC" button - end the program
	JE endProgram
	
	cmp ah, 17h													; check if the user clicked "I" button
	JE instructionWin
	
	cmp ah, 1Ch													; check if the user clicked "Enter" button
	JE gameWin
	
	jmp Wait4DataHome



;*******************************************
; 		   Insructions Window              *
;******************************************* 

instructionWin:
	push offset instructFileName
	push 0
	push 0
	push 320
	push 200
	call displayImage2

Wait4DataInstruct:
	mov ah, 1
	int 16h
	jz Wait4DataInstruct
	
	mov ah, 0
	int 16h
	
	cmp ah, 1h													; check if the user clicked "ESC" button - return to home window
	JE homeWin
	
	jmp Wait4DataInstruct
	
	
	
;*******************************************
; 		       Game Window                 *
;******************************************* 

gameWin:

	; paint the court
	push offset areaFileName
	push 0
	push 0
	push 320
	push 200
	call displayImage2
	
	call printScore												; print the score
	
	; read player1
	push offset player1Background
	push [p1X]
	push [p1Y]
	push 36
	push 36
	call readArray
	
	; paint player1
	push offset p1FileName
	push [p1X]
	push [p1Y]
	push 36
	push 36
	call displayImage
	
	; read player1 pixels
	push offset player1Pixels
	push [p1X]
	push [p1Y]
	push 36
	push 36
	call readArray
	
	push offset player1Pixels
	push offset player1Background
	push 1296
	call deleteBackground
	
	; write player1 background
	push 1
	push offset player1Background
	push [p1X]
	push [p1Y]
	push 36
	push 36
	call writeArray
	
	

	; read player2
	push offset player2Background
	push [p2X]
	push [p2Y]
	push 36
	push 36
	call readArray
	
	; paint player2
	push offset p2FileName
	push [p2X]
	push [p2Y]
	push 36
	push 36
	call displayImage
	
	; read player2 pixels
	push offset player2Pixels
	push [p2X]
	push [p2Y]
	push 36
	push 36
	call readArray
	
	push offset player2Pixels
	push offset player2Background
	push 1296
	call deleteBackground
	
	; write player2 background
	push 2
	push offset player2Background
	push [p2X]
	push [p2Y]
	push 36
	push 36
	call writeArray
	

	
	; read ball
	push offset ballBackground
	push [ballX]
	push [ballY]
	push 20
	push 20
	call readArray
	
	; paint ball
	push offset ballFileName
	push [ballX]
	push [ballY]
	push 20
	push 20
	call displayImage
	
	; read ball pixels
	push offset ballPixels
	push [ballX]
	push [ballY]
	push 20
	push 20
	call readArray
	
	push offset ballPixels
	push offset ballBackground
	push 400
	call deleteBackground
	
	; write ball background
	push 0
	push offset ballBackground
	push [ballX]
	push [ballY]
	push 20
	push 20
	call writeArray

mainLoop:
	
	mov ax, [p1X]
	mov [formerXPlayer1], ax
	mov ax, [p1Y]
	mov [formerYPlayer1], ax
	
	mov ax, [p2X]
	mov [formerXPlayer2], ax
	mov ax, [p2Y]
	mov [formerYPlayer2], ax
	
	mov ax, [ballX]
	mov [formerXball], ax
	mov ax, [ballY]
	mov [formerYball], ax

	; Checks if the position of one of the players and / or the ball has changed and
    ; if so, delete from the current position.
	
	cmp [doMovePlayer1], 0
	je checkMovePlayer2
	
	push 1
	push offset player1Pixels
	push [p1X]
	push [p1Y]
	push 36
	push 36
	call writeArray
	
	mov [doMovePlayer1], 0
	
; ==============================
checkMovePlayer2:
	cmp [doMovePlayer2], 0
	je checkMoveBall
	
	push 2
	push offset player2Pixels
	push [p2X]
	push [p2Y]
	push 36
	push 36
	call writeArray
	
	mov [doMovePlayer2], 0
	
; ==============================
	
checkMoveBall:
	
	push 0
	push offset ballPixels
	push [ballX]
	push [ballY]
	push 20
	push 20
	call writeArray
	
	mov [doMoveBall], 0
	
	
; ==============================
	
	
delayLabel:
	
	; Receives input from the keyboard
	call keyboardInputGame

	; Updates the position of the ball
	call movementBallByColor
	
	mov ax, [speedX]
	add [ballX], ax
	
	mov ax, [speedY]
	add [ballY], ax
	
	; Checking to see if one of the players scored a goal
	call checkGoal
	
	; If a goal is scored from scratch the positions of the players and the ball
	call ResetPlayersPositionsRound
	
	; Prints the score of the two players
	call printScore	

; Checks if the position of one of the players and / or the ball has changed and
; If so, paint in the new position
checkIfPaintPlayer1:
	mov ax, [p1X]
	cmp ax, [formerXPlayer1]
	JNE printPlayer1
	mov ax, [p1Y]
	cmp ax, [formerYPlayer1]
	JE checkIfPaintPlayer2
		
printPlayer1:
	
	push 1
	push offset player1Background
	push [formerXPlayer1]
	push [formerYPlayer1]
	push 36
	push 36
	call writeArray
	
	mov [doMovePlayer1], 1


checkIfPaintPlayer2:
	mov ax, [p2X]
	cmp ax, [formerXPlayer2]
	JNE printPlayer2
	mov ax, [p2Y]
	cmp ax, [formerYPlayer2]
	JE printBall

	
printPlayer2:
	
	push 2
	push offset player2Background
	push [formerXPlayer2]
	push [formerYPlayer2]
	push 36
	push 36
	call writeArray
	
	mov [doMovePlayer2], 1
	
printBall:
	
	push 0
	push offset ballBackground
	push [formerXball]
	push [formerYball]
	push 20
	push 20
	call writeArray

continueMain:
	
	; Checking to see if one of the players won
	cmp [p1Score], WINNER_SCORE
	je p1WinnerWin
	
	cmp [p2Score], WINNER_SCORE
	je p2WinnerWin
	
	; Will run until one wins or the app closes
	jmp mainLoop
	
	
	
;*******************************************
; 		     Player1 Win Window            *
;******************************************* 

p1WinnerWin:
	push offset p1WinFilename
	push 0
	push 0
	push 320
	push 200
	call displayImage2
	
Wait4DataP1winner:
	mov ah, 1
	int 16h
	jz Wait4DataP1winner
	
	mov ah, 0
	int 16h
	
	cmp ah, 1h													; check if the user clicked "ESC" button - exit from app
	JE endProgram
	
	jmp Wait4DataP1winner
	
	
	
;*******************************************
; 		     Player2 Win Window            *
;******************************************* 

p2WinnerWin:
	push offset p2WinFilename
	push 0
	push 0
	push 320
	push 200
	call displayImage2
	
Wait4DataP2winner:
	mov ah, 1
	int 16h
	jz Wait4DataP2winner
	
	mov ah, 0
	int 16h
	
	cmp ah, 1h													; check if the user clicked "ESC" button - exit from app
	JE endProgram
		
	jmp Wait4DataP2winner



;*******************************************
; 		    End of the program             * 
;******************************************* 

endProgram:
	; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h

exit:
	mov ax, 4c00h
	int 21h

END start



; Just to have a nice number of lines (-: