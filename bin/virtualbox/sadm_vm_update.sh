#! /usr/bin/env bash
mkdir /mnt/nfs    >/dev/null 2>&1
mkdir /mnt/cdrom  >/dev/null 2>&1

mount borg:/vm/iso /mnt/nfs
mount /mnt/nfs/VBoxGuestAdditions.iso /mnt/cdrom -o loop
/mnt/cdrom/VBoxLinuxAdditions.run

umount /mnt/cdrom
umount /mnt/nfs
