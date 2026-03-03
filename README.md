
# asm-fetch: A fetch tool written in x86_64 assembly :/


```ansi
       /\       asm-fetch:
      /  \      CPU:    Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
     /\   \     Kernel: 6.19.5-3-cachyos
    /  \   \    WM:     Hyprland
   /____\___\   RAM:    7800 MB
```

This is a little project written in x86_64 assembly for fetching system information. Why? Because I was bored and now I hate myself.

## Features

- None. It can show data and that's it. I would not recommend trying to customize it. Maybe don't even use it actually.

## Build Instructions

To build `asm-fetch`, you'll need the NASM Assembler and standard GNU Linker.
Ensure `nasm` and `ld` (via `binutils`) are installed on your system.

```bash
# 1. Assemble the ELF64 object 
nasm -f elf64 asm-fetch.asm 
# 2. Link it into a native binary executable 
ld asm-fetch.o -o asm-fetch
```

## Running

Run the resulting executable directly through your shell:

```bash
./asm-fetch
```
If you want to actually use it like normal, you could also add it to your PATH I guess. 
