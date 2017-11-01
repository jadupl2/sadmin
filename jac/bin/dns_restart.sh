#! /bin/sh
tput clear
echo "Before Stop"
ps -ef | grep named | grep -v grep
systemctl restart named-chroot
echo "After Start"
ps -ef | grep named | grep -v grep
echo " " 
systemctl status named-chroot 
