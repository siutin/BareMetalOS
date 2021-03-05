all: run

prepare:
	mkdir -p build

build/loader.o: prepare loader.asm
	nasm -felf32 -o build/loader.o loader.asm

build/main.o: prepare main.c
	gcc -c -no-pie -m32 -z max-page-size=0x1000 -lgcc -Wall -Wextra -ffreestanding -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -T linker.ld -Wl,-n -o build/main.o main.c

build/kernel: prepare build/loader.o build/main.o
	ld -m elf_i386 -nostdlib --script=linker.ld -n -o build/kernel build/loader.o build/main.o

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