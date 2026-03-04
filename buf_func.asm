;                   DRAW_BUF_CMP_VM
;------------------------------------------------------------------------------------------------------------------
; Descr:    compare characters (with their`s attributes) from VM with appropriate characters from Draw_buf
;           and if they aren`t same, change current character in Draw_buf and Save_buf to another one from VM.
; Entry:    --
; Exit:     --
; Exp:      es -> VM
;           ds -> data seg (equal code seg in model tiny)
; Glob:   - Frame_wid
;         - Frame_len
;         - Frame_offset_VM -- offset in VM to frame`s upper-left corner position
;         - New_line_remain -- offset from the last frame character in line 
;                              to the first frame character in the line below 
;         - Save_buf, Draw_buf which size equal to size of the frame
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
                    mov ds:[bx], ax         ; VM ds:[si] -> Save_buf es:[bx]
                    jmp @@continue

                    endp

;                   VM_COPY_TO_SAVE_BUF
;------------------------------------------------------------------------------------------------------------------
; Descr:    copy characters (with their`s attributes) from the VM to Save_buf. Works with area under the frame only.
; Entry:    --
; Exit:     --
; Exp:      --
; Glob:   - Frame_wid
;         - Frame_len
;         - Frame_offset_VM -- offset in VM to frame`s upper-left corner position
;         - New_line_remain -- offset from the last frame character in line 
;                              to the first frame character in the line below 
;         - Save_buf
; Destr:    --
; Save:     ax, bx, cx, si, di, ds, es
;------------------------------------------------------------------------------------------------------------------

VM_copy_to_Save_buf proc
                    PUSH cx si di es bx ax ds

                    mov ax, 0b800h
                    mov ds, ax                  ; ds -> VM
                    mov ax, cs
                    mov es, ax                  ; es -> code seg

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

                    POP ds ax bx es di si cx
                    ret

                    endp

;                   Print_buf
;------------------------------------------------------------------------------------------------------------------
; Descr:    print data from buffer (which size Frame_len*Frame_wid) into VM.
; Entry:    ax -> start of printing buffer
; Exit:     --
; Exp:      ds -> code seg 
; Glob:   - Frame_wid
;         - Frame_len
;         - Frame_offset_VM -- offset in VM to frame`s upper-left corner position
;         - New_line_remain -- offset from the last frame character in line 
;                              to the first frame character in the line below 
; Destr:    ax
; Save:     bx, cx, si, di, es, ds
;------------------------------------------------------------------------------------------------------------------

Print_buf           proc

                    PUSH cx si di es bx ds

                    mov si, ax                  ; si -> start of Save_buf
                    mov di, Frame_offset_VM     ; di -> start position in VM

                    mov ax, 0b800h
                    mov es, ax                  ; es -> VM
                    mov ax, cs
                    mov ds, ax                  ; ds -> code seg
                    
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

                    POP ds bx es di si cx
                    ret

                    endp