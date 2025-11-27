BITS 16                 ; 16-bit code

ORG 0x0000              ; Kernel loaded at 0x8000:0x0000, so its internal origin is 0x0000

; Constants
MAX_INPUT_LEN equ 64    ; Maximum characters for command input

KernelStart:
    ; Set up segment registers for safety
    mov ax, 0x8000
    mov ds, ax
    mov es, ax

    ; --- Print initial Kernel message ---
    mov si, KernelMessage1 ; Load address of KernelMessage1 into SI
    call PrintString       ; Call our print function

TerminalLoop:
    ; --- Print command prompt ---
    mov si, PromptMessage  ; Load address of PromptMessage into SI
    call PrintString       ; Call print function

    ; --- Read command line input ---
    xor cx, cx             ; Initialize character count to 0
    mov di, InputBuffer    ; Set DI to the start of the input buffer

.ReadInputLoop:
    call ReadKey           ; Read a character into AL

    cmp al, 0x08           ; Backspace?
    je .HandleBackspace

    cmp al, 0x0D           ; Enter key?
    je .HandleEnter

    ; Echo character to screen
    mov ah, 0x0E
    mov bx, 0x0000
    int 0x10

    ; Store character in buffer
    mov [di], al
    inc di                 ; Move to next buffer position
    inc cx                 ; Increment character count

    cmp cx, MAX_INPUT_LEN  ; Check for buffer overflow
    jl .ReadInputLoop      ; If not full, continue reading
    jmp .HandleEnter       ; If full, treat as enter

.HandleBackspace:
    cmp cx, 0              ; Any chars to backspace?
    je .ReadInputLoop      ; No, ignore backspace

    dec di                 ; Move back in buffer
    dec cx                 ; Decrement character count

    ; Erase character from screen: backspace, space, backspace
    mov ah, 0x0E
    mov al, 0x08           ; Backspace
    int 0x10
    mov al, ' '            ; Space
    int 0x10
    mov al, 0x08           ; Backspace again
    int 0x10
    jmp .ReadInputLoop

.HandleEnter:
    mov byte [di], 0       ; Null-terminate the input string
    ; Print a newline after enter
    mov al, 10
    int 0x10
    mov al, 13
    int 0x10

    ; --- Process Command (for now, just echo it) ---
    mov si, EchoMessage    ; Print 'You typed: '
    call PrintString
    mov si, InputBuffer    ; Print the input buffer
    call PrintString
    mov al, 10             ; Newline
    int 0x10
    mov al, 13             ; Carriage return
    int 0x10

    jmp TerminalLoop       ; Go back to prompt for next command

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

; --- ReadKey Procedure ---
; Output: AL = ASCII code of pressed key
ReadKey:
    mov ah, 0x00        ; BIOS Get Keystroke function
    int 0x16            ; Call BIOS keyboard services
    ; AH contains scan code, AL contains ASCII code
    ret                 ; Return from procedure

; --- Data ---
KernelMessage1 db "Welcome to YannaOS Terminal!", 10, 13, 0
PromptMessage  db "YannaOS> ", 0
EchoMessage    db "You typed: ", 0
InputBuffer    times MAX_INPUT_LEN db 0 ; Buffer for keyboard input
