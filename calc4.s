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
;       - Számon tartja, hogy változott-e a kapcsolók állása, 
;         ha igen, akkor változik a kijelzés, ha nem akkor nem
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
;   Kijelzés:
;       Regisztereket változtatja: R6, R7, R8, R9, R10, R11, R12
;       Funkciók:
;           - R6: Jobb oldali két digit
;           - R7: bal oldali két digit
;           - R8: blank és dp konfiguráció
;
;   Mit csinal?
;       Kijelzõre írja a {R7[7:4], R7[3:0], R6[7:4], R6[3:0]} számot
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
;   Bináris BCD átalakító:
;       Regisztereket változtatja: R6, R8, R9, R10
;       Funkciók:
;           - R6 :  Bináris szám  (bemenet)
;           - R6 :  BCD szám      (eredmény)
;           - R8 :  Ideiglenes tárolás maszkoláshoz
;           - R9 :  Ciklusváltozó
;           - R10: Ideiglenes eredmény
;
;   Mit csinal?
;       - Átalakítja az R6-ban lévõ bináris számot BCD számmá
;   Fontos:
;       - A bemenet 8 bites bináris szám minden esetben
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
;   Input kezelõ szubrutin:
;       Regisztereket változtatja: R0, R1, R2
;       Funkciók:
;           - R0 :  Elsõ szám
;           - R1 :  Második szám
;           - R2 :  Két szám egymás után (hibajelzés miatt kell)
;
;   Mit csinal?
;       - Berakja a megfelelõ regiszterekbe a kapcsolók állását
;       - R0-ba az elsõ, R1-be a második operandust
;
;   Indoklás:
;        - Ezeket a funkciókat a fõprogram látná el normál esetben, viszont
;          szubrutinba kiszervezve csökken a kód mérete
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
;   Számjegy ellenõrzõ:
;       Regisztereket változtatja: R2, R7, R8
;       Funkciók:
;              - Nem lényeges
;
;   Mit csinal?
;       - R2 regiszter tartalmát bemásolja az R7 regiszterbe, kivéve
;         ha az nem értelmes számjegyet tartalmaz, ezzel megvalósul a hibakezelés
;       - DISP elõtt kell hívni annak a paramétereit egyengeti
;       - R8 blank vezérlését állítja be megfelelõen
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
;   Gyûjtõ szubrutin eredmény kijelzésére
;---------------------------------
STANDARD_PRINT:
    jsr BIN2BCD
    jsr GET_INPUT
    jsr CHECK_VALUE
    jsr DISP






