ORG 0x7C00              ; Origin of the boot sector

BITS 16                 ; 16-bit code

; --- Setup Segment Registers ---
    mov ax, 0x07C0      ; Set AX to the current segment
    mov ds, ax          ; Set Data Segment (DS) to AX
    mov es, ax          ; Set Extra Segment (ES) to AX
    mov ss, ax          ; Set Stack Segment (SS) to AX
    mov sp, 0xFFFE      ; Set Stack Pointer (SP) to a high address

; --- Print a message ---
    mov ah, 0x0E        ; BIOS teletype function
    mov bx, 0x0000      ; Page number (for video mode)
    mov si, BootMessage ; Load address of BootMessage into SI

.PrintLoop:
    lodsb               ; Load byte from [si] into AL, increment SI
    cmp al, 0           ; Check if end of string
    je .EndPrintLoop    ; If yes, jump to end
    int 0x10            ; Call BIOS to print character
    jmp .PrintLoop      ; Loop

.EndPrintLoop:
    jmp $               ; Infinite loop to halt system

BootMessage db "Booting YannaOS...", 0 ; Null-terminated string

; --- Padding and Boot Signature ---
TIMES 510 - ($ - $$) db 0 ; Pad with zeros until 510 bytes
dw 0xAA55               ; Boot signature