all: run

boot.o: boot.asm
	nasm -felf32 boot.asm

boot: boot.o
	ld -m elf_i386 -o boot boot.o
	
run: boot
	./boot

clean:
	-rm boot.o
	-rm boot