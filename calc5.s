DEF LD   0x80                ; LED adatregiszter          (�rhat�/olvashat�)
DEF DIG0 0x90                ; Kijelz� DIG0 adatregiszter (�rhat�/olvashat�)
DEF DIG1 0x91                ; Kijelz� DIG1 adatregiszter (�rhat�/olvashat�)
DEF DIG2 0x92                ; Kijelz� DIG2 adatregiszter (�rhat�/olvashat�)
DEF DIG3 0x93                ; Kijelz� DIG3 adatregiszter (�rhat�/olvashat�)
DEF COL0 0x94                ; Kijelz� COL0 adatregiszter (�rhat�/olvashat�)
DEF COL1 0x95                ; Kijelz� COL1 adatregiszter (�rhat�/olvashat�)
DEF COL2 0x96                ; Kijelz� COL2 adatregiszter (�rhat�/olvashat�)
DEF COL3 0x97                ; Kijelz� COL3 adatregiszter (�rhat�/olvashat�)
DEF COL4 0x98                ; Kijelz� COL4 adatregiszter (�rhat�/olvashat�)

DEF SWMASK_Lower 0x0F
DEF SWMASK_Upper  0xF0
DEF BIT_NUMBER 4

DEF State1 1
DEF State2 2
DEF State3 3
DEF StateDefault 4

DEF UC_INIT 0b00001110       ; FIFO t�rl�s, USRT vev� enged�lyezett
DEF UIE_INIT 0b00001100
DEF ASCII_EQU 0x3D
DEF ASCII_ADD 0x2B
DEF ASCII_SUB 0x2D
DEF ASCII_MUL 0x2A
DEF ASCII_DIV 0x2F
DEF ASCII_ESC 0x1B
DEF ASCII_CR 0x0D

    code
    
jmp start
jmp rx_irq


;----------------------------
;   USRT:
;       Regisztereket v�ltoztatja: R5, R15, R0
;       Funkci�k:
;           - R0: Inicializ�lja az USRT-t
;           - R5: Jelz� bit
;                   - 1: J�tt karakter
;                   - 0: Nem j�tt m�g karakter
;           - R15: Karaktert tartalamz� regiszter
;   Mit csin�l?
;       - USRT Termin�lon kapott adatot R15-be helyezi. R5-�n kereszt�l jelzi a programnak, hogy j�tt karakter
;---------------------------   
start:                  ; ez az, ami b�rmi t�rt�nik, beker�l a MAIN-be.
    cli
    mov r0, #0          ; LD t�rl�se
    mov LD, r0
    mov r0, #UC_INIT    ; Vez�rl�regiszter be�ll�t�sa
    mov UC, r0
    mov r0, #UIE_INIT   ; IT enged�lyez�s
    mov UIE, r0
    sti
    
rx_irq:
    mov r15, UD         ; UD tartalmazza a v�teli vonalon kapott karaktert 
    mov LD, r15         ; Ki �rom LED-re a kapott �rt�ket (DEBUG, sz�val elhanyagolhat�)
    mov r5, #1          ; Jelz� BIT 1-es = kaptam adatot
    rti



    
    
; stateReg: R13
; operandusok: R1: els�, R2: m�sodik
; m�veleti szubrutin c�me: R3
state_loop:
    cmp r5, #1
    jnz state_loop
    mov r14, r15
    mov r5, #0
    
    cmp r14, #ASCII_ESC
    jnz State_1
    mov r13, #State1
    
State_1:
    cmp r13, #State1
    jnz State_2
    
    and r14, #SWMASK_Lower
    cmp r14, #10
    jnc nok1
    
    mov r13, #State2
    mov r1, r14
    mov r7, r14
    swp r7
    ;jsr DISP
nok1:
    jmp state_loop
    
State_2:
    cmp r13, #State2
    jnz State_3
    
    cmp r14, #ASCII_ADD
    jnz not_add
    mov r3, LADD
    jmp symbol_end
not_add:
    cmp r14, #ASCII_DIV
    jnz not_sub
    mov r3, LSUB
    jmp symbol_end
not_sub:
    cmp r14, #ASCII_MUL
    jnz not_mul
    mov r3, LMUL
    jmp symbol_end
not_mul:
    cmp r14, #ASCII_DIV
    jnz s2_default
    mov r3, LDIV
    jmp symbol_end
s2_default:
    jmp state_loop

symbol_end:
    mov r13, State_3
    jmp state_loop
    
    
State_3:
    cmp r13, #State3
    jnz State_4
    
    and r14, #SWMASK_Lower
    cmp r14, #10
    jnc nok2
    
    mov r13, #State_4
    mov r2, r14
    add r7, r14
    ; jsr DISP
nok2:
    jmp state_loop
    
State_4:
    cmp r13, #State4
    jnz State_end
    
    cmp r14, #ASCII_EQU
    jz eq
    cmp r14, #ASCII_CR
    jz eq
    jmp state_loop
    
    mov r13, #State_end
    jsr (r3)
    jmp state_loop
State_end:
    jmp state_loop
    
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
    
    
;----------------------------
;   Szorz�rutin:
;       Regisztereket v�ltoztatja: R6, R9, R10, R11, R12,
;       Funkci�k:
;           - R6: Eredm�ny a 7szegmensesnek
;           - R9: Ciklus iter�tor
;           - R10: Input 1
;           - R11: Input2
;           - R12: Szorz�s eredm�nye
;
;   Mit csinal?
;       - �sszeszorozza R10 �s R11 sz�mot. Az eredm�nyt R12 �s R6 tartalmazza
;---------------------------   
LMUL:
    mov R10, r2 ; Input1
    mov R11, r2 ; Input2
    mov R12, #0 ;eredmeny
    mov r9, #BIT_NUMBER ; ciklussz�ml�l�
    SUB r9, #1
mul_loop:
    SR0 r11
    JNC NOT
    ADD r12, r10
    SL0 r10
NOT:
    SUB r9, #1
    JNZ mul_loop
    mov r6, R12
    jsr STANDARD_PRINT
    rts
    
    
LADD:
    mov r4, r1
    add r4, r2
    mov r6, r4
    mov r8, #0
    jsr DISP
    rts
    
LSUB:
    mov r4, r2
    sub r4, r1
    jc error
    mov r6, r4
    mov r8, #0
    jsr DISP
    rts
    
error:
    mov r7, #0xEE
    mov r8, #0
    jsr DISP
    rts
    

    