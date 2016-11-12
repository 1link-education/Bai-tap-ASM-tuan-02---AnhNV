name "anhnv-calc"

org     0x100
 
  
.data
  
msg1  db 0x0D, 0x0A, 0x0D, 0x0A, 'input numbers in range: [-32768..32767]'
      db 0x0D, 0x0A, 'the first number  : $'
msg2  db 0x0D, 0x0A, 'the second number: $'
msg3  db 0x0D, 0x0A, 'SUM               : $'
msg4  db 0x0D, 0x0A, '!overflow!$'

reslt  dw ?


;--------------------------------------------------------------------------

.code

MAIN_LOOP:
    
    mov dx, offset msg1
    mov ah, 0x09
    int 0x21

    call    scan_num

    mov     reslt, cx


    mov dx, offset msg2
    mov ah, 0x09
    int 0x21

    call    scan_num


    add     reslt, cx
    jo      overflow_notify                ; short jump if overflow


    mov dx, offset msg3
    mov ah, 0x09
    int 0x21


    mov     ax, reslt
    call    print_num

    jmp     MAIN_LOOP


overflow_notify:
    mov dx, offset msg1
    mov ah, 9
    int 21h

;--------------------------------------------------------------------------


putchar     MACRO   char
            push    ax               ; conserve ax's original value
            mov     al, char
            mov     ah, 0x0E         ; teletype output for int 0x10
            int     0x10     
            pop     ax
ENDM



make_minus      db      ?            ; used as a flag, 1 for negative  

number10        dw      10

; get signed number, store in cx
SCAN_NUM        PROC    NEAR                                    ; NEAR for intrasegment/in same segment, 16-bit
                                                                ; http://www.shsu.edu/csc_tjm/spring2001/cs272/ch4b.html
        ; save previous digit's information
        ;push    dx
        ;push    ax
        ;push    si
        
        mov     cx, 0

        ; reset minus flag
        mov     make_minus, 0

next_digit:
        ; get char -> al
        mov     ah, 0x00
        int     0x16        
        mov     ah, 0x0E            ; teletype output, al = character to write
        int     0x10

        ; check for -
        cmp     al, '-'
        je      set_minus

        ; check for ENTER
        cmp     al, 0x0D
        jne     not_cret            ; jump if not equal
        jmp     stop_input

not_cret:
        ; check for BACKSPACE
        cmp     al, 0x08                
        jne     not_backspace       
        ; remove last digit
        mov     dx, 0      
        mov     ax, cx   
        div     number10         ; ax = dx:ax / number10;  dx = remainder
        mov     cx, ax 
        
        putchar ' '                     
        putchar 0x08                 
        jmp     next_digit

not_backspace:
        cmp     al, '0'
        jae     AE_0             ; Above or Equal to 0
        jmp     not_digit

AE_0:        
        cmp     al, '9'
        jbe     ok_digit

not_digit: 
        ; not digit thi remove thoi :-D      
        putchar 0x08
        putchar ' '
        putchar 0x08       
        jmp     next_digit       

ok_digit:                        ; BE_9
        ; multiply cx by number10
        push    ax
        mov     ax, cx
        mul     number10             ; dx:dx = ax * number10
        mov     cx, ax
        pop     ax

        ; check if the number is too big
        cmp     dx, 0                   ; cmp dx, 0x00?
        jne     num_too_big

        ; convert from ASCII
        sub     al, 0x30

        ; add al -> cx
        mov     ah, 0
        mov     dx, cx              ; backup to dx if reslt of (add cx, ax) too big...
        add     cx, ax
        jc      addition_too_big    ; jump if the result number is too big (cf = 1)

        jmp     next_digit



set_minus:
        mov     make_minus, 1
        jmp     next_digit

num_too_big:
        mov     ax, cx
        div     number10
        mov     cx, ax
        
        putchar 0x08
        putchar ' '
        putchar 0x08       
        jmp     next_digit          ; wait for Enter/Backspace.     
        
addition_too_big:
        mov     cx, dx              ; restore dx to cx
        mov     dx, 0
                
stop_input:
        cmp     make_minus, 0
        je      not_minus
        neg     cx                  ; negate cx (eg: 5 to -5)

not_minus:
        ;pop     si
        ;pop     ax
        ;pop     dx
        ret
        

SCAN_NUM        ENDP


; print number in ax
PRINT_NUM       PROC    NEAR
        ;push    dx
        ;push    ax

        cmp     ax, 0
        jnz     not_zero

        putchar '0'
        jmp     printed

not_zero:
        cmp     ax, 0
        jns     positive            ; jmp if not signed (positive)
        neg     ax

        putchar '-'

positive:
        call    PRINT_NUM_UNS

printed:
        ;pop     ax
        ;pop     dx
        ret
PRINT_NUM       ENDP


PRINT_NUM_UNS   PROC    NEAR
        ;push    ax
        ;push    bx
        ;push    cx
        ;push    dx

        mov     cx, 1                   ; flag, avoid printing 0 before number

        mov     bx, 10000               ; devider

        cmp     ax, 0
        jz      print_zero

begin_print:
        cmp     bx, 0
        jz      end_print
        
        cmp     cx, 0                   ; avoid printing 0 before number
        je      calc

        cmp     ax, bx
        jb      skip                    ; ax/bx = 0

calc:
        mov     cx, 0                   ; set flag

        mov     dx, 0
        div     bx                      ; ax = dx:ax / bx   (dx = remainder)

        ; print last digit
        add     al, 0x30                ; to ASCII
        putchar al


        mov     ax, dx                  ; get remainder from last division

skip:
        ; bx /= 10
        push    ax
        mov     dx, 0
        mov     ax, bx
        div     number10             ; ax = dx:ax / number10   (dx = remainder)
        mov     bx, ax
        pop     ax

        jmp     begin_print
        
print_zero:
        putchar '0'
        

end_print:
        ;pop     dx
        ;pop     cx
        ;pop     bx
        ;pop     ax
        ret
PRINT_NUM_UNS   ENDP