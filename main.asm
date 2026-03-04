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

                    mov ax, 3508h                   ; find out adr of int 09h handler
                    int 21h
                    mov Old_08_ofs, bx
                    mov bx, es
                    mov Old_08_seg, bx

                    push 0
                    pop es                          ; es -> int table

                    cli                             ; int flag = 0
                    mov bx, 08h * 4                 ; 4 is size of elem in int table
                    mov es:[bx], offset New_int08   ; adr = New_int08 (in int table)
                    mov ax, cs                      ; ax -> code seg
                    mov es:[bx + 2], ax             ; seg = cs (in int table)

                    mov bx, 09h * 4                
                    mov es:[bx], offset New_int09   
                    mov es:[bx + 2], ax            
                    sti                             ; int flag = 1

                    mov ax, 3100h                   ; int 21h: fn resident ending
                    mov dx, offset End_of_prog      ; dx = size of all program code (in bytes)
                    shr dx, 4                       ; ...(in paragraphs)
                    inc dx                          ; division remainder
                    int 21h


;                   NEW_INT09
;------------------------------------------------------------------------------------------------------------------
; Descr:    this procedure replaces original 09h interrapt. When triggered, prints the frame contains information about
;           current value fo the some registers (11), flags (9) and elements from the top of the stack (11) into VM. 
;           Current screen condition under the frame refresh by timer-tick (int 08h (New_int08)), therefore 
;           image under the frame always sustains actual.
;           By pressing "ctrl + 1" on keyboard frame appears.
;           By pressing "ctrl + 2" on keyboard frame disappears, and VM backs to the actual condition accept frame. 
; Entry:    --
; Exit:     --
; Exp:      Old INT 09h vector must be saved in Old_09_seg and Old_09_ofs
; Destr:    --
; Save:     ax, bx, cx, dx, si, di, bp, ds, es, ss, sp + FLAGS
; Notes:  - Uses Draw_buf as temporary buffer, then flips to VM
;         - Uses Save_buf to store and refresh actual screen condition under the frame
;
; Frame exp:
;                     INFORMATION         
;            ╔═══════════════════════════╗
;            ║    REGS   | FLAGS | STACK ║
;            ║---------------------------║
;            ║ ax = 000A | c = 1 | 0001<-║
;            ║ bx = 0230 | p = 0 | 0002  ║
;            ║ cx = FF01 | a = 0 | 1300  ║
;            ║ dx = 1000 | z = 1 | 00D1  ║
;            ║ si = 0021 | s = 1 | 0000  ║
;            ║ di = 0D10 | t = 0 | 34F0  ║
;            ║ bp = DF78 | i = 0 | FFFF  ║
;            ║ sp = DAA0 | d = 1 | 0000  ║
;            ║ ds = 89AF | o = 0 | 0000  ║
;            ║ es = B800 |       | DAA1  ║
;            ║ ss = 0100 |       | 97F0  ║
;            ╚═══════════════════════════╝
;
;------------------------------------------------------------------------------------------------------------------

New_int09           proc
                    PUSH ax

;                           === CHECK SCAN-CODE & PICK UP APPROPRIATE OPTION ===

                    mov ah, 02h                 
                    int 16h                     ; al = shift status information
                    and al, 4                   ; bit-mask for getting ctrl-shift status
                    test al, al
                    jz @@end_of_int

                    in al, 60h                  ; al = scan-code 

                    cmp al, 3                   ; scan-code to print Save_buf
                    jne @@check_draw_buf
                    mov ax, offset Save_buf
                    CALL Print_buf
                    jmp @@end_of_int

    @@check_draw_buf:   
                    cmp al, 2                   ; scan-code to print Draw_buf
                    jne @@end_of_int

                    PUSH sp ss es ds bp di si dx cx bx ax   ; save regs
                    PUSHF

                    CALL VM_copy_to_Save_buf

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
                    add al, '0'                 
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
                    mov ax, offset Draw_buf
                    CALL Print_buf

                    POPF
                    POP ax bx cx dx si di bp ds es ss sp        ; recover regs

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

;                   NEW_INT08
;------------------------------------------------------------------------------------------------------------------
; Descr:    replacement for int 08h (timer-tick); is triggered every 55ms. By timer-tick compares VM content
;           with Draw_buf content and restores different characters in the same position from VM 
;           to Save_buf and Draw_buf. 
; Entry:    --
; Exit:     --
; Exp:      Old INT 08h vector must be saved in Old_08_seg and Old_08_ofs
; Destr:    --
; Save:     ax, bx, cx, dx, si, di, bp, ds, es, ss, sp + FLAGS
;------------------------------------------------------------------------------------------------------------------

New_int08           proc
                    PUSH sp ss es ds bp di si dx cx bx ax       ; save regs
                    PUSHF

                    mov ax, 0b800h
                    mov es, ax
                    mov ax, cs
                    mov ds, ax
                    CALL Draw_buf_cmp_VM

                    mov al, 20H                 ; send End-Of-Interrupt signal
                    out 20H, al                 ; to the 8259 Interrupt Controller

                    POPF
                    POP ax bx cx dx si di bp ds es ss sp        ; recover regs

                    db 0eah                     ; jmp far to old int 08
                    Old_08_ofs dw 0
                    Old_08_seg dw 0

                    iret                        ; return from jmp far
                    endp

;                   FUNCTIONS INCLUDES
;==================================================================================================================

include buf_func.asm
include utils.asm

;                   INIT_DATA
;==================================================================================================================

; Buffers & constants
Count_of_regs       = 11

Frame_wid           = 16
Frame_len           = 29
Frame_size          = Frame_len * Frame_wid * 2
Frame_offset_VM     = (26 + 4 * 80) * 2
New_line_remain     = (80 - Frame_len) * 2

Draw_buf            db Frame_size dup (0)
Save_buf            db Frame_size dup (0)
Stack_buf           dw 11 dup(0)

include FRAMEBUF.asm                            ; frame template

;------------------------------------------------------------------------------------------------------------------

End_of_prog:                                    ; is used to define size of all program code
end                 Start                    