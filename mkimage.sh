# Modified from Original Source - https://github.com/roscopeco/mink/blob/master/mkimage.sh

# Create the actual disk image - 10MB
dd if=/dev/zero of=build/os.img count=10 bs=1048576

# Make the partition table, partition and set it bootable.
parted --script build/os.img mklabel msdos mkpart p ext2 1 10 set 1 esp on set 1 boot on p

# Map the partitions from the image file and find where loopback will be
looppart=`kpartx -l build/os.img | awk -e '{ print $1; exit }'`
loopdev=`kpartx -l build/os.img | awk -e '{ print $5; exit }'`
kpartx -av build/os.img

# sleep a sec, wait for kpartx to create the device nodes
sleep 2

# Make an ext2 filesystem on the first partition.
mkfs.ext2 /dev/mapper/$looppart

# Make the mount-point
mkdir -p build/mnt/p1

# Mount the filesystem via loopback
mount /dev/mapper/$looppart build/mnt/p1

# Copy in the files from the staging directory
cp -r build/img/* build/mnt/p1

# Create a device map for grub
echo "(hd0) $loopdev" > build/mnt/device.map

# Use grub2-install to actually install Grub. The options are:
#   * No floppy polling.
#   * Use the device map we generated in the previous step.
#   * Include the basic set of modules we need in the Grub image.
#   * Install grub into the filesystem at our loopback mountpoint.
#   * Install the MBR to the loopback device itself.
grub-install  --no-floppy                                                      \
              --grub-mkdevicemap=build/mnt/device.map                          \
              --modules="biosdisk part_msdos ext2 configfile normal multiboot" \
              --root-directory=build/mnt/p1                                    \
              --boot-directory=build/mnt/p1/boot                               \
              --force                                                          \
              --target="i386-pc"                                               \
              $loopdev

# Unmount the loopback
umount build/mnt/p1

# Unmap the image
kpartx -dv build/os.img