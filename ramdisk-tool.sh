#!/bin/bash

QEMU_IMAGE_CENTOS_5_4="centos-5.4.qcow2"
QEMU_IMAGE_CENTOS_5_8="centos-5.8.qcow2"
QEMU_IMAGEM_CLEAN_SNAPSHOT_NAME="Clean"
NEW_ROOT_FS="centos-image.tgz"

function build_initramdisk() {
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
}

function restore_qemu_images() {
	qemu-img snapshot -a ${QEMU_IMAGEM_CLEAN_SNAPSHOT_NAME} ${QEMU_IMAGE_CENTOS_5_4}
	qemu-img snapshot -a ${QEMU_IMAGEM_CLEAN_SNAPSHOT_NAME} ${QEMU_IMAGE_CENTOS_5_8}
}

function test_initramdisk() {
	local hda=$1
	#TODO: Adapt to use hda's with snapshots
	restore_qemu_images
	build_initramdisk
	qemu-system-x86_64 \
	-m 2048 \
	-nographic \
	-hda ${hda} \
	-kernel boot/vmlinuz-migration \
	-initrd boot/initrd-migration.img \
	-append "console=ttyS0"
}

function transfer_initramdisk_and_run() {
	build_initramdisk
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$1 -p $2
	scp -P $2 boot/* root@$1:/boot
	scp -P $2 ${NEW_ROOT_FS} root@$1:/home/.
	ssh root@$1 -p $2 "new-kernel-pkg --initrdfile=/boot/initrd-migration.img --make-default --install migration;new-kernel-pkg --remove-args='ro root=LABEL=/ quiet 8250.nr_uarts=32 panic=5 loglevel=3' --update migration;reboot"
}

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -b|--build)
        build_initramdisk;
        exit 0;
        ;;
        -t5_4|--test5_4)
        test_initramdisk ${QEMU_IMAGE_CENTOS_5_4};
        exit 0;
        ;;
        -t5_8|--test5_8)
        test_initramdisk ${QEMU_IMAGE_CENTOS_5_8};
        exit 0;
        ;;
        -r|--run)
        # arg1 is the remote host arg2 is the port
        transfer_initramdisk_and_run $2 $3;
        exit 0;
        ;;
        -c|--clean_disks)
        restore_qemu_images;
        exit 0;
        ;;
        *)
        echo "Unknown option '$key'"
        ;;
    esac
    shift
done
