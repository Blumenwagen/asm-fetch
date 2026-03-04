<div align="center">
  <img src="showcase.png" width="0" height="0"> <!-- preload -->
  
  <h1>🚀 asm-fetch</h1>
  <p><b>A fetch tool written in x86_64 assembly :/</b></p>
  <p><i>x86_64 assembly • Sys-Info fetching • Pretty fast</i></p>

  <p>
    <img src="https://img.shields.io/badge/Language-Assembly-blue?style=for-the-badge&logo=nasm" alt="Language">
    <img src="https://img.shields.io/badge/Features-Not%20Bad%20Actually-green?style=for-the-badge" alt="Features">
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
      /  \      Host:    archy
     /\   \     Distro:  CachyOS
    /  \   \    CPU:     AMD Ryzen 7 5800X 8-Core Processor
   /____\___\   Kernel:  6.19.3-2-cachyos
                WM:      Hyprland
                Shell:   /bin/fish
                Uptime:  3h 11m
                RAM:     32012 MB
```

## 🧩 Features

| Info | Source |
|------|--------|
| �️ **Hostname** | `/proc/sys/kernel/hostname` |
| 🐧 **Distro** | `/etc/os-release` (`PRETTY_NAME`) |
| ⚡ **CPU** | `CPUID` instruction (direct hardware query) |
| � **Kernel** | `/proc/sys/kernel/osrelease` |
| 🪟 **WM / Desktop** | `XDG_CURRENT_DESKTOP` env var |
| � **Shell** | `SHELL` env var |
| ⏱️ **Uptime** | `/proc/uptime` → `Xd Xh Xm` |
| � **RAM** | `sysinfo` syscall → MB |

> [!TIP]
> Pure syscalls, zero dependencies, no libc. Just raw x86_64.

## 🚀 Quick Start

### Build Instructions

You'll need **NASM** and **ld** (via `binutils`).

```bash

# After installing dependencies, clone the repo
git clone https://github.com/blumenwagen/asm-fetch.git
cd asm-fetch

# Build (assemble + link + strip)
make

# Clean build artifacts
make clean

# Install to ~/.local/bin/
make install
```

Or manually:

```bash
nasm -f elf64 asm-fetch.asm -o asm-fetch.o
ld -s asm-fetch.o -o asm-fetch
```

### Running

```bash
./asm-fetch
```

> [!NOTE]
> You can also run `make install` to copy it to `~/.local/bin/`, or manually add it to your PATH.
