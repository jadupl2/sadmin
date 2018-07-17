#! /bin/bash
mkdir /mnt/nfs
chmod 755 /mnt/nfs
mount holmes:/install /mnt/nfs
/mnt/nfs/sadm_postinstall.sh
