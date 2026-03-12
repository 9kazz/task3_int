.286
JUMPS
locals @@
.model tiny
.code
org 100h

;==================================================================================================================

Start:              mov ax, 3509h                   ; find out adr of int 09h handler
                    int 21h
                    mov Old_09_ofs, bx
                    mov bx, es
                    mov Old_09_seg, bx

                    push 0
                    pop es                          ; es -> int table

                    cli                             ; int flag = 0
                    mov bx, 09h * 4                 ; 4 is size of elem in int table
                    mov es:[bx], offset New_int09   ; adr = New_int08 (in int table)
                    mov ax, cs                      ; ax -> code seg
                    mov es:[bx + 2], ax             ; seg = cs (in int table)
                    sti

                    mov ax, 3100h                   ; int 21h: fn resident ending
                    mov dx, offset End_of_prog      ; dx = size of all program code (in bytes)
                    shr dx, 4                       ; ...(in paragraphs)
                    inc dx                          ; division remainder
                    int 21h


MouseClick_handler  proc
                    PUSHA
                    PUSH es

                    test bx, 1
                    jz @@end_of_func

                    mov ax, 0b800h
                    mov es, ax
                    mov bx, (5*80+40)*2
                    mov ax, 4c03h
                    mov es:[bx], ax

    @@end_of_func:  POP es
                    POPA
                    xor cx, cx
                    retf
                    endp


New_int09           proc
                    PUSH sp ss es ds bp di si dx cx bx ax       ; save regs

                    in al, 60h                  ; al = scan-code 
                    cmp al, 2                   ; scan-code to print Save_buf
                    jne @@end_of_int

                    push cs
                    pop es
                    mov dx, offset MouseClick_handler
                    mov ax, 000ch                   ; set mouse-click handler
                    mov cx, 02h                     ; set event mask
                    int 33h

    @@end_of_int:   POP ax bx cx dx si di bp ds es ss sp        ; recover regs

                    db 0eah                     ; jmp far to old int 08
                    Old_09_ofs dw 0
                    Old_09_seg dw 0

                    endp

;------------------------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    