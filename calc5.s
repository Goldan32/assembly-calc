DEF LD   0x80                ; LED adatregiszter                    (írható/olvasható)
DEF BT   0x84                ; Nyomógomb adatregiszter              (csak olvasható)
DEF BTIE 0x85                ; Nyomógomb megszakítás eng. regiszter (írható/olvasható)
DEF BTIF 0x86                ; Nyomógomb megszakítás flag regiszter (olvasható és a bit 1 beírásával törölhetõ)
DEF UC   0x88                ; USRT kontroll regiszter              (csak írható)
DEF US   0x89                ; USRT FIFO státusz regiszter          (csak olvasható)
DEF UIE  0x8A                ; USRT megszakítás eng. reg.           (írható/olvasható)
DEF UD   0x8B                ; USRT adatregiszter                   (írható/olvasható)
DEF UC_INIT 0b00001110       ; FIFO törlés, USRT vevõ engedélyezett
DEF UIE_INIT 0b00001100
DEF ASCII_EQU 0x3D
DEF ASCII_ADD 0x2B
DEF ASCII_SUB 0x2D
DEF ASCII_MUL 0x2A
DEF ASCII_DIV 0x2F
DEF ASCII_ESC 0x1B

    code
jmp start
jmp rx_irq  ; 0x01 helyen IT rutin jump utasítás

;----------------------------
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
;---------------------------   

start:              ; ez az, ami bármi történik, bekerül a MAIN-be.
    mov r0, #0  ; LD törlése
    mov LD, r0
    mov r0, #UC_INIT    ; Vezérlõregiszter beállítása
    mov UC, r0
    mov r0, #UIE_INIT   ; IT engedélyezés
    mov UIE, r0
    sti
loop:           ; ez az amit te már külön rutinban csinálsz
    AND r5, #1
    JZ loop
    XOR r5, #1
    JMP loop
    
rx_irq:
    mov r15, UD     ; UD tartalmazza a vételi vonalon kapott karaktert 
    mov LD, r15     ; Ki írom LED-re a kapott értéket (DEBUG, szóval elhanyagolható)
    mov r5, #1      ; Jelzõ BIT 1-es = kaptam adatot
    rti
    
    