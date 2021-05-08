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
;       - Sz�mon tartja, hogy v�ltozott-e a kapcsol�k �ll�sa, 
;         ha igen, akkor v�ltozik a kijelz�s, ha nem akkor nem
;---------------------------
start:
    
    jsr GET_INPUT
    cmp r5, r2
    jz no_change
    jsr CHECK_VALUE
    mov r8, #0b00110000
    jsr DISP
    mov r5, SW
no_change:
    
    mov r2, BT
    mov r3, BTIF
    mov BTIF, r3
    and r2, r3
    tst r2, #BT0
    jz tst_BT1
    add r0, r1
    mov LD, r0
    mov r6, r0
    jsr STANDARD_PRINT
    jmp start
tst_BT1:
    tst r2, #BT1
    jz tst_BT2
    sub r0,r1
    JC error
    mov LD, r0
    mov r6, r0
    jsr STANDARD_PRINT
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
    mov R10, r0
    mov R11, r1
    mov R12, #0
mul_loop:
    add R12,R11
    sub R10, #1
    jnz mul_loop
    mov LD,R12
    mov r6, R12
    jsr STANDARD_PRINT
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
    
    jsr GET_INPUT
    jsr CHECK_VALUE
    add r8, #0b00000100
    jsr DISP
    
    rts
error:
    mov r8, #0x00
    mov r3, #0xFF
    mov LD, r3
    mov r6, #0xEE
    
    jsr GET_INPUT
    jsr CHECK_VALUE
    jsr DISP
    
    rts
    
;----------------------------
;   Kijelz�s:
;       Regisztereket v�ltoztatja: R6, R7, R8, R9, R10, R11, R12
;       Funkci�k:
;           - R6: Jobb oldali k�t digit
;           - R7: bal oldali k�t digit
;           - R8: blank �s dp konfigur�ci�
;
;   Mit csinal?
;       Kijelz�re �rja a {R7[7:4], R7[3:0], R6[7:4], R6[3:0]} sz�mot
;---------------------------
DISP:
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
    
    mov r12, #DIG0                  ; blank logika
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
    add r12, #1
    sub r11, #1
    jnz blank_loop
    
    mov r12, #DIG0                  ; dp logika
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
    add r12, #1
    sub r11, #1
    jnz dp_loop
    
    rts

;----------------------------
;   Bin�ris BCD �talak�t�:
;       Regisztereket v�ltoztatja: R6, R8, R9, R10
;       Funkci�k:
;           - R6 :  Bin�ris sz�m  (bemenet)
;           - R6 :  BCD sz�m      (eredm�ny)
;           - R8 :  Ideiglenes t�rol�s maszkol�shoz
;           - R9 :  Ciklusv�ltoz�
;           - R10: Ideiglenes eredm�ny
;
;   Mit csinal?
;       - �talak�tja az R6-ban l�v� bin�ris sz�mot BCD sz�mm�
;   Fontos:
;       - A bemenet 8 bites bin�ris sz�m minden esetben
;---------------------------
BIN2BCD:
    mov r10, #0
    mov r9, #8

b2b_loop:
    mov r8, r10
    and r8, #SWMASK_Lower
    cmp r8, #5
    jc not_add3
    add r10, #3
not_add3:
    
    sl0 r6
    rlc r10
    sub r9, #1
    jnz b2b_loop
    
    mov r6, r10
    rts
    
;----------------------------
;   Input kezel� szubrutin:
;       Regisztereket v�ltoztatja: R0, R1, R2
;       Funkci�k:
;           - R0 :  Els� sz�m
;           - R1 :  M�sodik sz�m
;           - R2 :  K�t sz�m egym�s ut�n (hibajelz�s miatt kell)
;
;   Mit csinal?
;       - Berakja a megfelel� regiszterekbe a kapcsol�k �ll�s�t
;       - R0-ba az els�, R1-be a m�sodik operandust
;
;   Indokl�s:
;        - Ezeket a funkci�kat a f�program l�tn� el norm�l esetben, viszont
;          szubrutinba kiszervezve cs�kken a k�d m�rete
;---------------------------  
GET_INPUT:
    mov r2, SW
    mov r0, r2
    and r0, #SWMASK_Upper
    swp r0  
    mov r1, r2
    and r1, #SWMASK_Lower
    rts
    


;----------------------------
;   Sz�mjegy ellen�rz�:
;       Regisztereket v�ltoztatja: R2, R7, R8
;       Funkci�k:
;              - Nem l�nyeges
;
;   Mit csinal?
;       - R2 regiszter tartalm�t bem�solja az R7 regiszterbe, kiv�ve
;         ha az nem �rtelmes sz�mjegyet tartalmaz, ezzel megval�sul a hibakezel�s
;       - DISP el�tt kell h�vni annak a param�tereit egyengeti
;       - R8 blank vez�rl�s�t �ll�tja be megfelel�en
;---------------------------  
CHECK_VALUE:
    mov r7, r2
    mov r8, #0
    cmp r0, #10
    jc ok1
    and r7, #SWMASK_Lower
    add r7, #0xE0
    mov r8, #0b00110000
ok1:
    cmp r1, #10
    jc ok2
    and r7, #SWMASK_Upper
    add r7, #0x0E
    mov r8, #0b00110000
ok2:
    rts
    
;---------------------------------
;   Gy�jt� szubrutin eredm�ny kijelz�s�re
;---------------------------------
STANDARD_PRINT:
    jsr BIN2BCD
    jsr GET_INPUT
    jsr CHECK_VALUE
    jsr DISP






