<div align="center">
  <img src="showcase.png" width="0" height="0"> <!-- preload -->
  
  <h1>🚀 asm-fetch</h1>
  <p><b>A fetch tool written in x86_64 assembly :/</b></p>
  <p><i>x86_64 assembly • Sys-Info fetching • Pretty fast</i></p>

  <p>
    <img src="https://img.shields.io/badge/Language-Assembly-blue?style=for-the-badge&logo=nasm" alt="Language">
    <img src="https://img.shields.io/badge/Features-Almost%20None-red?style=for-the-badge" alt="Features">
  </p>
</div>

<br>

<p align="center">
  <img src="showcase.png" alt="asm-fetch execution" width="100%" onerror="this.style.display='none';"> 
</p>

## 📝 About

This is a little project written in x86_64 assembly for fetching system information. Why? Because I was bored and now I hate myself.

**Besides all my problems, it turned out that writing something in assembly makes it really, really fast. Probably one of the fastest fetch programs out there... maybe... idk.**

```ansi
       /\       asm-fetch:
      /  \      CPU:    Intel(R) Core(TM) i5-8250U CPU @ 1.60GHz
     /\   \     Kernel: 6.19.5-3-cachyos
    /  \   \    WM:     Hyprland
   /____\___\   RAM:    7800 MB
```

## 🧩 Features

| Feature | Description |
|---------|-------------|
| 🚀 **Speed** | It's written in Assembly. It's actually not that slow. |
| 🪹 **Features** | Almost None. It can show data and that's it. |
| 🛠️ **Customizability** | I would not recommend trying to customize it. |
| 🤔 **Usability** | Usable but not very customizable. |

## 🚀 Quick Start

### Build Instructions

There is a prebuilt binary in the repo if you don't want to build it yourself.

To build `asm-fetch`, you'll need the **NASM Assembler** and standard **GNU Linker**.
Ensure `nasm` and `ld` (via `binutils`) are installed on your system.

```bash
# 1. Assemble the ELF64 object 
nasm -f elf64 asm-fetch.asm 

# 2. Link it into a native binary executable 
ld asm-fetch.o -o asm-fetch
```

### Running

Run the resulting executable directly through your shell:

```bash
./asm-fetch
```

> [!NOTE]
> If you want to actually use it like normal, you could also add it to your PATH by copying it to `/usr/local/bin` or `/bin`.
