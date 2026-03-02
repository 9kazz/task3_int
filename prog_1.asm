.286
JUMPS
locals @@
.model tiny
.code
org 100h

;                   MACROSES & DEFINES
;==================================================================================================================

;                   PRINT_STR
;------------------------------------------------------------------------------------------------------------------
; Descr:    store string to es:[di] memmory addres
; Entry:    str_adr == storing string addres
;           str_len == storing string length
; Exit:     si -> data after storing string
; Exp:      es:[ds] -> wanted memmory location to store the string
; Destr:    ax, cx | si
; Save:     --
;------------------------------------------------------------------------------------------------------------------

PRINT_STR           macro str_adr, str_len
                    mov si, str_adr
                    mov cx, str_len
                    @@print_one_char:
                        lodsw
                        stosw
                        loop @@print_one_char
                    endm

;==================================================================================================================

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
                    PUSH ax

                    in al, 60h                  ; al = scan-code        
                    cmp al, 2                   ; scan-code to trigger regs dump
                    jne @@end_of_int

                    PUSHF
                    PUSH ss es ds sp bp di si dx cx bx ax   ; save regs

                    PUSH cs cs
                    POP ds es

                    mov di, offset Draw_buf     ; di -> Draw_buf
                    add di, (5 * 80 + 40) * 2        

                    mov cx, 11                  ; count of printing regs
                    mov bp, sp                  ; bp -> head of the stack

                    PUSHF 
                    POP bx                      ; bx = flag-reg
                    CALL Repack_flag_reg        ; bx = repacked flag-reg
                    mov si, offset Prefix_arr   ; si -> Prefix_arr

    @@print_one_line:
                    PUSH di                         ; save start of cur line

        @@print_reg_prefix:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of reg-prefix
                        je  @@print_reg_value
                    stosw
                    jmp @@print_reg_prefix

        @@print_reg_value:
                    mov dx, [bp]
                    CALL Itoa


        @@print_flag_prefix:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of flag-prefix
                        je @@print_flag_value 
                    cmp ax, '%'                     ; '%' means end of whole line (no more flags)
                        je @@end_of_cycle 
                    stosw
                    jmp @@print_flag_prefix

        @@print_flag_value:
                    mov al, bl
                    and al, 1                   ; al = cur flag value
                    add al, 48
                    mov ah, 70h                 ; ah = attribute
                    stosw                       

                    shr bx, 1

    @@end_of_cycle: POP di
                    add di, 80 * 2              ; new line
                    add bp, 2                   ; next reg
                    
                    loop @@print_one_line

                    PUSH 0b800h
                    POP es                      ; es -> VM
                    CALL Dump_Draw_buf

                    POP ax bx cx dx si di bp sp ds es ss        ; recover regs
                    POPF

    @@end_of_int:   in al, 61h
                    or al, 80h                  ; port blinking
                    out 61h, al
                    and al, not 80h
                    out 61h, al    

                    mov al, 20h                 ; report PPI about end of int
                    out 20h, al

                    POP ax
                    
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
; Destr:    ax, dx | di
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

;                   REPACK_FLAG_REG
;------------------------------------------------------------------------------------------------------------------
; Descr:    repack flag-register`s flags into bx in order c-p-a-z-s-t-i-d-o to convenient handle.
; Entry:    bx == flag-register
; Exit:     bx == repacked flag-register
; Exp:      --
; Destr:    ax | bx
; Note:     originaly in flag-register flags are located in appropriate order:
;           c(0), p(2), a(4), z(6), s(7), t(8), i(9), d(10), o(11) 
;           * numder of the register`s bit in the bracket    
;------------------------------------------------------------------------------------------------------------------

Repack_flag_reg     proc

                    or ah, 1
                    and ah, bl
                    and ah, 1        ; ah = 0...0c (not hex num -- it`s flag configuration in the flag-register)

                    irp MASK, <2, 4> ; after end of this macros ah = 0...apc, dx = ...oditsz0a0p
                    shr bx, 1
                    mov al, bl
                    and al, MASK
                    or ah, al
                    endm

                    shr bx, 1       ; bx = ...oditsz0a0
                    and bx, 01F8h   ; bx = 0...0oditsz000
                    or bl, ah       ; bx = 0...0oditszapc

                    ret
                    endp


;                   INIT_DATA
;==================================================================================================================

; Buffers
Draw_buf            db 80 * 25 * 2 dup (0)
Draw_buf_Len        = 80 * 25 * 2

; ; Prefixes to print registers ('$' means end of prefix)
; Reg_prefix_arr      dw 0700h + 'a', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ax = $"
;                     dw 0700h + 'b', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "bx = $"
;                     dw 0700h + 'c', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "cx = $"
;                     dw 0700h + 'd', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "dx = $"
;                     dw 0700h + 's', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "si = $"
;                     dw 0700h + 'd', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "di = $"
;                     dw 0700h + 'b', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "bp = $"
;                     dw 0700h + 's', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "sp = $"
;                     dw 0700h + 'd', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ds = $"
;                     dw 0700h + 'e', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "es = $"
;                     dw 0700h + 's', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ss = $"
                 
; ; Prefixes to print flags ('%' means new line, '$' means end of prefix)              
; Flag_prefix_arr     dw 0700h + ' ', 0700h + 'c', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " c = %"
;                     dw 0700h + ' ', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " p = $"
;                     dw 0700h + ' ', 0700h + 'a', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " a = $"
;                     dw 0700h + ' ', 0700h + 'z', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " z = $"
;                     dw 0700h + ' ', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " s = $"
;                     dw 0700h + ' ', 0700h + 't', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " t = $"
;                     dw 0700h + ' ', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " i = $"
;                     dw 0700h + ' ', 0700h + 'd', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " d = $"
;                     dw 0700h + ' ', 0700h + 'o', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " o = $"
;                     dw '%'                                                                   ; "%"
;                     dw '%'                                                                   ; "%"

Prefix_arr      dw 0700h + 'a', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ax = $"
                    dw 0700h + ' ', 0700h + 'c', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " c = $"

                    dw 0700h + 'b', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "bx = $"
                    dw 0700h + ' ', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " p = $"

                    dw 0700h + 'c', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "cx = $"
                    dw 0700h + ' ', 0700h + 'a', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " a = $"

                    dw 0700h + 'd', 0700h + 'x', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "dx = $"
                    dw 0700h + ' ', 0700h + 'z', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " z = $"

                    dw 0700h + 's', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "si = $"
                    dw 0700h + ' ', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " s = $"

                    dw 0700h + 'd', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "di = $"
                    dw 0700h + ' ', 0700h + 't', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " t = $"

                    dw 0700h + 'b', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "bp = $"
                    dw 0700h + ' ', 0700h + 'i', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " i = $"

                    dw 0700h + 's', 0700h + 'p', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "sp = $"
                    dw 0700h + ' ', 0700h + 'd', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " d = $"

                    dw 0700h + 'd', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ds = $"
                    dw 0700h + ' ', 0700h + 'o', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; " o = $"

                    dw 0700h + 'e', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "es = $"
                    dw '%'                                                                   ; "%"

                    dw 0700h + 's', 0700h + 's', 0700h + ' ', 0700h + '=', 0700h + ' ', '$'  ; "ss = $"
                    dw '%'                                                                   ; "%"

;------------------------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    
