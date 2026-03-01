.286
locals @@
.model tiny
.code
org 100h

;-------------------------------------------------------------------------------------------------

Print_buf           db 80 * 25 dup (0)
Print_buf_Len       = 80 * 25

;-------------------------------------------------------------------------------------------------

Start:              mov ax, 3509h               ; find out adr of int handler
                    int 21h
                    mov Old_09_ofs, bx
                    mov bx, es
                    mov Old_09_seg, bx

                    push 0
                    pop es                      ; es -> int table
                    cli                         ; int flag = 0
                    mov bx, 09h * 4             ; 4 is size of elem in int table
                    mov es:[bx], offset New_int ; adr = New_int (in int table)
                    mov ax, cs                  ; ax -> code seg
                    mov es:[bx + 2], ax         ; seg = cs (in int table)
                    sti                         ; int flag = 1

                    mov ax, 3100h               ; int 21h: fn resident ending
                    mov dx, offset End_of_prog  ; dx = size of all program code (in bytes)
                    shr dx, 4                   ; ...(in paragraphs)
                    inc dx                      ; division remainder
                    int 21h

New_int             proc
                    push ax bx cx dx es

                    push 0b800h
                    pop es                      ; es -> VM
                    mov bx, (5 * 80d + 40d) * 2 ; offset in VM
                    mov ah, 4eh                 ; color attribute

                    ; in al, 60h                  ; al = scan-code        
                    ; mov es:[bx], ax

                    in al, 61h
                    or al, 80h                  ; port blinking
                    out 61h, al
                    and al, not 80h
                    out 61h, al    

                    mov al, 20h                 ; report PPI about end of int
                    out 20h, al

                    pop es dx cx bx ax
                    
                    db 0eah                     ; jmp far to old int
                    Old_09_ofs dw 0
                    Old_09_seg dw 0

                    iret                        ; return from jmp far
                    endp
                        
;-------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    


;                   ITOA
;------------------------------------------------------------------------------------------------------------------
; Descr:    convert register value into string uncludes hex digits and save it in the di-addres
; Entry:    dx == value to convert
;           di -> memmory to save string
; Exit:     di += 4 (count of hex digit)
; Exp:      --
; Destr:    ax dx
; Save:     cx
;------------------------------------------------------------------------------------------------------------------

Itoa                proc
                    PUSH cx

                    mov cx, 4

    @@get_one_sign: mov al, dh                  ; get 4 highest bytes in temp reg
                    shr al, 4                   ; get highest bytes in lower pos in temp reg
                    shl dx, 4                   ; get next 4 bytes in highest pos

                    cmp al, 9
                    ja @@trans2letter

    @@trans2digit:  add al, 48                  ; al = ASCII digit
    @@fill_buf:     stosb                       ; store ASKII in Print_buf 

                    loop @@get_one_sign

                    POP cx
                    ret

    @@trans2letter: add al, 55
                    jmp @@fill_buf              ; al = ASKII letter

                    endp

;                   DUMP_PRINT_BUF
;------------------------------------------------------------------------------------------------------------------
; Descr:    print data from Print_buf into VM
; Entry:    --
; Exit:     --
; Exp:      es -> VM
; Destr:    ax
; Save:     cx, si, di
;------------------------------------------------------------------------------------------------------------------


Dump_Print_buf:     proc

                    PUSH cx, si, di

                    mov cx, Print_buf_Len
                    mov ah, 70h                 ; attribute

                    mov si, offset Print_buf    ; si -> start of Print_buf
                    xor di, di                  ; fi -> start of VM
                    
    @@print_one_char:
                    lodsb 
                    stosw
                    loop @@print_one_char

                    POP di, si, cx
                    ret

                    endp