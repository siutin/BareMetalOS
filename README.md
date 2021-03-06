# Bare Metal OS

---

An bare metal os written in NASM and C from scratch for own study.


## Building the kernel

```
make build/kernel
```

## Installing to a disk image

```
make build-img
```

## Making a bootable ISO
```
make build-iso
```

## Testing the system with QEMU

```
make run-img
# OR
make run-iso
```