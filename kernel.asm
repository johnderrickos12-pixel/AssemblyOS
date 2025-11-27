BITS 16                 ; 16-bit code

ORG 0x0000              ; Kernel loaded at 0x8000:0x0000, so its internal origin is 0x0000

KernelStart:
    ; Set up segment registers if needed, though bootloader set them to 0x07C0 or 0x8000
    ; For simplicity, we'll assume ES/DS are still valid or can be reset.
    ; Let's re-establish DS and ES for safety in the kernel context
    mov ax, 0x8000
    mov ds, ax
    mov es, ax

    ; --- Print initial Kernel message ---
    mov si, KernelMessage1 ; Load address of KernelMessage1 into SI
    call PrintString       ; Call our new print function

    ; --- Print another message using the same function ---
    mov si, KernelMessage2 ; Load address of KernelMessage2 into SI
    call PrintString       ; Call print function again

    jmp $                  ; Infinite loop to halt system

; --- PrintString Procedure ---
; Input: SI = Address of null-terminated string
PrintString:
    mov ah, 0x0E        ; BIOS teletype function
    mov bx, 0x0000      ; Page number (for video mode)

.PrintLoop:
    lodsb               ; Load byte from [si] into AL, increment SI
    cmp al, 0           ; Check if end of string
    je .EndPrintLoop    ; If yes, jump to end
    int 0x10            ; Call BIOS to print character
    jmp .PrintLoop      ; Loop

.EndPrintLoop:
    ret                 ; Return from procedure

; --- Data ---
KernelMessage1 db "Welcome to YannaOS Kernel!", 10, 13, 0 ; Null-terminated, with newline/carriage return
KernelMessage2 db "A new day begins in YannaOS.", 10, 13, 0 ; Another message
