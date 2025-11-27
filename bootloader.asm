; bootloader.asm
; YannaOS 16-bit Bootloader with Protected Mode transition

BITS 16
ORG 0x7C00

; Define constants for GDT selectors
CODE_SEG_SEL    EQU 0x08 ; Selector for our 32-bit code segment
DATA_SEG_SEL    EQU 0x10 ; Selector for our 32-bit data segment

Start:
    ; Standard BIOS setup
    XOR AX, AX
    MOV DS, AX
    MOV ES, AX
    MOV SS, AX
    MOV SP, 0x7C00 ; Stack grows downwards from bootloader start

    MOV SI, BootMessage
    CALL PrintString

    ; --- Enable A20 Line ---
    ; This is required to access more than 1MB of memory.
    ; Method 2: Using the Keyboard Controller (most common)
    CLI                      ; Disable interrupts
    CALL A20_WAIT_INPUT      ; Wait for input buffer empty
    MOV AL, 0xD1             ; Command: Write to Output Port
    OUT 0x64, AL
    CALL A20_WAIT_INPUT      ; Wait for input buffer empty
    MOV AL, 0xDF             ; Data: Enable A20
    OUT 0x60, AL
    CALL A20_WAIT_OUTPUT     ; Wait for output buffer full (optional but good practice)
    STI                      ; Enable interrupts

    ; --- Load GDT ---
    LGDT [gdt_descriptor]

    ; --- Enter Protected Mode ---
    MOV EAX, CR0
    OR AL, 0x01 ; Set PE bit (bit 0)
    MOV CR0, EAX

    ; --- Far jump to 32-bit code segment ---
    ; The jump destination is a `segment:offset` pair.
    ; Here, segment is our 32-bit code selector, offset is the 32-bit entry point in kernel.
    JMP CODE_SEG_SEL:ProtectedModeEntry

; --- A20 Helper Functions ---
A20_WAIT_INPUT:
    IN AL, 0x64
    TEST AL, 0x02
    JNZ A20_WAIT_INPUT
    RET

A20_WAIT_OUTPUT:
    IN AL, 0x64
    TEST AL, 0x01
    JZ A20_WAIT_OUTPUT
    RET

; PrintString: 16-bit real mode string print (BIOS int 10h)
; Input: SI = Address of null-terminated string
PrintString:
    PUSH AX
    PUSH BX
    PUSH SI

.loop:
    MOV AL, [SI]
    CMP AL, 0
    JE .done

    MOV AH, 0x0E ; BIOS teletype output
    MOV BH, 0x00 ; Page number
    MOV BL, 0x07 ; Light Gray on Black
    INT 0x10

    INC SI
    JMP .loop

.done:
    POP SI
    POP BX
    POP AX
    RET

; --- Global Descriptor Table (GDT) ---
; Each descriptor is 8 bytes.
gdt_start:
    ; Null Descriptor (mandatory)
    dq 0x0

    ; Code Segment Descriptor (Selector 0x08)
    ; Base = 0x00000000, Limit = 0xFFFFFFFF (4GB)
    ; Flags: Present(1), DPL(0), S(1=code/data), Type(1010=Executable, Readable)
    ; Granularity(1=4KB units), D/B(1=32bit), L(0=not 64bit)
    CODE_SEG_DESC:
    dw 0xFFFF    ; Segment Limit (low)
    dw 0x0000    ; Base Address (low)
    db 0x00      ; Base Address (middle)
    db 10011010b ; Access Byte: Present, Ring 0, Code, Exec/Read, Accessed
    db 11001111b ; Granularity (1=4KB limit units), 32-bit default operand size, Limit (high)
    db 0x00      ; Base Address (high)

    ; Data Segment Descriptor (Selector 0x10)
    ; Base = 0x00000000, Limit = 0xFFFFFFFF (4GB)
    ; Flags: Present(1), DPL(0), S(1=code/data), Type(0010=Read/Write)
    ; Granularity(1=4KB units), D/B(1=32bit)
    DATA_SEG_DESC:
    dw 0xFFFF    ; Segment Limit (low)
    dw 0x0000    ; Base Address (low)
    db 0x00      ; Base Address (middle)
    db 10010010b ; Access Byte: Present, Ring 0, Data, Read/Write, Accessed
    db 11001111b ; Granularity (1=4KB limit units), 32-bit default operand size, Limit (high)
    db 0x00      ; Base Address (high)

gdt_end:

; GDT pointer structure (for LGDT instruction)
gdt_descriptor:
    dw gdt_end - gdt_start - 1 ; Size of GDT - 1
    dd gdt_start               ; Address of GDT

BootMessage: DB "Booting YannaOS (Protected Mode Transition)...", 0x0D, 0x0A, 0

; Bootloader signature
TIMES 510 - ($ - $$) DB 0
DW 0xAA55