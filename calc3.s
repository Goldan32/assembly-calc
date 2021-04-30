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

start:
    mov r0, SW
    mov r7, SW
    mov r3, r0
    AND r3, #SWMASK_Upper
    SWP r3
    mov r4, r0
    AND r4, #SWMASK_Lower
    mov r1, BT
    mov r2, BTIF
    mov BTIF, r2
    and r1, r2
    tst r1, #BT0
    jz tst_BT1
    jsr LADD
    jmp start
tst_BT1:
    tst r1, #BT1
    jz tst_BT2
    jsr LSUB
    jmp start
tst_BT2:
    tst r1, #BT2
    jz tst_BT3
    jsr LMUL
    jmp start
tst_BT3:
    tst r1, #BT3
    jz start
    jsr LDIV
    jmp start

LADD:
    ADD r3, r4
    mov LD, r3
    mov r6, r3
    jsr DISP
    rts

LSUB:
    SUB r3,r4
    JC sub_error
    mov LD, r3
    mov r6, r3
    jsr DISP
    rts
sub_error:
    mov r3, #0xFF
    mov LD, r3
    rts

LMUL:
    mov r5, r4
    mov r4, r3
    mov r3, #0
mul_loop:
    add r3,r4
    sub r5, #1
    jnz mul_loop
    mov LD,r3
    mov r6, r3
    jsr DISP
    rts

LDIV:
    cmp r4, #0
    jz div_error
    mov r5, #BIT_NUMBER     ; ciklisvaltozo
    mov r9, r3              ; maradek
    mov r10, #0              ; eredmeny    
shift_loop:                 ; oszto hatvanyozasa
    sl0 r4
    sub r5, #1
    jnz shift_loop
    mov r5, #BIT_NUMBER
div_loop:
    sr0 r4
    cmp r9, r4
    jc rem_lt_div           ; ha maradek kisebb mint osztohatvany
    sl1 r10
    sub r9, r4
rem_lt_div:
    sl0 r10
    sub r5, #1
    jnz div_loop
    mov r5, #3
divmod_loop:
    sl0 r10
    sub r5, #1
    jnz divmod_loop
    add r10, r9
    mov LD, r10
    mov r6, r10
    jsr DISP
    rts
div_error:
    mov r3, #0xFF
    mov LD, r3
    rts

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
    rts
    





