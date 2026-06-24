bits 16
org 0x0000

MAX_INPUT equ 80
COM1 equ 0x3f8
SCREEN_COLS equ 80

ATTR_DESKTOP equ 0x1f
ATTR_TOPBAR equ 0x70
ATTR_TILE_SHELL equ 0x3f
ATTR_TILE_FILES equ 0x2f
ATTR_TILE_SETTINGS equ 0x5f
ATTR_TILE_POWER equ 0x4f
ATTR_WINDOW equ 0x0f
ATTR_WINDOW_BAR equ 0x70
ATTR_WINDOW_FOOTER equ 0x78
ATTR_TERM equ 0x0f
ATTR_DOCK equ 0x70
ATTR_SHADOW equ 0x08

WIN_LEFT equ 4
WIN_TOP equ 6
WIN_WIDTH equ 72
WIN_HEIGHT equ 15

TERM_LEFT equ 5
TERM_TOP equ 8
TERM_WIDTH equ 70
TERM_HEIGHT equ 12

start:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xfffe
    sti

    call serial_init
    call draw_ui

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
    call term_putc
    pop ax
    call serial_putc
    ret

draw_ui:
    push ax
    push bx
    push cx
    push dx
    push si

    mov ax, 0x0003
    int 0x10

    mov dh, 0
    mov dl, 0
    mov ch, 25
    mov cl, 80
    mov bl, ATTR_DESKTOP
    call fill_rect

    mov dh, 0
    mov dl, 0
    mov ch, 1
    mov cl, 80
    mov bl, ATTR_TOPBAR
    call fill_rect

    mov si, top_brand
    mov dh, 0
    mov dl, 2
    mov bl, ATTR_TOPBAR
    call draw_text_at
    mov si, top_menu
    mov dh, 0
    mov dl, 19
    mov bl, ATTR_TOPBAR
    call draw_text_at
    mov si, top_status
    mov dh, 0
    mov dl, 67
    mov bl, ATTR_TOPBAR
    call draw_text_at

    mov dh, 2
    mov dl, 4
    mov ch, 3
    mov cl, 16
    mov bl, ATTR_TILE_SHELL
    call fill_rect
    mov dh, 2
    mov dl, 23
    mov ch, 3
    mov cl, 16
    mov bl, ATTR_TILE_FILES
    call fill_rect
    mov dh, 2
    mov dl, 42
    mov ch, 3
    mov cl, 16
    mov bl, ATTR_TILE_SETTINGS
    call fill_rect
    mov dh, 2
    mov dl, 61
    mov ch, 3
    mov cl, 15
    mov bl, ATTR_TILE_POWER
    call fill_rect

    mov si, tile_shell_title
    mov dh, 2
    mov dl, 6
    mov bl, ATTR_TILE_SHELL
    call draw_text_at
    mov si, tile_shell_sub
    mov dh, 3
    mov dl, 6
    mov bl, ATTR_TILE_SHELL
    call draw_text_at
    mov si, tile_files_title
    mov dh, 2
    mov dl, 25
    mov bl, ATTR_TILE_FILES
    call draw_text_at
    mov si, tile_files_sub
    mov dh, 3
    mov dl, 25
    mov bl, ATTR_TILE_FILES
    call draw_text_at
    mov si, tile_settings_title
    mov dh, 2
    mov dl, 44
    mov bl, ATTR_TILE_SETTINGS
    call draw_text_at
    mov si, tile_settings_sub
    mov dh, 3
    mov dl, 44
    mov bl, ATTR_TILE_SETTINGS
    call draw_text_at
    mov si, tile_power_title
    mov dh, 2
    mov dl, 63
    mov bl, ATTR_TILE_POWER
    call draw_text_at
    mov si, tile_power_sub
    mov dh, 3
    mov dl, 63
    mov bl, ATTR_TILE_POWER
    call draw_text_at

    mov dh, WIN_TOP + 1
    mov dl, WIN_LEFT + 2
    mov ch, WIN_HEIGHT
    mov cl, WIN_WIDTH
    mov bl, ATTR_SHADOW
    call fill_rect

    mov dh, WIN_TOP
    mov dl, WIN_LEFT
    mov ch, WIN_HEIGHT
    mov cl, WIN_WIDTH
    mov bl, ATTR_WINDOW
    call fill_rect

    mov dh, WIN_TOP
    mov dl, WIN_LEFT
    mov ch, 1
    mov cl, WIN_WIDTH
    mov bl, ATTR_WINDOW_BAR
    call fill_rect
    mov si, window_title
    mov dh, WIN_TOP
    mov dl, WIN_LEFT + 2
    mov bl, ATTR_WINDOW_BAR
    call draw_text_at

    mov dh, WIN_TOP + WIN_HEIGHT - 1
    mov dl, WIN_LEFT
    mov ch, 1
    mov cl, WIN_WIDTH
    mov bl, ATTR_WINDOW_FOOTER
    call fill_rect
    mov si, window_footer
    mov dh, WIN_TOP + WIN_HEIGHT - 1
    mov dl, WIN_LEFT + 2
    mov bl, ATTR_WINDOW_FOOTER
    call draw_text_at

    mov dh, 22
    mov dl, 8
    mov ch, 2
    mov cl, 64
    mov bl, ATTR_DOCK
    call fill_rect
    mov si, dock_label
    mov dh, 22
    mov dl, 15
    mov bl, ATTR_DOCK
    call draw_text_at

    mov byte [cursor_row], TERM_TOP
    mov byte [cursor_col], TERM_LEFT
    call sync_hw_cursor

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

fill_rect:
    push ax
    push bx
    push cx
    push dx

    mov [rect_top], dh
    mov [rect_left], dl
    mov [rect_height], ch
    mov [rect_width], cl

    mov ah, 0x06
    xor al, al
    mov bh, bl
    mov ch, [rect_top]
    mov cl, [rect_left]
    mov dh, [rect_top]
    add dh, [rect_height]
    dec dh
    mov dl, [rect_left]
    add dl, [rect_width]
    dec dl
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_text_at:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    call calc_offset
    mov ax, 0xb800
    mov es, ax
    mov ah, bl
.next:
    lodsb
    cmp al, 0
    je .done
    stosw
    jmp .next
.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

calc_offset:
    xor ax, ax
    mov al, dh
    mov cl, SCREEN_COLS
    mul cl
    xor cx, cx
    mov cl, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    ret

vga_write_char:
    push bx
    push cx
    push dx
    push di
    push es
    push ax

    call calc_offset
    mov cx, 0xb800
    mov es, cx
    pop ax
    mov ah, bl
    mov [es:di], ax

    pop es
    pop di
    pop dx
    pop cx
    pop bx
    ret

term_putc:
    push ax
    push bx
    push dx

    cmp al, 13
    je .carriage
    cmp al, 10
    je .line_feed
    cmp al, 8
    je .backspace
    cmp al, 32
    jb .done

    mov dh, [cursor_row]
    mov dl, [cursor_col]
    mov bl, ATTR_TERM
    call vga_write_char
    inc byte [cursor_col]
    cmp byte [cursor_col], TERM_LEFT + TERM_WIDTH
    jb .sync
    mov byte [cursor_col], TERM_LEFT
    call terminal_newline
    jmp .sync

.carriage:
    mov byte [cursor_col], TERM_LEFT
    jmp .sync

.line_feed:
    call terminal_newline
    jmp .sync

.backspace:
    cmp byte [cursor_col], TERM_LEFT
    ja .same_line
    cmp byte [cursor_row], TERM_TOP
    jbe .sync
    dec byte [cursor_row]
    mov byte [cursor_col], TERM_LEFT + TERM_WIDTH - 1
    jmp .erase
.same_line:
    dec byte [cursor_col]
.erase:
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    mov al, ' '
    mov bl, ATTR_TERM
    call vga_write_char
    jmp .sync

.sync:
    call sync_hw_cursor
.done:
    pop dx
    pop bx
    pop ax
    ret

terminal_newline:
    inc byte [cursor_row]
    cmp byte [cursor_row], TERM_TOP + TERM_HEIGHT
    jb .done
    mov byte [cursor_row], TERM_TOP + TERM_HEIGHT - 1
    call scroll_terminal
.done:
    ret

scroll_terminal:
    push ax
    push bx
    push cx
    push dx

    mov ah, 0x06
    mov al, 1
    mov bh, ATTR_TERM
    mov ch, TERM_TOP
    mov cl, TERM_LEFT
    mov dh, TERM_TOP + TERM_HEIGHT - 1
    mov dl, TERM_LEFT + TERM_WIDTH - 1
    int 0x10

    pop dx
    pop cx
    pop bx
    pop ax
    ret

sync_hw_cursor:
    push ax
    push bx
    push dx

    mov ah, 0x02
    mov bh, 0
    mov dh, [cursor_row]
    mov dl, [cursor_col]
    int 0x10

    pop dx
    pop bx
    pop ax
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

    mov di, cmd_gui
    call streq
    cmp al, 1
    je command_gui

    mov di, cmd_desktop
    call streq
    cmp al, 1
    je command_gui

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
    call draw_ui
    ret

command_gui:
    call draw_ui
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
       db "Terminal OS Desktop", 13, 10
       db "A clean VGA workspace with a built-in shell. Type 'help'.", 13, 10, 13, 10, 0
prompt db "desk> ", 0

help_message db "commands: help about clear cls gui desktop echo mem reboot poweroff halt", 13, 10, 0
about_message db "Terminal OS: one boot sector, one 16-bit kernel, one tiny shell, and a modern VGA desktop.", 13, 10, 0
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
cmd_gui db "gui", 0
cmd_desktop db "desktop", 0
cmd_echo db "echo", 0
cmd_echo_prefix db "echo ", 0
cmd_mem db "mem", 0
cmd_reboot db "reboot", 0
cmd_poweroff db "poweroff", 0
cmd_halt db "halt", 0
cmd_exit db "exit", 0

top_brand db "Terminal OS", 0
top_menu db "Desktop   Shell   Files   Settings", 0
top_status db "Status: Ready", 0
tile_shell_title db "Shell", 0
tile_shell_sub db "live console", 0
tile_files_title db "Files", 0
tile_files_sub db "coming soon", 0
tile_settings_title db "Settings", 0
tile_settings_sub db "display", 0
tile_power_title db "Power", 0
tile_power_sub db "safe exit", 0
window_title db "[x] [ ] [ ]  Shell", 0
window_footer db "Type help for commands. gui redraws the desktop.", 0
dock_label db "[ Shell ]   [ Files ]   [ Settings ]   [ Power ]", 0

cursor_row db TERM_TOP
cursor_col db TERM_LEFT
rect_top db 0
rect_left db 0
rect_height db 0
rect_width db 0

input_buffer times MAX_INPUT db 0
