; kernel.asm
; YannaOS 32-bit Protected Mode Kernel

BITS 32 ; Tell NASM to assemble in 32-bit mode
ORG 0x8000 ; This is where the kernel will be loaded (same as before)

; Define constants for GDT selectors (should match bootloader)
CODE_SEG_SEL    EQU 0x08
DATA_SEG_SEL    EQU 0x10

ProtectedModeEntry:
    ; Set up segment registers for 32-bit Protected Mode
    ; All segment registers except CS should point to the data segment
    MOV AX, DATA_SEG_SEL
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX ; Stack segment
    MOV ESP, 0x90000 ; Set up a stack pointer at a higher address (e.g., end of 512KB mark)

    ; Now we are in 32-bit Protected Mode!
    ; We can't use BIOS interrupts (int 10h) directly anymore for screen output.
    ; We'll use direct video memory access (text mode) at 0xB8000.

    MOV EDI, 0xB8000 ; Point EDI to video memory

    ; Clear screen (simple method for now)
    MOV ECX, 80 * 25 ; Total characters on screen
    MOV EAX, 0x07200720 ; Space char with light grey on black attribute
.clear_loop:
    MOV DWORD [EDI], EAX
    ADD EDI, 4
    LOOP .clear_loop

    ; Reset EDI to start of video memory
    MOV EDI, 0xB8000

    ; Print a confirmation message by writing directly to VRAM.
    MOV ECX, Kernel32BitMessageLen
    MOV ESI, Kernel32BitMessage
    MOV EBX, 0x07 ; Light Gray on Black attribute

.print_loop:
    MOV AL, [ESI]
    MOV AH, BL
    MOV WORD [EDI], AX ; Write char + attribute
    ADD EDI, 2
    INC ESI
    LOOP .print_loop

    ; Infinite loop to halt the OS
    JMP $

; --- Data Section ---
Kernel32BitMessage: DB "YannaOS Kernel (32-bit Protected Mode)!", 0
Kernel32BitMessageLen EQU $ - Kernel32BitMessage

; Pad kernel to 512 bytes (or more if needed)
TIMES 512 - ($ - $$) DB 0