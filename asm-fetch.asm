; ===========================================================================
; asm-fetch — x86_64 Linux system information tool
; Build:  nasm -f elf64 asm-fetch.asm && ld -s asm-fetch.o -o asm-fetch
; ===========================================================================

DEFAULT REL

; ---------------------------------------------------------------------------
;  Constants
; ---------------------------------------------------------------------------
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3
SYS_SYSINFO equ 99
SYS_EXIT    equ 60
STDOUT      equ 1
O_RDONLY    equ 0

; ---------------------------------------------------------------------------
;  Data Section — ASCII art + labels
;  Each art column is exactly 16 visible chars, then the label follows.
; ---------------------------------------------------------------------------
section .data
    ; -- ANSI color codes --
    ; Cyan bold = \e[36;1m   Blue bold = \e[34;1m   Magenta bold = \e[35;1m
    ; Reset     = \e[0m

    ;                     |---- 16 chars ---|
    ; Row 0: header (art row 1)
    ascii_0      db 10
                 db 27, "[36;1m", "       /\       ", 27, "[35;1m", "asm-fetch:", 27, "[0m", 10, 0

    ; Row 1: Hostname (art row 2)
    label_host   db 27, "[36;1m", "      /  \      ", 27, "[34;1m", "Host:    ", 27, "[0m", 0

    ; Row 2: Distro (art row 3)
    label_dist   db 27, "[36;1m", "     /\   \     ", 27, "[34;1m", "Distro:  ", 27, "[0m", 0

    ; Row 3: CPU (art row 4)
    label_cpu    db 27, "[36;1m", "    /  \   \    ", 27, "[34;1m", "CPU:     ", 27, "[0m", 0

    ; Row 4: Kernel (art row 5 — base)
    label_ker    db 27, "[36;1m", "   /____\___\   ", 27, "[34;1m", "Kernel:  ", 27, "[0m", 0

    ; Row 5: WM (no art)
    label_wm     db 27, "[36;1m", "                ", 27, "[34;1m", "WM:      ", 27, "[0m", 0

    ; Row 6: Shell (no art)
    label_shell  db 27, "[36;1m", "                ", 27, "[34;1m", "Shell:   ", 27, "[0m", 0

    ; Row 7: Uptime (no art)
    label_upt    db 27, "[36;1m", "                ", 27, "[34;1m", "Uptime:  ", 27, "[0m", 0

    ; Row 8: RAM (no art)
    label_mem    db 27, "[36;1m", "                ", 27, "[34;1m", "RAM:     ", 27, "[0m", 0

    ; -- File paths --
    path_os      db "/proc/sys/kernel/osrelease", 0
    path_host    db "/proc/sys/kernel/hostname", 0
    path_osrel   db "/etc/os-release", 0
    path_uptime  db "/proc/uptime", 0

    ; -- Misc strings --
    newline      db 10
    unit_mb      db " MB", 10, 0
    unknown_str  db "Unknown", 10, 0
    day_str      db "d ", 0
    hour_str     db "h ", 0
    min_str      db "m", 10, 0

    ; -- Env var keys --
    env_wm       db "XDG_CURRENT_DESKTOP=", 0
    env_shell    db "SHELL=", 0

    ; -- For parsing PRETTY_NAME from os-release --
    pretty_key   db "PRETTY_NAME=", 0

; ---------------------------------------------------------------------------
;  BSS Section
; ---------------------------------------------------------------------------
section .bss
    buffer       resb 256
    cpu_brand    resb 48
    mem_str      resb 16
    upt_str      resb 32
    envp_ptr     resq 1

; ---------------------------------------------------------------------------
;  Text Section
; ---------------------------------------------------------------------------
section .text
    global _start

_start:
    ; Save stack pointer early (contains argc, argv, envp)
    mov [envp_ptr], rsp

    ; ===== Row 0: Header ASCII art =====
    mov rsi, ascii_0
    call print_str

    ; ===== Row 1: Hostname =====
    mov rsi, label_host
    call print_str
    mov rdi, path_host
    call read_proc_file
    test rax, rax
    jle .host_unknown
    mov rdi, buffer
    call trim_newline
    mov rsi, buffer
    call print_str
    call print_newline
    jmp .distro_start
.host_unknown:
    mov rsi, unknown_str
    call print_str

.distro_start:
    ; ===== Row 2: Distro (parse PRETTY_NAME from /etc/os-release) =====
    mov rsi, label_dist
    call print_str
    mov rdi, path_osrel
    call read_proc_file
    test rax, rax
    jle .distro_unknown
    mov rdi, buffer
    mov rsi, pretty_key
    mov rdx, rax
    call find_line_value
    test rax, rax
    jz .distro_unknown
    mov rsi, rax
    call print_until_newline
    call print_newline
    jmp .cpu_start
.distro_unknown:
    mov rsi, unknown_str
    call print_str

.cpu_start:
    ; ===== Row 3: CPU Brand (via CPUID) =====
    mov rdi, cpu_brand
    mov eax, 0x80000002
    cpuid
    mov [rdi], eax
    mov [rdi+4], ebx
    mov [rdi+8], ecx
    mov [rdi+12], edx
    mov eax, 0x80000003
    cpuid
    mov [rdi+16], eax
    mov [rdi+20], ebx
    mov [rdi+24], ecx
    mov [rdi+28], edx
    mov eax, 0x80000004
    cpuid
    mov [rdi+32], eax
    mov [rdi+36], ebx
    mov [rdi+40], ecx
    mov [rdi+44], edx

    mov rsi, label_cpu
    call print_str
    mov rsi, cpu_brand
    call skip_spaces
    mov rsi, rax
    call print_str
    call print_newline

.kernel_start:
    ; ===== Row 4: Kernel Version =====
    mov rsi, label_ker
    call print_str
    mov rdi, path_os
    call read_proc_file
    test rax, rax
    jle .kernel_unknown
    mov rdi, buffer
    call trim_newline
    mov rsi, buffer
    call print_str
    call print_newline
    jmp .wm_start
.kernel_unknown:
    mov rsi, unknown_str
    call print_str

.wm_start:
    ; ===== Row 5: WM / Desktop =====
    mov rsi, label_wm
    call print_str
    mov rdi, env_wm
    call get_env
    test rax, rax
    jz .wm_unknown
    mov rsi, rax
    call print_str
    call print_newline
    jmp .shell_start
.wm_unknown:
    mov rsi, unknown_str
    call print_str

.shell_start:
    ; ===== Row 6: Shell =====
    mov rsi, label_shell
    call print_str
    mov rdi, env_shell
    call get_env
    test rax, rax
    jz .shell_unknown
    mov rsi, rax
    call print_str
    call print_newline
    jmp .uptime_start
.shell_unknown:
    mov rsi, unknown_str
    call print_str

.uptime_start:
    ; ===== Row 7: Uptime (parse /proc/uptime) =====
    mov rsi, label_upt
    call print_str
    mov rdi, path_uptime
    call read_proc_file
    test rax, rax
    jle .upt_unknown

    ; Parse integer part of uptime (seconds before the '.' or ' ')
    mov rsi, buffer
    xor rax, rax
    xor rcx, rcx
.parse_upt:
    movzx rdx, byte [rsi + rcx]
    cmp dl, '.'
    je .upt_parsed
    cmp dl, ' '
    je .upt_parsed
    cmp dl, 0
    je .upt_parsed
    sub dl, '0'
    imul rax, 10
    movzx rdx, dl
    add rax, rdx
    inc rcx
    jmp .parse_upt

.upt_parsed:
    ; rax = total seconds — convert to days, hours, minutes
    xor rdx, rdx
    mov rbx, 86400
    div rbx
    mov r12, rax           ; r12 = days
    mov rax, rdx
    xor rdx, rdx
    mov rbx, 3600
    div rbx
    mov r13, rax           ; r13 = hours
    mov rax, rdx
    xor rdx, rdx
    mov rbx, 60
    div rbx
    mov r14, rax           ; r14 = minutes

    ; Print days if > 0
    test r12, r12
    jz .upt_hours
    mov rax, r12
    mov rdi, upt_str
    call int_to_string
    call print_str
    mov rsi, day_str
    call print_str

.upt_hours:
    mov rax, r13
    mov rdi, upt_str
    call int_to_string
    call print_str
    mov rsi, hour_str
    call print_str

    mov rax, r14
    mov rdi, upt_str
    call int_to_string
    call print_str
    mov rsi, min_str
    call print_str
    jmp .ram_start

.upt_unknown:
    mov rsi, unknown_str
    call print_str

.ram_start:
    ; ===== Row 8: RAM (sysinfo syscall) =====
    sub rsp, 128
    mov rax, SYS_SYSINFO
    mov rdi, rsp
    syscall
    test rax, rax
    jnz .ram_unknown

    ; totalram at offset 32, mem_unit at offset 104
    mov rax, [rsp + 32]
    xor rbx, rbx
    mov ebx, [rsp + 104]
    mul rbx
    shr rax, 20            ; convert to MB

    mov rdi, mem_str
    call int_to_string
    push rsi

    mov rsi, label_mem
    call print_str

    pop rsi
    call print_str

    mov rsi, unit_mb
    call print_str
    jmp .exit

.ram_unknown:
    mov rsi, label_mem
    call print_str
    mov rsi, unknown_str
    call print_str

.exit:
    add rsp, 128
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; ===========================================================================
;  Helper Functions
; ===========================================================================

; print_str: print null-terminated string at RSI to stdout
print_str:
    push rsi
    xor rdx, rdx
.loop_p:
    cmp byte [rsi + rdx], 0
    je .done_p
    inc rdx
    jmp .loop_p
.done_p:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    pop rsi
    ret

; print_newline: write a single newline to stdout
print_newline:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

; print_until_newline: print chars at RSI until newline, null, or closing quote
print_until_newline:
    push rsi
    ; Skip leading double-quote if present
    cmp byte [rsi], '"'
    jne .no_lead_quote
    inc rsi
.no_lead_quote:
    xor rdx, rdx
.loop_pun:
    mov al, [rsi + rdx]
    cmp al, 10
    je .done_pun
    cmp al, 0
    je .done_pun
    cmp al, '"'
    je .done_pun
    inc rdx
    jmp .loop_pun
.done_pun:
    test rdx, rdx
    jz .skip_print
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
.skip_print:
    pop rsi
    ret

; int_to_string: convert integer in RAX to decimal string
;   RDI = pointer to buffer (needs ~11 bytes)
;   Returns: RSI = pointer to start of string in buffer
int_to_string:
    add rdi, 10
    mov byte [rdi], 0
    mov rbx, 10
.loop_i:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rdi
    mov [rdi], dl
    test rax, rax
    jnz .loop_i
    mov rsi, rdi
    ret

; read_proc_file: open file at RDI path, read up to 255 bytes into `buffer`
;   Returns: RAX = bytes read (negative on error)
read_proc_file:
    push rdi
    mov rax, SYS_OPEN
    xor rsi, rsi
    xor rdx, rdx
    syscall
    test rax, rax
    js .rpf_fail

    mov rdi, rax
    mov rax, SYS_READ
    mov rsi, buffer
    mov rdx, 255
    syscall
    push rax

    mov rax, SYS_CLOSE
    syscall

    pop rax
    pop rdi
    ret
.rpf_fail:
    xor rax, rax
    pop rdi
    ret

; trim_newline: replace first newline in string at RDI with null
trim_newline:
    xor rcx, rcx
.loop_tn:
    cmp byte [rdi + rcx], 0
    je .done_tn
    cmp byte [rdi + rcx], 10
    je .found_tn
    inc rcx
    jmp .loop_tn
.found_tn:
    mov byte [rdi + rcx], 0
.done_tn:
    ret

; skip_spaces: skip leading spaces/tabs in string at RSI
;   Returns: RAX = pointer to first non-space character
skip_spaces:
    mov rax, rsi
.loop_ss:
    cmp byte [rax], ' '
    je .next_ss
    cmp byte [rax], 9
    je .next_ss
    ret
.next_ss:
    inc rax
    jmp .loop_ss

; find_line_value: find a key in multi-line text and return pointer to value
;   RDI = haystack, RSI = needle (null-terminated), RDX = haystack length
;   Returns: RAX = pointer to value after key, or 0 if not found
find_line_value:
    push rbx
    push r8
    push r9
    ; Get needle length
    xor r8, r8
.needle_len:
    cmp byte [rsi + r8], 0
    je .needle_done
    inc r8
    jmp .needle_len
.needle_done:
    xor rbx, rbx
.search_loop:
    mov r9, rdx
    sub r9, rbx
    cmp r9, r8
    jl .not_found_flv
    mov r9, rbx
    xor rcx, rcx
.cmp_loop:
    cmp rcx, r8
    je .found_flv
    movzx eax, byte [rdi + rbx]
    cmp al, [rsi + rcx]
    jne .no_match
    inc rbx
    inc rcx
    jmp .cmp_loop
.no_match:
    lea rbx, [r9 + 1]
    jmp .search_loop
.found_flv:
    lea rax, [rdi + rbx]
    pop r9
    pop r8
    pop rbx
    ret
.not_found_flv:
    xor rax, rax
    pop r9
    pop r8
    pop rbx
    ret

; get_env: search environment for variable starting with string at RDI
;   Returns: RAX = pointer to value (after prefix), or 0 if not found
get_env:
    mov rcx, [envp_ptr]
    mov rbx, [rcx]
    lea r8, [rcx + 8 + rbx*8 + 8]
.loop_e:
    mov rsi, [r8]
    test rsi, rsi
    jz .not_found_e
    push rdi
    push rsi
    xor rdx, rdx
.cmploop_e:
    mov al, [rdi + rdx]
    test al, al
    jz .match_e
    mov ah, [rsi + rdx]
    cmp al, ah
    jne .differ_e
    inc rdx
    jmp .cmploop_e
.differ_e:
    pop rsi
    pop rdi
    add r8, 8
    jmp .loop_e
.match_e:
    pop rsi
    pop rdi
    lea rax, [rsi + rdx]
    ret
.not_found_e:
    xor rax, rax
    ret
