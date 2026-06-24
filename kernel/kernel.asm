bits 16
org 0x0000

MAX_INPUT equ 80
COM1 equ 0x3f8

start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xfffe
    sti

    call serial_init
    mov ax, 0x0003
    int 0x10

    mov si, banner
    call puts

shell_loop:
    mov si, prompt
    call puts
    mov di, input_buffer
    call read_line
    mov si, input_buffer
    call handle_command
    jmp shell_loop

serial_init:
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x80
    out dx, al
    mov dx, COM1
    mov al, 0x03
    out dx, al
    mov dx, COM1 + 1
    xor al, al
    out dx, al
    mov dx, COM1 + 3
    mov al, 0x03
    out dx, al
    mov dx, COM1 + 2
    mov al, 0xc7
    out dx, al
    mov dx, COM1 + 4
    mov al, 0x0b
    out dx, al
    ret

serial_has_char:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x01
    jz .none
    stc
    ret
.none:
    clc
    ret

serial_putc:
    push ax
    push dx
    mov ah, al
.wait:
    mov dx, COM1 + 5
    in al, dx
    test al, 0x20
    jz .wait
    mov dx, COM1
    mov al, ah
    out dx, al
    pop dx
    pop ax
    ret

read_char:
.again:
    call serial_has_char
    jc .from_serial
    mov ah, 0x01
    int 0x16
    jz .again
    xor ah, ah
    int 0x16
    ret
.from_serial:
    mov dx, COM1
    in al, dx
    cmp al, 10
    jne .done
    mov al, 13
.done:
    ret

putc:
    push ax
    push bx
    push cx
    push dx
    mov ah, 0x0e
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    pop dx
    pop cx
    pop bx
    pop ax
    call serial_putc
    ret

puts:
    push ax
    push si
.next:
    lodsb
    cmp al, 0
    je .done
    call putc
    jmp .next
.done:
    pop si
    pop ax
    ret

newline:
    mov al, 13
    call putc
    mov al, 10
    call putc
    ret

read_line:
    xor cx, cx
.next:
    call read_char
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace
    cmp al, 127
    je .backspace
    cmp al, 32
    jb .next
    cmp cx, MAX_INPUT - 1
    jae .next
    stosb
    inc cx
    call putc
    jmp .next
.backspace:
    cmp cx, 0
    je .next
    dec di
    dec cx
    mov al, 8
    call putc
    mov al, ' '
    call putc
    mov al, 8
    call putc
    jmp .next
.enter:
    mov al, 0
    stosb
    call newline
    ret

skip_spaces:
    cmp byte [si], ' '
    jne .done
    inc si
    jmp skip_spaces
.done:
    ret

streq:
    push si
    push di
.next:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .no
    cmp al, 0
    je .yes
    inc si
    inc di
    jmp .next
.yes:
    mov al, 1
    jmp .done
.no:
    xor al, al
.done:
    pop di
    pop si
    ret

startswith:
    push si
    push di
.next:
    mov bl, [di]
    cmp bl, 0
    je .yes
    mov al, [si]
    cmp al, bl
    jne .no
    inc si
    inc di
    jmp .next
.yes:
    mov al, 1
    jmp .done
.no:
    xor al, al
.done:
    pop di
    pop si
    ret

handle_command:
    call skip_spaces
    cmp byte [si], 0
    je .done

    mov di, cmd_help
    call streq
    cmp al, 1
    je command_help

    mov di, cmd_about
    call streq
    cmp al, 1
    je command_about

    mov di, cmd_clear
    call streq
    cmp al, 1
    je command_clear

    mov di, cmd_cls
    call streq
    cmp al, 1
    je command_clear

    mov di, cmd_echo
    call streq
    cmp al, 1
    je command_echo_blank

    mov di, cmd_echo_prefix
    call startswith
    cmp al, 1
    je command_echo

    mov di, cmd_mem
    call streq
    cmp al, 1
    je command_mem

    mov di, cmd_reboot
    call streq
    cmp al, 1
    je command_reboot

    mov di, cmd_poweroff
    call streq
    cmp al, 1
    je command_poweroff

    mov di, cmd_halt
    call streq
    cmp al, 1
    je command_halt

    mov di, cmd_exit
    call streq
    cmp al, 1
    je command_poweroff

    mov si, unknown_message
    call puts
    mov si, input_buffer
    call skip_spaces
    call puts
    call newline
.done:
    ret

command_help:
    mov si, help_message
    call puts
    ret

command_about:
    mov si, about_message
    call puts
    ret

command_clear:
    mov ax, 0x0003
    int 0x10
    ret

command_echo_blank:
    call newline
    ret

command_echo:
    add si, 5
    call puts
    call newline
    ret

command_mem:
    mov si, mem_message
    call puts
    int 0x12
    call print_u16
    mov si, kb_message
    call puts
    ret

command_reboot:
    mov si, reboot_message
    call puts
    cli
    xor ax, ax
    mov ds, ax
    mov word [0x0472], 0x1234
    mov al, 0xfe
    out 0x64, al
    jmp 0xffff:0x0000

command_poweroff:
    mov si, poweroff_message
    call puts
    mov dx, 0x0604
    mov ax, 0x2000
    out dx, ax
    jmp command_halt

command_halt:
    mov si, halt_message
    call puts
    cli
.forever:
    hlt
    jmp .forever

print_u16:
    push ax
    push bx
    push cx
    push dx
    cmp ax, 0
    jne .convert
    mov al, '0'
    call putc
    jmp .done
.convert:
    xor cx, cx
    mov bx, 10
.digit:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    cmp ax, 0
    jne .digit
.print:
    pop dx
    mov al, dl
    call putc
    loop .print
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

banner db 13, 10
       db "Terminal OS", 13, 10
       db "A minimal text-only system. Type 'help'.", 13, 10, 13, 10, 0
prompt db "tinyos> ", 0

help_message db "commands: help about clear cls echo mem reboot poweroff halt", 13, 10, 0
about_message db "Terminal OS: one boot sector, one 16-bit kernel, one tiny shell.", 13, 10, 0
unknown_message db "unknown command: ", 0
mem_message db "conventional memory: ", 0
kb_message db " KB", 13, 10, 0
reboot_message db "rebooting...", 13, 10, 0
poweroff_message db "powering off...", 13, 10, 0
halt_message db "system halted.", 13, 10, 0

cmd_help db "help", 0
cmd_about db "about", 0
cmd_clear db "clear", 0
cmd_cls db "cls", 0
cmd_echo db "echo", 0
cmd_echo_prefix db "echo ", 0
cmd_mem db "mem", 0
cmd_reboot db "reboot", 0
cmd_poweroff db "poweroff", 0
cmd_halt db "halt", 0
cmd_exit db "exit", 0

input_buffer times MAX_INPUT db 0
