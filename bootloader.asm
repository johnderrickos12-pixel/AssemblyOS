ORG 0x7C00              ; Origin of the boot sector

BITS 16                 ; 16-bit code

; --- Setup Segment Registers ---
    mov ax, 0x07C0      ; Set AX to the current segment
    mov ds, ax          ; Set Data Segment (DS) to AX
    mov es, ax          ; Set Extra Segment (ES) to AX
    mov ss, ax          ; Set Stack Segment (SS) to AX
    mov sp, 0xFFFE      ; Set Stack Pointer (SP) to a high address

; --- Print Boot Message ---
    mov ah, 0x0E        ; BIOS teletype function
    mov bx, 0x0000      ; Page number (for video mode)
    mov si, BootMessage ; Load address of BootMessage into SI

.PrintBootLoop:
    lodsb               ; Load byte from [si] into AL, increment SI
    cmp al, 0           ; Check if end of string
    je .EndPrintBootLoop; If yes, jump to end
    int 0x10            ; Call BIOS to print character
    jmp .PrintBootLoop  ; Loop

.EndPrintBootLoop:
    ; --- Load Kernel ---
    ; We'll load the kernel to 0x8000:0x0000 (segment 0x8000, offset 0x0000)
    ; This means ES:BX = 0x8000:0x0000
    mov ax, 0x8000      ; Segment where kernel will be loaded
    mov es, ax          ; Set ES to segment 0x8000
    xor bx, bx          ; Set BX to 0 (offset)

    mov ah, 0x02        ; BIOS Read Disk Sectors function
    mov al, 1           ; Number of sectors to read (1 sector for kernel)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Starting sector 2 (boot sector is 1, kernel is 2)
    mov dh, 0           ; Head 0
    mov dl, 0x80        ; Drive number (0x80 for first hard disk, 0x00 for first floppy)
                        ; For QEMU, 0x00 is usually floppy, 0x80 is first HDD. Let's assume floppy for now (0x00)
                        ; If booting from floppy image, use 0x00. Our Makefile creates a floppy image.
    int 0x13            ; Call BIOS disk services

    jc .DiskError       ; Jump if carry flag set (error)

    ; --- Jump to Kernel ---
    jmp 0x8000:0x0000   ; Far jump to the loaded kernel

.DiskError:
    mov ah, 0x0E        ; BIOS teletype function
    mov bx, 0x0000
    mov si, ErrorMessage
.PrintErrorLoop:
    lodsb
    cmp al, 0
    je .EndPrintErrorLoop
    int 0x10
    jmp .PrintErrorLoop
.EndPrintErrorLoop:
    jmp $               ; Halt on error

BootMessage  db "Booting YannaOS...", 0
ErrorMessage db "Disk Read Error!", 0

; --- Padding and Boot Signature ---
TIMES 510 - ($ - $$) db 0 ; Pad with zeros until 510 bytes
dw 0xAA55               ; Boot signature