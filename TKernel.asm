; #Name: TKernel
; #Description: TabsOS Kernel
; #Author: Timothy Peacock
; #Started: 12/20/2010
; #Last Updated: 10/14/2013

; Assemble to .com format (for testing purposes)
org 100h

mov ax, 0003h ; Set video mode to 80x25 text mode
int 10h       ; Call bios interupt 10h

; #Main Loop

main:
	lea si, [prompt]  ; Load the prompt text into SI
	call dstring	  ; Display the text in SI
	lea di, [keybuff] ; Load keybuff (the keyboard buffer) into DI
	call keyboard	  ; Call keyboard (for keyboard input processing)

	; #Move the cursor down one
	mov ah, 03h ; Get cursor position
	int 10h     ;

	mov dl, 0 ; Put 0 into dl
	inc dh	  ; Increase dh (move the cursor down one)
	mov ah, 2 ; Set the cursor position
	int 10h   ;

	call cmdCmp ; Compare the key buffer for any of the supported commands
	jmp main    ; Jump back to main (creating an infinite loop)

cmdCmp:
	push si
	lea si, [keybuff]
	lea di, [comCls]
	call strcmp
	cmp al, 1
	jz clear
    
	lea si, [keybuff]
	lea di, [comHelp]
	call strcmp
	cmp al, 1
	jz help
    
	lea si, [keybuff]
	mov al, [si]
	cmp al, 0
	jz main
    
	jmp ecom

	clear:
		call clear_screen
		call write_sector
		jmp main

	help:
		lea si, [helptext]
		call dstring
		jmp afterCmd

	ecom:
		lea si, [ecomtext1]
		call dstring

		lea si, [keybuff]
		call dstring

		lea si, [ecomtext2]
		call dstring
		jmp afterCmd
		
; #String Functions

; #Name: keyboard
; #Description: processes input from the keyboard
; #Argument(s): di - Offset of buffer (lea di, [buffer]  
keyboard:
	cld
	xor bx, bx

	getKeyLoop:
		mov ah, 00h ; Get key from buffer
		int 16h     ;

		cmp al, 13	; Check to see if the enter key was pressed
		jz enterKey	; and go to the "enterkey" label

		cmp al, 8	; Check to see if the backspace key was pressed
		jz back 	; and go to the "back" label

		; #Output the character entered to the screen
		mov ah, 0eh
		int 10h

		; #Add the character to "keybuff" buffer
		stosb
		inc bx

		jmp getKeyLoop ; Jump to the "getKeyLoop" label to do it again

	enterKey:
		mov al, 0
		stosb
		ret

	back:
		mov al, 8
		mov ah, 0eh
		int 10h

		mov al, 0
		mov bh, 0
		mov cx, 1
		mov ah, 0ah
		int 10h

		dec di
		jmp getKeyLoop


afterCmd:
	; #Move the cursor down 2
	mov ah, 03h
	int 10h

	add dh, 2
	mov dl, 0
	mov bh, 0
	mov ah, 2
	int 10h
	jmp main

strcmp:
	; |================================|
	; |      Compare two strings       |
	; |================================|
	; | si - First string              |
	; | di - Second string             |
	; | al=1 equal                     |
	; | al=0 not equal                 |
	; |================================|
	mov al, [si]
	mov bl, [di]
	cmp al, bl
	jne notequal

	cmp al, 0
	je strdone

	inc di
	inc si
	jmp strcmp

	notequal:
		mov al, 0
		ret

	strdone:
		mov al, 1
		ret

dstring:
	; |=========================================|
	; |    Display a string onto the screen     |
	; |=========================================|
	; | si - offset of string (lea si, [msg])   |
	; |=========================================|
	disploop:
		lodsb
		cmp al, 0
		je enddisp
		mov ah, 0Eh
		int 10h
		jmp disploop

	enddisp:
		ret

clear_screen:
	mov cx, 0	 ; Upper-left corner of full screen
	mov dx, 8025	 ; Load lower-right XY coordinates into dx
	mov al, 0	 ; 0 specifies clear entire region
	mov bh, 07h	 ; Specify "normal" attribute for blanked line(s)
	mov ah, 06h	 ; Select VIDEO service 6: Initialize/Scroll
	int 10h 	 ; Call VIDEO

	; Set the cursor to the beginning of the screen
	mov dh, 0
	mov dl, 0
	mov bh, 0
	mov ah, 2
	int 10h

	ret
	
write_sector:
    xor ax, ax
    mov ds, ax
    
    mov ax, 0310h ;write sector|read 10 sector
    mov cx, 0002h ;Cylinder|Starting sector
    mov dx, 0000h ;head|drive (0 for floppy)
    mov bx, offset databuff
    int 13h
    jc writeError
    ret
    
    writeError:
    ret 
    

; #String Variables
databuff db 512 dup (0)
keybuff db 100 dup(?)  ; Buffer for keyboard input
prompt db "TOS>",0     ; Prompt text

; #Help text
helptext db "TabsOS Help:",13,10
	 db "1) help - Displays this text",13,10
	 db "2) clear - Clears the screen",0

; #Command not recognized text
ecomtext1 db "Command '",0
ecomtext2 db "' Not recognized. Type help for a list of supported commands",0

; #Commands
comCls db "clear",0 ; Cls command
comHelp db "help",0 ; Help command

dw 0xAA55		   ; Boot signature (standard)