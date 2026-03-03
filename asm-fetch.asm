DEFAULT REL

section .data
    ascii_0      db 10, 27, "[36;1m", "       /\       ", 27, "[35;1m", "asm-fetch:", 27, "[0m", 10, 0
    label_cpu    db 27, "[36;1m", "      /  \      ", 27, "[34;1m", "CPU:    ", 27, "[0m", 0
    label_ker    db 27, "[36;1m", "     /\   \     ", 27, "[34;1m", "Kernel: ", 27, "[0m", 0
    label_wm     db 27, "[36;1m", "    /  \   \    ", 27, "[34;1m", "WM:     ", 27, "[0m", 0
    label_mem    db 27, "[36;1m", "   /____\___\   ", 27, "[34;1m", "RAM:    ", 27, "[0m", 0
    newline      db 10
    path_os      db "/proc/sys/kernel/osrelease", 0
    unit_mb      db " MB", 10, 0
    env_wm       db "XDG_CURRENT_DESKTOP=", 0
    wm_unknown   db "Unknown", 10, 0

section .bss
    buffer       resb 128
    cpu_brand    resb 48
    mem_str      resb 16
    envp_ptr     resq 1

section .text
    global _start

_start:
    mov [envp_ptr], rsp

    mov rsi, ascii_0
    call print_str

    ; --- 1. Get CPU Brand (The hardware way) ---
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

    ; Print CPU Label and Brand
    mov rsi, label_cpu
    call print_str
    mov rsi, cpu_brand
    call print_str
    call print_newline

    ; --- 2. Get Kernel Version ---
    mov rsi, label_ker
    call print_str
    ; Open osrelease
    mov rax, 2          ; open
    mov rdi, path_os
    xor rsi, rsi        ; O_RDONLY
    syscall
    mov rdi, rax        ; fd
    mov rax, 0          ; read
    mov rsi, buffer
    mov rdx, 64
    syscall
    mov rdx, rax        ; length read
    mov rax, 1          ; write
    mov rdi, 1          ; stdout
    mov rsi, buffer
    syscall

    ; --- 3. Get WM ---
    mov rsi, label_wm
    call print_str
    
    mov rdi, env_wm
    call get_env
    test rax, rax
    jz .wm_unknown
    
    mov rsi, rax
    call print_str
    call print_newline
    jmp .ram_start
    
.wm_unknown:
    mov rsi, wm_unknown
    call print_str

.ram_start:
    ; --- 4. Get RAM (Using sysinfo syscall) ---
    sub rsp, 128        ; Allocate space on stack
    mov rax, 99         ; sysinfo syscall
    mov rdi, rsp        ; pointer to struct
    syscall
    
    ; totalram is at offset 32 (8 bytes), mem_unit is at offset 104 (4 bytes)
    mov rax, [rsp + 32] ; totalram
    xor rbx, rbx
    mov ebx, [rsp + 104]; mem_unit
    mul rbx             ; rax = total bytes
    shr rax, 20         ; divide by 1024*1024 (convert to MB)
    
    mov rdi, mem_str
    call int_to_string
    push rsi           ; save the pointer returned by int_to_string

    mov rsi, label_mem
    call print_str
    
    pop rsi            ; restore the pointer
    call print_str
    
    mov rsi, unit_mb
    call print_str

    ; --- Exit ---
    mov rax, 60
    xor rdi, rdi
    syscall

; --- Helper Functions ---

print_str:
    push rsi
    xor rdx, rdx
.loop_p:
    cmp byte [rsi + rdx], 0
    je .done
    inc rdx
    jmp .loop_p
.done:
    mov rax, 1
    mov rdi, 1
    syscall
    pop rsi
    ret

print_newline:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    ret

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

get_env:
    mov rcx, [envp_ptr]
    mov rbx, [rcx]       ; argc
    lea r8, [rcx + 8 + rbx*8 + 8] ; pointer to envp array
.loop_e:
    mov rsi, [r8]        ; rsi = envp[i]
    test rsi, rsi
    jz .not_found
    push rdi
    push rsi
    xor rdx, rdx
.cmploop:
    mov al, [rdi + rdx]
    test al, al
    jz .match
    mov ah, [rsi + rdx]
    cmp al, ah
    jne .differ
    inc rdx
    jmp .cmploop
.differ:
    pop rsi
    pop rdi
    add r8, 8
    jmp .loop_e
.match:
    pop rsi
    pop rdi
    lea rax, [rsi + rdx]
    ret
.not_found:
    xor rax, rax
    ret
