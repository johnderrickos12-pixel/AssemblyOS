BITS 16                 ; 16-bit code

; --- Print a message ---
    mov ah, 0x0E        ; BIOS teletype function
    mov bx, 0x0000      ; Page number (for video mode)
    mov si, KernelMessage ; Load address of KernelMessage into SI

.PrintLoop:
    lodsb               ; Load byte from [si] into AL, increment SI
    cmp al, 0           ; Check if end of string
    je .EndPrintLoop    ; If yes, jump to end
    int 0x10            ; Call BIOS to print character
    jmp .PrintLoop      ; Loop

.EndPrintLoop:
    jmp $               ; Infinite loop to halt system

KernelMessage db "Welcome to YannaOS Kernel!", 0 ; Null-terminated string