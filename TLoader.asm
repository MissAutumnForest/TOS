#make_boot#

; boot record is loaded at 0000:7c00
org 7c00h

; initialize the stack:
mov ax, 07c0h
mov ss, ax
mov sp, 03feh ; top of the stack.


; set data segment:
xor ax, ax
mov ds, ax

mov ah, 02h ; read function.
mov al, 2   ; sectors to read.
mov ch, 0   ; cylinder.
mov cl, 2   ; sector.
mov dh, 0   ; head.
; dl not changed! - drive number.

; es:bx points to receiving
; data buffer:
mov bx, 1000h   
mov es, bx
mov bx, 0

; read!
int 13h

; pass control to kernel:
jmp 1000h:0000h