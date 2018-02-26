./ramdisk-build.sh
ssh-copy-id -i ~/.ssh/id_rsa.pub root@$1
scp -P 2258 boot/* root@$1:/boot
scp -P 2258 $2 root@$1:/home/newrootfs.tgz
ssh root@$1 "new-kernel-pkg --initrdfile=/boot/initrd-migration.img --make-default --install migration;new-kernel-pkg --remove-args='ro root=LABEL=/ quiet 8250.nr_uarts=32 panic=5 loglevel=3' --update migration"
