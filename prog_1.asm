.286
JUMPS
locals @@
.model tiny
.code
org 100h

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


;                   NEW_INT
;------------------------------------------------------------------------------------------------------------------
; Descr:    this code block replaces original 09h interrapt. Prints all registers and flags into VM 
;           by pressing "r" on keyboard
; Entry:    --
; Exit:     --
; Exp:      --
; Destr:    --
; Save:     ax, bx, cx, dx, es
;------------------------------------------------------------------------------------------------------------------

New_int             proc
                    PUSH ax dx di es ds

                    in al, 60h                  ; al = scan-code        
                    cmp al, 2                   ; scan-code to trigger regs dump
                    jne @@end_of_int

                    PUSH cs cs
                    POP ds es

                    mov di, offset Draw_buf     ; di -> Draw_buf
                    add di, (5 * 80 + 40) * 2        

                    irp REG, <ax, bx, cx, dx, si, di, bp, sp, ds, es, ss, cs>   ; print regs
                    mov dx, REG
                    CALL Itoa
                    add di, (80 - 4) * 2
                    endm

                    PUSH 0b800h
                    POP es                      ; es -> VM
                    CALL Dump_Draw_buf

    @@end_of_int:   in al, 61h
                    or al, 80h                  ; port blinking
                    out 61h, al
                    and al, not 80h
                    out 61h, al    

                    mov al, 20h                 ; report PPI about end of int
                    out 20h, al

                    POP ds es di dx ax
                    
                    db 0eah                     ; jmp far to old int
                    Old_09_ofs dw 0
                    Old_09_seg dw 0

                    iret                        ; return from jmp far
                    endp

;                   ITOA
;------------------------------------------------------------------------------------------------------------------
; Descr:    convert register value into string uncludes hex digits and save it in the di-addres
; Entry:    dx == value to convert
;           di -> memmory to save string
; Exit:     di += 4 (count of hex digit)
; Exp:      --
; Destr:    ax dx | di
; Save:     cx
;------------------------------------------------------------------------------------------------------------------

Itoa                proc
                    PUSH cx

                    mov ah, 070h                ; attribute
                    mov cx, 4

    @@get_one_sign: mov al, dh                  ; get 4 highest bytes in temp reg
                    shr al, 4                   ; get highest bytes in lower pos in temp reg
                    shl dx, 4                   ; get next 4 bytes in highest pos

                    cmp al, 9
                    ja @@trans2letter

    @@trans2digit:  add al, 48                  ; al = ASCII digit
    @@fill_buf:     stosw                       ; store ASKII in buffer

                    loop @@get_one_sign

                    POP cx
                    ret

    @@trans2letter: add al, 55
                    jmp @@fill_buf              ; al = ASKII letter

                    endp

;                   DUMP_DRAW_BUF
;------------------------------------------------------------------------------------------------------------------
; Descr:    print data from Print_buf into VM
; Entry:    --
; Exit:     --
; Exp:      es -> VM
; Destr:    ax
; Save:     cx, si, di
;------------------------------------------------------------------------------------------------------------------

Dump_Draw_buf       proc

                    PUSH cx si di

                    mov cx, Draw_buf_Len

                    mov si, offset Draw_buf    ; si -> start of Print_buf
                    xor di, di                 ; di -> start of VM
                    
    @@print_one_char:
                    lodsw 
                    stosw
                    loop @@print_one_char

                    POP di si cx
                    ret

                    endp

;-------------------------------------------------------------------------------------------------

; INIT BUFFERS
Draw_buf            db 80 * 25 * 2 dup (0)
Draw_buf_Len        = 80 * 25 * 2
                
;-------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    
