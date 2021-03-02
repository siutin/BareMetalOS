all: run

prepare:
	mkdir -p build
	
build/boot.o: prepare boot.asm
	nasm -felf32 -o build/boot.o boot.asm

build/boot: prepare build/boot.o
	ld -m elf_i386 --script=linker.ld -n -o build/boot build/boot.o
	
build/os.iso: prepare build/boot
	mkdir -p build/img/boot/
	cp -a grub build/img/boot/
	cp build/boot build/img/boot/
	grub-mkrescue -o build/os.iso build/img

build/os.img: prepare build/boot
	sudo ./mkimage.sh && sudo chown 1000:1000 build/os.img

run-iso: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso

run-img: build/os.img
	qemu-system-x86_64 -hda build/os.img

clean:
	-rm build/boot.o
	-rm build/boot
	-rm build/os.iso
	-rm build/os.img