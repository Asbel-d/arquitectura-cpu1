org 100h

mov ax,1110h
mov bx,1000h
mov cx,256
xor dx,dx
mov bp,font
int 10h
int 20h

font: file 'terminus.f16'
