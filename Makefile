all: run

build/boot.o: boot.asm
	nasm -felf32 -o build/boot.o boot.asm

build/boot: build/boot.o
	ld -m elf_i386 --script=linker.ld -n -o build/boot build/boot.o
	
iso: build/boot
	mkdir -p build
	cp -a iso build/
	cp build/boot build/iso/boot
	grub-mkrescue -o build/os.iso build/iso

run: iso
	qemu-system-x86_64 -cdrom build/os.iso

clean:
	-rm build/boot.o
	-rm build/boot
	-rm build/os.iso