./ramdisk-build.sh
qemu-system-x86_64 -nographic -kernel boot/vmlinuz-migration -initrd boot/initrd-migration.img -append "console=ttyS0"
