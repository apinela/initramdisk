echo "Changing directory to initramfs..."
pushd initramfs 2>&1 > /dev/null

echo "Building ramdiskfs..."
find . | cpio -H newc -o > ../initramfs.cpio
popd 2>&1 > /dev/null

echo "Compressing ramdisk in gzip..."
cat initramfs.cpio | gzip > boot/initrd-migration.img

echo "Cleaning intermediate files..."
rm -vf initramfs.cpio

echo "Built ramdisk: initrd-migration.img"
