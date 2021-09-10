all: run

prepare:
	mkdir -p build

build/loader.o: prepare loader.asm
	nasm -felf64 -o build/loader.o loader.asm

build/lowlevel.o: prepare lowlevel.asm
	nasm -g -felf64 -o build/lowlevel.o lowlevel.asm

build/vga.o: prepare vga.h vga.h
	gcc -c -Og -m64 -z max-page-size=0x1000 -lgcc -Wall -Wextra -ffreestanding -fno-asynchronous-unwind-tables -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -fno-pic -no-pie -T linker.ld -Wl,-n -o build/vga.o vga.c

build/keyb.o: prepare keyb.c
	gcc -c -Og -m64 -z max-page-size=0x1000 -lgcc -Wall -Wextra -ffreestanding -fno-asynchronous-unwind-tables -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -fno-pic -no-pie -T linker.ld -Wl,-n -o build/keyb.o keyb.c

build/printf.o: prepare printf.c printf.h
	gcc -c -Og -m64 -z max-page-size=0x1000 -lgcc -Wall -Wextra -ffreestanding -fno-asynchronous-unwind-tables -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -fno-pic -no-pie -T linker.ld -Wl,-n -o build/printf.o printf.c

build/main.o: prepare main.c main.h
	gcc -g -c -Og -m64 -z max-page-size=0x1000 -lgcc -Wall -Wextra -ffreestanding -fno-asynchronous-unwind-tables -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -fno-pic -no-pie -T linker.ld -Wl,-n -o build/main.o main.c

build/kernel: prepare build/loader.o build/lowlevel.o build/vga.o build/keyb.o build/printf.o build/main.o
	ld -m elf_x86_64 -nostdlib --script=linker.ld -n -o build/kernel build/loader.o build/lowlevel.o build/vga.o build/keyb.o build/printf.o build/main.o

# build/kernel.elf: build/loader.o build/lowlevel.o build/vga.o build/keyb.o build/printf.o build/main.o
# 	gcc -Og -m64 -Wl,--build-id=none -T linker.ld -o build/kernel.elf -lgcc -Wall -Wextra -ffreestanding -fno-asynchronous-unwind-tables -fno-builtin -nostdlib -fno-omit-frame-pointer -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -fno-pic -no-pie build/loader.o build/lowlevel.o build/vga.o build/keyb.o build/printf.o build/main.o

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
	qemu-system-x86_64 -m 4G -drive format=raw,file=build/os.img -chardev stdio,id=char0,mux=on,logfile=serial.log,signal=on \
  -serial chardev:char0 -mon chardev=char0

run-img-gdb: build/os.img
	qemu-system-x86_64 -m 4G -drive format=raw,file=build/os.img -chardev stdio,id=char0,mux=on,logfile=serial.log,signal=on \
  -serial chardev:char0 -mon chardev=char0 -s -S -d int -no-reboot -no-shutdown

fix:
	sudo dmsetup remove -f loop1p1

clean:
	-rm build/kernel.o
	-rm build/kernel
	-rm build/os.iso
	-rm build/os.img
	-rm build/kernel.elf