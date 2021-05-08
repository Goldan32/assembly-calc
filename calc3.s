DEF LD   0x80                ; LED adatregiszter                    (�rhat�/olvashat�)
DEF SW   0x81                ; DIP kapcsol� adatregiszter           (csak olvashat�)
DEF BT   0x84                ; Nyom�gomb adatregiszter              (csak olvashat�)
DEF BTIE 0x85                ; Nyom�gomb megszak�t�s eng. regiszter (�rhat�/olvashat�)
DEF BTIF 0x86                ; Nyom�gomb megszak�t�s flag regiszter (olvashat�, �s a bit 1-be �r�s�val t�r�lhet�)
DEF BT0 0x01
DEF BT1 0x02
DEF BT2 0x04
DEF BT3 0x08
DEF DIG0 0x90                ; Kijelz� DIG0 adatregiszter           (�rhat�/olvashat�)
DEF DIG1 0x91                ; Kijelz� DIG1 adatregiszter           (�rhat�/olvashat�)
DEF DIG2 0x92                ; Kijelz� DIG2 adatregiszter           (�rhat�/olvashat�)
DEF DIG3 0x93                ; Kijelz� DIG3 adatregiszter           (�rhat�/olvashat�)
DEF SWMASK_Upper  0xF0
DEF SWMASK_Lower  0x0F
DEF BIT_NUMBER 4

    data
    
    sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79,0x71


    code
;----------------------------
;   F�program: r0...r5
;   szubrutinokban: r6...r12
;       input: r7, r6
;       output: r7, r6
;       IT: r13...r15, f�programmal k�z�s: r5,r4
;   - R0: Op1
;   - R1: Op2
;   - R2: SW, majd BT �rt�k
;   - R3: BTIF �rt�k
;
;   Mit csinal?
;       - Beolvassa a SW, �s BT �rt�keket, �s a megfelelo szubrutinba visz
;---------------------------
start:
    mov r2, SW
    mov r0, r2
    AND r0, #SWMASK_Upper
    SWP r0
    mov r1, r2
    AND r1, #SWMASK_Lower
    mov r2, BT
    mov r3, BTIF
    mov BTIF, r3
    and r2, r3
    tst r2, #BT0
    jz tst_BT1
    ADD r0, r1
    mov LD, r0
    mov r6, r0      
    jsr DISP
    jmp start
tst_BT1:
    tst r2, #BT1
    jz tst_BT2
    SUB r0,r1
    JC error
    mov LD, r0
    mov r6, r0
    jsr DISP
    jmp start
tst_BT2:
    tst r2, #BT2
    jz tst_BT3
    jsr LMUL
    jmp start
tst_BT3:
    tst r2, #BT3
    jz start
    jsr LDIV
    jmp start
    
LMUL:
    mov R10, r0 ; Input1
    mov R11, r1 ; Input2
    mov R12, #0 ;eredmeny
    mov r9, #BIT_NUMBER ; ciklussz�ml�l�
mul_loop:
    SR0 r11
    JNC not_adding
    ADD r12, r10
    ADD r11, #8     ; k�rbeforgat�s cig�nyosan (ha m�s a bitsz�m akkor ezen is v�ltoztatni kell
not_adding:
    SR0 r12
    SUB R9, #1
    JNZ mul_loop
    SWP r12
    AND r12, #0xF0
    ADD r12, r11
    mov LD, r12
    mov r6, R12
    jsr DISP
    rts


;----------------------------
;   Oszt�rutin:
;       Regisztereket v�ltoztatja: R6, R7, R8, R9
;       Funkci�k:
;           - R6: OP2 (oszt�)   - marad�k
;           - R7: OP1 (osztand�) - eredm�ny
;           - R8: bels� ciklussv�ltoz�
;           - R9: algoritmuson bel�li marad�k
;
;   Mit csinal?
;       - Elosztja R7-et R6-al. Ha R6 == 0, akkor error rutint h�v
;---------------------------

LDIV:
    mov r7, r0 ; OP1 bet�lt�se a szubrutin regiszter�be
    mov r6, r1 ; OP2 bet�lt�se a szubrutin regiszter�be
    cmp r6, #0 ; Amennyiben az z�r� oszt� -> error
    jz error
    mov R8, #BIT_NUMBER     ; ciklisvaltozo
    mov r9, r7              ; maradek
    mov r7, #0              ; eredmeny    
shift_loop:                 ; oszto hatvanyozasa
    sl0 R6
    sub R8, #1
    jnz shift_loop
    mov R8, #BIT_NUMBER
div_loop:
    sr0 R6
    cmp r9, R6
    jc rem_lt_div           ; ha maradek kisebb mint osztohatvany
    sl1 r7
    sub r9, R6
    JMP check
rem_lt_div:
    sl0 r7
check:
    sub R8, #1
    jnz div_loop
    mov R8, #4
divmod_loop:
    sl0 r7
    sub R8, #1
    jnz divmod_loop
    add r7, r9
    mov LD, r7
    mov r6, r7      
    mov r8, #0
    jsr DISP
    rts
error:
    mov r3, #0xFF
    mov LD, r3
    mov r6, #0xEE
    jsr DISP
    rts

DISP:
    mov r7, SW
    mov r9, r6
    and r9, #SWMASK_Lower
    mov r10, #sgtbl
    add r9, r10
    mov r9, (r9)
    mov DIG0, r9
    mov r11, #4
disp_shift1:
    sr0 r6
    sub r11, #1
    jnz disp_shift1
    add r6, r10
    mov r6, (r6)
    mov DIG1, r6
    mov r9, r7                      ; m�sodik k�t digit
    and r9, #SWMASK_Lower
    add r9, r10
    mov r9, (r9)
    mov DIG2, r9
    mov r11, #4
disp_shift2:
    sr0 r7
    sub r11, #1
    jnz disp_shift2
    add r7, r10
    mov r7, (r7)
    mov DIG3, r7
    
    mov r12, #DIG0
    mov r11, #4
    mov r10, #0b00001000
blank_loop:
    mov r9, r8
    sl0 r10
    and r9, r10
    jz not_blank
    mov r9, #0
    mov (r12), r9
not_blank:
    sub r11, #1
    add r12, #1
    jnz blank_loop
    
    mov r12, #DIG0
    mov r11, #4
    mov r10, #0b00010000
dp_loop:
    mov r9, r8
    sr0 r10
    and r9, r10
    jz not_dp
    mov r9, (r12)
    add r9, #0x80
    mov (r12), r9
not_dp:
    sub r11, #1
    add r12, #1
    jnz dp_loop
    
    rts





