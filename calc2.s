DEF LD   0x80                ; LED adatregiszter                    (�rhat�/olvashat�)
DEF SW   0x81                ; DIP kapcsol� adatregiszter           (csak olvashat�)
DEF BT   0x84                ; Nyom�gomb adatregiszter              (csak olvashat�)
DEF BTIE 0x85                ; Nyom�gomb megszak�t�s eng. regiszter (�rhat�/olvashat�)
DEF BTIF 0x86                ; Nyom�gomb megszak�t�s flag regiszter (olvashat� �s a bit 1 be�r�s�val t�r�lheto)
DEF BT0 0x01
DEF BT1 0x02
DEF BT2 0x04
DEF BT3 0x08
DEF SWMASK_Upper  0xF0
DEF SWMASK_Lower  0x0F
DEF BIT_NUMBER 4

    code

start: ;main
    mov r0, SW
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
    rts

LSUB:
    SUB r3,r4
    JC error
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
    rts

LDIV:
    cmp r4, #0
    jz error
    mov r5, #BIT_NUMBER              ; ciklusv�ltoz�
    mov r6, r3              ; marad�k
    mov r7, #0              ; eredm�ny    
shift_loop:                 ; oszt� hatv�nyoz�sa
    sl0 r4
    sub r5, #1
    jnz shift_loop
    mov r5, #BIT_NUMBER
div_loop:
    sr0 r4
    cmp r6, r4
    jc rem_lt_div           ; ha marad�k kisebb mint oszt�hatv�ny
    sl1 r7
    sub r6, r4
    JMP check
rem_lt_div:
    sl0 r7
check:
    sub r5, #1
    jnz div_loop
    mov r5, #4
divmod_loop:
    sl0 r7
    sub r5, #1
    jnz divmod_loop
    add r7, r6
    mov LD, r7
    rts

error:
    mov r3, #0xFF
    mov LD, r3
    rts