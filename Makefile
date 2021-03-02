all: run

prepare:
	mkdir -p build

build/kernel.o: prepare kernel.asm
	nasm -felf32 -o build/kernel.o kernel.asm

build/kernel: prepare build/kernel.o
	ld -m elf_i386 --script=linker.ld -n -o build/kernel build/kernel.o

build/os: prepare build/kernel
	mkdir -p build/img/boot/
	cp -a grub build/img/boot/
	cp build/kernel build/img/boot/

build/os.iso: build/os
	grub-mkrescue -o build/os.iso build/img

build/os.img: build/os
	sudo ./mkimage.sh && sudo chown 1000:1000 build/os.img

run-iso: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso

run-img: build/os.img
	qemu-system-x86_64 -hda build/os.img

clean:
	-rm build/kernel.o
	-rm build/kernel
	-rm build/os.iso
	-rm build/os.img