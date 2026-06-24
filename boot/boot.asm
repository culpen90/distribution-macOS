bits 16
org 0x7c00

%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 32
%endif

KERNEL_SEG equ 0x1000

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    mov [boot_drive], dl
    mov si, boot_message
    call puts

    mov ax, KERNEL_SEG
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    jmp KERNEL_SEG:0x0000

disk_error:
    mov si, disk_error_message
    call puts

halt:
    cli
    hlt
    jmp halt

puts:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0e
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp puts
.done:
    ret

boot_drive db 0
boot_message db 13, 10, "Terminal OS booting...", 13, 10, 0
disk_error_message db "Disk read failed.", 13, 10, 0

times 510 - ($ - $$) db 0
dw 0xaa55
