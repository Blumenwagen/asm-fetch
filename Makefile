ASM      = nasm
LDFLAGS  = -s
SRC      = asm-fetch.asm
OBJ      = asm-fetch.o
BIN      = asm-fetch

.PHONY: all clean install

all: $(BIN)

$(OBJ): $(SRC)
	$(ASM) -f elf64 $(SRC) -o $(OBJ)

$(BIN): $(OBJ)
	ld $(LDFLAGS) $(OBJ) -o $(BIN)

clean:
	rm -f $(OBJ) $(BIN)

install: $(BIN)
	install -Dm755 $(BIN) $(HOME)/.local/bin/$(BIN)
