DEF LD   0x80                ; LED adatregiszter                    (írható/olvasható)
DEF SW   0x81                ; DIP kapcsoló adatregiszter           (csak olvasható)
DEF BT   0x84                ; Nyomógomb adatregiszter              (csak olvasható)
DEF BTIE 0x85                ; Nyomógomb megszakítás eng. regiszter (írható/olvasható)
DEF BTIF 0x86                ; Nyomógomb megszakítás flag regiszter (olvasható és a bit 1 beírásával törölhetõ)
DEF BT0 0x01
DEF BT1 0x02
DEF BT2 0x04
DEF BT3 0x08
DEF SWMASK_Upper  0xF0
DEF SWMASK_Lower  0x0F

    code
start:
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
    jsr LXOR
    jmp start
LADD:
    ADD r3, r4
    mov LD, r3
    rts
LSUB:
    SUB r3,r4
    JC sub_error
    mov LD, r3
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
    rts
LXOR:
    XOR r3,r4
    mov LD,r3
    rts