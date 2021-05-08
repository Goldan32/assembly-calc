DEF LD   0x80                ; LED adatregiszter                    (írható/olvasható)
DEF SW   0x81                ; DIP kapcsoló adatregiszter           (csak olvasható)
DEF BT   0x84                ; Nyomógomb adatregiszter              (csak olvasható)
DEF BTIE 0x85                ; Nyomógomb megszakítás eng. regiszter (írható/olvasható)
DEF BTIF 0x86                ; Nyomógomb megszakítás flag regiszter (olvasható, és a bit 1-be írásával törölhetõ)
DEF BT0 0x01
DEF BT1 0x02
DEF BT2 0x04
DEF BT3 0x08
DEF DIG0 0x90                ; Kijelzõ DIG0 adatregiszter           (írható/olvasható)
DEF DIG1 0x91                ; Kijelzõ DIG1 adatregiszter           (írható/olvasható)
DEF DIG2 0x92                ; Kijelzõ DIG2 adatregiszter           (írható/olvasható)
DEF DIG3 0x93                ; Kijelzõ DIG3 adatregiszter           (írható/olvasható)
DEF SWMASK_Upper  0xF0
DEF SWMASK_Lower  0x0F
DEF BIT_NUMBER 4

    data
    
    sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79,0x71


    code
;----------------------------
;   Fõprogram: r0...r5
;   szubrutinokban: r6...r12
;       input: r7, r6
;       output: r7, r6
;       IT: r13...r15, fõprogrammal közös: r5,r4
;   - R0: Op1
;   - R1: Op2
;   - R2: SW, majd BT érték
;   - R3: BTIF érték
;
;   Mit csinal?
;       - Beolvassa a SW, és BT értékeket, és a megfelelo szubrutinba visz
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
    mov r9, #BIT_NUMBER ; ciklusszámláló
mul_loop:
    SR0 r11
    JNC not_adding
    ADD r12, r10
    ADD r11, #8     ; körbeforgatás cigányosan (ha más a bitszám akkor ezen is változtatni kell
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
;   Osztórutin:
;       Regisztereket változtatja: R6, R7, R8, R9
;       Funkciók:
;           - R6: OP2 (osztó)   - maradék
;           - R7: OP1 (osztandó) - eredmény
;           - R8: belsõ ciklussváltozó
;           - R9: algoritmuson belüli maradék
;
;   Mit csinal?
;       - Elosztja R7-et R6-al. Ha R6 == 0, akkor error rutint hív
;---------------------------

LDIV:
    mov r7, r0 ; OP1 betöltése a szubrutin regiszterébe
    mov r6, r1 ; OP2 betöltése a szubrutin regiszterébe
    cmp r6, #0 ; Amennyiben az zéró osztó -> error
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
    mov r9, r7                      ; második két digit
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





