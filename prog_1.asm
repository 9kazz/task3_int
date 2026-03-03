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
;           by pressing "1" on keyboard
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

                    mov ax, cs
                    mov ds, ax                  
                    mov es, ax                  ; ds, es -> code seg

                    mov cx, Count_of_regs       ; count of printing regs
                    mov bp, sp                  ; bp -> head of the stack
                    mov di, offset Stack_buf 

    @@save_stack:   mov ax, [bp + 30]           ; bp + 30 == the head of stack before int call
                    stosw
                    add bp, 2
                    loop @@save_stack

                    mov di, offset Draw_buf     ; di -> Draw_buf
                    PUSH di

                    CALL Repack_flag_reg        ; bx = repacked flag-reg
                    mov si, offset Frame_arr    ; si -> Frame_arr 

;                           === UPPER FRAME SIDE ===
    @@print_frame_uside:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of line
                        je  @@cycle_init
                    cmp ax, '%'
                        je @@new_line 
                    stosw
                    jmp @@print_frame_uside

    @@new_line:     POP di
                    add di, Frame_len * 2           ; new line
                    PUSH di
                    jmp @@print_frame_uside

;                           === MAIN CYCLE: FILLING ONE LINE ===

    @@cycle_init:   POP di
                    add di, Frame_len * 2           ; new line
                    mov cx, Count_of_regs           ; count of printing regs

    @@print_one_line:
                    PUSH di                         ; save start of cur line

;                           === PRINT REGISTERS & LEFT FRAME SIDE ===
        @@print_reg_prefix:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of reg-prefix
                        je  @@print_reg_value
                    stosw
                    jmp @@print_reg_prefix

        @@print_reg_value:
                    mov dx, [bp]
                    CALL Itoa

;                           === PRINT FLAGS ===
        @@print_flag_prefix:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of flag-prefix
                        je @@print_flag_value 
                    cmp ax, '%'                     ; '%' means end of printing flag (no more flags)
                        je @@print_stk_prefix
                    stosw
                    jmp @@print_flag_prefix

        @@print_flag_value:
                    mov al, bl
                    and al, 1                   ; al = cur flag value
                    add al, 48                  ; 48 is ASCII "0"
                    mov ah, TEXT_ATR            ; ah = attribute
                    stosw                       

                    shr bx, 1

;                           === PRINT STACK ===
        @@print_stk_prefix:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of stack-prefix
                        je  @@print_stk_value
                    stosw
                    jmp @@print_stk_prefix

        @@print_stk_value:
                    PUSH bx              
                    mov bx, Count_of_regs   
                    sub bx, cx
                    shl bx, 1
                    mov dx, [Stack_buf + bx]
                    CALL Itoa
                    POP bx

;                           === PRINT FRAME RIGHT SIDE ===
        @@print_frame_rside:
                    lodsw
                    cmp ax, '$'                     ; '$' means end of line
                        je  @@end_of_cycle
                    stosw
                    jmp @@print_frame_rside

    @@end_of_cycle: POP di
                    add di, Frame_len * 2       ; new line
                    add bp, 2                   ; next reg
                    
                    loop @@print_one_line

;                           === LOWER FRAME SIDE ===
    @@print_frame_lside:
                    lodsw
                    cmp ax, '$'                 ; '$' means end of line
                        je  @@end_of_printing
                    stosw
                    jmp @@print_frame_lside


    @@end_of_printing: 
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

                    mov ah, TEXT_ATR            ; attribute
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
; Exp:      --
; Destr:    ax
; Save:     cx, si, di, es, bx
;------------------------------------------------------------------------------------------------------------------

Dump_Draw_buf       proc

                    PUSH cx si di es bx

                    mov ax, 0b800h
                    mov es, ax                  ; es -> VM

                    mov si, offset Draw_buf     ; si -> start of Print_buf
                    mov di, Frame_offset_VM     ; di -> start position in VM
                    
                    mov bx, Frame_wid           ; bx = count of lines to print
                    
    @@print_one_line:                    
                    mov cx, Frame_len           ; cx = count of chars in one line

        @@print_one_char:
                    lodsw 
                    stosw
                    loop @@print_one_char

    @@new_line:     add di, New_line_remain
                    dec bx
                    test bx, bx
                    jnz @@print_one_line

                    POP bx es di si cx
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

                    PUSHF 
                    POP bx           ; bx = flag-reg

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

;                   DRAW_BUF_CMP_VM
;------------------------------------------------------------------------------------------------------------------
; Descr:    compare characters (with their`s attributes) from VM with appropriate characters from Draw_buf
;           and if they aren`t same, change current character in Draw_buf and Save_buf to another one from VM
; Entry:    --
; Exit:     --
; Exp:      es -> VM
;           ds -> data seg (equal code seg in model tiny)
; Destr:    --
; Save:     ax, bx, si, di, cx, dx
;------------------------------------------------------------------------------------------------------------------

Draw_buf_cmp_VM     proc
                    PUSH ax bx si di cx dx

                    mov bx, offset Save_buf             ; bx -> start of the Save_buf
                    mov si, offset Draw_buf             ; si -> start of the Draw_buf
                    mov di, Frame_offset_VM             ; di -> start printing position of the VM

                    mov dx, Frame_wid                   ; dx = count of the lines to check

    @@check_one_line:
                    mov cx, Frame_len                   ; cx = count of the chars to check in one line 
        @@cmp_one_char: 
                    lodsw                               ; ax = char from Draw_buf
                    scasw                               ; cmp ax with appropriate char from VM
                    jne @@copy_char
        @@continue: add bx, 2                           ; next char in the Save_buf
                    loop @@cmp_one_char

    @@new_line:     add di, New_line_remain
                    dec dx
                    test dx, dx
                    jnz @@check_one_line

                    POP dx cx di si bx ax
                    ret

    @@copy_char:    mov ax, es:[di - 2]     ; ax = char from VM. di-2 because scasb increased di before.
                    mov ds:[si - 2], ax     ; VM ds:[si] -> Draw_buf es:[di]
                    mov es:[bx], ax         ; VM ds:[si] -> Save_buf es:[bx]
                    jmp @@continue

                    endp

;                   DRAW_BUF_CMP_VM
;------------------------------------------------------------------------------------------------------------------
; Descr:    copy screen area under the frame from VM to Save_buf.
; Entry:    --
; Exit:     --
; Exp:      --
; Destr:    --
; Save:     ax, bx, si, di, cx, dx
;------------------------------------------------------------------------------------------------------------------

VM_copy_to_Save_buf proc
                    PUSH cx si di es bx ax

                    mov ax, 0b800h
                    mov ds, ax                  ; ds -> VM
                    mov ax, cs
                    mov es, cs                  ; es -> code deg


                    mov di, offset Save_buf     ; di -> start of Save_buf
                    mov si, Frame_offset_VM     ; si -> start position in VM
                    
                    mov bx, Frame_wid           ; bx = count of lines to print
                    
    @@copy_one_line:                    
                    mov cx, Frame_len           ; cx = count of chars in one line

        @@copy_one_char:
                    lodsw 
                    stosw
                    loop @@copy_one_char

    @@new_line:     add si, New_line_remain
                    dec bx
                    test bx, bx
                    jnz @@copy_one_line

                    POP ax bx es di si cx
                    ret

                    endp

;                   INIT_DATA
;==================================================================================================================

; Buffers & constants
Count_of_regs       = 11
Frame_wid           = 16
Frame_len           = 29
Frame_size          = Frame_len * Frame_wid * 2
Frame_offset_VM     = (26 + 4 * 80) * 2
New_line_remain     = (80 - 29) * 2
Draw_buf            db Frame_size dup (0)
Save_buf            db Frame_size dup (0)

Stack_buf           dw 11 dup(0)

; Prefixes to print flags ('%' means new line, '$' means end of text-block)
TEXT_ATR            = 70h
FRAME_ATR           = 7000h
Frame_arr           dw 9 dup(FRAME_ATR + ' '), FRAME_ATR + 'I', FRAME_ATR + 'N', FRAME_ATR + 'F', FRAME_ATR + 'O', FRAME_ATR + 'R', FRAME_ATR + 'M', FRAME_ATR + 'A', FRAME_ATR + 'T', FRAME_ATR + 'I', FRAME_ATR + 'O', FRAME_ATR + 'N', 9 dup(FRAME_ATR + ' '), '%'    ; "         INFORMATION         %"
                    dw FRAME_ATR + 0c9h, 27 dup(FRAME_ATR + 0cdh), FRAME_ATR + 0bbh, '%'                                                            ; upper frame side
                    dw FRAME_ATR + 0bah, 4 dup(FRAME_ATR + ' '), FRAME_ATR + 'R', FRAME_ATR + 'E', FRAME_ATR + 'G', FRAME_ATR + 'S', 3 dup(FRAME_ATR + ' '), FRAME_ATR + 0b3h, 1 dup(FRAME_ATR + ' '), FRAME_ATR + 'F', FRAME_ATR + 'L', FRAME_ATR + 'A', FRAME_ATR + 'G', FRAME_ATR + 'S', 1 dup(FRAME_ATR + ' '), FRAME_ATR + 0b3h, 1 dup(FRAME_ATR + ' '), FRAME_ATR + 'S', FRAME_ATR + 'T', FRAME_ATR + 'A', FRAME_ATR + 'C' , FRAME_ATR + 'K', 1 dup (FRAME_ATR + ' '), FRAME_ATR + 0bah, '%'
                    ; "|   REGS   FLAGS   STACK   |"
                    dw FRAME_ATR + 0bah, 27 dup(FRAME_ATR + 0c4h), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '                                                                                            ; left frame side
                    dw FRAME_ATR + 'a', FRAME_ATR + 'x',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "ax = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'c', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | c = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw FRAME_ATR + '<', FRAME_ATR + 0c4h, FRAME_ATR + 0bah, '$'                                                                                       ; right frame side

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'b', FRAME_ATR + 'x',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "bx = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'p', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | p = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'c', FRAME_ATR + 'x',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "cx = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'a', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | a = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'd', FRAME_ATR + 'x',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "dx = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'z', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | z = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 's', FRAME_ATR + 'i',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "si = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 's', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | s = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'd', FRAME_ATR + 'i',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "di = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 't', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | t = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'b', FRAME_ATR + 'p',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "bp = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'i', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | i = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 's', FRAME_ATR + 'p',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "sp = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'd', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | d = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'd', FRAME_ATR + 's',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "ds = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', FRAME_ATR + 'o', FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'  ; " | o = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 'e', FRAME_ATR + 's',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "es = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', 5 dup(FRAME_ATR + ' '), '%'                                              ; " |      %"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0bah, FRAME_ATR + ' '
                    dw FRAME_ATR + 's', FRAME_ATR + 's',  FRAME_ATR + ' ', FRAME_ATR + '=', FRAME_ATR + ' ', '$'                                    ; "ss = $"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', 5 dup(FRAME_ATR + ' '), '%'                                              ; " |      %"
                    dw FRAME_ATR + ' ', FRAME_ATR + 0b3h, FRAME_ATR + ' ', '$'                                                                      ; " | $"
                    dw 2 dup(FRAME_ATR + ' '), FRAME_ATR + 0bah, '$'

                    dw FRAME_ATR + 0c8h, 27 dup(FRAME_ATR + 0cdh), FRAME_ATR + 0bch, '$'                                                            ; lower frame side
;------------------------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    
