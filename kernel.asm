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
    ; If full, fall through to HandleEnter as no more input can be taken

.HandleEnter:
    mov byte [di], 0       ; Null-terminate the input string
    ; Print a newline after enter
    mov al, 10
    int 0x10
    mov al, 13
    int 0x10

    ; --- Process Command ---
    mov si, InputBuffer    ; SI points to the start of the input string
    call ParseAndExecute   ; Go to command parser

    jmp TerminalLoop       ; Go back to prompt for next command

; --- ParseAndExecute Procedure ---
; Input: SI = Address of the input string (command line)
ParseAndExecute:
    ; Find the first space to separate command from arguments
    push si                 ; Save SI (start of command string)
    mov di, si              ; DI will scan for space
.FindSpaceLoop:
    cmp byte [di], ' '     ; Is it a space?
    je .SpaceFound
    cmp byte [di], 0        ; End of string?
    je .NoSpaceFound
    inc di
    jmp .FindSpaceLoop

.SpaceFound:
    mov byte [di], 0        ; Null-terminate the command part
    inc di                  ; DI now points to the start of arguments (or null if no args)
    mov bx, di              ; BX now holds address of arguments
    jmp .CommandCheck

.NoSpaceFound:
    xor bx, bx              ; No arguments (BX = 0)

.CommandCheck:
    pop si                  ; Restore SI to point to command

    ; --- Check for 'help' command ---
    push bx                 ; Save BX (arguments address)
    mov di, HelpCmd         ; DI points to 'help' string
    call StrCmp             ; Compare command with 'help'
    cmp ax, 0               ; If AX == 0, strings are equal
    je .ExecuteHelp
    pop bx                  ; Restore BX

    ; --- Check for 'clear' command ---
    push bx                 ; Save BX
    mov di, ClearCmd        ; DI points to 'clear' string
    call StrCmp
    cmp ax, 0
    je .ExecuteClear
    pop bx                  ; Restore BX

    ; --- Check for 'echo' command ---
    push bx                 ; Save BX
    mov di, EchoCmd         ; DI points to 'echo' string
    call StrCmp
    cmp ax, 0
    je .ExecuteEcho
    pop bx                  ; Restore BX

    ; --- Unknown Command ---
    mov si, UnknownCmdMsg   ; Load 'Unknown command' message
    call PrintString
    jmp .EndExecute

.ExecuteHelp:
    pop bx                  ; Discard saved BX, not needed for help
    mov si, HelpMessage
    call PrintString
    jmp .EndExecute

.ExecuteClear:
    pop bx                  ; Discard saved BX
    call ClearScreen
    jmp .EndExecute

.ExecuteEcho:
    pop bx                  ; BX now holds argument address (or 0 if none)
    cmp bx, 0               ; Any arguments?
    je .EchoNoArgs          ; If no args, just print newline
    mov si, bx              ; SI points to the argument string
    call PrintString
    jmp .EndExecute
.EchoNoArgs:
    ; Just print newline (already done by .HandleEnter, but keep for consistency)
    ; Not strictly needed here as newlines are handled after command execution
    jmp .EndExecute

.EndExecute:
    ret                     ; Return from ParseAndExecute

; --- StrCmp Procedure ---
; Input: SI = Ptr to string 1, DI = Ptr to string 2
; Output: AX = 0 if equal, non-zero if not equal
StrCmp:
    push cx                 ; Save CX
.CompareLoop:
    mov cl, [si]            ; Get char from string 1
    mov ch, [di]            ; Get char from string 2
    cmp cl, ch              ; Compare characters
    jne .NotEqual
    cmp cl, 0               ; End of string 1 (and thus string 2 if equal so far)?
    je .Equal
    inc si
    inc di
    jmp .CompareLoop
.NotEqual:
    mov ax, 1               ; Set AX to non-zero (not equal)
    jmp .EndStrCmp
.Equal:
    mov ax, 0               ; Set AX to 0 (equal)
.EndStrCmp:
    pop cx                  ; Restore CX
    ret

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

; --- ClearScreen Procedure ---
ClearScreen:
    mov ah, 0x00        ; BIOS Set Video Mode function
    mov al, 0x03        ; Text mode 80x25, 16 colors, 8 pages
    int 0x10            ; Call BIOS video services
    ret

; --- Data ---
KernelMessage1 db "Welcome to YannaOS Terminal! Type 'help' for commands.", 10, 13, 0
PromptMessage  db "YannaOS> ", 0
UnknownCmdMsg  db "Unknown command. Type 'help'.", 10, 13, 0
HelpCmd        db "help", 0
ClearCmd       db "clear", 0
EchoCmd        db "echo", 0
HelpMessage    db "Available commands:", 10, 13
               db "  help - Display this help message", 10, 13
               db "  clear - Clear the screen", 10, 13
               db "  echo <message> - Display a message", 10, 13, 0
InputBuffer    times MAX_INPUT_LEN db 0 ; Buffer for keyboard input
