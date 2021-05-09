DEF LD   0x80                ; LED adatregiszter                    (�rhat�/olvashat�)
DEF BT   0x84                ; Nyom�gomb adatregiszter              (csak olvashat�)
DEF BTIE 0x85                ; Nyom�gomb megszak�t�s eng. regiszter (�rhat�/olvashat�)
DEF BTIF 0x86                ; Nyom�gomb megszak�t�s flag regiszter (olvashat� �s a bit 1 be�r�s�val t�r�lhet�)
DEF UC   0x88                ; USRT kontroll regiszter              (csak �rhat�)
DEF US   0x89                ; USRT FIFO st�tusz regiszter          (csak olvashat�)
DEF UIE  0x8A                ; USRT megszak�t�s eng. reg.           (�rhat�/olvashat�)
DEF UD   0x8B                ; USRT adatregiszter                   (�rhat�/olvashat�)
DEF UC_INIT 0b00001110       ; FIFO t�rl�s, USRT vev� enged�lyezett
DEF UIE_INIT 0b00001100
DEF ASCII_EQU 0x3D
DEF ASCII_ADD 0x2B
DEF ASCII_SUB 0x2D
DEF ASCII_MUL 0x2A
DEF ASCII_DIV 0x2F
DEF ASCII_ESC 0x1B

    code
jmp start
jmp rx_irq  ; 0x01 helyen IT rutin jump utas�t�s

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

start:              ; ez az, ami b�rmi t�rt�nik, beker�l a MAIN-be.
    mov r0, #0  ; LD t�rl�se
    mov LD, r0
    mov r0, #UC_INIT    ; Vez�rl�regiszter be�ll�t�sa
    mov UC, r0
    mov r0, #UIE_INIT   ; IT enged�lyez�s
    mov UIE, r0
    sti
loop:           ; ez az amit te m�r k�l�n rutinban csin�lsz
    AND r5, #1
    JZ loop
    XOR r5, #1
    JMP loop
    
rx_irq:
    mov r15, UD     ; UD tartalmazza a v�teli vonalon kapott karaktert 
    mov LD, r15     ; Ki �rom LED-re a kapott �rt�ket (DEBUG, sz�val elhanyagolhat�)
    mov r5, #1      ; Jelz� BIT 1-es = kaptam adatot
    rti
    
    