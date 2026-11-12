AS ?= as
LD ?= ld
PYTHON ?= python3
.PHONY: all clean test
all: dist/SHIPS.COM
build/ships.o: src/ships.S
	mkdir -p build
	$(AS) --32 -o $@ $<
dist/SHIPS.COM: build/ships.o
	mkdir -p dist
	$(LD) -m elf_i386 -Ttext 0x100 --oformat binary -o $@ $<
test: all
	$(PYTHON) tests/check_8086.py build/ships.o dist/SHIPS.COM
clean:
	rm -rf build dist/SHIPS.COM
