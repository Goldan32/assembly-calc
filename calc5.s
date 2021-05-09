DEF LD   0x80                ; LED adatregiszter          (írható/olvasható)
DEF DIG0 0x90                ; Kijelzõ DIG0 adatregiszter (írható/olvasható)
DEF DIG1 0x91                ; Kijelzõ DIG1 adatregiszter (írható/olvasható)
DEF DIG2 0x92                ; Kijelzõ DIG2 adatregiszter (írható/olvasható)
DEF DIG3 0x93                ; Kijelzõ DIG3 adatregiszter (írható/olvasható)
DEF COL0 0x94                ; Kijelzõ COL0 adatregiszter (írható/olvasható)
DEF COL1 0x95                ; Kijelzõ COL1 adatregiszter (írható/olvasható)
DEF COL2 0x96                ; Kijelzõ COL2 adatregiszter (írható/olvasható)
DEF COL3 0x97                ; Kijelzõ COL3 adatregiszter (írható/olvasható)
DEF COL4 0x98                ; Kijelzõ COL4 adatregiszter (írható/olvasható)
DEF UC  0x88                ; USRT kontroll regiszter     (csak írható)
DEF US  0x89                ; USRT FIFO státusz regiszter (csak olvasható)
DEF UIE 0x8A                ; USRT megszakítás eng. reg.  (írható/olvasható)
DEF UD  0x8B                ; USRT adatregiszter          (írható/olvasható)

DEF SWMASK_Lower 0x0F
DEF SWMASK_Upper  0xF0
DEF BIT_NUMBER 4

DEF State1 1
DEF State2 2
DEF State3 3
DEF State4 4
DEF StateEnd 5

DEF UC_INIT 0b00001110       ; FIFO törlés, USRT vevõ engedélyezett
DEF UIE_INIT 0b00001100
DEF ASCII_EQU 0x3D
DEF ASCII_ADD 0x2B
DEF ASCII_SUB 0x2D
DEF ASCII_MUL 0x2A
DEF ASCII_DIV 0x2F
DEF ASCII_ESC 0x1B
DEF ASCII_CR 0x0D

    data
    
    sgtbl: DB 0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, 0x77, 0x7c, 0x39, 0x5e, 0x79,0x71

    code
    
jmp start
jmp rx_irq


;-------------------------------------------------------------------------
;   USRT:
;       Regisztereket változtatja: R5, R15, R0
;       Funkciók:
;           - R0: Inicializálja az USRT-t
;           - R5: Jelzõ bit
;                   - 1: Jött karakter
;                   - 0: Nem jött még karakter
;           - R15: Karaktert tartalamzó regiszter
;   Mit csinál?
;       - USRT Terminálon kapott adatot R15-be helyezi. R5-ön keresztül jelzi a programnak, hogy jött karakter
;-------------------------------------------------------------------------
start:                  ; ez az, ami bármi történik, bekerül a MAIN-be.
    cli
    mov r0, #0          ; LD törlése
    mov LD, r0
    mov r0, #UC_INIT    ; Vezérlõregiszter beállítása
    mov UC, r0
    mov r0, #UIE_INIT   ; IT engedélyezés
    mov UIE, r0
    mov r13, #State1
    jmp state_loop
    
rx_irq:
    mov r15, UD         ; UD tartalmazza a vételi vonalon kapott karaktert 
    mov LD, r15         ; Ki írom LED-re a kapott értéket (DEBUG, szóval elhanyagolható)
    mov r5, #1          ; Jelzõ BIT 1-es = kaptam adatot
    rti

;-------------------------------------------------------------------------
;   Bemeneti értékeket kezelõ állapotgép (nem szubrutin):
;       Regisztereket változtatja: R5, R13, R14, R6, R7, R8, R1, R2, R3
;       Funkciók:
;           - R1:   Elsõ operandus
;           - R2:   Második operandus
;           - R3:   Végzendõ operációs szubrutin címe
;           - R13:  Jelenlegi állapot
;
;   Mit csinal?
;       - Kezeli az USRT bementen érkezõ karaktereket
;       - Kiírja a megfelelõ idõben a legális karaktereket
;       - Meghívja a megfelelõ mûveletet végzõ szubrutinokat
;       - Megvalósítja a megfelelõ blank és dp vezérlést
;-------------------------------------------------------------------------
state_loop:
    sti
    cmp r5, #1
    jnz state_loop
    cli
    mov r14, r15
    mov r5, #0
    
    cmp r14, #ASCII_ESC
    jnz State_1
    mov r13, #State1
    mov r8, #0b11110000
    jsr DISP
    
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
    mov r8, #0b01110000
    jsr DISP
nok1:
    jmp state_loop
    
State_2:
    cmp r13, #State2
    jnz State_3
    
    cmp r14, #ASCII_ADD
    jnz not_add
    mov r3, #LADD
    jmp symbol_end
not_add:
    cmp r14, #ASCII_SUB
    jnz not_sub
    mov r3, #LSUB
    jmp symbol_end
not_sub:
    cmp r14, #ASCII_MUL
    jnz not_mul
    mov r3, #LMUL
    jmp symbol_end
not_mul:
    cmp r14, #ASCII_DIV
    jnz s2_default
    mov r3, #LDIV
    jmp symbol_end
s2_default:
    jmp state_loop
symbol_end:
    mov r13, #State3
    jmp state_loop
    
State_3:
    cmp r13, #State3
    jnz State_4
    and r14, #SWMASK_Lower
    cmp r14, #10
    jnc nok2
    
    mov r13, #State4
    mov r2, r14
    add r7, r14
    mov r8, #0b00110000
    jsr DISP
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
eq:    
    mov r13, #StateEnd
    jsr (r3)
    jmp state_loop
State_end:
    jmp state_loop
    
    
    
    
;----------------------------
;   Kijelzés:
;       Regisztereket változtatja: R4, R6, R4, R9, R10, R11, R12
;       Funkciók:
;           - R6: Jobb oldali két digit
;           - R7: bal oldali két digit
;           - R8: blank és dp konfiguráció
;
;   Mit csinal?
;       Kijelzõre írja a {R7[7:4], R7[3:0], R6[7:4], R6[3:0]} számot
;---------------------------
DISP:
    mov r4, r7
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
    mov r9, r4                      ; második két digit
    and r9, #SWMASK_Lower
    add r9, r10
    mov r9, (r9)
    mov DIG2, r9
    mov r11, #4
disp_shift2:
    sr0 r4
    sub r11, #1
    jnz disp_shift2
    add r4, r10
    mov r4, (r4)
    mov DIG3, r4
    
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
;           - R11 :  Ideiglenes tárolás maszkoláshoz
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
    mov r11, r10
    and r11, #SWMASK_Lower
    cmp r11, #5
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
;   Osztórutin:
;       Regisztereket változtatja: R4, R6, R9, R10, R8
;       Funkciók:
;           - R6:  OP2 (osztó)   - maradék, legvégül az eredmény is ide kerül
;           - R4:  OP1 (osztandó) - eredmény
;           - R10: belsõ ciklussváltozó
;           - R9:  algoritmuson belüli maradék
;           - R8:  funkciójának megfelelõen változik
;
;   Mit csinal?
;       - Elosztja R1-et R2-vel. Ha R2 == 0, akkor error rutint hív
;---------------------------
LDIV:
    mov r4, r1 ; OP1 betöltése a szubrutin regiszterébe
    mov r6, r2 ; OP2 betöltése a szubrutin regiszterébe
    cmp r6, #0 ; Amennyiben az zéró osztó -> error
    jz error
    mov R10, #BIT_NUMBER     ; ciklisvaltozo
    mov r9, r4              ; maradek
    mov r4, #0              ; eredmeny    
shift_loop:                 ; oszto hatvanyozasa
    sl0 R6
    sub R10, #1
    jnz shift_loop
    mov R10, #BIT_NUMBER
div_loop:
    sr0 R6
    cmp r9, R6
    jc rem_lt_div           ; ha maradek kisebb mint osztohatvany
    sl1 r4
    sub r9, R6
    JMP check
rem_lt_div:
    sl0 r4
check:
    sub R10, #1
    jnz div_loop
    mov R10, #4
divmod_loop:
    sl0 r4
    sub R10, #1
    jnz divmod_loop
    add r4, r9
    mov r6, r4
    
    mov r8, #0b00000100
    jsr DISP
    
    rts
    
    
;----------------------------
;   Szorzórutin:
;       Regisztereket változtatja: R6, R9, R10, R11, R12,
;       Funkciók:
;           - R6: Eredmény a 7szegmensesnek
;           - R9: Ciklus iterátor
;           - R10: Input 1
;           - R11: Input2
;           - R12: Szorzás eredménye
;
;   Mit csinal?
;       - Összeszorozza R10 és R11 számot. Az eredményt R12 és R6 tartalmazza
;---------------------------   
LMUL:
    mov R10, r1 ; Input1
    mov R11, r2 ; Input2
    mov R12, #0 ;eredmeny
    mov r9, #BIT_NUMBER ; ciklusszámláló
mul_loop:
    SR0 r11
    JNC NOT
    ADD r12, r10
NOT:
    SL0 r10
    SUB r9, #1
    JNZ mul_loop
    mov r6, R12
    mov r8, #0
    jsr BIN2BCD
    jsr DISP
    rts

;---------------------------
; Összeadó szubrutin
;---------------------------
LADD:
    mov r4, r1
    add r4, r2
    mov r6, r4
    mov r8, #0
    jsr BIN2BCD
    jsr DISP
    rts

;---------------------------
; Kivonó szubrutin
;---------------------------
LSUB:
    mov r4, r1
    sub r4, r2
    jc error
    mov r6, r4
    mov r8, #0
    jsr BIN2BCD
    jsr DISP
    rts

;---------------------------
; Error kezelés
;   - Önmagában nem szubrutin
;   - Csak szubrutinból kerülünk ide, így visszatérhetünk rts-sel
;---------------------------
error:
    mov r6, #0xEE
    mov r8, #0
    jsr DISP
    rts
    

    