all: run

boot.o: boot.asm
	nasm -felf32 boot.asm

boot: boot.o
	ld -m elf_i386 --script=linker.ld -n -o boot boot.o
	

iso: boot
	cp boot iso/boot
	grub-mkrescue -o os.iso iso

run: boot iso
	qemu-system-x86_64 -cdrom os.iso

clean:
	-rm boot.o
	-rm boot