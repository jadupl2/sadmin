#! /bin/bash
# This script is used to backup all important unix files on the system.
# It could easily fit on a diskette
# Original protections are preserved
# Jacques Duplessis - September 1999
# =============================================================================
#
# Where backup is done
#set -x

# Where File will be backup
BDIR=/mystuff/Files_to_Keep  ; export BDIR

# Make Directories Structure where backup will reside
mkdir -p $BDIR/usr/spool/cron/crontabs
mkdir -p $BDIR/etc/rc.d
mkdir -p $BDIR/home_root
tput clear

# DNS FILES
echo -e "\nCopying DNS Setup Files ..."
mkdir -p   $BDIR/etc/named.dat
cp -vfp    /etc/named.conf   $BDIR/etc
cp -vfRdp  /etc/named.dat/*  $BDIR/etc/named.dat
cp -vfp    /etc/resolv.conf  $BDIR/etc

# PPP FILES
echo -e "\nCopying PPP Files ..."
mkdir -p $BDIR/etc/ppp
cp -vfRdp /etc/ppp $BDIR/etc/ppp

# NETWORK CONFIG FILES
echo -e "\nCopying ssh Files ..."
cp -vfRdp /etc/socks5*       $BDIR/etc
cp -vfp   /etc/pump..conf    $BDIR/etc/pump.conf
cp -vfp   /etc/diald.conf    $BDIR/etc/diald.conf

# SSH FILES
echo -e "\nCopying ssh Files ..."
mkdir -p $BDIR/etc/ssh
mkdir -p $BDIR/etc/ssh2
cp -vfRdp /etc/ssh/*         $BDIR/etc/ssh
cp -vfRdp /etc/ssh2/*        $BDIR/etc/ssh2
cp -vfRdp /usr/local/etc     $BDIR/usr/local/etc

# SENDMAIL CONFIG FILES
echo -e "\nCopying Mail Files ..."
mkdir -p $BDIR/etc/mail
cp -vfRdp /etc/aliases       $BDIR/etc/
cp -vfRdp /etc/sendmail.cf   $BDIR/etc/
cp -vfRdp /etc/sendmail.cw   $BDIR/etc/
cp -vfRdp /etc/mail/*        $BDIR/etc/mail

# XWINDOWS CONFIG FILES 
echo -e "\nCopying Xwindows Setup ..."
cp -vfp /etc/X11/XF86Config  $BDIR/etc/X11/XF86Config.`hostname`

# PRINTER CONFIG FILES 
echo -e "\nCopying Printer info ..."
cp -vfp /etc/printcap* $BDIR/etc

echo -e "\nCopying Samba Files ..."
cp -vfp /etc/smb.conf $BDIR/etc

echo -e "\nCopying TCP/IP Files ..."
cp -vfp /etc/hosts $BDIR/etc
cp -vfp /etc/ntp.*  $BDIR/etc
cp -vfp /etc/exports $BDIR/etc
cp -vfp /etc/ftpusers $BDIR/etc
cp -vfp /etc/hosts* $BDIR/etc
cp -vfp /etc/ftpaccess $BDIR/etc
cp -vfp /etc/conf.modules $BDIR/etc

echo -e "\nCustomized files ..."
cp -vfp /etc/nputrc $BDIR/etc/inputrc
cp -vfp /etc/rc.d/rc.local $BDIR/etc/rc.d
cp -vfp /etc/profile $BDIR/etc
cp -vfp /etc/lilo.conf $BDIR/etc
cp -vfp /usr/spool/cron/crontabs/root $BDIR/usr/spool/cron/crontabs
cp -vfp /home/jacques/.* $BDIR/home
cp -Rfpv /etc/rc.d/* $BDIR/etc/rc.d

echo -e "\nCustomized root user files ..."
cp -vfRp /root $BDIR/home_root
