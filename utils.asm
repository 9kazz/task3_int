;                   ITOA
;------------------------------------------------------------------------------------------------------------------
; Descr:    convert register value into string consisting hex digits and save it in the di-addres
; Entry:    dx == value to convert
;           di -> memmory to save string
; Exit:     di += 4 (count of hex digit)
; Exp:      --
; Destr:    ax, dx | Change: di
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

    @@trans2digit:  add al, '0'                  ; al = ASCII digit
    @@fill_buf:     stosw                       ; store ASKII in buffer

                    loop @@get_one_sign

                    POP cx
                    ret

    @@trans2letter: add al, 'A' - 10
                    jmp @@fill_buf              ; al = ASKII letter

                    endp

;                   REPACK_FLAG_REG
;------------------------------------------------------------------------------------------------------------------
; Descr:    repack flag-register`s into bx in order c-p-a-z-s-t-i-d-o. It necessary to more convenient handle.
; Entry:    bx == flag-register
; Exit:     bx == repacked flag-register
; Exp:      --
; Destr:    ax | Change: bx
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

