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