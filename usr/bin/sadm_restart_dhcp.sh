#! /bin/sh
tput clear
echo "Before Stop"
ps -ef | grep dhcpd | grep -v grep
systemctl restart dhcpd
echo "After Start"
ps -ef | grep dhcpd | grep -v grep
echo " " 
systemctl status dhcpd
